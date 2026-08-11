# ============================================================================
# MCP Profile Manager - Global Claude Code MCP tool management
# ============================================================================
# Manages MCP tool profiles (notion-only, docs-focus, project-focus, all-tools)
# Auto-detects projects with .mcp.json and switches configurations
# Integrates with existing 1Password secret loading via _secure_run pattern
#
# Add this to: ~/.dotfiles/shells/oh-my-zsh/custom/functions.zsh
# Then use: mcp-switch <profile> or mcp-profile <command>

# Helper: Find .mcp.json in current directory or parent directories
_mcp_find_project_root() {
    local current_dir="$PWD"

    while [ "$current_dir" != "/" ]; do
        if [ -f "$current_dir/.mcp.json" ]; then
            echo "$current_dir"
            return 0
        fi
        current_dir=$(dirname "$current_dir")
    done

    return 1
}

# Helper: Load MCP secrets using existing secure profile pattern
_mcp_load_secrets() {
    local profile="$1"

    # Use existing _secure_run infrastructure if available
    # This leverages your existing 1Password integration
    if [ -f "$DOTFILES/shells/oh-my-zsh/custom/secure_profiles/mcp-secrets" ]; then
        # Source MCP-specific secrets profile if it exists
        source "$DOTFILES/shells/oh-my-zsh/custom/secure_profiles/mcp-secrets"
    fi

    # Profile-specific secret loading
    case "$profile" in
        docs-focus|all-tools)
            # Load Notion
            export NOTION_API_KEY="${NOTION_API_KEY:-}"
            # Load Google Drive
            export GOOGLE_APPLICATION_CREDENTIALS="${GOOGLE_APPLICATION_CREDENTIALS:-}"
            ;;
        project-focus|all-tools)
            # Load Notion
            export NOTION_API_KEY="${NOTION_API_KEY:-}"
            ;;
        notion-only)
            # Load Notion
            export NOTION_API_KEY="${NOTION_API_KEY:-}"
            ;;
    esac
}

# Main: Switch MCP profile
mcp_switch() {
    local profile="${1:-}"

    if [ -z "$profile" ]; then
        echo "Usage: mcp-switch <profile>"
        echo "Profiles: notion-only, docs-focus, project-focus, all-tools"
        return 1
    fi

    # Find project root with .mcp.json
    local project_root
    project_root=$(_mcp_find_project_root) || {
        echo "Error: No .mcp.json found in current directory or parents"
        echo "This command works in projects configured with Claude Code MCP"
        return 1
    }

    local config_file="${project_root}/.mcp.json"
    local template_file="${project_root}/.mcp.${profile}.json"

    # Check template exists
    if [ ! -f "$template_file" ]; then
        echo "Error: Profile not found: .mcp.${profile}.json"
        echo "Available profiles:"
        ls -1 "${project_root}/.mcp."*.json 2>/dev/null | \
            sed "s|${project_root}/.mcp.||g; s|.json||g" | sed 's/^/  - /'
        return 1
    fi

    # Backup current config
    if [ -f "$config_file" ]; then
        local backup_file="${config_file}.backup.$(date +%s)"
        cp "$config_file" "$backup_file"
        echo "✓ Backed up: .mcp.json → $(basename "$backup_file")"
    fi

    # Switch config
    cp "$template_file" "$config_file"
    echo "✓ Switched to '$profile' profile"

    # Load secrets
    echo ""
    _mcp_load_secrets "$profile"
    echo "✓ Environment configured (restart Claude Code to apply changes)"
}

