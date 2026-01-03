# MCP Setup Sync Plan

This document outlines the steps to sync the new MCP (Model Context Protocol) setup between the main dotfiles and private dotfiles repositories.

## Current Status

### Main Dotfiles (`~/.dotfiles`)
- ✅ Branch created: `feature/add-mcp-servers-bun`
- ✅ New files added:
  - `.dotbot/configs/bun.yaml` - Bun installation
  - `.dotbot/configs/mcp.yaml` - MCP server setup
  - `tools/mcp/` - MCP configuration templates
  - `docs/mcp.md` - MCP documentation
  - `docs/mcp-api-keys.md` - API keys setup guide
- ✅ Modified files:
  - `.dotbot/profiles/ai-tools` - Added bun and mcp
  - `tools/1password/secret-paths.json.template` - Added MCP secrets
  - `shells/zsh/zshrc` - (check what changed)

### Private Dotfiles (`~/.dotfiles-private`)
- ✅ Branch created: `feature/sync-mcp-setup`
- ⚠️ Needs update: `secrets/1password/secret-paths.json` - Add MCP secrets

## Sync Steps

### Step 1: Update Private Repo Secret Paths

The private repo needs the MCP secrets added to `secrets/1password/secret-paths.json`:

```json
{
  "mcp": {
    "notion_api_key": {
      "item": "Notion API Key",
      "field": "credential",
      "vault": "API Keys",
      "account": "personal"
    },
    "google_drive_credentials": {
      "item": "Google Drive OAuth Credentials",
      "field": "credential",
      "vault": "API Keys",
      "account": "personal"
    },
    "linear_api_key": {
      "item": "Linear API Key",
      "field": "credential",
      "vault": "API Keys",
      "account": "personal"
    }
  }
}
```

**Action**: Merge this into the existing `secrets/1password/secret-paths.json` in the private repo.

### Step 2: Commit Changes to Main Dotfiles

```bash
cd ~/.dotfiles
git add .
git commit -m "Add MCP servers (Notion, Google Drive, Linear, Outlook) and Bun runtime"
git push -u origin feature/add-mcp-servers-bun
```

### Step 3: Update Private Repo

```bash
cd ~/.dotfiles-private
# Update secret-paths.json with MCP secrets (see Step 1)
git add secrets/1password/secret-paths.json
git commit -m "Add MCP secret paths configuration"
git push -u origin feature/sync-mcp-setup
```

### Step 4: Test Fresh Install (Optional)

To test a fresh install:

1. **Backup current setup** (if needed):
   ```bash
   # Backup current MCP configs
   cp ~/Library/Application\ Support/Claude/claude_desktop_config.json ~/Desktop/claude_desktop_config.json.backup
   cp ~/.cursor/mcp.json ~/Desktop/cursor_mcp.json.backup
   ```

2. **Test install from scratch** (in a test directory):
   ```bash
   # Clone main repo
   git clone <your-main-repo-url> ~/.dotfiles-test
   cd ~/.dotfiles-test
   git checkout feature/add-mcp-servers-bun

   # Run install
   ./install profile ai-tools
   ```

## Files That Need to Be in Private Repo

### Required
- ✅ `secrets/1password/secret-paths.json` - Must include MCP secrets
- ✅ `tools/accounts.json` - Already exists
- ✅ `git/` - Git configs (already exists)
- ✅ `aliases/` - Aliases (already exists)

### Optional (if you have them)
- `secrets/aws/` - AWS credentials
- `secrets/ssh/` - SSH keys/configs

## Files That Stay in Main Repo

These are public/template files:
- ✅ `tools/mcp/` - MCP configuration templates
- ✅ `.dotbot/configs/mcp.yaml` - MCP installation config
- ✅ `.dotbot/configs/bun.yaml` - Bun installation config
- ✅ `docs/mcp.md` - Documentation
- ✅ `tools/1password/secret-paths.json.template` - Template (no real secrets)

## After Syncing

Once both repos are updated:

1. **Merge branches** (when ready):
   ```bash
   # Main repo
   cd ~/.dotfiles
   git checkout main
   git merge feature/add-mcp-servers-bun
   git push origin main

   # Private repo
   cd ~/.dotfiles-private
   git checkout main
   git merge feature/sync-mcp-setup
   git push origin main
   ```

2. **Reinstall from dotfiles**:
   ```bash
   cd ~/.dotfiles
   ./install profile ai-tools
   ```

3. **Verify MCP setup**:
   ```bash
   # Check configs exist
   ls -la ~/Library/Application\ Support/Claude/claude_desktop_config.json
   ls -la ~/.cursor/mcp.json

   # Check secrets are resolved (should not contain "1password://")
   grep -r "1password://" ~/Library/Application\ Support/Claude/claude_desktop_config.json ~/.cursor/mcp.json
   ```

## Next Steps

1. ✅ Branches created in both repos
2. ⏳ Update private repo's `secret-paths.json` with MCP secrets
3. ⏳ Commit changes to both repos
4. ⏳ Test installation
5. ⏳ Merge branches when ready
