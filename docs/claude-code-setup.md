# Claude Code Setup with 1Password

This document describes how Claude Code is configured to use a setup token stored in 1Password.

## Overview

Claude Code supports multiple authentication methods:
- **`claude login`**: Interactive login using your Claude subscription (Pro/Max) - best for local development
- **`claude setup-token`**: Long-lived OAuth token for automation/headless use (e.g., clawdbot in homelab)
- **API Key**: Pay-as-you-go billing via `ANTHROPIC_API_KEY` environment variable (optional, for specific tools)

**Default Setup**: Everything uses subscription authentication:
- **Laptop**: Use `claude login` for Claude Code (subscription)
- **Homelab**: Use `setup-token` for clawdbot (subscription)
- **Conductor**: Automatically uses subscription (inherits from Claude Code login)

## Configuration

### 1Password Secret

The Claude Code setup token is stored in 1Password:
- **Item ID**: `wyy3kchgemuihnd6x32efyrzci`
- **Item Name**: "Claude Code Token"
- **Vault**: "AI"
- **Field**: "credential"
- **Account**: "your-account"

This is configured in `~/.dotfiles-private/secrets/1password/secret-paths.json`:

```json
{
  "claude_code": {
    "claude_code_setup_token": {
      "item": "wyy3kchgemuihnd6x32efyrzci",
      "field": "credential",
      "vault": "AI",
      "account": "your-account"
    }
  }
}
```

## Setup Process

### Option 1: Use `claude login` (Recommended for Laptop)

For interactive use on your laptop:

1. **Login to Claude Code**:
   ```bash
   claude login
   ```
   This will open a browser for OAuth authentication and use your subscription.

2. **Verify login**:
   ```bash
   claude /status
   ```

3. **Use Claude Code normally**:
   ```bash
   # Since ANTHROPIC_API_KEY is not set by default, Claude Code will use your subscription
   claude "your prompt"
   ```

   **Note**: If you need to temporarily use an API key for a specific tool, use:
   ```bash
   use-api-key    # Set API key temporarily
   your-tool      # Run your tool
   use-subscription  # Switch back to subscription
   ```

### Option 2: Use Setup Token (For Homelab/Automation)

For non-interactive use (e.g., clawdbot in homelab):

1. **Generate setup token**:
   ```bash
   claude setup-token
   ```

2. **Save to 1Password**:
   ```bash
   op item edit wyy3kchgemuihnd6x32efyrzci --vault AI credential="<token>"
   ```

3. **Configure in your tool**:
   - **clawdbot**: Configure in clawdbot settings to fetch from 1Password
   - **Conductor**: Automatically configured via `setup-conductor-auth.sh` (runs during dotfiles install)

### Automatic Setup

When you run the dotfiles installation with the `claude-code` config:

```bash
./install config claude-code
```

The setup script will:
1. Validate the setup token from 1Password (for Conductor/clawdbot)
2. **NOT** set `apiKeyHelper` in `~/.claude/settings.json` (to avoid conflicts with `claude login`)
3. Configure Conductor's bundled binary separately (via `setup-conductor-auth.sh`)
4. Guide you to use `claude login` for main Claude Code

## Token Renewal

If your token expires, you'll need to:

1. **Generate a new token**:
   ```bash
   claude setup-token
   ```

2. **Update the token in 1Password**:

   Option A: Via 1Password app
   - Open 1Password
   - Find "Claude Code Token" in the "AI" vault
   - Update the "credential" field with the new token

   Option B: Via 1Password CLI
   ```bash
   op item edit wyy3kchgemuihnd6x32efyrzci --vault AI credential="<new-token>"
   ```

3. **Re-run the setup script**:
   ```bash
   ~/.dotfiles/scripts/setup-claude-code.sh
   ```

## How It Works

### Two Different Authentication Methods

**Important**: Claude Code uses **two different types of credentials** that serve different purposes:

1. **Setup Token (OAuth)**: Generated via `claude setup-token`
   - Used by **Claude Code** for subscription-based authentication
   - Stored via `apiKeyHelper` in `~/.claude/settings.json`
   - Uses your Claude subscription (Pro/Max) - no API charges
   - Fetched from 1Password: `claude_code_setup_token`

2. **API Key**: From Anthropic Console (Optional)
   - Used for specific tools that need pay-as-you-go billing
   - Can be set temporarily via `use-api-key` function
   - Pay-as-you-go billing
   - Fetched from 1Password: `anthropic_api_key`
   - **Not set by default** - everything uses subscription

### Authentication Priority

**⚠️ Important**: Claude Code uses this priority order:
1. **`ANTHROPIC_API_KEY` environment variable** (if set) - pay-as-you-go billing
2. **`claude login` credentials** - subscription-based
3. **Setup token** (via `apiKeyHelper`) - subscription-based

