# MCP Profile Manager Integration

This document describes the MCP profile manager that provides global command-line switching between different MCP tool configurations for Claude Code (Cursor, Claude Desktop, and Claude CLI).

## Overview

The MCP profile manager adds a global function to your dotfiles that:

- Switches between predefined MCP tool configurations (`notion-only`, `docs-focus`, `project-focus`, `all-tools`)
- Auto-detects `.mcp.json` project configuration from any directory
- Integrates with your existing 1Password infrastructure via `_secure_run` pattern
- Backs up previous configurations before switching
- Works globally from any project directory

## Available Profiles

| Profile | Tools | Use Case |
|---------|-------|----------|
| `notion-only` | Notion | Lightweight knowledge access |
| `docs-focus` | Notion + Google Drive | Documentation work, research |
| `project-focus` | Notion | Project management |
| `all-tools` | Notion + Google Drive + Outlook + Claude Swarm | Full power mode |

Each profile corresponds to a template file (`.mcp.*.json`) that you copy into your projects.

## Installation

### 1. Add Function to Dotfiles

```bash
# Open your functions file
code ~/.dotfiles/shells/oh-my-zsh/custom/functions.zsh

# Scroll to the end and paste entire content from:
# mcp-profile-functions.zsh (available in workspace directory)

# Save and close
```

### 2. Reload Shell

```bash
exec zsh
```

### 3. Verify Installation

```bash
mcp-profile help
# Should display the help menu with all available commands
```

## Usage

### Basic Commands

```bash
# List available profiles in current project
mcp-profile list

# Switch to a profile (auto-loads secrets)
mcp-switch docs-focus

# Show currently active tools
mcp-profile show

# Check if secrets are loaded
mcp-profile status

# Display help
mcp-profile help
```

### Typical Workflow

```bash
# Navigate to a project
cd ~/projects/my-project

# See what profiles are available
mcp-profile list
# Output:
# Available profiles:
# - .mcp.notion-only.json
# - .mcp.docs-focus.json
# - .mcp.project-focus.json

# Switch to the profile you want
mcp-switch docs-focus

# Verify it's active
mcp-profile show
# Output:
# Currently active: .mcp.docs-focus.json
# Active tools:
# - Notion
# - Google Drive
```

## Per-Project Setup

For each project that uses MCP profiles:

```bash
# Copy all profile templates to your project
cp /tmp/attachments/.mcp.*.json ~/my-project/

# You now have these profiles available:
cd ~/my-project
mcp-profile list
```

Only the template files (`.mcp.*.json`) are needed—the function auto-detects them.

## Conductor Workspace Setup

For Conductor workspaces, use the built-in `conductor` command to initialize MCP profiles:

```bash
# In a new Conductor workspace
mcp-profile conductor setup docs-focus

# This will:
# • Copy all profile templates to the workspace
# • Set docs-focus as the active profile
# • Create .mcp.json with the active configuration
```

### Typical Conductor Workflow

```bash
# Create a new Conductor workspace
conductor new my-workspace

# Navigate to workspace (or when workspace is active)
cd $CONDUCTOR_WORKSPACE_PATH

# Set up a specific MCP profile
mcp-profile conductor setup docs-focus

# List all available profiles
mcp-profile conductor list

# Switch to a different profile anytime
mcp-switch project-focus

# Check what's active
mcp-profile show
```

The `conductor setup` command copies all profile templates to your workspace, then activates the one you specify. You can then switch between profiles using the regular `mcp-switch` command.

## Secret Management

The MCP profile manager integrates with your existing 1Password setup.

### Using Existing 1Password Infrastructure

Secrets are loaded via the optional file:

```bash
~/.dotfiles/shells/oh-my-zsh/custom/secure_profiles/mcp-secrets
```

If this file exists, it will be automatically sourced when switching profiles. Add your MCP-specific secret loading here:

```bash
# Example: Load API keys from 1Password
# export NOTION_API_KEY=$(op read "op://Private/Notion Integration/api_key")
# export GOOGLE_APPLICATION_CREDENTIALS=$(op read "op://Private/Google Drive Service Account/credentials_json")
```

### Manual Secret Setup (Optional)

If you don't use the centralized file, you can set environment variables directly:

```bash
export NOTION_API_KEY="your_api_key"
export GOOGLE_APPLICATION_CREDENTIALS="your_json_content"
```

Then verify they're loaded:

```bash
mcp-profile status
```

## How It Integrates With Your Dotfiles

The MCP profile manager is designed to integrate seamlessly:

- **Location**: Added to `~/.dotfiles/shells/oh-my-zsh/custom/functions.zsh`
- **1Password Integration**: Uses existing `_secure_run()` pattern (if available)
- **No Configuration Changes**: No edits needed to `.zshrc` or other shell config
- **Graceful Fallback**: Works even if optional tools (like `jq`) are missing

## File Organization

```
~/.dotfiles/
└── shells/oh-my-zsh/custom/
    ├── functions.zsh                    ← MCP functions added here
    └── secure_profiles/
        └── mcp-secrets                  ← Optional: MCP-specific secrets

~/projects/my-project/
├── .mcp.json                            ← Active config (auto-switched)
├── .mcp.notion-only.json
├── .mcp.docs-focus.json
├── .mcp.project-focus.json
└── .mcp.all-tools.json
```

## Committing to Dotfiles

Once you've tested the integration:

```bash
cd ~/.dotfiles
git add shells/oh-my-zsh/custom/functions.zsh
git commit -m "Add MCP profile manager for global tool switching"
git push
```

Then copy profile templates to your projects as needed:

```bash
cp /tmp/attachments/.mcp.*.json ~/projects/my-project/
```

## Advanced Configuration

### Custom Secret Loading

If you want MCP-specific secret loading (optional):

```bash
# Create the secure profile directory
mkdir -p ~/.dotfiles/shells/oh-my-zsh/custom/secure_profiles

# Create MCP secrets file
cat > ~/.dotfiles/shells/oh-my-zsh/custom/secure_profiles/mcp-secrets <<'EOF'
# Load MCP-specific secrets from 1Password
# Uncomment and customize as needed:

# export NOTION_API_KEY=$(op read "op://Private/Notion Integration/api_key")
# export GOOGLE_APPLICATION_CREDENTIALS=$(op read "op://Private/Google Drive Service Account/credentials_json")
EOF
```

The function will automatically source this file when switching profiles.

## Troubleshooting

### Command Not Found

If you get "command not found: mcp-profile":

1. Verify the function was added: `grep -n "mcp_profile()" ~/.dotfiles/shells/oh-my-zsh/custom/functions.zsh`
2. Reload your shell: `exec zsh`
3. Check that the file exists: `ls ~/.dotfiles/shells/oh-my-zsh/custom/functions.zsh`

### No Profiles Found

If `mcp-profile list` shows no profiles:

1. Check you're in a project directory with `.mcp.json` files
2. Verify the files exist: `ls .mcp.*.json`
3. Confirm the function can find the project: `echo $PWD`

### Secrets Not Loading

If `mcp-profile status` shows secrets as unset:

1. Verify your secret file exists: `ls ~/.dotfiles/shells/oh-my-zsh/custom/secure_profiles/mcp-secrets`
2. Test 1Password connection: `op signin`
3. Check the secret path: `op read "op://Private/Notion Integration/api_key"`

## Related Documentation

- For Claude Desktop and Cursor MCP setup, see `~/.dotfiles/docs/mcp.md`
- For API key setup and management, see `~/.dotfiles/docs/mcp-api-keys.md`
