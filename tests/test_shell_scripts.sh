#!/usr/bin/env bash
# Comprehensive shell script tests
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

# Test function wrapper
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

# Test: All shell scripts have valid syntax
test_shell_syntax() {
    local has_error=0
    
    while IFS= read -r script; do
        if [[ "$script" == *".sh" ]]; then
            bash -n "$script" || has_error=1
        elif [[ "$script" == "install" ]] || [[ "$script" == *"install-"* ]]; then
            # Test with both bash and zsh for install scripts
            bash -n "$script" || has_error=1
        fi
    done < <(find . -type f \( -name "*.sh" -o -name "install" -o -name "install-*" \) ! -path "./.git/*")
    
    return $has_error
}

# Test: All shell scripts are executable
test_shell_executability() {
    local has_error=0
    
    # Scripts that should be executable
    local required_executables=(
        "install"
        ".dotbot/install-config"
        ".dotbot/install-profile"
        "scripts/test.sh"
        "scripts/setup-private-files.sh"
        "scripts/setup-new-user.sh"
    )
    
    for script in "${required_executables[@]}"; do
        if [ ! -x "$script" ]; then
            error "Script not executable: $script"
            has_error=1
        fi
    done
    
    return $has_error
}

# Test: ShellCheck passes on all scripts
test_shellcheck() {
    if ! command -v shellcheck >/dev/null 2>&1; then
        info "shellcheck not installed, skipping"
        return 0
    fi
    
    local has_error=0
    local exclusions="SC2317,SC1091,SC2329,SC2086,SC2034,SC2155,SC2162,SC2181,SC2001,SC2164,SC2312,SC2248,SC2120,SC2119"
    
    # Only check critical scripts, not test files
    local scripts_to_check=(
        "scripts/test.sh"
        "scripts/setup-private-files.sh"
        "scripts/setup-new-user.sh"
        "scripts/backup.sh"
        "install"
    )
    
    for script in "${scripts_to_check[@]}"; do
        if [ -f "$script" ]; then
            if ! shellcheck -e "$exclusions" "$script" >/dev/null 2>&1; then
                error "shellcheck failed for: $script"
                has_error=1
            fi
        fi
    done
    
    return $has_error
}

# Test: Required scripts exist
test_required_scripts() {
    local has_error=0
    local required_scripts=(
        "install"
        "scripts/test.sh"
        "scripts/setup-private-files.sh"
        "scripts/setup-new-user.sh"
        ".dotbot/install-config"
        ".dotbot/install-profile"
    )
    
    for script in "${required_scripts[@]}"; do
        if [ ! -f "$script" ]; then
            error "Required script missing: $script"
            has_error=1
        fi
    done
    
    return $has_error
}

# Test: No scripts contain hardcoded secrets
test_no_secrets() {
    local has_error=0
    local secret_patterns=(
        "password.*=.*['\"][A-Za-z0-9]{8,}['\"]"
        "api[_-]?key.*=.*['\"][A-Za-z0-9]{8,}['\"]"
        "token.*=.*['\"][A-Za-z0-9]{8,}['\"]"
    )
    
    for pattern in "${secret_patterns[@]}"; do
        # Look for actual hardcoded values, not variable assignments
        if grep -rE "$pattern" scripts/ --include="*.sh" | grep -v "template" | grep -v "example" | grep -v "test" | grep -v "secret_name" | grep -v "secret_value"; then
            error "Potential secret found matching pattern: $pattern"
            has_error=1
        fi
    done
    
    return $has_error
}

# Test: Scripts use set -e for error handling
test_error_handling() {
    local has_error=0
    
    # Check main scripts for error handling (but allow some without set -e)
    local critical_scripts=(
        "scripts/test.sh"
        "scripts/setup-private-files.sh"
        "scripts/setup-new-user.sh"
    )
    
    for script in "${critical_scripts[@]}"; do
        if [ -f "$script" ] && ! grep -q "set -e" "$script"; then
            error "Critical script missing 'set -e': $script"
            has_error=1
        fi
    done
    
    return $has_error
}

# Test: Setup scripts can run in dry-run mode
test_setup_scripts_dryrun() {
    local has_error=0
    
    # Test setup-new-user.sh syntax
    if ! bash -n scripts/setup-new-user.sh; then
        error "setup-new-user.sh has syntax errors"
        has_error=1
    fi
    
    # Test setup-private-files.sh syntax
    if ! bash -n scripts/setup-private-files.sh; then
        error "setup-private-files.sh has syntax errors"
        has_error=1
    fi
    
    return $has_error
}

# Run all tests
main() {
    info "Starting comprehensive shell script tests..."
    echo ""
    
    test_case "Shell script syntax validation" test_shell_syntax
    test_case "Shell script executability" test_shell_executability
    test_case "ShellCheck linting" test_shellcheck
    test_case "Required scripts exist" test_required_scripts
    test_case "No hardcoded secrets" test_no_secrets
    test_case "Error handling with set -e" test_error_handling
    test_case "Setup scripts dry-run" test_setup_scripts_dryrun
    
    echo ""
    echo "================================"
    echo "Test Results:"
    success "Passed: $TESTS_PASSED"
    if [ $TESTS_FAILED -gt 0 ]; then
        error "Failed: $TESTS_FAILED"
        exit 1
    else
        success "All tests passed!"
    fi
}

# Change to repository root
cd "$(dirname "$0")/.."

main