# Show current profile
mcp_show() {
    local project_root
    project_root=$(_mcp_find_project_root) || {
        echo "Error: No .mcp.json found in current directory or parents"
        return 1
    }

    local config_file="${project_root}/.mcp.json"

    if [ ! -f "$config_file" ]; then
        echo "Error: No active .mcp.json found"
        return 1
    fi

    echo "Active MCP tools in $(basename "$project_root"):"
    echo ""

    if command -v jq &> /dev/null; then
        jq -r '.mcpServers | keys[]' "$config_file" 2>/dev/null | sed 's/^/  • /' || echo "  (unable to parse config)"
    else
        grep -o '"[^"]*"' "$config_file" 2>/dev/null | grep -v '^"$' | head -10 | sed 's/"//g; s/^/  • /'
    fi

    echo ""
    echo "Config: ${config_file#"$HOME/"}"
}

# List available profiles
mcp_list() {
    local project_root
    project_root=$(_mcp_find_project_root) || {
        echo "Error: No .mcp.json found in current directory or parents"
        return 1
    }

    echo "Available profiles in $(basename "$project_root"):"
    echo ""

    ls -1 "${project_root}/.mcp."*.json 2>/dev/null | \
        sed "s|${project_root}/.mcp.||g; s|.json||g" | \
        while read -r profile; do
            if [ "$profile" != "json" ]; then
                echo "  • $profile"
            fi
        done
}

# Check API key status
mcp_status() {
    echo "API Key Status:"
    echo ""

    [ -n "${NOTION_API_KEY:-}" ] && echo "✓ NOTION_API_KEY is set" || echo "✗ NOTION_API_KEY not set"
    [ -n "${GOOGLE_APPLICATION_CREDENTIALS:-}" ] && echo "✓ GOOGLE_APPLICATION_CREDENTIALS is set" || echo "✗ GOOGLE_APPLICATION_CREDENTIALS not set"

    echo ""
    mcp_show
}

# Configure MCP for Conductor workspace
mcp_conductor() {
    local action="${1:-}"
    local profile="${2:-}"

    if [ -z "$action" ]; then
        cat << 'CONDUCTOR_HELP'
mcp-profile conductor - Configure MCP for Conductor workspaces

USAGE:
  mcp-profile conductor setup <profile>      Set up a specific profile for this workspace
  mcp-profile conductor list                 Show all available profile templates
  mcp-profile conductor help                 Show this help

PROFILES:
  notion-only     Notion only (lightweight)
  docs-focus      Notion + Google Drive
  project-focus   Notion (project management)
  all-tools       All available tools

EXAMPLES:
  # In a new Conductor workspace, set up a profile:
  mcp-profile conductor setup docs-focus

  # List available profiles:
  mcp-profile conductor list

NOTES:
  • Run this in your Conductor workspace directory
  • Copies profile template from dotfiles to workspace
  • Creates .mcp.json as active configuration
  • Other profile templates (.mcp.*.json) remain as options
CONDUCTOR_HELP
        return 0
    fi

    case "$action" in
        setup)
            if [ -z "$profile" ]; then
                echo "Error: Profile name required"
                echo "Usage: mcp-profile conductor setup <profile>"
                echo "Profiles: notion-only, docs-focus, project-focus, all-tools"
                return 1
            fi

            # Check if we're in a Conductor workspace
            if [ -z "${CONDUCTOR_WORKSPACE_PATH:-}" ]; then
                echo "Note: Not running in a Conductor workspace (\$CONDUCTOR_WORKSPACE_PATH not set)"
                echo "Proceeding with current directory: $PWD"
                local target_dir="$PWD"
            else
                local target_dir="$CONDUCTOR_WORKSPACE_PATH"
            fi

            # Find template in dotfiles
            local template_source="${DOTFILES}/tools/mcp/.mcp.${profile}.json"

            # Fallback to /tmp/attachments if not in dotfiles yet
            if [ ! -f "$template_source" ]; then
                template_source="/tmp/attachments/.mcp.${profile}.json"
            fi

            if [ ! -f "$template_source" ]; then
                echo "Error: Profile template not found: .mcp.${profile}.json"
                echo ""
                echo "Expected locations:"
                echo "  - ${DOTFILES}/tools/mcp/.mcp.${profile}.json"
                echo "  - /tmp/attachments/.mcp.${profile}.json"
                return 1
            fi

            # Copy all profile templates to workspace
            echo "Setting up MCP profiles in: $target_dir"
            echo ""

            for template in /tmp/attachments/.mcp.*.json "${DOTFILES}/tools/mcp/.mcp."*.json; do
                if [ -f "$template" ]; then
                    local filename=$(basename "$template")
                    cp "$template" "${target_dir}/${filename}"
                    echo "✓ Copied: $filename"
                fi
            done

            # Set active profile
            cp "$template_source" "${target_dir}/.mcp.json"
            echo ""
            echo "✓ Active profile set to: $profile"
            echo ""
            echo "Next steps:"
            echo "  1. Verify: mcp-profile show"
            echo "  2. Switch profiles: mcp-switch <profile>"
            echo "  3. Check secrets: mcp-profile status"
            ;;

        list)
            echo "Available profile templates:"
            echo ""

            # Check both locations
            for location in "${DOTFILES}/tools/mcp" "/tmp/attachments"; do
                if [ -d "$location" ]; then
                    ls -1 "$location"/.mcp.*.json 2>/dev/null | \
                        sed "s|${location}/.mcp.||g; s|.json||g" | \
                        while read -r profile; do
                            if [ -n "$profile" ] && [ "$profile" != "json" ]; then
                                echo "  • $profile"
                            fi
                        done
                fi
            done
            ;;

        help)
            mcp_conductor
            ;;

        *)
            echo "Error: Unknown conductor command: $action"
            echo "Run 'mcp-profile conductor help' for usage"
            return 1
            ;;
    esac
}