If `ANTHROPIC_API_KEY` is set, Claude Code will **always use it** instead of your subscription login or setup token.

### Recommended Setup: Login on Laptop, Setup Token for Non-Interactive

**For your laptop (Claude Code)**:
1. Use `claude login` for interactive use (subscription)
2. `ANTHROPIC_API_KEY` is NOT set by default (uses subscription)
3. Use Claude Code normally - it will use your subscription

**For your homelab (clawdbot)**:
1. Use `setup-token` stored in 1Password
2. Configure clawdbot to use the setup token (not API key)
3. This allows non-interactive subscription-based authentication

**For Conductor**:
1. Uses setup token via `apiKeyHelper` in its bundled binary's config
2. Configured automatically via `setup-conductor-auth.sh` during dotfiles install
3. `ANTHROPIC_API_KEY` is NOT set by default (uses subscription)

## Token Validation

The setup script validates:
- Token format (must start with `sk-ant-`)
- Token length (must be at least 50 characters)

Actual authentication validation happens when you use Claude Code. If you get authentication errors, the token may be expired.

## Checking Token Status

You can check if your token is configured and working:

```bash
~/.dotfiles/scripts/check-claude-token.sh
```

This script will:
- Check if a token exists in the config
- Verify Claude Code is installed
- Provide guidance if the token needs renewal

## Troubleshooting

### Token Not Found

If you get an error that the token can't be fetched:

1. **Check 1Password CLI is signed in**:
   ```bash
   op signin
   ```

2. **Verify you're on the correct account**:
   ```bash
   op account list
   op signin --account your-account
   ```

3. **Verify the item exists**:
   ```bash
   op item get wyy3kchgemuihnd6x32efyrzci --vault AI
   ```

### Authentication Errors

If Claude Code gives authentication errors:

1. The token may be expired - follow the [Token Renewal](#token-renewal) steps
2. Check the token format in 1Password matches what `claude setup-token` generates
3. Verify the token was saved correctly:
   ```bash
   cat ~/.config/claude/config.json | jq .api_key
   ```

### Conductor "API Key Invalid" After Generating Setup Token

**Problem**: After generating a setup token on another machine (or the same machine), Conductor reports "API key is invalid".

**Root Cause**: The setup token and API key are **different credentials**:
- Setup token (OAuth) is for Claude Code authentication
- API key is for Conductor and API calls

**Solution**:

1. **Verify your API key is correct in 1Password**:
   ```bash
   # Check what's stored in 1Password
   ~/.dotfiles/scripts/get-claude-api-key.sh api
   ```

2. **Ensure you're using the right token in the right place**:
   - Setup token should be in 1Password item: `claude_code_setup_token`
   - API key should be in 1Password item: `anthropic_api_key`
   - **Do NOT** copy the setup token to the API key field

3. **Check your environment variable**:
   ```bash
   # In a new shell, verify ANTHROPIC_API_KEY is set correctly
   echo $ANTHROPIC_API_KEY | head -c 20
   # Should show: sk-ant-api03-...
   ```

4. **If you accidentally mixed them up**:
   - Get your API key from Anthropic Console: https://console.anthropic.com/
   - Update it in 1Password:
     ```bash
     op item edit "Anthropic API Key" --vault AI credential="<your-api-key>"
     ```
   - Restart your shell to reload the environment variable

5. **Verify the tokens are different**:
   ```bash
   # Setup token (for Claude Code)
   SETUP_TOKEN=$(~/.dotfiles/scripts/get-claude-setup-token.sh)
   echo "Setup token: ${SETUP_TOKEN:0:20}..."

   # API key (for Conductor)
   API_KEY=$(~/.dotfiles/scripts/get-claude-api-key.sh api)
   echo "API key: ${API_KEY:0:20}..."

   # They should be different!
   if [ "$SETUP_TOKEN" = "$API_KEY" ]; then
     echo "ERROR: Setup token and API key are the same!"
   fi
   ```

**Key Points**:
- ✅ You CAN use both setup token and API key simultaneously
- ✅ Setup token goes in `claude_code_setup_token` (1Password)
- ✅ API key goes in `anthropic_api_key` (1Password)
- ❌ Do NOT use setup token as your API key
- ❌ Do NOT use API key as your setup token

### Script Not Executable

If you get "permission denied" errors:

```bash
chmod +x ~/.dotfiles/scripts/setup-claude-code.sh
chmod +x ~/.dotfiles/scripts/check-claude-token.sh
```

## Related Files

- `~/.dotfiles/scripts/setup-claude-code.sh` - Main setup script
- `~/.dotfiles/scripts/check-claude-token.sh` - Token validation script
- `~/.dotfiles/.dotbot/configs/claude-code.yaml` - Dotbot configuration
- `~/.dotfiles-private/secrets/1password/secret-paths.json` - 1Password secret paths
- `~/.config/claude/config.json` - Claude Code configuration (generated)
