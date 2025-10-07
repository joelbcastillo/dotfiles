# Testing Documentation

This document describes the testing framework and how to run tests for the dotfiles repository.

## Overview

The dotfiles repository includes a comprehensive testing framework to ensure code quality, correctness, and compatibility across different macOS versions.

## Test Suites

### 1. Shell Script Tests (`tests/test_shell_scripts.sh`)

Validates all shell scripts in the repository for:
- **Syntax validation**: Ensures all scripts have valid bash/zsh syntax
- **Executability**: Verifies required scripts are executable
- **ShellCheck linting**: Runs shellcheck on critical scripts
- **Required scripts**: Checks that essential scripts exist
- **Security**: Scans for hardcoded secrets
- **Error handling**: Validates proper use of `set -e`

**Run locally:**
```bash
./tests/test_shell_scripts.sh
```

### 2. Dotbot Configuration Tests (`tests/test_dotbot_config.sh`)

Validates Dotbot configurations:
- **Base configuration**: Checks that base.yaml exists and is valid
- **Profile configs**: Verifies all profiles exist
- **Config references**: Validates that referenced configs exist
- **Install scripts**: Ensures dotbot install scripts are executable
- **YAML validity**: Validates YAML syntax
- **Required configs**: Checks for essential configuration files

**Run locally:**
```bash
./tests/test_dotbot_config.sh
```

### 3. Private Files Tests (`tests/test_private_files.sh`)

Validates private file handling:
- **Template files**: Ensures template files exist for private configs
- **.gitignore**: Verifies private files are excluded from git
- **Setup scripts**: Validates private file setup scripts
- **Documentation**: Checks that private setup documentation exists
- **Security**: Ensures no private files are accidentally committed
- **Config structure**: Validates config.json.example structure

**Run locally:**
```bash
./tests/test_private_files.sh
```

### 4. Shell Function Tests (`tests/run_tests.zsh`)

Tests the shell functions defined in `shells/oh-my-zsh/custom/functions.zsh`:
- Directory utilities (mkcd, backup, restore)
- Git utilities (gitinit, gb, gs)
- Python utilities (venv)
- Development workflow (new-project)
- System utilities (psgrep, localip, sysinfo)

**Run locally:**
```bash
zsh tests/run_tests.zsh
```

### 5. Repository Validation (`scripts/test.sh`)

Original test script that performs:
- ShellCheck linting on all shell scripts
- Validation of required files and directories
- Install script syntax checking

**Run locally:**
```bash
./scripts/test.sh
```

## Running All Tests

To run all test suites at once:

```bash
./tests/run_all_tests.sh
```

## GitHub Actions CI/CD

The repository uses GitHub Actions for continuous testing across multiple macOS versions.

### Test Matrix

Tests run on:
- macOS 11 (Big Sur)
- macOS 12 (Monterey)
- macOS 13 (Ventura)

### Workflow Configuration

The workflow (`.github/workflows/test.yml`) includes:

1. **Dependency Caching**: Homebrew cache is used to speed up workflow execution
2. **Version Pinning**: Uses specific versions of actions (e.g., `actions/checkout@v4`)
3. **Parallel Testing**: Tests run in parallel across different macOS versions
4. **Comprehensive Testing**: Includes shell linting, function tests, dotbot validation, and private file checks

### Workflow Features

- **Matrix Strategy**: Tests on multiple macOS versions with `fail-fast: false`
- **Caching**: Homebrew packages and dependencies are cached
- **Manual Triggers**: Workflow can be triggered manually via `workflow_dispatch`
- **Submodule Support**: Recursively checks out submodules

## Test Best Practices

### Writing Tests

1. **Test Independence**: Each test should be independent and not rely on other tests
2. **Cleanup**: Always clean up temporary files and directories
3. **Error Messages**: Provide clear error messages that help diagnose issues
4. **Exit Codes**: Return appropriate exit codes (0 for success, 1 for failure)

### Running Tests Locally

Before pushing changes:

1. Run shellcheck on modified scripts:
   ```bash
   shellcheck scripts/your-script.sh
   ```

2. Run the full test suite:
   ```bash
   ./tests/run_all_tests.sh
   ```

3. Test on your local machine:
   ```bash
   ./install bootstrap
   ./install profile default
   ```

### Common Issues

#### ShellCheck Warnings

Some shellcheck warnings are excluded by design:
- **SC2317**: Unreachable commands (utility functions)
- **SC1091**: Not following sourced files
- **SC2086**: Unquoted variables (intentional for third-party code)

See `scripts/test.sh` for the full list of excluded checks.

#### Broken Symlinks

Private files may appear as broken symlinks in CI environments. Tests are designed to handle this gracefully.

#### Missing Dependencies

Some tests require specific tools:
- `shellcheck`: For shell script linting
- `zsh`: For zsh-specific tests
- `python3`: For YAML validation (optional)

## Adding New Tests

### For Shell Scripts

Add tests to `tests/test_shell_scripts.sh`:

```bash
# Test: Your test description
test_your_feature() {
    local has_error=0
    
    # Your test logic here
    
    return $has_error
}
```

Then add to the main function:
```bash
test_case "Your test description" test_your_feature
```

### For Dotbot Configs

Add tests to `tests/test_dotbot_config.sh` following the same pattern.

### For Private Files

Add tests to `tests/test_private_files.sh` for any new private file handling.

## Continuous Improvement

The testing framework is continuously improved. Suggestions for enhancements:

1. Add integration tests for the install process
2. Test on additional macOS versions as they're released
3. Add performance benchmarks
4. Expand coverage for edge cases
5. Add automated security scanning

## Resources

- [ShellCheck Wiki](https://github.com/koalaman/shellcheck/wiki)
- [Dotbot Documentation](https://github.com/anishathalye/dotbot)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [macOS GitHub Actions Runners](https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners)

## Support

For issues with tests:
1. Check the test output for specific error messages
2. Review the test script source code for details
3. Open an issue with test failure details
4. Include your environment details (macOS version, shell, etc.)
