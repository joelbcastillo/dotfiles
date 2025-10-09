# Multi-User Homebrew Setup

This dotfiles repository supports multiple Homebrew installation scenarios for different use cases.

## Supported Installation Locations

The shell configuration automatically detects Homebrew in this priority order:

1. **User-local** (`~/.homebrew`) - Each user has their own installation
2. **Apple Silicon** (`/opt/homebrew`) - Default for ARM Macs (M1/M2/M3/M4)
3. **Intel Mac** (`/usr/local`) - Default for Intel Macs
4. **Custom PATH** - Any location where `brew` command is available
5. **Environment variable** (`$HOMEBREW_PREFIX`) - User-specified location

## Installation Options

### Option 1: User-Local Installation (Recommended for Shared Machines)

Each user gets their own Homebrew installation:

```bash
# Install to user's home directory
mkdir ~/.homebrew
curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip-components 1 -C ~/.homebrew

# The dotfiles will automatically detect this location
```

**Advantages:**
- ✅ No sudo required
- ✅ No conflicts between users
- ✅ Each user can have different package versions
- ✅ Full control over your environment

**Disadvantages:**
- ❌ Uses more disk space (duplicated packages)
- ❌ Each user maintains their own packages

### Option 2: System-Wide Installation (Default)

Standard Homebrew installation shared by all users:

```bash
# Default installation (uses /opt/homebrew on ARM, /usr/local on Intel)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**Advantages:**
- ✅ Saves disk space (shared packages)
- ✅ Single installation to maintain
- ✅ Standard location

**Disadvantages:**
- ❌ Requires admin privileges to install packages
- ❌ All users share same package versions
- ❌ Potential for conflicts

### Option 3: Shared with Group Permissions

Allow multiple users to manage a shared Homebrew:

```bash
# Create homebrew admin group
sudo dscl . -create /Groups/homebrewadmin
sudo dscl . -create /Groups/homebrewadmin PrimaryGroupID 2000

# Add users to the group
sudo dseditgroup -o edit -a username1 -t user homebrewadmin
sudo dseditgroup -o edit -a username2 -t user homebrewadmin

# Set group ownership
sudo chgrp -R homebrewadmin /opt/homebrew
sudo chmod -R g+w /opt/homebrew
```

**Advantages:**
- ✅ Multiple users can install packages
- ✅ Saves disk space
- ✅ Collaborative package management

**Disadvantages:**
- ❌ All users share same package versions
- ❌ Requires sudo setup

## Using Brewfile for Personal Package Lists

Regardless of installation method, you can maintain personal package lists:

```bash
# Create your personal Brewfile
cat > ~/dotfiles/Brewfile.personal <<EOF
# Personal packages
brew "ripgrep"
brew "fzf"
cask "visual-studio-code"
EOF

# Install only your packages
brew bundle --file=~/dotfiles/Brewfile.personal
```

## Environment Variable Override

You can force a specific Homebrew location by setting:

```bash
# In your ~/.zshrc.local or similar
export HOMEBREW_PREFIX="/custom/path/to/homebrew"
```

## Troubleshooting

### Check Current Homebrew Location

```bash
# See which Homebrew is being used
which brew
brew --prefix
```

### Multiple Homebrews Installed

If you have multiple Homebrew installations, the priority order is:

1. `~/.homebrew` (user-local)
2. `/opt/homebrew` (Apple Silicon)
3. `/usr/local` (Intel Mac)
4. First `brew` in `$PATH`

### Permission Issues

If you get permission errors:

```bash
# For system-wide Homebrew, check ownership
ls -ld $(brew --prefix)

# Fix permissions (requires admin)
sudo chown -R $(whoami) $(brew --prefix)/*
```

## Best Practices

### For Personal Machines
- Use standard system-wide installation (`/opt/homebrew` or `/usr/local`)
- Simple, works out of the box

### For Shared Development Machines
- Use user-local installation (`~/.homebrew`)
- Each developer has full control
- No sudo required

### For Team Machines
- Use group permissions
- Coordinate package versions
- Document shared packages in version-controlled Brewfile

## Migration

### Moving from System to User-Local

```bash
# Install user-local Homebrew
mkdir ~/.homebrew
curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip-components 1 -C ~/.homebrew

# Export current package list
/opt/homebrew/bin/brew bundle dump --file=~/Brewfile.backup

# Install in user-local
~/.homebrew/bin/brew bundle --file=~/Brewfile.backup

# Restart shell - dotfiles will detect new location
exec zsh
```

### Moving from User-Local to System

```bash
# Export package list
~/.homebrew/bin/brew bundle dump --file=~/Brewfile.backup

# Remove user-local
rm -rf ~/.homebrew

# Install system-wide
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Restore packages
/opt/homebrew/bin/brew bundle --file=~/Brewfile.backup

# Restart shell
exec zsh
```
