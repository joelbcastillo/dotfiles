#!/bin/bash

# Script to fetch Claude Code setup token from 1Password
# This is specifically for Claude Code authentication/login
# The setup token is different from the API key used for Conductor

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FETCH_SCRIPT="$DOTFILES_DIR/scripts/fetch-1password-secrets.sh"

# Fetch the setup token from 1Password
token=$("$FETCH_SCRIPT" "claude_code_setup_token" 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$token" ]; then
    echo "Error: Could not fetch Claude Code setup token from 1Password" >&2
    echo "Make sure:" >&2
    echo "  1. 1Password CLI is installed and signed in: op signin" >&2
    echo "  2. The token item exists in your 1Password vault" >&2
    exit 1
fi

# Output the token (Claude Code will read this)
echo "$token"
