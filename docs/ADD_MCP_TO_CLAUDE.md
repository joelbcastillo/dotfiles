# How to Add MCP Servers to Claude Desktop

The MCP servers are already configured in your dotfiles! Here's how to set them up in Claude Desktop.

## Automatic Setup (Recommended)

The easiest way is to run the dotfiles installation:

```bash
cd ~/.dotfiles
./install config mcp
```

This will:
1. ✅ Link the MCP config template to Claude Desktop
2. ✅ Resolve all 1Password secrets
3. ✅ Expand the USERNAME placeholder
4. ✅ Set up MCP servers:
   - NotionMCP
   - GoogleDriveMCP
   - OutlookMCP

## Manual Setup (If Needed)

If you want to set it up manually or verify the setup:

### Step 1: Ensure Config is Linked

```bash
# Check if config is linked
ls -la ~/Library/Application\ Support/Claude/claude_desktop_config.json

# If not linked, create the link
ln -sf ~/.dotfiles/tools/mcp/claude_desktop_config.json.template \
       ~/Library/Application\ Support/Claude/claude_desktop_config.json
```

### Step 2: Resolve 1Password Secrets

```bash
# Sign in to 1Password CLI (JBC Tech Solutions account)
op signin your-account.1password.com

# Resolve secrets in the config
~/.dotfiles/scripts/resolve-1password-secrets.sh \
  ~/Library/Application\ Support/Claude/claude_desktop_config.json
```

### Step 3: Expand USERNAME Placeholder

```bash
# Replace USERNAME with your actual username
sed -i '' "s|/Users/USERNAME|$HOME|g" \
  ~/Library/Application\ Support/Claude/claude_desktop_config.json
```

### Step 4: Verify the Config

```bash
# Check the config is valid JSON
cat ~/Library/Application\ Support/Claude/claude_desktop_config.json | jq .

# Verify secrets are resolved (should NOT contain "1password://")
grep "1password://" ~/Library/Application\ Support/Claude/claude_desktop_config.json
# Should return nothing if secrets are resolved

# Check MCP servers are listed
cat ~/Library/Application\ Support/Claude/claude_desktop_config.json | jq '.mcpServers | keys'
# Should show: ["GoogleDriveMCP", "NotionMCP", "OutlookMCP", ...]
```

### Step 5: Restart Claude Desktop

1. **Quit Claude Desktop completely** (Cmd+Q)
2. **Reopen Claude Desktop**
3. The MCP servers should now be available

## Verify MCP Servers are Working

After restarting Claude Desktop:

1. Open Claude Desktop
2. Start a new conversation
3. Try asking:
   - "Can you check my Notion databases?"
   - "List my Google Drive files"
   - "Check my Outlook emails"

If the MCP servers are working, Claude will be able to access these services.

## Troubleshooting

### MCP Servers Not Appearing

1. **Check the config file exists**:
   ```bash
   ls -la ~/Library/Application\ Support/Claude/claude_desktop_config.json
   ```

2. **Verify JSON is valid**:
   ```bash
   cat ~/Library/Application\ Support/Claude/claude_desktop_config.json | jq .
   ```

3. **Check secrets are resolved**:
   ```bash
   # Should be empty (no "1password://" references)
   grep "1password://" ~/Library/Application\ Support/Claude/claude_desktop_config.json
   ```

4. **Check 1Password CLI is working**:
   ```bash
   op signin your-account.1password.com
   ~/.dotfiles/scripts/fetch-1password-secrets.sh notion_api_key
   ```

### OutlookMCP Not Working

1. **Verify Bun is installed**:
   ```bash
   which bun
   bun --version
   ```

2. **Check Outlook MCP repository exists**:
   ```bash
   ls -la ~/.repos/github.com/syedazharmbnr1/claude-outlook-mcp
   ```

3. **Verify Microsoft Outlook is installed and logged in**

4. **Check Accessibility permissions**:
   - System Preferences > Privacy & Security > Privacy > Accessibility
   - Ensure Terminal (or your terminal app) has access

### Secrets Not Resolving

1. **Sign in to 1Password CLI**:
   ```bash
   op signin your-account.1password.com
   ```

2. **Test secret retrieval**:
   ```bash
   ~/.dotfiles/scripts/fetch-1password-secrets.sh notion_api_key
   ```

3. **Re-run resolve script**:
   ```bash
   ~/.dotfiles/scripts/resolve-1password-secrets.sh \
     ~/Library/Application\ Support/Claude/claude_desktop_config.json
   ```

## Current Configuration

Your Claude Desktop config is located at:
```
~/Library/Application Support/Claude/claude_desktop_config.json
```

It's symlinked from:
```
~/.dotfiles/tools/mcp/claude_desktop_config.json.template
```

## Next Steps

1. ✅ Run `./install config mcp` to set everything up
2. ✅ Restart Claude Desktop
3. ✅ Test the MCP servers by asking Claude to access your services
