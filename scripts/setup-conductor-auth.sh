#!/bin/bash

# Script to configure Conductor's bundled Claude Code binary to use subscription
# Conductor bundles its own Claude Code binary, so it needs separate configuration

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONDUCTOR_BIN="$HOME/Library/Application Support/com.conductor.app/bin/claude"
CONDUCTOR_CLAUDE_DIR="$HOME/Library/Application Support/com.conductor.app/.claude"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if Conductor is installed
if [ ! -f "$CONDUCTOR_BIN" ]; then
    print_error "Conductor's bundled Claude binary not found at: $CONDUCTOR_BIN"
    echo "Make sure Conductor is installed."
    exit 1
fi

print_info "Found Conductor's bundled Claude binary"

# Create Conductor's Claude config directory
mkdir -p "$CONDUCTOR_CLAUDE_DIR"

# Setup apiKeyHelper to use setup token
SETUP_TOKEN_SCRIPT="$DOTFILES_DIR/scripts/get-claude-setup-token.sh"
SETTINGS_FILE="$CONDUCTOR_CLAUDE_DIR/settings.json"

# Create or update settings.json
if [ -f "$SETTINGS_FILE" ] && command -v jq >/dev/null 2>&1; then
    # Update existing settings
    jq --arg helper "$SETUP_TOKEN_SCRIPT" '.apiKeyHelper = $helper' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
    print_info "Updated Conductor's Claude settings.json with apiKeyHelper"
else
    # Create new settings
    cat > "$SETTINGS_FILE" <<EOF
{
  "apiKeyHelper": "$SETUP_TOKEN_SCRIPT"
}
EOF
    print_info "Created Conductor's Claude settings.json with apiKeyHelper"
fi

print_info "Conductor's bundled Claude Code is now configured to use setup token"
echo ""
print_warning "Note: Conductor also has a Settings → Env section in its UI"
print_warning "      You can set ANTHROPIC_API_KEY there if you want to override"
print_warning "      To use subscription, leave ANTHROPIC_API_KEY empty in Conductor settings"
echo ""
echo "To verify, check Conductor's Settings → Env and ensure ANTHROPIC_API_KEY is not set"
