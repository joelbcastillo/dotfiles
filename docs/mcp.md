# MCP (Model Context Protocol) Configuration

This document describes how MCP servers are configured for Claude Desktop, Cursor, and Claude CLI in this dotfiles repository.

## Overview

MCP (Model Context Protocol) allows AI assistants like Claude and Cursor to connect to external data sources and tools. This dotfiles setup manages MCP server configurations for:

- **Claude Desktop**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Cursor**: `~/.cursor/mcp.json`
- **Claude CLI**: Project-specific `.mcp.json` files

## 1Password Integration

This setup uses the **official 1Password approach** for securing MCP credentials:

- Uses `op run` to inject secrets at runtime
- Secrets are never written to disk
- Uses `op://vault/item/field` syntax for secret references
- Requires 1Password CLI (`op`) to be installed and authenticated

### How It Works

Instead of storing secrets in config files, MCP servers are launched via `op run`:

```json
{
  "notion": {
    "command": "op",
    "args": ["run", "--account", "ACCOUNT_UUID", "--", "bash", "-c", "..."],
    "env": {
      "NOTION_API_KEY": "op://vault_id/item_id/credential"
    }
  }
}
```

When the MCP server starts:
1. `op run` reads the `op://` references
2. Fetches secrets from 1Password
3. Injects them as environment variables
4. Executes the actual MCP server command

## Configured MCP Servers

### 1. Notion MCP
Provides access to Notion workspaces and databases.

- **Package**: `@notionhq/notion-mcp-server`
- **Installation**: Via `npx` (automatic)
- **Authentication**: 1Password (`op run` with `op://` syntax)
- **Usage**: Access and query Notion databases, pages, and content

### 2. Google Drive MCP
Provides access to Google Drive files and folders.

- **Package**: `@piotr-agier/google-drive-mcp`
- **Installation**: Via `npx` (automatic)
- **Authentication**: OAuth flow (browser-based, no 1Password needed for secrets)
- **Configuration**: Requires OAuth credentials file at `~/.config/google-drive-mcp/gcp-oauth.keys.json`
- **Usage**: Read, search, and manage Google Drive files

### 3. Linear MCP
Provides access to Linear issue tracking and project management.

