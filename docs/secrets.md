# Managing Secrets in Your Dotfiles Template

This document provides guidance on handling secrets and sensitive data in your dotfiles template.

## What to Exclude

Always exclude the following from your repository:

- **Personal credentials**: Passwords, API keys, tokens, and SSH keys.
- **Environment files**: `.env`, `.env.local`, and any environment-specific files.
- **Backup files**: Any `.bak`, `.backup`, or `.old` files.
- **Temporary files**: Files in `tmp/` or `temp/` directories.
- **User-specific files**: Logs, swap files, and any files ending with `~`.

## How to Manage Secrets

### 1. Use Environment Variables

Store sensitive data in environment variables. For example:

```bash
# .env file (excluded from git)
API_KEY=your_api_key_here
```

Load these variables in your scripts:

```bash
# Load environment variables
source .env
```

### 2. Use a Secrets Manager

Consider using a secrets manager (like [1Password](https://1password.com/) or [pass](https://www.passwordstore.org/)) to store and retrieve sensitive data securely.

### 3. Use Git Hooks

Implement Git hooks to prevent accidentally committing sensitive files. For example, use a pre-commit hook to check for excluded files.

## Best Practices

- **Never commit secrets**: Always exclude sensitive data from your repository.
- **Document exclusions**: Clearly document what should be excluded in your `.gitignore` and `README`.
- **Use templates**: Provide template files (e.g., `.env.example`) to guide users on what to include.
- **Regular audits**: Periodically audit your repository to ensure no sensitive data is committed.

## Example: Using 1Password for Secrets

1Password CLI is a powerful tool for managing secrets. Here's how to set it up with your dotfiles template:

### Step 1: Install 1Password CLI

If you haven't already, install the 1Password CLI:

```bash
brew install 1password-cli
```

### Step 2: Sign In

Sign in to your 1Password account:

```bash
op signin
```

Follow the prompts to complete the sign-in process.

### Step 3: Pull Secrets from a Vault

To pull secrets from a vault, use the `op` command. For example, to retrieve an API key:

```bash
# Pull a secret from a vault
op get item "API Key" --vault "Development" --format json
```

You can automate this in your scripts:

```bash
# Example script to load secrets from 1Password
API_KEY=$(op get item "API Key" --vault "Development" --format json | jq -r '.details.password')
export API_KEY
```

### Step 4: Automate with Scripts

Create a script to load all necessary secrets at once:

```bash
#!/usr/bin/env bash
# load_secrets.sh

# Load API Key
API_KEY=$(op get item "API Key" --vault "Development" --format json | jq -r '.details.password')
export API_KEY

# Load Database Credentials
DB_USER=$(op get item "Database User" --vault "Development" --format json | jq -r '.details.username')
DB_PASS=$(op get item "Database Password" --vault "Development" --format json | jq -r '.details.password')
export DB_USER
export DB_PASS

echo "Secrets loaded successfully!"
```

Run this script in your environment setup to ensure all secrets are available.

By integrating 1Password, you can securely manage and retrieve secrets without storing them in your repository. 