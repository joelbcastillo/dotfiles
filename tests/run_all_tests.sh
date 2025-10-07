#!/usr/bin/env bash
# Master test runner - runs all test suites
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

function info() { echo -e "${YELLOW}[INFO] $1${NC}"; }
function success() { echo -e "${GREEN}[SUCCESS] $1${NC}"; }
function error() { echo -e "${RED}[ERROR] $1${NC}"; }
function header() { echo -e "${BLUE}=== $1 ===${NC}"; }

TOTAL_SUITES=0
FAILED_SUITES=0
TEST_DIR="$(cd "$(dirname "$0")" && pwd)"

# Run a test suite
run_suite() {
    local suite_name="$1"
    local suite_script="$2"
    
    ((TOTAL_SUITES++))
    
    header "$suite_name"
    echo ""
    
    if [ ! -f "$suite_script" ]; then
        error "Test suite not found: $suite_script"
        ((FAILED_SUITES++))
        return 1
    fi
    
    if bash "$suite_script"; then
        success "✅ $suite_name completed successfully"
        echo ""
        return 0
    else
        error "❌ $suite_name failed"
        ((FAILED_SUITES++))
        echo ""
        return 1
    fi
}

main() {
    info "Starting comprehensive test suite..."
    echo ""
    
    # Change to repository root
    cd "$TEST_DIR/.."
    
    # Run all test suites
    run_suite "Shell Script Tests" "$TEST_DIR/test_shell_scripts.sh" || true
    run_suite "Dotbot Configuration Tests" "$TEST_DIR/test_dotbot_config.sh" || true
    run_suite "Private Files Tests" "$TEST_DIR/test_private_files.sh" || true
    run_suite "Repository Validation" "$TEST_DIR/../scripts/test.sh" || true
    
    # Summary
    echo ""
    header "Test Summary"
    echo ""
    echo "Total test suites: $TOTAL_SUITES"
    if [ $FAILED_SUITES -eq 0 ]; then
        success "All test suites passed! 🎉"
        exit 0
    else
        error "Failed test suites: $FAILED_SUITES"
        exit 1
    fi
}

main "$@"
