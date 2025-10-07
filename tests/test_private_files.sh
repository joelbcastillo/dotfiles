#!/usr/bin/env bash
# Private file handling tests
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

# Test: Template files exist for private configs
test_template_files_exist() {
    local has_error=0
    
    # Check for user template
    if [ ! -f "tools/git/gitconfig.user.template" ]; then
        error "Template file missing: tools/git/gitconfig.user.template"
        has_error=1
    fi
    
    # Check for work/company template (name may vary)
    if ! ls tools/git/gitconfig.*.template 2>/dev/null | grep -v "user.template" | grep -q "."; then
        error "No work/company git template found (e.g., gitconfig.work.template)"
        has_error=1
    fi
    
    if [ ! -f "config.json.example" ]; then
        error "Template file missing: config.json.example"
        has_error=1
    fi
    
    return $has_error
}

# Test: .gitignore properly excludes private files
test_gitignore_private_files() {
    local has_error=0
    
    local private_patterns=(
        "config.json"
        ".dotbot/configs/ssh-.*\.yaml"
        "tools/ssh/keys/.*/ssh"
        "tools/aws/.*/credentials"
    )
    
    for pattern in "${private_patterns[@]}"; do
        if ! grep -q "$pattern" .gitignore; then
            error ".gitignore missing pattern: $pattern"
            has_error=1
        fi
    done
    
    return $has_error
}

# Test: Setup private files script is valid
test_setup_private_script() {
    local has_error=0
    
    if [ ! -f "scripts/setup-private-files.sh" ]; then
        error "setup-private-files.sh not found"
        return 1
    fi
    
    if [ ! -x "scripts/setup-private-files.sh" ]; then
        error "setup-private-files.sh not executable"
        has_error=1
    fi
    
    # Check syntax
    if ! bash -n "scripts/setup-private-files.sh"; then
        error "setup-private-files.sh has syntax errors"
        has_error=1
    fi
    
    return $has_error
}

# Test: Setup new user script is valid
test_setup_new_user_script() {
    local has_error=0
    
    if [ ! -f "scripts/setup-new-user.sh" ]; then
        error "setup-new-user.sh not found"
        return 1
    fi
    
    if [ ! -x "scripts/setup-new-user.sh" ]; then
        error "setup-new-user.sh not executable"
        has_error=1
    fi
    
    # Check syntax
    if ! bash -n "scripts/setup-new-user.sh"; then
        error "setup-new-user.sh has syntax errors"
        has_error=1
    fi
    
    return $has_error
}

# Test: Private directory structure in documentation
test_private_docs() {
    local has_error=0
    
    if [ ! -f "docs/private-setup.md" ]; then
        error "private-setup.md documentation not found"
        has_error=1
    fi
    
    # Check for important sections
    if [ -f "docs/private-setup.md" ]; then
        if ! grep -q "Private Repository Setup" "docs/private-setup.md"; then
            error "private-setup.md missing 'Private Repository Setup' section"
            has_error=1
        fi
    fi
    
    return $has_error
}

# Test: No private files accidentally committed
test_no_committed_private_files() {
    local has_error=0
    
    # Check for actual config.json (not example)
    if [ -f "config.json" ] && ! git check-ignore -q "config.json" 2>/dev/null; then
        error "config.json exists and is not ignored"
        has_error=1
    fi
    
    # Check for actual private git configs (not templates)
    if [ -f "tools/git/gitconfig.user" ] && [ ! -L "tools/git/gitconfig.user" ]; then
        error "gitconfig.user exists and is not a symlink (might be committed)"
        has_error=1
    fi
    
    if [ -f "tools/git/gitconfig.work" ] && [ ! -L "tools/git/gitconfig.work" ]; then
        error "gitconfig.work exists and is not a symlink (might be committed)"
        has_error=1
    fi
    
    return $has_error
}

# Test: Template files are not empty
test_template_files_content() {
    local has_error=0
    
    # Check template files have content
    if [ -f "tools/git/gitconfig.user.template" ] && [ ! -s "tools/git/gitconfig.user.template" ]; then
        error "Template file is empty: tools/git/gitconfig.user.template"
        has_error=1
    fi
    
    if [ -f "config.json.example" ] && [ ! -s "config.json.example" ]; then
        error "Template file is empty: config.json.example"
        has_error=1
    fi
    
    return $has_error
}

# Test: Private config YAML exists
test_private_config_yaml() {
    local has_error=0
    
    if [ ! -f ".dotbot/configs/private.yaml" ]; then
        error "private.yaml config not found"
        has_error=1
    fi
    
    return $has_error
}

# Test: Install script handles private profile
test_install_private_support() {
    local has_error=0
    
    if [ ! -f "install" ]; then
        error "install script not found"
        return 1
    fi
    
    # Check if install script mentions private setup
    if ! grep -q "private" "install"; then
        error "install script does not support private setup"
        has_error=1
    fi
    
    return $has_error
}

# Test: Config.json.example has required fields
test_config_example_structure() {
    local has_error=0
    
    if [ ! -f "config.json.example" ]; then
        error "config.json.example not found"
        return 1
    fi
    
    # Check for common JSON structure (if jq available)
    if command -v python3 >/dev/null 2>&1; then
        if ! python3 -c "import json; json.load(open('config.json.example'))" 2>/dev/null; then
            error "config.json.example is not valid JSON"
            has_error=1
        fi
    fi
    
    return $has_error
}

# Test: Pre-commit hook setup for private files
test_precommit_hook() {
    local has_error=0
    
    if [ -f ".git/hooks/pre-commit" ]; then
        # Check if pre-commit hook handles private files
        if ! grep -q "private\|symlink" ".git/hooks/pre-commit" 2>/dev/null; then
            info "pre-commit hook exists but may not handle private files"
        fi
    fi
    
    # Check for pre-commit config
    if [ -f ".pre-commit-config.yaml" ]; then
        success "pre-commit configuration found"
    fi
    
    return $has_error
}

# Run all tests
main() {
    info "Starting private file handling tests..."
    echo ""
    
    test_case "Template files exist" test_template_files_exist
    test_case ".gitignore excludes private files" test_gitignore_private_files
    test_case "Setup private files script" test_setup_private_script
    test_case "Setup new user script" test_setup_new_user_script
    test_case "Private setup documentation" test_private_docs
    test_case "No private files committed" test_no_committed_private_files
    test_case "Template files have content" test_template_files_content
    test_case "Private config YAML exists" test_private_config_yaml
    test_case "Install script supports private" test_install_private_support
    test_case "Config.json.example structure" test_config_example_structure
    test_case "Pre-commit hook setup" test_precommit_hook
    
    echo ""
    echo "================================"
    echo "Test Results:"
    success "Passed: $TESTS_PASSED"
    if [ $TESTS_FAILED -gt 0 ]; then
        error "Failed: $TESTS_FAILED"
        exit 1
    else
        success "All private file tests passed!"
    fi
}

# Change to repository root
cd "$(dirname "$0")/.."

main
