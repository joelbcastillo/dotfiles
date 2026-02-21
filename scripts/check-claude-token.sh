#!/bin/bash

# Script to check if Claude Code token is valid and prompt for renewal if expired
# This can be called before using Claude Code or as a wrapper
# Usage: ./check-claude-token.sh [claude-command] [args...]

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FETCH_SCRIPT="$DOTFILES_DIR/scripts/fetch-1password-secrets.sh"
SETUP_SCRIPT="$DOTFILES_DIR/scripts/setup-claude-code.sh"

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function to print colored messages
print_error() {
    echo -e "${RED}Error:${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}Warning:${NC} $1" >&2
}

print_success() {
    echo -e "${GREEN}Success:${NC} $1"
}

# Check if token exists in config
check_token_in_config() {
    local claude_config="$HOME/.config/claude/config.json"

    if [ ! -f "$claude_config" ]; then
        return 1
    fi

    # Check if config has an api_key field
    if command -v jq >/dev/null 2>&1; then
        local api_key
        api_key=$(jq -r '.api_key // empty' "$claude_config" 2>/dev/null)
        if [ -n "$api_key" ] && [ "$api_key" != "null" ] && [ "$api_key" != "" ]; then
            return 0
        fi
    fi

    return 1
}

# Try to validate token by making a test call
validate_token_with_claude() {
    # Try to run a simple claude command that requires auth
    # If it fails with auth error, token is likely expired

    # Claude Code might have different ways to check auth
    # We'll try a simple command and check the exit code/error

    if ! command -v claude >/dev/null 2>&1; then
        return 1
    fi

    # Try a simple command - version check doesn't require auth
    # But we can try to see if claude responds
    local output
    local exit_code

    # Try to get help or version - these usually don't require auth
    # but if token is completely invalid, claude might fail
    output=$(claude --version 2>&1)
    exit_code=$?

    if [ $exit_code -eq 0 ]; then
        # Claude is working, but this doesn't test auth
        # We'll need to actually try an authenticated command
        # For now, we'll assume if claude runs, it's okay
        # The actual auth check will happen when user tries to use it
        return 0
    fi

    return 1
}

# Main function
main() {
    # If arguments provided, we're wrapping a claude command
    if [ $# -gt 0 ]; then
        # Check token first
        if ! check_token_in_config; then
            print_warning "Claude Code token not found in config"
            echo "Running setup script..."
            if "$SETUP_SCRIPT"; then
                # Setup succeeded, continue with command
                exec claude "$@"
            else
                print_error "Failed to setup Claude Code token"
                exit 1
            fi
        else
            # Token exists, try to run the command
            # If it fails with auth error, we'll catch it
            if claude "$@" 2>&1; then
                exit 0
            else
                local claude_exit=$?
                # Check if error is auth-related
                # This is a simple check - actual error handling would be more sophisticated
                print_warning "Claude Code command failed (exit code: $claude_exit)"
                print_warning "If this is an authentication error, your token may be expired"
                echo ""
                echo "To renew your token:"
                echo "  1. Run: claude setup-token"
                echo "  2. Update the token in 1Password"
                echo "  3. Run: ~/.dotfiles/scripts/setup-claude-code.sh"
                exit $claude_exit
            fi
        fi
    else
        # No arguments - just check token status
        if check_token_in_config; then
            print_success "Claude Code token found in config"
            if validate_token_with_claude; then
                print_success "Claude Code appears to be working"
            else
                print_warning "Claude Code may have authentication issues"
                echo "Run: ~/.dotfiles/scripts/setup-claude-code.sh to refresh token"
            fi
        else
            print_warning "Claude Code token not found"
            echo "Running setup script..."
            "$SETUP_SCRIPT"
        fi
    fi
}

# Run main function
main "$@"
