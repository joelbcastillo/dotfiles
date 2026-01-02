# MCP (Model Context Protocol) Configuration

This directory contains MCP server configuration templates for various AI-powered development tools.

## Supported Applications

- **Claude Desktop** - `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Cursor** - `~/.cursor/mcp.json`
- **VS Code** - `~/Library/Application Support/Code/User/mcp.json`
- **BoltAI** - `~/.boltai/mcp.json`
- **Claude CLI** - Configured via `claude mcp` commands
- **Project-level** - `.mcp.json` in any project directory

## Files

- `claude_desktop_config.json.template` - Configuration template for Claude Desktop MCP servers
- `cursor_mcp.json.template` - Configuration template for Cursor/VS Code/BoltAI/project-level MCP servers

## Current MCP Servers

### NotionMCP
- **Package**: `@notionhq/notion-mcp-server`
- **Purpose**: Access Notion workspaces, databases, and pages
- **Credentials**: Notion API key (via 1Password)

### GoogleDriveMCP
- **Package**: `@piotr-agier/google-drive-mcp`
- **Purpose**: Access and manage Google Drive files
- **Credentials**: Google Drive OAuth credentials (via 1Password)

### LinearMCP
- **Package**: `mcp-remote` (connects to Linear's official MCP endpoint)
- **Purpose**: Access Linear issue tracking and project management
- **Credentials**: Linear API key (via 1Password)

### OutlookMCP
- **Package**: `claude-outlook-mcp` (GitHub: syedazharmbnr1/claude-outlook-mcp)
- **Purpose**: Access Microsoft Outlook on macOS via AppleScript
- **Credentials**: **None required** - uses existing Outlook login
- **Requirements**:
  - Bun runtime
  - Microsoft Outlook for Mac installed and configured
  - Accessibility permissions for Terminal

## Installation

### Install All Application Configs

These templates are installed via the `mcp` dotbot config:

```bash
./install config mcp
```

The installation will:
1. Create necessary directories
2. Install OutlookMCP dependencies (clone repo, install with bun)
3. Copy templates to their target locations
4. Resolve 1Password secrets automatically
5. Configure Claude CLI MCP servers

### Check Installation Status

```bash
# Check all MCP configs
~/.dotfiles/scripts/check-mcp-installed.sh

# Or use the shell function
mcp-check
```

### Install Project-Level MCP Config

To install `.mcp.json` in a project directory:

```bash
# Install in current directory
mcp-init

# Install in a specific directory
mcp-init /path/to/project

# Or use the script directly
~/.dotfiles/scripts/check-mcp-installed.sh -t project -i
~/.dotfiles/scripts/check-mcp-installed.sh -t project -i -d /path/to/project
```

### Install Specific Application Config

```bash
# Claude Desktop only
~/.dotfiles/scripts/check-mcp-installed.sh -t claude-desktop -i

# Cursor only
~/.dotfiles/scripts/check-mcp-installed.sh -t cursor -i

# VS Code only
~/.dotfiles/scripts/check-mcp-installed.sh -t vscode -i

# BoltAI only
~/.dotfiles/scripts/check-mcp-installed.sh -t boltai -i

# Claude CLI only
~/.dotfiles/scripts/check-mcp-installed.sh -t claude-cli -i
```

### Force Reinstall

To force reinstall even if config exists:

```bash
~/.dotfiles/scripts/check-mcp-installed.sh --install --force
```

## Shell Functions

After sourcing your zsh configuration, these functions are available:

- `mcp-check` - Check or install MCP configurations (wrapper for check-mcp-installed.sh)
- `mcp-init` - Quick install `.mcp.json` in current or specified directory

## Customization

To add or modify MCP servers, edit the template files and re-run the installation.

See `docs/mcp.md` for detailed documentation.