- **Package**: `mcp-remote` (connects to Linear's official MCP endpoint)
- **Installation**: Via `npx` (automatic)
- **Authentication**: Browser-based OAuth via `mcp-remote`
- **Usage**: Access Linear issues, projects, teams, and create/update issues

### 4. Outlook MCP
Provides access to Microsoft Outlook on macOS.

- **Package**: `claude-outlook-mcp` (GitHub: syedazharmbnr1/claude-outlook-mcp)
- **Installation**: Cloned to `~/.repos/github.com/syedazharmbnr1/claude-outlook-mcp`
- **Authentication**: Uses AppleScript to interact with the Outlook macOS app directly
- **Usage**: Read and manage Outlook emails, calendar, and contacts
- **Prerequisites**:
  - Requires `bun` runtime
  - Requires Microsoft Outlook for Mac to be installed and configured
  - Requires Accessibility permissions for Terminal

### 5. Claude Swarm MCP
Provides orchestration capabilities for parallel Claude workers.

- **Package**: `@just-every/claude-swarm-mcp`
- **Installation**: Via `npx` (automatic)
- **Authentication**: None required
- **Usage**: Coordinate multiple Claude workers on complex tasks

## MCP Profiles

This dotfiles setup includes multiple MCP profiles for different use cases:

| Profile | File | Servers Included |
|---------|------|------------------|
| All Tools | `.mcp.all-tools.json` | Notion, Google Drive, Linear, Outlook, Claude Swarm |
| Docs Focus | `.mcp.docs-focus.json` | Notion, Google Drive |
| Project Focus | `.mcp.project-focus.json` | Notion, Linear |
| Notion Only | `.mcp.notion-only.json` | Notion |

### Using Profiles

Copy or symlink a profile to your project:

```bash
# For Claude CLI
cp ~/.dotfiles/tools/mcp/.mcp.all-tools.json ./.mcp.json

# Or symlink for auto-updates
ln -sf ~/.dotfiles/tools/mcp/.mcp.all-tools.json ./.mcp.json
```

## Installation

### Prerequisites

1. **1Password CLI**: Required for secret injection
   ```bash
   brew install 1password-cli
   ```

2. **1Password Authentication**: Sign in to 1Password CLI
   ```bash
   op signin
   ```

3. **Bun Runtime** (for Outlook MCP):
   ```bash
   curl -fsSL https://bun.sh/install | bash
   ```

### Install MCP Configuration

```bash
./install config mcp
```

This will:
1. Create necessary directories
2. Link MCP configuration templates
3. Set up profiles in `tools/mcp/`

## Secret Management

### 1Password Secret Paths

Secrets are defined in `.dotfiles-private/secrets/1password/secret-paths.json`:

```json
{
  "mcp": {
    "notion_api_key": {
      "item_id": "namjmkrvi7y3rlv6glujnol54i",
      "field": "credential",
      "vault": "je45orsqeqmplaeemrshp3kiea",
      "account": "your-account"
    }
  }
}
```

### op:// Reference Format

The `op://` syntax is: `op://vault_id/item_id/field`

Example:
```
op://je45orsqeqmplaeemrshp3kiea/namjmkrvi7y3rlv6glujnol54i/credential
```

### Setting Up Secrets

1. **Notion API Key**: Get from [Notion Integrations](https://www.notion.so/my-integrations)
2. **Linear**: Uses browser OAuth via `mcp-remote` (no API key needed in config)
3. **Google Drive**: Uses browser OAuth (requires OAuth credentials file)

For detailed instructions, see **[MCP API Keys Setup Guide](mcp-api-keys.md)**.

## Adding New MCP Servers

### Simple Server (no secrets)

```json
{
  "server-name": {
    "command": "npx",
    "args": ["-y", "@package/name"]
  }
}
```

### Server with 1Password Secret

```json
{
  "server-name": {
    "command": "op",
    "args": [
      "run",
      "--account", "ACCOUNT_UUID",
      "--",
      "npx", "-y", "@package/name"
    ],
    "env": {
      "API_KEY": "op://vault_id/item_id/field"
    }
  }
}
```

### Server with Complex Environment Variable (like Notion)

For servers that need constructed env vars (e.g., JSON headers):

```json
{
  "server-name": {
    "command": "op",
    "args": [
      "run",
      "--account", "ACCOUNT_UUID",
      "--",
      "bash", "-c",
      "export COMPLEX_VAR='{...}'\"$SECRET\"'...' && exec npx -y @package/name"
    ],
    "env": {
      "SECRET": "op://vault_id/item_id/field"
    }
  }
}
```

## Troubleshooting

### MCP Servers Not Loading

1. **Check 1Password CLI is authenticated**:
   ```bash
   op account list
   ```

2. **Test secret retrieval**:
   ```bash
   op read "op://vault_id/item_id/field" --account ACCOUNT_UUID
   ```

3. **Check configuration files**:
   ```bash
   cat .mcp.json
   ```

4. **Restart applications**: Restart Claude Desktop/Cursor after configuration changes

### Notion MCP Not Working

1. **Test the Notion API key**:
   ```bash
   op read "op://je45orsqeqmplaeemrshp3kiea/namjmkrvi7y3rlv6glujnol54i/credential" \
     --account 5SAUNQII5ZHUBBSBJQTSKLFV7Q
   ```

2. **Verify Notion integration permissions** in Notion settings

3. **Check if `op run` works**:
   ```bash
   op run --account 5SAUNQII5ZHUBBSBJQTSKLFV7Q -- echo "Test: $NOTION_API_KEY"
   ```

### Google Drive MCP Not Working

1. **Check OAuth credentials file exists**:
   ```bash
   ls -la ~/.config/google-drive-mcp/gcp-oauth.keys.json
   ```

2. **Run initial OAuth flow**:
   ```bash
   npx @piotr-agier/google-drive-mcp auth
   ```

## References

- [Model Context Protocol Documentation](https://modelcontextprotocol.io/)
- [Notion MCP Server](https://github.com/notionhq/notion-mcp-server)
- [Google Drive MCP Server](https://github.com/piotr-agier/google-drive-mcp)
- [1Password CLI Documentation](https://developer.1password.com/docs/cli)
- [Securing MCP Servers with 1Password](https://1password.com/blog/securing-mcp-servers-with-1password-stop-credential-exposure-in-your-agent)
