#!/bin/bash

# Script to fetch Claude Code API key from 1Password
# This script is used by Claude Code's apiKeyHelper setting
# It outputs the API key to stdout, or exits with error code if not found
#
# Usage: This script can be called with an optional argument:
#   - No argument or "setup": Returns the setup token (for Claude Code auth)
#   - "api": Returns the API key (for Conductor and API calls)

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FETCH_SCRIPT="$DOTFILES_DIR/scripts/fetch-1password-secrets.sh"

# Determine which key to fetch based on argument or context
KEY_TYPE="${1:-setup}"

if [ "$KEY_TYPE" = "api" ]; then
    # Fetch the actual API key (for Conductor and API calls)
    token=$("$FETCH_SCRIPT" "anthropic_api_key" 2>/dev/null)

    if [ $? -ne 0 ] || [ -z "$token" ]; then
        echo "Error: Could not fetch Anthropic API key from 1Password" >&2
        echo "Make sure:" >&2
        echo "  1. 1Password CLI is installed and signed in: op signin" >&2
        echo "  2. The 'Anthropic API Key' item exists in your 1Password vault" >&2
        exit 1
    fi
else
    # Fetch the setup token (for Claude Code authentication)
    token=$("$FETCH_SCRIPT" "claude_code_setup_token" 2>/dev/null)

    if [ $? -ne 0 ] || [ -z "$token" ]; then
        echo "Error: Could not fetch Claude Code setup token from 1Password" >&2
        echo "Make sure:" >&2
        echo "  1. 1Password CLI is installed and signed in: op signin" >&2
        echo "  2. The 'Claude Code Token' item exists in your 1Password vault" >&2
        exit 1
    fi
fi

# Output the token
echo "$token"
