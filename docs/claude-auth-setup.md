# Claude Authentication Setup Guide

This guide explains how to use subscription authentication for Claude Code, clawdbot, and Conductor.

## Quick Summary

- **Laptop (Claude Code)**: Use `claude login` (subscription)
- **Homelab (clawdbot)**: Use `setup-token` from 1Password (subscription)
- **Conductor**: Uses subscription automatically (inherits from Claude Code login)

## Setup Instructions

### 1. Laptop: Claude Code with Subscription Login

```bash
# Step 1: Login to Claude Code (one-time setup)
claude login

# Step 2: Verify login
claude /status

# Step 3: Use Claude Code normally (uses subscription)
claude "your prompt here"
```

**Important**: Make sure `ANTHROPIC_API_KEY` is NOT set in your environment. If it is, unset it:
```bash
unset ANTHROPIC_API_KEY
```

### 2. Homelab: clawdbot with Setup Token

```bash
# Step 1: Generate setup token (on any machine)
claude setup-token

# Step 2: Save to 1Password
op item edit wyy3kchgemuihnd6x32efyrzci --vault AI credential="<token>"

# Step 3: Configure clawdbot to use setup token
# (See clawdbot documentation for configuration)
```

The setup token is stored in 1Password and can be fetched by clawdbot for non-interactive authentication.

### 3. Conductor: Subscription Setup

**Important**: Conductor bundles its own Claude Code binary, so it needs separate configuration.

**Option A: Configure via Script (Recommended)**

```bash
# Configure Conductor's bundled binary to use setup token
~/.dotfiles/scripts/setup-conductor-auth.sh
```

This configures Conductor's bundled Claude Code to use the setup token from 1Password.

**Option B: Configure via Conductor UI**

1. Open Conductor
2. Go to **Settings → Env**
3. **Leave `ANTHROPIC_API_KEY` empty** (or remove it if it's set)
4. Conductor will use subscription authentication via the setup token

**Verify Configuration**:
```bash
# Check Conductor's settings
cat ~/Library/Application\ Support/com.conductor.app/.claude/settings.json

# Should show apiKeyHelper pointing to get-claude-setup-token.sh
```

## How It Works

### Authentication Priority

Claude Code and Conductor check authentication in this order:
1. `ANTHROPIC_API_KEY` environment variable (if set) → pay-as-you-go
2. `claude login` credentials → subscription
3. Setup token (via `apiKeyHelper`) → subscription

**Important**: If `ANTHROPIC_API_KEY` is set, both Claude Code and Conductor will use it (pay-as-you-go), even if you're logged in. To use subscription, ensure `ANTHROPIC_API_KEY` is NOT set.

### Why This Setup?

- **Laptop**: Interactive use with subscription benefits
- **Homelab**: Non-interactive authentication (no browser) via setup token
- **Conductor**: Automatically uses subscription (inherits from Claude Code login)

## Troubleshooting

### Claude Code/Conductor is using API key instead of subscription

**Problem**: `claude /status` shows API key authentication instead of login.

**Solution**: Unset the API key and ensure you're logged in:
```bash
# Unset API key
unset ANTHROPIC_API_KEY

# Verify login status
claude /status

# Should show subscription/login authentication
```

### Need to temporarily use API key for a specific tool

**Problem**: You need pay-as-you-go billing for a specific script/tool.

**Solution**: Use the helper function:
```bash
# Set API key temporarily
use-api-key

# Run your tool
your-tool-that-needs-api-key

# Switch back to subscription
use-subscription
```

### Check current authentication method

```bash
# Quick check (shows everything)
claude-auth

# Or check individually
claude /status
echo $ANTHROPIC_API_KEY
```

## Files Reference

- `~/.dotfiles/scripts/check-claude-auth.sh` - Check authentication status
- `~/.dotfiles/scripts/get-claude-api-key.sh` - Fetch API key from 1Password
- `~/.dotfiles/scripts/get-claude-setup-token.sh` - Fetch setup token from 1Password
- `~/.dotfiles/shells/zsh/zshrc` - Shell profile with helper functions

## Helper Functions

Available in your shell:

- `claude-auth` - Check current authentication status
- `use-api-key` - Temporarily set API key (pay-as-you-go)
- `use-subscription` - Unset API key and use subscription
