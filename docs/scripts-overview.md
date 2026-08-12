# Scripts Overview

This document describes the purpose of each script in the `scripts/` directory.

## Core Installation Scripts

- **`install-asdf.sh`** - Installs ASDF version manager for multiple programming languages
- **`install-oh-my-zsh.sh`** - Installs Oh My Zsh framework for Zsh
- **`install-oh-my-zsh-plugins.sh`** - Installs and configures Oh My Zsh plugins

## Private File Management

- **`setup-private-files.sh`** - Core script for setting up private files from dotfiles-private repository

## Template/Public Setup

- **`setup-new-user.sh`** - Helps new users configure their personal settings

## Security & SSH

- **`fetch-ssh-keys.sh`** - Fetches SSH keys from 1Password and configures them
- **`install-touchid-for-sudo.sh`** - Enables TouchID for sudo authentication
- **`uninstall-touchid-for-sudo.sh`** - Disables TouchID for sudo authentication

## 1Password Integration

- **`fetch-1password-secrets.sh`** - Fetches secrets from 1Password
- **`resolve-1password-secrets.sh`** - Resolves 1Password secrets in configuration files

## Parallel Agents (dmux)

- **`dmux-phone`** - Attaches a phone client to a project's dmux session via a grouped tmux session, so it gets independent geometry, then zooms the active pane
- **`dmux-focus`** - Selects a pane and zooms it; used to retarget the phone via `tmux send-keys` without navigating the dmux TUI
- **`dmux-doctor`** - Preflight for the parallel-agent workflow (tmux/node/git versions, dmux, agent CLIs, tailnet reachability); exits non-zero on failure

See the [desk and phone workflow](../README.md#parallel-agents-desk-and-phone) in the README.

## Backup & Testing

- **`backup.sh`** - General backup script for dotfiles
- **`test.sh`** - Main test suite for dotfiles functionality

## Usage

Most scripts are automatically called by the main `./install` script or by Dotbot configurations. For manual usage:

```bash
# Setup private files
./install private

# Convert to public template

# Run tests
./scripts/test.sh

# Backup files
./scripts/backup.sh
```

## Functions

The dotfiles also include useful shell functions in `shells/oh-my-zsh/custom/functions.zsh`:

- **`git-config <suffix>`** - Switch between different git configurations
  - `git-config user` - Switch to personal git config
  - `git-config work` - Switch to work git config
  - `git-config` - List available configurations
