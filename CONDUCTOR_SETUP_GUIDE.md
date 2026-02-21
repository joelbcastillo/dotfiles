# Conductor Workspace MCP Setup Guide

The MCP profile manager now includes built-in support for Conductor workspaces through the `mcp-profile conductor` command.

## Quick Setup

```bash
# In a new Conductor workspace
mcp-profile conductor setup docs-focus
```

This single command will:
- Copy all profile templates (`.mcp.*.json`) to your workspace
- Set the specified profile as active (`.mcp.json`)
- Configure the workspace to use MCP

## Available Commands

### Setup a Profile

```bash
mcp-profile conductor setup <profile>
```

Sets up a specific profile for the current workspace. Copies all available profiles and activates the one you choose.

**Profiles:**
- `notion-only` - Notion only (lightweight)
- `docs-focus` - Notion + Google Drive
- `project-focus` - Notion + Linear
- `all-tools` - All available tools

### List Available Profiles

```bash
mcp-profile conductor list
```

Shows all profile templates available for use.

### Get Help

```bash
mcp-profile conductor help
```

Displays the Conductor setup help.

## Typical Workflow

1. **Create a new Conductor workspace**:
   ```bash
   conductor new my-workspace
   ```

2. **Set up MCP profiles**:
   ```bash
   # Navigate to workspace (automatically done by Conductor)
   cd $CONDUCTOR_WORKSPACE_PATH
   
   # Initialize with a specific profile
   mcp-profile conductor setup docs-focus
   ```

3. **Verify setup**:
   ```bash
   mcp-profile show        # See active tools
   mcp-profile conductor list    # See all available profiles
   ```

4. **Switch profiles anytime**:
   ```bash
   mcp-switch project-focus    # Change to different profile
   mcp-profile show            # Verify
   ```

## How It Works

The `mcp-profile conductor setup <profile>` command:

1. **Detects Conductor context**: Checks for `$CONDUCTOR_WORKSPACE_PATH` environment variable
2. **Copies all templates**: Copies `.mcp.*.json` files from dotfiles or `/tmp/attachments`
3. **Activates selected profile**: Creates `.mcp.json` based on your choice
4. **Prepares workspace**: Workspace is ready to use with Claude Code

## Manual Fallback

If you prefer to set up profiles manually:

```bash
# In your workspace
cp /tmp/attachments/.mcp.*.json .

# Choose which profile to use as active
cp .mcp.docs-focus.json .mcp.json
```

Then use the regular `mcp-switch` command to change profiles.

## Integration with conductor.json

To automate MCP setup in a `conductor.json` setup script:

```bash
#!/bin/bash
# In your conductor-setup.sh

# Set up MCP profiles if the function is available
if command -v mcp-profile &> /dev/null; then
    mcp-profile conductor setup docs-focus
fi
```

This can be called from your `conductor.json`:

```json
{
    "scripts": {
        "setup": "./conductor-setup.sh"
    }
}
```

## Notes

- The function gracefully handles both Conductor and non-Conductor environments
- All profile templates are copied to the workspace (you choose which to use)
- Profile switching works globally via `mcp-switch` in any Conductor workspace
- Secrets are loaded via your existing 1Password integration
- No changes needed to `.zshrc` - the function is automatically available

## Related Commands

Once profiles are set up, use standard commands:

```bash
mcp-profile show        # Show active tools
mcp-profile list        # List available profiles
mcp-switch <profile>    # Switch profiles
mcp-profile status      # Check API keys
```

For more details, see `START_HERE.md` or run `mcp-profile help`.
