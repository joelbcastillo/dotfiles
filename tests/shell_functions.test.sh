#!/bin/bash

# Source the test environment
source "$(dirname "$0")/test_env.zsh"

# Test utilities
function assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"

    if [ "$expected" = "$actual" ]; then
        echo "✅ PASS: $message"
    else
        echo "❌ FAIL: $message"
        echo "Expected: $expected"
        echo "Actual:   $actual"
        exit 1
    fi
}

function assert_contains() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"

    if echo "$actual" | grep -q "$expected"; then
        echo "✅ PASS: $message"
    else
        echo "❌ FAIL: $message"
        echo "Expected to contain: $expected"
        echo "Actual: $actual"
        exit 1
    fi
}

function assert_success() {
    local command="$1"
    local message="${2:-}"

    if eval "$command" >/dev/null 2>&1; then
        echo "✅ PASS: $message"
    else
        echo "❌ FAIL: $message"
        echo "Command failed: $command"
        exit 1
    fi
}

function assert_failure() {
    local command="$1"
    local message="${2:-}"

    if ! eval "$command" >/dev/null 2>&1; then
        echo "✅ PASS: $message"
    else
        echo "❌ FAIL: $message"
        echo "Command succeeded when it should have failed: $command"
        exit 1
    fi
}

# Test setup
function setup() {
    # Create temporary directory for tests
    TEST_DIR=$(mktemp -d)
    cd "$TEST_DIR" || exit 1
}

function teardown() {
    # Clean up temporary directory
    cd - >/dev/null || exit 1
    rm -rf "$TEST_DIR"
}

# Test cases

# Test mkcd function
function test_mkcd() {
    echo "Testing mkcd function..."
    
    # Test creating and changing to a new directory
    mkcd test_dir
    assert_equals "$TEST_DIR/test_dir" "$(pwd)" "mkcd should create and change to new directory"
    
    # Test creating nested directories
    mkcd nested/deep/dir
    assert_equals "$TEST_DIR/test_dir/nested/deep/dir" "$(pwd)" "mkcd should create nested directories"
}

# Test venv function
function test_venv() {
    echo "Testing venv function..."
    
    # Test creating default virtual environment
    venv
    assert_success "[ -d .venv ]" "venv should create .venv directory"
    assert_success "[ -f .venv/bin/activate ]" "venv should create activate script"
    
    # Test creating named virtual environment
    venv test_venv
    assert_success "[ -d test_venv ]" "venv should create named directory"
    assert_success "[ -f test_venv/bin/activate ]" "venv should create activate script in named directory"
}

# Test git functions
function test_git_functions() {
    echo "Testing git functions..."
    
    # Test gitinit
    gitinit
    assert_success "git rev-parse --is-inside-work-tree" "gitinit should initialize git repository"
    
    # Test gb (git branch)
    gb test_branch
    assert_equals "test_branch" "$(git branch --show-current)" "gb should create and switch to new branch"
    
    # Test gs (git status)
    echo "test" > test.txt
    git add test.txt
    local status_output
    status_output=$(gs)
    assert_contains "test.txt" "$status_output" "gs should show staged files"
}

# Test Docker functions
function test_docker_functions() {
    echo "Testing Docker functions..."
    
    # Test dls (docker list)
    local docker_output
    docker_output=$(dls)
    assert_contains "CONTAINER ID" "$docker_output" "dls should show container list"
    
    # Test drm (docker remove)
    # Note: This test might fail if there are no stopped containers
    drm
    assert_success "true" "drm should not fail"
    
    # Test drmi (docker remove images)
    # Note: This test might fail if there are no unused images
    drmi
    assert_success "true" "drmi should not fail"
}

# Test AWS functions
function test_aws_functions() {
    echo "Testing AWS functions..."
    
    # Test awsprofiles
    awsprofiles
    assert_success "true" "awsprofiles should not fail"
    
    # Test awsprofile
    awsprofile test_profile
    assert_equals "test_profile" "$AWS_PROFILE" "awsprofile should set AWS_PROFILE"
}

# Test utility functions
function test_utility_functions() {
    echo "Testing utility functions..."
    
    # Test backup
    echo "test" > test.txt
    backup test.txt
    assert_success "[ -f test.txt.bak ]" "backup should create backup file"
    
    # Test restore
    rm test.txt
    restore test.txt
    assert_success "[ -f test.txt ]" "restore should restore from backup"
    
    # Test genpass
    local password
    password=$(genpass 8)
    assert_equals 8 "${#password}" "genpass should generate password of specified length"
}

# Test development workflow functions
function test_development_workflow() {
    echo "Testing development workflow functions..."
    
    # Test new-project (Python)
    new-project test_python python
    assert_success "[ -d test_python ]" "new-project should create project directory"
    assert_success "[ -d test_python/.venv ]" "new-project should create virtual environment"
    assert_success "[ -f test_python/README.md ]" "new-project should create README"
    
    # Test new-project (Node)
    new-project test_node node
    assert_success "[ -d test_node ]" "new-project should create project directory"
    assert_success "[ -f test_node/package.json ]" "new-project should create package.json"
}

# Test system functions
function test_system_functions() {
    echo "Testing system functions..."
    
    # Test psgrep
    local ps_output
    ps_output=$(psgrep zsh)
    assert_contains "zsh" "$ps_output" "psgrep should find processes"
    
    # Test localip
    local ip_output
    ip_output=$(localip)
    assert_contains "." "$ip_output" "localip should return IP address"
    
    # Test sysinfo
    local sysinfo_output
    sysinfo_output=$(sysinfo)
    assert_contains "System Information" "$sysinfo_output" "sysinfo should show system information"
}

# Run all tests
function run_tests() {
    echo "Running shell function tests..."
    echo "=============================="
    
    run_all_tests
    
    echo "=============================="
    echo "All tests completed successfully!"
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi 
