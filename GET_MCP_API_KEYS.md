# Step-by-Step Guide: Getting MCP API Keys

This guide walks you through obtaining each API key needed for the MCP servers.

## Prerequisites

- Access to your JBC Tech Solutions 1Password account (`jbctechsolutions.1password.com`)
- Admin access to the services you're setting up

---

## 1. Notion API Key

### Step 1: Go to Notion Integrations
1. Open your browser and go to: **https://www.notion.so/my-integrations**
2. Sign in with your Notion account (use your JBC Tech Solutions account if you have one)

### Step 2: Create New Integration
1. Click **"+ New integration"** button (top right)
2. Fill in the details:
   - **Name**: `Claude MCP` (or any name you prefer)
   - **Logo**: Optional - you can skip this
   - **Associated workspace**: Select the workspace you want Claude to access
3. Click **"Submit"**

### Step 3: Copy the Integration Token
1. After creating, you'll see a page with your integration details
2. Find the **"Internal Integration Token"** section
3. Click **"Show"** or **"Copy"** to reveal the token
4. The token will look like: `secret_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
5. **Copy this token** - you'll need it in Step 4

### Step 4: Grant Access to Pages/Databases
1. Go to any Notion page or database you want Claude to access
2. Click the **"..."** menu (top right)
3. Select **"Add connections"** or **"Connections"**
4. Search for and select your integration (e.g., "Claude MCP")
5. Repeat for each page/database you want to access

### Step 5: Save to 1Password
1. Open 1Password and sign in to your **JBC Tech Solutions** account
2. Navigate to the **"API Keys"** vault
3. Click **"+"** to create a new item
4. Choose **"Password"** type
5. Fill in:
   - **Title**: `Notion API Key`
   - **Password/credential field**: Paste the token (starts with `secret_`)
   - **Notes**: Optional - add which workspace it's for
6. Click **"Save"**

---

## 2. Linear API Key

### Step 1: Open Linear Settings
1. Open Linear (app or web: https://linear.app)
2. Sign in with your account
3. Click your **profile icon** (bottom left or top right)
4. Select **"Settings"**

### Step 2: Navigate to API Section
1. In Settings, look for **"API"** in the left sidebar
2. Click on **"API"**

### Step 3: Create API Key
1. Click **"Create API Key"** button
2. Fill in:
   - **Name**: `Claude MCP` (or any name you prefer)
   - **Description**: Optional - e.g., "For Claude MCP server access"
3. Click **"Create"**

### Step 4: Copy the API Key
1. **Important**: Copy the API key immediately - you won't be able to see it again!
2. The key will look like: `lin_api_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
3. **Copy this key** - you'll need it in Step 5

### Step 5: Save to 1Password
1. Open 1Password and sign in to your **JBC Tech Solutions** account
2. Navigate to the **"API Keys"** vault
3. Click **"+"** to create a new item
4. Choose **"Password"** type
5. Fill in:
   - **Title**: `Linear API Key`
   - **Password/credential field**: Paste the API key
   - **Notes**: Optional - add which Linear workspace it's for
6. Click **"Save"**

---

## 3. Google Drive OAuth Credentials

### Step 1: Go to Google Cloud Console
1. Open your browser and go to: **https://console.cloud.google.com/**
2. Sign in with your Google account (use your JBC Tech Solutions Google account if you have one)
3. If you don't have a project, you'll need to create one

### Step 2: Create or Select a Project
1. Click the **project dropdown** at the top (next to "Google Cloud")
2. Either:
   - **Select an existing project**, OR
   - Click **"New Project"** and create one (e.g., "Claude MCP")

### Step 3: Enable Google Drive API
1. In the left sidebar, go to **"APIs & Services"** > **"Library"**
2. In the search bar, type: **"Google Drive API"**
3. Click on **"Google Drive API"** from the results
4. Click the **"Enable"** button
5. Wait for it to enable (may take a few seconds)

