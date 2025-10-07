#!/bin/zsh

# Enable error handling
set -e

# Source the shell functions
source "$(dirname "$0")/../shells/oh-my-zsh/custom/functions.zsh"

# Create a test environment
function setup_test_env() {
    # Create temporary directory
    TEST_DIR=$(mktemp -d)
    cd "$TEST_DIR" || exit 1
    
    # Set up test environment variables
    export TEST_MODE=1
    export TEST_DIR
    
    # Create test files and directories
    mkdir -p test_files
    echo "test content" > test_files/test.txt
    
    # Set up git test environment
    git init
    git config --local user.name "Test User"
    git config --local user.email "test@example.com"
    
    echo "Test environment set up in $TEST_DIR"
}

# Clean up test environment
function cleanup_test_env() {
    if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
        cd - >/dev/null || exit 1
        rm -rf "$TEST_DIR"
        echo "Test environment cleaned up"
    fi
}

# Run a test function
function run_test() {
    local test_name="$1"
    local test_func="$2"
    
    echo "Running test: $test_name"
    if $test_func; then
        echo "✅ PASS: $test_name"
    else
        echo "❌ FAIL: $test_name"
        return 1
    fi
}

# Test utilities
function assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"
    
    if [ "$expected" = "$actual" ]; then
        echo "✅ PASS: $message"
        return 0
    else
        echo "❌ FAIL: $message"
        echo "Expected: $expected"
        echo "Actual:   $actual"
        return 1
    fi
}

function assert_contains() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"
    
    if echo "$actual" | grep -q "$expected"; then
        echo "✅ PASS: $message"
        return 0
    else
        echo "❌ FAIL: $message"
        echo "Expected to contain: $expected"
        echo "Actual: $actual"
        return 1
    fi
}

function assert_success() {
    local command="$1"
    local message="${2:-}"
    
    if eval "$command" >/dev/null 2>&1; then
        echo "✅ PASS: $message"
        return 0
    else
        echo "❌ FAIL: $message"
        echo "Command failed: $command"
        return 1
    fi
}

function assert_failure() {
    local command="$1"
    local message="${2:-}"
    
    if ! eval "$command" >/dev/null 2>&1; then
        echo "✅ PASS: $message"
        return 0
    else
        echo "❌ FAIL: $message"
        echo "Command succeeded when it should have failed: $command"
        return 1
    fi
}

# Run all tests
function run_all_tests() {
    local failed=0
    
    # Set up test environment
    setup_test_env
    
    # Run each test
    # List of test functions to run
    local test_functions=(
        "test_mkcd"
        "test_venv" 
        "test_git_functions"
        "test_docker_functions"
        "test_aws_functions"
        "test_utility_functions"
        "test_development_workflow"
        "test_system_functions"
    )
    
    for test_func in "${test_functions[@]}"; do
        if ! run_test "${test_func#test_}" "$test_func"; then
            failed=1
        fi
    done
    
    # Clean up test environment
    cleanup_test_env
    
    # Return overall status
    return $failed
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_all_tests
fi 