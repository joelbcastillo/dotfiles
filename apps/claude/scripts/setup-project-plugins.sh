#!/bin/bash
# Setup project-specific Claude plugin configuration
# Usage: setup-project-plugins.sh [template-name]

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR=$(pwd)
CONFIG_FILE=".claude/settings.local.json"

# Color output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

show_menu() {
    echo -e "${BLUE}Claude Plugin Configuration Setup${NC}"
    echo ""
    echo "Select a template for this project:"
    echo ""
    echo "  1) Software Development (General)"
    echo "     Plugins: github, context7, pr-review-toolkit"
    echo "     Tokens: ~9,400"
    echo ""
    echo "  2) Data Engineering / ETL"
    echo "     Plugins: github, context7"
    echo "     Tokens: ~5,900"
    echo ""
    echo "  3) Web Development (Stripe)"
    echo "     Plugins: github, context7, stripe, pr-review-toolkit"
    echo "     Tokens: ~10,600"
    echo ""
    echo "  4) Business/Project Management"
    echo "     Plugins: Notion, github, outlook-mcp"
    echo "     Tokens: ~10,400"
    echo ""
    echo "  5) Communication/Collaboration"
    echo "     Plugins: slack, outlook-mcp, Notion"
    echo "     Tokens: ~8,100"
    echo ""
    echo "  6) AV Production / Technical Services"
    echo "     Plugins: cursor-builder, Notion, github"
    echo "     Tokens: ~10,100"
    echo ""
    echo "  7) Minimal (Learning/Exploration)"
    echo "     Plugins: context7"
    echo "     Tokens: ~4,400"
    echo ""
    echo "  8) Custom (select individual plugins)"
    echo ""
    echo "  0) Exit"
    echo ""
}

create_config() {
    local template=$1
    mkdir -p .claude

    case $template in
        1)
            cat > "$CONFIG_FILE" << 'EOF'
{
  "enabledPlugins": {
    "github@claude-plugins-official": true,
    "context7@claude-plugins-official": true,
    "pr-review-toolkit@claude-plugins-official": true
  }
}
EOF
            ;;
        2)
            cat > "$CONFIG_FILE" << 'EOF'
{
  "enabledPlugins": {
    "github@claude-plugins-official": true,
    "context7@claude-plugins-official": true
  }
}
EOF
            ;;
        3)
            cat > "$CONFIG_FILE" << 'EOF'
{
  "enabledPlugins": {
    "github@claude-plugins-official": true,
    "context7@claude-plugins-official": true,
    "stripe@claude-plugins-official": true,
    "pr-review-toolkit@claude-plugins-official": true
  }
}
EOF
            ;;
        4)
            cat > "$CONFIG_FILE" << 'EOF'
{
  "enabledPlugins": {
    "Notion@claude-plugins-official": true,
    "github@claude-plugins-official": true,
    "outlook-mcp@local": true
  }
}
EOF
            ;;
        5)
            cat > "$CONFIG_FILE" << 'EOF'
{
  "enabledPlugins": {
    "slack@claude-plugins-official": true,
    "outlook-mcp@local": true,
    "Notion@claude-plugins-official": true
  }
}
EOF
            ;;
        6)
            cat > "$CONFIG_FILE" << 'EOF'
{
  "enabledPlugins": {
    "cursor-builder@jbc-tech-solutions-marketplace": true,
    "Notion@claude-plugins-official": true,
    "github@claude-plugins-official": true
  }
}
EOF
            ;;
        7)
            cat > "$CONFIG_FILE" << 'EOF'
{
  "enabledPlugins": {
    "context7@claude-plugins-official": true
  }
}
EOF
            ;;
        8)
            create_custom_config
            return
            ;;
        *)
            echo "Invalid option"
            exit 1
            ;;
    esac

    echo -e "${GREEN}✓${NC} Created $CONFIG_FILE"
    echo ""
    echo "Plugin configuration saved. Restart Claude to apply changes."
}

create_custom_config() {
    echo ""
    echo "Available plugins:"
    echo "  1) github"
    echo "  2) context7"
    echo "  3) Notion"
    echo "  4) stripe"
    echo "  5) slack"
    echo "  6) pr-review-toolkit"
    echo "  7) cursor-builder"
    echo "  8) outlook-mcp"
    echo ""
    echo "Enter plugin numbers separated by spaces (e.g., '1 2 3'):"
    read -r selections

    mkdir -p .claude
    echo "{" > "$CONFIG_FILE"
    echo '  "enabledPlugins": {' >> "$CONFIG_FILE"

    first=true
    for num in $selections; do
        if [ "$first" = false ]; then
            echo "," >> "$CONFIG_FILE"
        fi
        first=false

        case $num in
            1) echo -n '    "github@claude-plugins-official": true' >> "$CONFIG_FILE" ;;
            2) echo -n '    "context7@claude-plugins-official": true' >> "$CONFIG_FILE" ;;
            3) echo -n '    "Notion@claude-plugins-official": true' >> "$CONFIG_FILE" ;;
            4) echo -n '    "stripe@claude-plugins-official": true' >> "$CONFIG_FILE" ;;
            5) echo -n '    "slack@claude-plugins-official": true' >> "$CONFIG_FILE" ;;
            6) echo -n '    "pr-review-toolkit@claude-plugins-official": true' >> "$CONFIG_FILE" ;;
            7) echo -n '    "cursor-builder@jbc-tech-solutions-marketplace": true' >> "$CONFIG_FILE" ;;
            8) echo -n '    "outlook-mcp@local": true' >> "$CONFIG_FILE" ;;
            *) ;;  # unknown index: skip silently (input was already validated above)
        esac
    done

    {
        echo ""
        echo '  }'
        echo '}'
    } >> "$CONFIG_FILE"

    echo -e "${GREEN}✓${NC} Created custom configuration"
}

# Main
if [ -f "$CONFIG_FILE" ]; then
    echo -e "${YELLOW}Warning:${NC} $CONFIG_FILE already exists"
    echo "Current configuration:"
    cat "$CONFIG_FILE"
    echo ""
    read -p "Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled"
        exit 0
    fi
fi

if [ -n "$1" ]; then
    create_config "$1"
else
    show_menu
    read -p "Enter your choice [0-8]: " choice

    if [ "$choice" = "0" ]; then
        exit 0
    fi

    create_config "$choice"
fi
