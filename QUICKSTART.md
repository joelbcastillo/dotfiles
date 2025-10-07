# 🚀 Quick Start Guide

This guide will help you set up your development environment using this dotfiles template.

## 📋 Prerequisites

- macOS (tested on macOS Ventura and later)
- Git
- Xcode Command Line Tools

## 🎯 For New Users (Public Template)

### Step 1: Create Your Repository

1. **Click "Use this template"** on GitHub to create your own repository
2. **Clone your new repository:**
   ```bash
   git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
   cd ~/.dotfiles
   ```

### Step 2: Basic Setup

1. **Bootstrap the system:**
   ```bash
   ./install bootstrap
   ```

2. **Set up your private repository:**
   ```bash
   ./install profile template
   ```
   This creates your private repository structure and template files.

3. **Edit your personal files:**
   ```bash
   # Edit your git configs with your personal information
   code ~/.dotfiles-private/git/gitconfig.user
   code ~/.dotfiles-private/git/gitconfig.work
   
   # Add your company-specific aliases
   code ~/.dotfiles-private/aliases/company-aliases.zsh
   ```

4. **Create and push your private repository:**
   ```bash
   # Create a private repository on GitHub (e.g., 'dotfiles-private')
   # Then push your files:
   cd ~/.dotfiles-private
   git remote add origin https://github.com/yourusername/dotfiles-private.git
   git add .
   git commit -m 'Initial private dotfiles'
   git push -u origin main
   ```

5. **Configure the main repository:**
   ```bash
   cp config.json.example config.json
   # Edit config.json with your private repository URL
   ```

6. **Install the full profile:**
   ```bash
   ./install profile full
   ```

7. **Set up private files:**
   ```bash
   ./install config private
   ```

8. **Restart your terminal** to load the new configuration


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
