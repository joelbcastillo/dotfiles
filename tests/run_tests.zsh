#!/bin/zsh

# Enable error handling and debug output
set -e
set -x

# Source the shell functions
source "$(dirname "$0")/../shells/oh-my-zsh/custom/functions.zsh"

# Create a test environment
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR" || exit 1

echo "Running tests in $TEST_DIR..."

# Test mkcd
echo "Testing mkcd..."
mkcd test_dir
if [ "$(pwd)" = "$TEST_DIR/test_dir" ]; then
    echo "✅ PASS: mkcd creates and changes to new directory"
else
    echo "❌ FAIL: mkcd test"
    exit 1
fi

# Test venv
echo "Testing venv..."
venv
if [ -d ".venv" ] && [ -f ".venv/bin/activate" ]; then
    echo "✅ PASS: venv creates virtual environment"
else
    echo "❌ FAIL: venv test"
    exit 1
fi

# Test git functions
echo "Testing git functions..."
# Create a test file before initializing git
echo "test content" > test.txt
gitinit
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "✅ PASS: gitinit initializes repository"
else
    echo "❌ FAIL: gitinit test"
    exit 1
fi

# Test git branch creation
echo "Testing git branch..."
gb test_branch
if [ "$(git branch --show-current)" = "test_branch" ]; then
    echo "✅ PASS: gb creates and switches to new branch"
else
    echo "❌ FAIL: gb test"
    exit 1
fi

# Test utility functions
echo "Testing utility functions..."
echo "test" > test.txt
backup test.txt
if [ -f "test.txt.bak" ]; then
    echo "✅ PASS: backup creates backup file"
else
    echo "❌ FAIL: backup test"
    exit 1
fi

# Test restore function
echo "Testing restore..."
rm test.txt
restore test.txt
if [ -f "test.txt" ]; then
    echo "✅ PASS: restore restores from backup"
else
    echo "❌ FAIL: restore test"
    exit 1
fi

# Test genpass function
echo "Testing genpass..."
password=$(genpass 8)
if [ ${#password} -eq 8 ]; then
    echo "✅ PASS: genpass generates correct length password"
else
    echo "❌ FAIL: genpass test"
    exit 1
fi

# Test nrun function
echo "Testing nrun..."
mkdir -p node_modules/.bin
printf '#!/usr/bin/env node\nconsole.log("nrun-ok");\n' > node_modules/.bin/fake-tool
chmod +x node_modules/.bin/fake-tool
if nrun fake-tool | grep -q "nrun-ok"; then
    echo "✅ PASS: nrun executes local node binary"
else
    echo "❌ FAIL: nrun execution test"
    exit 1
fi
# Error path: missing binary should fail and mention npm install
set +e
nrun_err=$(nrun no-such-tool 2>&1)
nrun_rc=$?
set -e
if [ $nrun_rc -ne 0 ] && echo "$nrun_err" | grep -q "npm install"; then
    echo "✅ PASS: nrun errors when binary not found"
else
    echo "❌ FAIL: nrun missing binary error test"
    exit 1
fi
rm -rf node_modules

# Test development workflow
echo "Testing development workflow..."
new-project test_python python
cd "$TEST_DIR/test_dir"
if [ -d "test_python" ] && [ -d "test_python/.venv" ] && [ -f "test_python/README.md" ]; then
    echo "✅ PASS: new-project creates Python project"
else
    echo "❌ FAIL: new-project test"
    exit 1
fi
if [ -f "test_python/.editorconfig" ] && [ -f "test_python/.gitignore" ] && [ -f "test_python/.claude/settings.local.json" ]; then
    echo "✅ PASS: new-project scaffolds .editorconfig, .gitignore, .claude/settings.local.json"
else
    echo "❌ FAIL: new-project scaffold files test"
    exit 1
fi

# Test system functions
echo "Testing system functions..."
if psgrep zsh >/dev/null 2>&1; then
    echo "✅ PASS: psgrep finds processes"
else
    echo "❌ FAIL: psgrep test"
    exit 1
fi

if localip >/dev/null 2>&1; then
    echo "✅ PASS: localip returns IP address"
else
    echo "❌ FAIL: localip test"
    exit 1
fi

if sysinfo | grep -q "System Information"; then
    echo "✅ PASS: sysinfo shows system information"
else
    echo "❌ FAIL: sysinfo test"
    exit 1
fi

# Clean up
cd - >/dev/null || exit 1
rm -rf "$TEST_DIR"

# Run standalone *.test.sh suites (hermetic; own their fixtures/cleanup).
echo "Running claude-plugins tests..."
bash "$(dirname "$0")/claude-plugins.test.sh"

echo "All tests completed successfully!"
