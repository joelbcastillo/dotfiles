#!/bin/bash

# Detect Homebrew installation and set HOMEBREW_PREFIX
# Supports: system-wide, user-local, and custom installations

detect_homebrew() {
    local brew_prefix=""

    # Priority 1: Check for user-local installation (macOS)
    if [ -x "$HOME/.homebrew/bin/brew" ]; then
        brew_prefix="$HOME/.homebrew"
        echo "Found user-local Homebrew at $brew_prefix"

    # Priority 2: Check standard ARM Mac location
    elif [ -x "/opt/homebrew/bin/brew" ]; then
        brew_prefix="/opt/homebrew"
        echo "Found Homebrew at $brew_prefix (Apple Silicon)"

    # Priority 3: Check standard Intel Mac location
    elif [ -x "/usr/local/bin/brew" ]; then
        brew_prefix="/usr/local"
        echo "Found Homebrew at $brew_prefix (Intel Mac)"

    # Priority 4: Linuxbrew default location
    elif [ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
        brew_prefix="/home/linuxbrew/.linuxbrew"
        echo "Found Homebrew at $brew_prefix (Linuxbrew)"

    # Priority 5: Check if brew is in PATH
    elif command -v brew >/dev/null 2>&1; then
        brew_prefix="$(brew --prefix)"
        echo "Found Homebrew at $brew_prefix (from PATH)"

    # Priority 6: Check HOMEBREW_PREFIX environment variable
    elif [ -n "${HOMEBREW_PREFIX:-}" ] && [ -x "$HOMEBREW_PREFIX/bin/brew" ]; then
        brew_prefix="$HOMEBREW_PREFIX"
        echo "Found Homebrew at $brew_prefix (from HOMEBREW_PREFIX)"

    else
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo "ERROR: Homebrew not found!"
            echo "Please install Homebrew or set HOMEBREW_PREFIX environment variable"
            return 1
        else
            # On Linux, brew is optional — exit 0 so callers don't break
            echo "Homebrew not detected (Linux — use apt via scripts/bootstrap-linux.sh)"
            return 0
        fi
    fi

    export HOMEBREW_PREFIX="$brew_prefix"
    export PATH="$brew_prefix/bin:$brew_prefix/sbin:$PATH"

    # Source brew shellenv for additional configuration
    eval "$("$brew_prefix/bin/brew" shellenv)"

    return 0
}

# Run detection
detect_homebrew
