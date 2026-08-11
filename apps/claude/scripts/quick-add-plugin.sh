#!/bin/bash
# Quick add a plugin to the current project
# Usage: quick-add-plugin.sh [plugin-name]

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CONFIG_FILE=".claude/settings.local.json"

show_available_plugins() {
    echo -e "${BLUE}Available plugins:${NC}"
    echo "  1) github         - GitHub API, PR/issue management"
    echo "  2) context7       - Documentation lookup"
    echo "  3) Notion         - Notion workspace integration"
    echo "  4) stripe         - Stripe payment integration"
    echo "  5) slack          - Slack messaging"
    echo "  6) pr-review      - Code review workflows"
    echo "  7) cursor-builder - Custom agent workflows"
    echo "  8) outlook        - Outlook email/calendar"
    echo ""
}

get_plugin_full_name() {
    case $1 in
        1|github) echo "github@claude-plugins-official" ;;
        2|context7) echo "context7@claude-plugins-official" ;;
        3|notion|Notion) echo "Notion@claude-plugins-official" ;;
        4|stripe) echo "stripe@claude-plugins-official" ;;
        5|slack) echo "slack@claude-plugins-official" ;;
        6|pr-review|pr-review-toolkit) echo "pr-review-toolkit@claude-plugins-official" ;;
        7|cursor-builder) echo "cursor-builder@jbc-tech-solutions-marketplace" ;;
        8|outlook|outlook-mcp) echo "outlook-mcp@local" ;;
        *) echo "" ;;
    esac
}

add_plugin() {
    local plugin_name=$1

    # Create .claude directory if it doesn't exist
    mkdir -p .claude

    # If config doesn't exist, create it
    if [ ! -f "$CONFIG_FILE" ]; then
        cat > "$CONFIG_FILE" << 'EOF'
{
  "enabledPlugins": {
  }
}
EOF
    fi

    # Check if plugin already enabled
    if grep -q "\"$plugin_name\": true" "$CONFIG_FILE" 2>/dev/null; then
        echo -e "${YELLOW}⚠${NC} $plugin_name is already enabled"
        return
    fi

    # Use python3 (universally available on macOS) for safe JSON editing
    python3 -c "
import json, sys
with open('$CONFIG_FILE', 'r') as f:
    config = json.load(f)
config.setdefault('enabledPlugins', {})['$plugin_name'] = True
with open('$CONFIG_FILE', 'w') as f:
    json.dump(config, f, indent=2)
    f.write('\n')
" 2>/dev/null

    echo -e "${GREEN}✓${NC} Added $plugin_name"
}

# Main
if [ ! -d ".git" ]; then
    echo -e "${YELLOW}Warning:${NC} Not in a git repository"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

if [ -n "$1" ]; then
    plugin_full=$(get_plugin_full_name "$1")
    if [ -z "$plugin_full" ]; then
        echo "Unknown plugin: $1"
        show_available_plugins
        exit 1
    fi
    add_plugin "$plugin_full"
else
    show_available_plugins
    read -p "Enter plugin number or name: " selection
    plugin_full=$(get_plugin_full_name "$selection")
    if [ -z "$plugin_full" ]; then
        echo "Invalid selection"
        exit 1
    fi
    add_plugin "$plugin_full"
fi

echo ""
echo "Current configuration:"
cat "$CONFIG_FILE"
echo ""
echo "Restart Claude to apply changes."
