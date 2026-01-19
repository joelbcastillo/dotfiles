# Claude Authentication Strategy

This document explains the long-term authentication strategy for Claude Code, Conductor, and clawdbot.

## The Problem

When `apiKeyHelper` is set in `~/.claude/settings.json`, it conflicts with `claude login`:
- `claude login` tries to authenticate via OAuth/subscription
- But `apiKeyHelper` intercepts and tries to use the setup token
- This causes "invalid API key" errors during login

## The Solution

**Separate authentication methods for different use cases:**

### 1. Main Claude Code (Laptop) - Interactive Use
- **Method**: `claude login` (OAuth/subscription)
- **Config**: NO `apiKeyHelper` in `~/.claude/settings.json`
- **Why**: Interactive login works best for daily use, no conflicts

### 2. Conductor's Bundled Binary - Non-Interactive
- **Method**: Setup token via `apiKeyHelper`
- **Config**: `~/Library/Application Support/com.conductor.app/.claude/settings.json`
- **Why**: Conductor bundles its own binary and needs non-interactive auth

### 3. clawdbot (Homelab) - Non-Interactive
- **Method**: Setup token from 1Password
- **Config**: Configured in clawdbot's settings
- **Why**: Headless server needs non-interactive authentication

## Configuration Files

### Main Claude Code
- **Location**: `~/.claude/settings.json`
- **Should NOT have**: `apiKeyHelper` (causes login conflicts)
- **Should have**: Plugin settings, other preferences

### Conductor's Bundled Binary
- **Location**: `~/Library/Application Support/com.conductor.app/.claude/settings.json`
- **Should have**: `apiKeyHelper` pointing to setup token script
- **Setup**: Run `~/.dotfiles/scripts/setup-conductor-auth.sh`

## Setup Process

1. **Main Claude Code**:
   ```bash
   # Just login - no apiKeyHelper needed
   claude login
   ```

2. **Conductor**:
   ```bash
   # Configure bundled binary with setup token
   ~/.dotfiles/scripts/setup-conductor-auth.sh
   ```

3. **clawdbot**:
   - Configure in clawdbot settings to use setup token from 1Password

## Why This Works

- **No conflicts**: Main Claude Code doesn't have apiKeyHelper, so login works
- **Non-interactive auth**: Conductor and clawdbot use setup token via apiKeyHelper
- **Flexibility**: Each tool uses the auth method that works best for its use case

## Troubleshooting

### "Invalid API key" when running `claude login`

**Cause**: `apiKeyHelper` is set in `~/.claude/settings.json`

**Fix**:
```bash
# Remove apiKeyHelper from main settings
jq 'del(.apiKeyHelper)' ~/.claude/settings.json > ~/.claude/settings.json.tmp
mv ~/.claude/settings.json.tmp ~/.claude/settings.json

# Then login
claude login
```

### Conductor not using subscription

**Cause**: Conductor's bundled binary doesn't have apiKeyHelper configured

**Fix**:
```bash
~/.dotfiles/scripts/setup-conductor-auth.sh
```

## Migration Notes

If you previously had `apiKeyHelper` in your main `~/.claude/settings.json`:
1. Remove it (it conflicts with login)
2. Run `claude login` to authenticate
3. Configure Conductor separately with `setup-conductor-auth.sh`
