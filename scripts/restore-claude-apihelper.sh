#!/bin/bash

# Script to restore apiKeyHelper after successful claude login
# This allows Claude Code to use setup token when needed

set -e

SETTINGS_FILE="$HOME/.claude/settings.json"
SETUP_TOKEN_SCRIPT="$HOME/.dotfiles/scripts/get-claude-setup-token.sh"

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}Restoring apiKeyHelper...${NC}"

if command -v jq >/dev/null 2>&1 && [ -f "$SETTINGS_FILE" ]; then
    jq --arg helper "$SETUP_TOKEN_SCRIPT" '.apiKeyHelper = $helper' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
    echo -e "${GREEN}✓ Restored apiKeyHelper${NC}"
    echo ""
    echo "Claude Code will now use setup token as fallback when needed"
else
    echo "Error: jq not found or settings.json doesn't exist"
    exit 1
fi
