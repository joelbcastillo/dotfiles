# 🚀 Quick Start Guide

This guide will help you set up your macOS development environment in minutes.

## 📋 Prerequisites

Before starting, make sure you have:
- ✅ macOS Ventura (13.0) or later
- ✅ Xcode Command Line Tools: `xcode-select --install`
- ✅ A GitHub account

## 🎯 Getting Started

Choose your setup path:

### Option A: Basic Setup (Quickest - ~5 minutes)

**Best for:** Getting started quickly with public configurations only

1. **Use this template** - Click "Use this template" button on GitHub
2. **Clone your repository:**
   ```bash
   git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
   cd ~/.dotfiles
   ```
3. **Bootstrap and install:**
   ```bash
   ./install bootstrap
   ./install profile default
   ```
4. **Restart terminal** - `exec zsh` or open a new terminal window

✅ **Done!** You now have a configured dev environment

### Option B: Full Setup with Private Files (~15 minutes)

**Best for:** Complete setup including personal git configs, SSH keys, and company-specific settings

#### Part 1: Initial Setup

1. **Use this template** and clone (same as Option A):
   ```bash
   git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
   cd ~/.dotfiles
   ./install bootstrap
   ```

#### Part 2: Create Private Repository

2. **Generate private file templates:**
   ```bash
   ./install profile template
   ```
   This creates `~/.dotfiles-private/` with template files

3. **Edit your personal information:**
   ```bash
   # Required: Update git configs with YOUR info
   code ~/.dotfiles-private/git/gitconfig.user
   code ~/.dotfiles-private/git/gitconfig.work  # Optional: for work

   # Optional: Add company aliases, SSH config, AWS credentials, etc.
   code ~/.dotfiles-private/aliases/company-aliases.zsh
   ```

4. **Create private GitHub repository:**
   - Go to GitHub and create a **private** repo named `dotfiles-private`
   - Then push your private files:
   ```bash
   cd ~/.dotfiles-private
   git remote add origin https://github.com/yourusername/dotfiles-private.git
   git add .
   git commit -m "Initial private dotfiles"
   git push -u origin main
   ```

#### Part 3: Link Everything Together

5. **Configure main dotfiles to use private repo:**
   ```bash
   cd ~/.dotfiles
   cp config.json.example config.json
   # Edit config.json - add your private repo URL
   ```

6. **Install full profile and link private files:**
   ```bash
   ./install profile full
   ./install config private
   ```

7. **Restart terminal** - `exec zsh`

✅ **Done!** Full environment with private configurations


## 🔧 For Template Maintainers

### What You Need to Do

1. **Test the setup:**
   ```bash
   # Test basic setup
   ./install bootstrap
   ./install profile full
   
   # Test private setup (if applicable)
   ./install private
   ```

2. **Verify everything works:**
   ```bash
   ./scripts/test.sh
   ```

3. **Commit and push:**
   ```bash
   git add -A
   git commit -m "Initial template setup"
   git push origin main
   ```

### How the Private File System Works

- **Public repo** = Template for others to use
- **Private repo** = Your personal configurations
- **Symlinks** = Connect the two without mixing them
- **Pre-commit hook** = Automatically ignores private symlinks

## 📁 File Structure

```
~/.dotfiles/                    # Your dotfiles (public template)
├── install                     # Main installation script
├── config.json.example         # Example config for private setup
├── .gitignore                  # Ignores private files automatically
├── .git/hooks/pre-commit       # Automatically ignores private symlinks
├── scripts/                    # Setup and utility scripts
├── tools/                      # Tool configurations
├── apps/                       # Application configurations
└── shells/                     # Shell configurations

~/.dotfiles-private/            # Your private files (separate repo)
├── git/                        # Personal git configs
├── aliases/                    # Company-specific aliases
├── vscode/                     # Personal VS Code settings
├── cursor/                     # Personal Cursor settings
└── dotbot/                     # Private dotbot configs
```

## 🔒 Private File Management

### What Gets Private vs Public

**Public (in template):**
- ✅ General aliases and functions
- ✅ Tool configurations
- ✅ Template files (`.template` suffix)
- ✅ Setup scripts

**Private (in your private repo):**
- 🔒 Personal git configs (`gitconfig.user`, `gitconfig.work`)
- 🔒 Company-specific aliases
- 🔒 Personal VS Code/Cursor settings
- 🔒 SSH configurations
- 🔒 API keys and secrets

### Setting Up Private Files

1. **Create your private repository:**
   ```bash
   mkdir ~/.dotfiles-private
   cd ~/.dotfiles-private
   git init
   git remote add origin https://github.com/yourusername/dotfiles-private.git
   ```

2. **Add your private files:**
   ```bash
   # Copy your personal git configs
   cp ~/.dotfiles/tools/git/gitconfig.user ~/.dotfiles-private/git/
   cp ~/.dotfiles/tools/git/gitconfig.work ~/.dotfiles-private/git/
   
   # Create company aliases
   echo 'alias myproject="command"' > ~/.dotfiles-private/aliases/company-aliases.zsh
   
   # Add personal VS Code settings
   cp ~/.dotfiles/apps/vscode/settings.json ~/.dotfiles-private/vscode/
   ```

3. **Commit and push:**
   ```bash
   git add -A
   git commit -m "Initial private files"
   git push -u origin main
   ```

4. **Configure the main repo:**
   ```bash
   cd ~/.dotfiles
   cp config.json.example config.json
   # Edit config.json with your private repo URL
   ```

5. **Set up private files:**
   ```bash
   ./install private
   ```

## 🧪 Testing

Run the test suite to verify everything is working:

```bash
./scripts/test.sh
```

## 🔄 Daily Usage

### Switching Git Configurations

```bash
# Switch to personal git config
git-config user

# Switch to work git config
git-config work

# List available configs
git-config
```

### Updating Private Files

```bash
# Update private files from your private repository
./install private
```

### Adding New Private Files

1. **Add to your private repository:**
   ```bash
   # Add new private file
   echo 'alias newcommand="command"' >> ~/.dotfiles-private/aliases/company-aliases.zsh
   
   # Commit and push
   cd ~/.dotfiles-private
   git add -A
   git commit -m "Add new private file"
   git push
   ```

2. **Update the main repo:**
   ```bash
   cd ~/.dotfiles
   ./install private
   ```

## 🆘 Troubleshooting

### Common Issues

1. **Private files not linking:**
   ```bash
   # Check if private repo is configured
   cat config.json
   
   # Re-run private setup
   ./install private
   ```

2. **Git config not working:**
   ```bash
   # Check if gitconfig.user is linked
   ls -la ~/.dotfiles/tools/git/gitconfig.user
   
   # Re-run git config
   ./install config git
   ```

3. **Symlinks not working:**
   ```bash
   # Check if private repo exists
   ls -la ~/.dotfiles-private
   
   # Re-run private setup
   ./install private
   ```

### Getting Help

- Check the main [README.md](README.md) for detailed documentation
- Look at [docs/](docs/) for specific guides
- Run `./install --help` for available commands

## 🎉 You're All Set!

Your development environment is now configured with:

- ✅ **Shell setup** (Zsh with Oh My Zsh)
- ✅ **Git configuration** (with easy switching)
- ✅ **Tool configurations** (VS Code, Cursor, etc.)
- ✅ **Private file management** (if configured)
- ✅ **Automatic updates** (via symlinks)

Happy coding! 🚀
