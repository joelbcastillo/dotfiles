# SSH Keys and 1Password Integration

This repository supports automatic SSH key management via 1Password, eliminating the need to commit public keys to the repository.

## Overview

Instead of storing SSH public keys in the repository, we use:
1. **1Password SSH Agent** - For SSH authentication
2. **Automatic key fetching** - Script pulls keys from 1Password and creates local symlinks

## Setup

### 1. Configure 1Password SSH Agent

The 1Password SSH agent is automatically configured in `shells/zsh/zsh.before/1password.zsh`:

```bash
export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
```

This allows SSH to use keys stored in 1Password without needing key files on disk.

### 2. Configure SSH Keys for Git Signing

For git commit signing, you need to fetch your public key from 1Password:

#### Option A: Using 1Password accounts.json (Recommended)

1. Copy the template:
   ```bash
   cp tools/1password/accounts.json.template tools/1password/accounts.json
   ```

2. Edit `tools/1password/accounts.json`:
   ```json
   {
     "active_accounts": ["personal", "work"],
     "accounts": {
       "personal": {
         "domain": "my.1password.com",
         "ssh_keys": [
           {
             "name": "GitHub SSH Key",
             "filename": "github",
             "vault": "Personal"
           }
         ]
       }
     }
   }
   ```

3. Run the fetch script:
   ```bash
   ./scripts/fetch-ssh-keys.sh
   ```

This will:
- Fetch keys from 1Password
- Store them in `tools/ssh/keys/{account}/`
- Create symlinks in `~/.ssh/`

#### Option B: Manual Setup

1. Export your public key from 1Password
2. Save it to `~/.ssh/github.pub` (or your preferred name)
3. Update `tools/git/gitconfig.user` to reference it:
   ```ini
   [user]
       signingkey = ~/.ssh/github.pub
   ```

### 3. Enable Git Signing

Your git config template at `tools/git/gitconfig.user.template` includes:

```ini
[user]
    signingkey = ~/.ssh/github.pub

[gpg]
    format = ssh

[commit]
    gpgsign = true
```

## Why Not Commit Public Keys?

While SSH public keys are "public" and technically safe to share, we don't commit them to the repository because:

1. **Security by obscurity** - Reduces information about your infrastructure
2. **Key rotation** - Easier to rotate keys without updating the repository
3. **Multi-account support** - Different users may use different keys
4. **Template flexibility** - Repository remains a true template without user-specific data

## How It Works

### SSH Authentication
1. 1Password SSH Agent intercepts SSH requests
2. Uses keys stored securely in 1Password vaults
3. No key files needed on disk for authentication

### Git Commit Signing
1. Git requires a public key file for verification
2. Script fetches public key from 1Password
3. Creates local file in `tools/ssh/keys/` (gitignored)
4. Symlinks to `~/.ssh/` for git to use

## Files and Directories

```
.dotfiles/
├── scripts/
│   └── fetch-ssh-keys.sh           # Fetches keys from 1Password
├── tools/
│   ├── 1password/
│   │   ├── accounts.json.template  # Configuration template
│   │   └── accounts.json           # Your config (gitignored)
│   ├── ssh/
│   │   └── keys/                   # Key storage (gitignored)
│   │       ├── personal/           # Personal account keys
│   │       └── work/               # Work account keys
│   └── git/
│       └── gitconfig.user.template # Git config template
└── shells/
    └── zsh/
        └── zsh.before/
            └── 1password.zsh       # SSH agent configuration
```

## Troubleshooting

### "Could not fetch key from 1Password"
- Ensure you're signed in: `op signin`
- Check the key name and vault name in your config
- Verify the key exists in 1Password

### "SSH agent not responding"
- Ensure 1Password app is running
- Check that SSH agent is enabled in 1Password settings
- Restart 1Password app

### "Git signing failed"
- Verify public key exists: `ls -la ~/.ssh/github.pub`
- Check git config: `git config user.signingkey`
- Re-run fetch script: `./scripts/fetch-ssh-keys.sh`

## Migration from Committed Keys

If you previously had public keys in the repository:

1. They've been removed and added to `.gitignore`
2. Run `./scripts/fetch-ssh-keys.sh` to fetch them from 1Password
3. Or manually place your public key in `~/.ssh/`

## References

- [1Password SSH Agent Documentation](https://developer.1password.com/docs/ssh/)
- [Git SSH Signing](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification)
- [1Password CLI Documentation](https://developer.1password.com/docs/cli/)
