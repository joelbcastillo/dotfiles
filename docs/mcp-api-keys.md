# MCP API Keys Setup Guide

This guide explains how to obtain and configure API keys for all MCP servers configured in this dotfiles repository.

## Overview

All MCP servers require authentication credentials. These are stored securely in 1Password and automatically resolved during installation.

## API Keys Required

### 1. Notion API Key

**Purpose**: Access Notion workspaces, databases, and pages

**How to Get It**:

1. Go to [Notion Integrations](https://www.notion.so/my-integrations)
2. Click **"+ New integration"**
3. Give it a name (e.g., "Claude MCP")
4. Select the workspace you want to access
5. Click **"Submit"**
6. Copy the **Internal Integration Token** (starts with `secret_`)

**Setup in 1Password**:
- Create item: **"Notion API Key"**
- Vault: **"API Keys"**
- Field: **"credential"** (paste the token)

**Reference**: [Notion API Documentation](https://developers.notion.com/docs/getting-started)

---

### 2. Google Drive OAuth Credentials

**Purpose**: Access and manage Google Drive files

**How to Get It**:

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable **Google Drive API**:
   - Go to **APIs & Services** > **Library**
   - Search for "Google Drive API"
   - Click **Enable**
4. Create OAuth credentials:
   - Go to **APIs & Services** > **Credentials**
   - Click **Create Credentials** > **OAuth client ID**
   - Choose **Desktop app** as application type
   - Give it a name (e.g., "Claude MCP")
   - Click **Create**
5. Download the credentials JSON file

**Setup in 1Password**:
- Create item: **"Google Drive OAuth Credentials"**
- Vault: **"API Keys"**
- Field: **"credential"** (paste the entire JSON content)

**Reference**: [Google Drive API Documentation](https://developers.google.com/drive/api/guides/about-sdk)

---

### 3. Outlook OAuth Credentials

**Status**: **NOT REQUIRED** for `syedazharmbnr1/claude-outlook-mcp`

**Purpose**: Access Microsoft Outlook on macOS

**How It Works**:
The `syedazharmbnr1/claude-outlook-mcp` uses **AppleScript** to interact directly with the Microsoft Outlook macOS app. This means:
- ✅ **No OAuth credentials needed** - it uses your existing Outlook login
- ✅ **No Azure App Registration required**
- ✅ Works with your current Outlook session

**Requirements**:
1. Microsoft Outlook for Mac must be installed
2. You must be logged into Outlook
3. Terminal must have Accessibility permissions (System Preferences > Privacy & Security > Privacy > Accessibility)

**Setup**:
1. Install Microsoft Outlook for Mac from the App Store
2. Log in to your Outlook account
3. Grant Accessibility permissions to Terminal (or your terminal app)
4. The MCP server will automatically use your Outlook session

**Note**: If you're using a different Outlook MCP that requires OAuth credentials, follow the Azure Portal setup instructions below.

**How to Get It** (if required):

1. Go to [Azure Portal](https://portal.azure.com/)
2. Navigate to **Azure Active Directory** > **App registrations**
3. Click **"New registration"**
4. Fill in:
   - **Name**: "Claude Outlook MCP"
   - **Supported account types**: Choose based on your needs
   - **Redirect URI**: Leave blank for now
5. Click **"Register"**
6. Note the **Application (client) ID** - this is your Client ID
7. Create a Client Secret:
   - Go to **Certificates & secrets**
   - Click **"New client secret"**
   - Add description and expiration
   - Click **"Add"**
   - **Copy the Value immediately** (you won't see it again)
8. Configure API Permissions:
   - Go to **API permissions**
   - Click **"Add a permission"**
   - Select **Microsoft Graph**
   - Choose **Delegated permissions**
   - Add: `Mail.Read`, `Mail.Send`, `Calendars.Read`, `Contacts.Read`
   - Click **"Add permissions"**
   - Click **"Grant admin consent"** (if you have admin rights)

**Setup in 1Password**:
- Create item: **"Outlook OAuth Client ID"**
  - Vault: **"API Keys"**
  - Field: **"credential"** (paste the Client ID)
- Create item: **"Outlook OAuth Client Secret"**
  - Vault: **"API Keys"**
  - Field: **"credential"** (paste the Client Secret Value)

**Reference**: [Microsoft Graph API Documentation](https://learn.microsoft.com/en-us/graph/overview)

---

## Setting Up Secrets in 1Password

### Step 1: Create the Items

For each API key above, create a new item in your 1Password vault:

1. Open 1Password
2. Navigate to your **"API Keys"** vault (or create it if it doesn't exist)
3. Click **"+"** to create a new item
4. Choose **"Password"** or **"Secure Note"** type
5. Name it exactly as specified (e.g., "Notion API Key")
6. Add the credential in the appropriate field:
   - For most keys: Use the **"password"** or **"notes"** field
   - For JSON credentials: Use the **"notes"** field and paste the entire JSON

### Step 2: Verify Secret Paths Configuration

The secret paths are configured in `tools/1password/secret-paths.json.template`. After creating items in 1Password, verify the mapping:

```json
{
  "mcp": {
    "notion_api_key": {
      "item": "Notion API Key",
      "field": "credential",
      "vault": "API Keys",
      "account": "personal"
    }
  }
}
```

### Step 3: Test Secret Retrieval

Test that secrets can be retrieved:

```bash
# Sign in to 1Password CLI
op signin

# Test retrieving a secret
~/.dotfiles/scripts/fetch-1password-secrets.sh notion_api_key
```

---

## Troubleshooting

### Secret Not Found

If you get "Secret not found" errors:

1. **Check item name**: Must match exactly (case-sensitive)
2. **Check vault name**: Must match exactly
3. **Check field name**: Usually "credential" or "password"
4. **Verify 1Password CLI**: Run `op signin` to ensure you're signed in

### Outlook MCP Not Working Without Credentials

If your Outlook MCP version doesn't require credentials:

1. Remove the `OUTLOOK_CLIENT_ID` and `OUTLOOK_CLIENT_SECRET` environment variables from the MCP config
2. Or leave them empty - the MCP server may use macOS authentication instead

### Notion Integration Issues

- Ensure the integration has access to the workspaces you want to use
- Check that the integration token is valid (starts with `secret_`)
- Verify workspace permissions

---

## Security Best Practices

1. **Never commit API keys** to version control
2. **Use 1Password** for all credential storage
3. **Rotate keys regularly** (especially if exposed)
4. **Use least privilege** - only grant necessary permissions
5. **Monitor API usage** in provider dashboards

---

## Quick Reference

| Service | Item Name in 1Password | Where to Get It |
|---------|----------------------|-----------------|
| Notion | Notion API Key | notion.so/my-integrations |
| Google Drive | Google Drive OAuth Credentials | Google Cloud Console |
| Outlook | Outlook OAuth Client ID/Secret | Azure Portal (if required) |

---

## Next Steps

After setting up all API keys in 1Password:

1. Run the MCP installation:
   ```bash
   ./install config mcp
   ```

2. Verify secrets are resolved:
   ```bash
   cat ~/Library/Application\ Support/Claude/claude_desktop_config.json | grep -v "1password://"
   ```

3. Restart Claude Desktop and Cursor to load the MCP servers