# Main dispatcher
mcp_profile() {
    local cmd="${1:-help}"

    case "$cmd" in
        switch)
            shift
            mcp_switch "$@"
            ;;
        show)
            mcp_show
            ;;
        list)
            mcp_list
            ;;
        status)
            mcp_status
            ;;
        conductor)
            shift
            mcp_conductor "$@"
            ;;
        help|--help|-h|"")
            cat << 'HELP'
mcp-profile - Global Claude Code MCP tool manager

USAGE:
  mcp-switch <profile>              Switch to an MCP profile
  mcp-profile show                 Show currently active tools
  mcp-profile list                 List all available profiles
  mcp-profile status               Check API key status
  mcp-profile conductor <action>   Configure MCP for Conductor workspaces
  mcp-profile help                 Show this help

PROFILES:
  notion-only     Notion only (lightweight)
  docs-focus      Notion + Google Drive
  project-focus   Notion (project management)
  all-tools       All available tools

CONDUCTOR:
  mcp-profile conductor setup <profile>    Set up a profile in Conductor workspace
  mcp-profile conductor list               List available profiles
  mcp-profile conductor help               Show Conductor help

EXAMPLES:
  # Regular project workflow:
  cd ~/projects/my-repo
  mcp-switch docs-focus              # Switch profile
  mcp-profile show                   # Show active tools
  mcp-profile list                   # List profiles
  mcp-profile status                 # Check credentials

  # Conductor workspace workflow:
  cd $CONDUCTOR_WORKSPACE_PATH
  mcp-profile conductor setup docs-focus    # Initialize workspace
  mcp-profile conductor list                # See all profiles
  mcp-switch project-focus                  # Switch to different profile

NOTES:
  • Works globally in any repo with .mcp.json
  • Auto-searches parent directories for .mcp.json
  • Backs up previous .mcp.json before switching
  • Loads secrets via existing 1Password integration
  • Restart Claude Code session after switching
  • Conductor setup copies all profiles, you select which to use

For more info: https://code.claude.com/docs
HELP
            ;;
        *)
            echo "Error: Unknown command: $cmd"
            echo "Run 'mcp-profile help' for usage"
            return 1
            ;;
    esac
}

# Create convenient aliases
alias mcp-switch="mcp_profile switch"
