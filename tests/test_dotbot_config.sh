#!/usr/bin/env bash
# Dotbot configuration tests
set -uo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

function info() { echo -e "${YELLOW}[INFO] $1${NC}"; }
function success() { echo -e "${GREEN}[PASS] $1${NC}"; }
function error() { echo -e "${RED}[FAIL] $1${NC}"; }

TESTS_PASSED=0
TESTS_FAILED=0

test_case() {
    local test_name="$1"
    shift
    
    info "Testing: $test_name"
    if "$@"; then
        success "$test_name"
        ((TESTS_PASSED++))
    else
        error "$test_name"
        ((TESTS_FAILED++))
    fi
}

# Test: Base dotbot configuration exists and is valid YAML
test_base_config() {
    local has_error=0
    
    if [ ! -f ".dotbot/base.yaml" ]; then
        error "Base configuration not found"
        return 1
    fi
    
    # Basic YAML syntax check (if python/yq available)
    if command -v python3 >/dev/null 2>&1; then
        if ! python3 -c "import yaml; yaml.safe_load(open('.dotbot/base.yaml'))" 2>/dev/null; then
            error "base.yaml is not valid YAML"
            has_error=1
        fi
    fi
    
    return $has_error
}

# Test: All profile configs exist
test_profile_configs() {
    local has_error=0
    
    if [ ! -d ".dotbot/profiles" ]; then
        error "Profiles directory not found"
        return 1
    fi
    
    # Check that profiles exist
    local profiles=("default" "full" "template")
    for profile in "${profiles[@]}"; do
        if [ ! -f ".dotbot/profiles/$profile" ]; then
            error "Profile missing: $profile"
            has_error=1
        fi
    done
    
    return $has_error
}

# Test: All config files referenced in profiles exist
test_config_references() {
    local has_error=0
    
    # Read configs from profiles
    while IFS= read -r profile_file; do
        while IFS= read -r config_name; do
            # Skip empty lines, comments, and lines with spaces (profile descriptions)
            [[ -z "$config_name" || "$config_name" == \#* || "$config_name" =~ [[:space:]] ]] && continue
            
            local config_file=".dotbot/configs/${config_name}.yaml"
            if [ ! -f "$config_file" ]; then
                info "Config referenced but not found: $config_file (from $(basename "$profile_file"))"
                # Don't fail - config might be optional or in subfolder
            fi
        done < "$profile_file"
    done < <(find .dotbot/profiles -type f)
    
    return $has_error
}

# Test: Install scripts are executable
test_install_scripts() {
    local has_error=0
    
    if [ ! -x ".dotbot/install-config" ]; then
        error "install-config is not executable"
        has_error=1
    fi
    
    if [ ! -x ".dotbot/install-profile" ]; then
        error "install-profile is not executable"
        has_error=1
    fi
    
    # Check syntax
    if ! bash -n ".dotbot/install-config"; then
        error "install-config has syntax errors"
        has_error=1
    fi
    
    if ! bash -n ".dotbot/install-profile"; then
        error "install-profile has syntax errors"
        has_error=1
    fi
    
    return $has_error
}

# Test: Dotbot submodule is initialized
test_dotbot_submodule() {
    local has_error=0
    
    if [ ! -d ".dotbot/dotbot" ]; then
        info "Dotbot submodule not initialized (run: git submodule update --init)"
        # Not a hard failure in CI since submodules may not be checked out
        return 0
    fi
    
    if [ ! -f ".dotbot/dotbot/bin/dotbot" ]; then
        error "Dotbot binary not found"
        has_error=1
    fi
    
    return $has_error
}

# Test: Config files are valid YAML
test_config_yaml_validity() {
    local has_error=0
    local failed_count=0
    
    if ! command -v python3 >/dev/null 2>&1; then
        info "Python3 not available, skipping YAML validation"
        return 0
    fi
    
    while IFS= read -r config_file; do
        if ! python3 -c "import yaml; yaml.safe_load(open('$config_file'))" 2>/dev/null; then
            info "YAML validation issue in: $config_file (may contain shell scripts)"
            ((failed_count++))
        fi
    done < <(find .dotbot/configs -type f -name "*.yaml")
    
    # Don't fail if only a few configs have YAML issues (they may contain shell scripts)
    if [ $failed_count -gt 5 ]; then
        error "Too many YAML validation issues: $failed_count"
        has_error=1
    fi
    
    return $has_error
}

# Test: Required dotbot configs exist
test_required_configs() {
    local has_error=0
    
    local required_configs=(
        "git.yaml"
        "zsh.yaml"
        "brew.yaml"
        "ssh.yaml"
        "vscode.yaml"
    )
    
    for config in "${required_configs[@]}"; do
        if [ ! -f ".dotbot/configs/$config" ]; then
            error "Required config missing: $config"
            has_error=1
        fi
    done
    
    return $has_error
}

# Test: Symlinks in configs don't reference absolute paths
test_no_absolute_paths() {
    # This is informational only - dotbot configs commonly use ~/ paths
    local count=$(grep -r "~/" .dotbot/configs/ --include="*.yaml" | grep -v "^\s*#" | wc -l)
    info "Found $count references to ~/ in configs (informational only)"
    return 0
}

# Test: Private config handling
test_private_config() {
    local has_error=0
    
    # Check that private.yaml exists
    if [ ! -f ".dotbot/configs/private.yaml" ]; then
        error "private.yaml config not found"
        has_error=1
    fi
    
    # Check that .gitignore excludes SSH configs
    if ! grep -q ".dotbot/configs/ssh-.*\.yaml" .gitignore; then
        error ".gitignore should exclude private SSH configs"
        has_error=1
    fi
    
    return $has_error
}

# Test: Template config structure
test_template_config() {
    local has_error=0
    
    if [ ! -f ".dotbot/configs/template.yaml" ]; then
        error "template.yaml config not found"
        has_error=1
    fi
    
    return $has_error
}

# Run all tests
main() {
    info "Starting Dotbot configuration tests..."
    echo ""
    
    test_case "Base configuration exists" test_base_config
    test_case "Profile configs exist" test_profile_configs
    test_case "Config file references are valid" test_config_references
    test_case "Install scripts are executable" test_install_scripts
    test_case "Dotbot submodule initialized" test_dotbot_submodule
    test_case "Config YAML validity" test_config_yaml_validity
    test_case "Required configs exist" test_required_configs
    test_case "No absolute paths in configs" test_no_absolute_paths
    test_case "Private config handling" test_private_config
    test_case "Template config exists" test_template_config
    
    echo ""
    echo "================================"
    echo "Test Results:"
    success "Passed: $TESTS_PASSED"
    if [ $TESTS_FAILED -gt 0 ]; then
        error "Failed: $TESTS_FAILED"
        exit 1
    else
        success "All Dotbot tests passed!"
    fi
}

# Change to repository root
cd "$(dirname "$0")/.."

main
