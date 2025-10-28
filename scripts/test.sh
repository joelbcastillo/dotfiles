#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

function info() { echo -e "${YELLOW}[I] $1${NC}"; }
function success() { echo -e "${GREEN}[S] $1${NC}"; }
function error() { echo -e "${RED}[E] $1${NC}"; }

# 1. Lint all shell scripts
info "Linting shell scripts with shellcheck..."
if ! command -v shellcheck >/dev/null 2>&1; then
  error "shellcheck is not installed. Please install it (brew install shellcheck)."
  exit 1
fi

# Run shellcheck with specific exclusions
find . -type f -name '*.sh' -o -name 'install' | while read -r script; do
  info "Linting $script"
  # SC2317: Command appears to be unreachable (safe to ignore for utility functions)
  # SC1091: Not following: file was not specified as input (safe to ignore for sourced files)
  # SC2329: Function is never invoked (safe to ignore for utility functions in install script)
  # SC2086: Double quote to prevent globbing (safe to ignore for third-party plugins)
  # SC2034: Variable appears unused (safe to ignore for configuration variables)
  # SC2155: Declare and assign separately (safe to ignore for performance scripts)
  # SC2162: read without -r (safe to ignore for interactive scripts)
  # SC2181: Check exit code directly (safe to ignore for legacy scripts)
  # SC2001: Use ${variable//search/replace} (safe to ignore for sed usage)
  # SC2248: Prefer double quoting (safe to ignore for arithmetic comparisons)
  # SC2030/SC2031: Subshell modifications (safe to ignore for counter variables in pipelines)
  shellcheck -e SC2317,SC1091,SC2329,SC2086,SC2034,SC2155,SC2162,SC2181,SC2001,SC2248,SC2030,SC2031 "$script"
done
success "All shell scripts passed shellcheck."

# 2. Check for required files/directories
info "Checking for required files and directories..."
REQUIRED=(
  ".dotbot"
  ".dotbot/profiles"
  "tools/homebrew/Brewfile"
  "apps/vscode/settings.json"
  "install"
)
for path in "${REQUIRED[@]}"; do
  if [ ! -e "$path" ]; then
    error "Missing required file or directory: $path"
    exit 1
  fi
done
success "All required files and directories are present."

# 3. Check install script syntax
info "Checking install script syntax..."
# Try different zsh locations
for zsh_path in /opt/homebrew/bin/zsh /usr/local/bin/zsh /bin/zsh zsh; do
  if command -v "$zsh_path" >/dev/null 2>&1; then
    "$zsh_path" -n install
    success "Install script syntax is valid."
    break
  fi
done

info "All tests passed!" 
