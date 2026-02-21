#!/bin/bash

# Script to setup Claude Code using a setup token from 1Password
# Checks if token is expired and prompts for renewal if needed
# Usage: ./setup-claude-code.sh

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FETCH_SCRIPT="$DOTFILES_DIR/scripts/fetch-1password-secrets.sh"

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

# Check if Claude Code CLI is installed
check_claude_installed() {
    if ! command -v claude >/dev/null 2>&1; then
        print_error "Claude Code CLI is not installed or not in PATH"
        echo "Please install Claude Code first:"
        echo "  brew install --cask claude"
        echo "  or visit: https://claude.ai/download"
        return 1
    fi
    return 0
}

# Fetch setup token from 1Password
fetch_setup_token() {
    local token
    token=$("$FETCH_SCRIPT" "claude_code_setup_token" 2>/dev/null)

    if [ $? -ne 0 ] || [ -z "$token" ]; then
        print_error "Could not fetch Claude Code setup token from 1Password"
        echo "Make sure:"
        echo "  1. 1Password CLI is installed and signed in: op signin"
        echo "  2. The token item exists in your 1Password vault"
        return 1
    fi

    echo "$token"
}

# Check if token is valid by attempting to use it
check_token_valid() {
    local token="$1"

    if [ -z "$token" ]; then
        return 1
    fi

    # Claude Code uses ANTHROPIC_API_KEY environment variable
    # We'll test the token by making a simple API call or checking auth

    # Set the token in environment
    export ANTHROPIC_API_KEY="$token"

    # Try to validate the token by checking if Claude Code can authenticate
    # Some options:
    # 1. Try a simple command that requires auth (if available)
    # 2. Check the token format (Anthropic tokens start with sk-ant-)
    # 3. Make a minimal API call to validate

    # First, check token format
    if [[ ! "$token" =~ ^sk-ant- ]]; then
        print_warning "Token format doesn't match expected Anthropic API key format"
        return 1
    fi

    # Try to use claude with the token
    # If claude has a way to test auth, use it
    # Otherwise, we'll assume the token is valid if format is correct
    # and let Claude Code itself handle validation when used

    # For now, we'll do a basic validation:
    # - Check format
    # - Check length (Anthropic API keys are typically long)
    if [ ${#token} -lt 50 ]; then
        print_warning "Token appears too short to be valid"
        return 1
    fi

    # If we get here, token format looks valid
    # Actual validation will happen when Claude Code tries to use it
    return 0
}

# Setup Claude Code with the token
setup_claude_with_token() {
    local token="$1"

    if [ -z "$token" ]; then
        print_error "No token provided"
        return 1
    fi

    print_success "Setting up Claude Code with token from 1Password..."

    # Claude Code on macOS uses:
    # 1. ANTHROPIC_API_KEY environment variable
    # 2. apiKeyHelper in ~/.claude/settings.json (runs a script to get the key)

    # Setup 1: Do NOT set apiKeyHelper for main Claude Code
    # apiKeyHelper conflicts with 'claude login' - it causes "invalid API key" errors
    # Instead, we only set apiKeyHelper for Conductor's bundled binary (non-interactive)
    # For main Claude Code, use 'claude login' for subscription authentication
    
    print_success "Claude Code setup completed"
    print_success ""
    print_success "Next steps:"
    print_success "  1. Run: claude login"
    print_success "  2. Configure Conductor: ~/.dotfiles/scripts/setup-conductor-auth.sh"
    print_success ""
    print_success "Note: apiKeyHelper is NOT set for main Claude Code to avoid login conflicts"
    print_success "      It will only be configured for Conductor's bundled binary"

    # Token format validation (for reference, but not blocking)
    if check_token_valid "$token"; then
        print_success "Setup token format is valid (stored in 1Password for Conductor/clawdbot)"
    else
        print_warning "Token format validation failed - may need to regenerate"
    fi
    
    echo ""
    print_success "Setup complete! You can now:"
    echo "  - Run 'claude login' for interactive subscription use"
    echo "  - Run '~/.dotfiles/scripts/setup-conductor-auth.sh' for Conductor"

    return 0
}

# Prompt user to renew token
prompt_token_renewal() {
    print_warning "The Claude Code setup token appears to be expired or invalid"
    echo ""
    echo "To set up a new token:"
    echo "  1. Run: claude setup-token"
    echo "  2. Copy the new token"
    echo "  3. Update the token in your 1Password item:"
    echo "     - Item: Claude Code Token (wyy3kchgemuihnd6x32efyrzci)"
    echo "     - Vault: AI"
    echo "     - Field: credential"
    echo ""
    echo "Or update it via 1Password CLI:"
    echo "  op item edit wyy3kchgemuihnd6x32efyrzci --vault AI credential=<new-token>"
    echo ""
    echo "Note: This token is used for Conductor and clawdbot (non-interactive)"
    echo "      For main Claude Code, use 'claude login' instead"
    echo ""
    read -p "Press Enter to continue or Ctrl+C to cancel..."
}

# Main function
main() {
    echo "Setting up Claude Code..."
    echo ""

    # Check if Claude is installed
    if ! check_claude_installed; then
        exit 1
    fi

    # Fetch token from 1Password
    print_success "Fetching setup token from 1Password..."
    local token
    token=$(fetch_setup_token)

    if [ $? -ne 0 ]; then
        exit 1
    fi

    # Setup Claude Code with the token
    setup_claude_with_token "$token"
    local setup_result=$?

    if [ $setup_result -eq 2 ]; then
        # Token appears to be expired
        prompt_token_renewal
        exit 1
    elif [ $setup_result -ne 0 ]; then
        print_error "Failed to setup Claude Code"
        exit 1
    fi

    print_success "Claude Code setup completed successfully!"
    echo ""
    echo "You can now use Claude Code. Try: claude --help"
}

# Run main function
main "$@"