### Step 4: Create OAuth Credentials
1. Go to **"APIs & Services"** > **"Credentials"** (in left sidebar)
2. Click **"+ Create Credentials"** at the top
3. Select **"OAuth client ID"**

### Step 5: Configure OAuth Consent Screen (if prompted)
If this is your first time, you'll need to configure the consent screen:
1. Click **"Configure Consent Screen"**
2. Choose **"Internal"** (if you have a Google Workspace) or **"External"**
3. Fill in:
   - **App name**: `Claude MCP`
   - **User support email**: Your email
   - **Developer contact**: Your email
4. Click **"Save and Continue"**
5. On "Scopes" page, click **"Save and Continue"** (no need to add scopes here)
6. On "Test users" page, click **"Save and Continue"**
7. Click **"Back to Dashboard"**

### Step 6: Create OAuth Client ID
1. Go back to **"APIs & Services"** > **"Credentials"**
2. Click **"+ Create Credentials"** > **"OAuth client ID"**
3. Select **"Desktop app"** as the application type
4. Give it a name: `Claude MCP Desktop`
5. Click **"Create"**

### Step 7: Download Credentials
1. A popup will appear with your **Client ID** and **Client Secret**
2. **Don't close this yet!**
3. Click **"Download JSON"** button
4. Save the file somewhere safe (e.g., Desktop)
5. The JSON file contains both Client ID and Client Secret

### Step 8: Save to 1Password
1. Open the downloaded JSON file in a text editor
2. It will look like:
   ```json
   {
     "installed": {
       "client_id": "xxxxx.apps.googleusercontent.com",
       "project_id": "xxxxx",
       "auth_uri": "https://accounts.google.com/o/oauth2/auth",
       "token_uri": "https://oauth2.googleapis.com/token",
       "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
       "client_secret": "xxxxx",
       "redirect_uris": ["urn:ietf:wg:oauth:2.0:oob", "http://localhost"]
     }
   }
   ```
3. Open 1Password and sign in to your **JBC Tech Solutions** account
4. Navigate to the **"API Keys"** vault
5. Click **"+"** to create a new item
6. Choose **"Secure Note"** type (since it's JSON)
7. Fill in:
   - **Title**: `Google Drive OAuth Credentials`
   - **Notes**: Paste the entire JSON content from the file
8. Click **"Save"**

---

## Verification

After adding all three keys to 1Password, verify they're accessible:

```bash
# Sign in to 1Password CLI with JBC Tech Solutions account
op signin jbctechsolutions.1password.com

# Test retrieving each key
~/.dotfiles/scripts/fetch-1password-secrets.sh notion_api_key
~/.dotfiles/scripts/fetch-1password-secrets.sh linear_api_key
~/.dotfiles/scripts/fetch-1password-secrets.sh google_drive_credentials
```

If all three commands return values (not errors), you're all set!

---

## Troubleshooting

### Notion API Key Issues
- **Token not working**: Make sure you've granted the integration access to the pages/databases you want to use
- **Can't find integration**: Check you're looking in the correct workspace

### Linear API Key Issues
- **Key not found**: Make sure you copied it before closing the dialog (you can't see it again)
- **Permission denied**: Ensure the API key has the right permissions for your Linear workspace

### Google Drive OAuth Issues
- **Can't enable API**: Make sure you have the right permissions in Google Cloud Console
- **JSON file missing**: You can recreate credentials, but you'll need to download the JSON again
- **Credentials not working**: Make sure you saved the entire JSON content, not just parts of it

---

## Next Steps

Once all keys are in 1Password:

1. **Test the setup**:
   ```bash
   cd ~/.dotfiles
   ./install config mcp
   ```

2. **Verify secrets are resolved**:
   ```bash
   # Should NOT contain "1password://"
   grep "1password://" ~/Library/Application\ Support/Claude/claude_desktop_config.json
   ```

3. **Restart Claude Desktop and Cursor** to load the MCP servers
