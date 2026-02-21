#!/bin/bash

# Script to fix "invalid API key" error when running claude login
# Temporarily removes apiKeyHelper so claude login can work

set -e

SETTINGS_FILE="$HOME/.claude/settings.json"
BACKUP_FILE="$HOME/.claude/settings.json.backup"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Preparing Claude Code for login...${NC}"

# Backup current settings
if [ -f "$SETTINGS_FILE" ]; then
    cp "$SETTINGS_FILE" "$BACKUP_FILE"
    echo "Backed up settings to $BACKUP_FILE"
fi

# Remove apiKeyHelper temporarily
if command -v jq >/dev/null 2>&1 && [ -f "$SETTINGS_FILE" ]; then
    jq 'del(.apiKeyHelper)' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
    echo -e "${GREEN}✓ Removed apiKeyHelper from settings${NC}"
    echo ""
    echo "Now you can run: claude login"
    echo ""
    echo "After successful login, you can restore apiKeyHelper by running:"
    echo "  ~/.dotfiles/scripts/restore-claude-apihelper.sh"
else
    echo -e "${YELLOW}Warning: jq not found or settings.json doesn't exist${NC}"
    echo "You may need to manually edit ~/.claude/settings.json"
    echo "Remove the 'apiKeyHelper' field temporarily"
fi
