# macOS Development Environment Template

This repository serves as a template for setting up a development environment on macOS. It provides a solid foundation with carefully selected tools and configurations that you can customize to your needs.

## 🚀 Quick Start

**New users:** See [QUICKSTART.md](QUICKSTART.md) for a step-by-step setup guide.

**Quick setup (3 steps):**
1. **Use this template** - Click "Use this template" on GitHub to create your repository
2. **Clone and bootstrap:**
   ```bash
   git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
   cd ~/.dotfiles
   ./install bootstrap
   ```
3. **Install profile:**
   ```bash
   ./install profile default
   ```

**Optional:** For private configurations (git identity, SSH keys, etc.), see the [Private Setup Guide](docs/private-setup.md).

## ✨ Features

- 🛠 **Modular Design**: Organized by tool and environment
- 🔧 **Easy Customization**: Simple to modify and extend
- 🔒 **Private File Support**: Secure handling of personal configurations
- 🎨 **Curated Configurations**:
  - Shell (Zsh with Oh My Zsh)
  - Git
  - VS Code
  - Homebrew
  - macOS defaults
  - And more!

## 📋 Prerequisites

### Platform Requirements

**Supported:**
- macOS Ventura (13.0) or later
- Apple Silicon (M1/M2/M3/M4) and Intel Macs
- Xcode Command Line Tools

**Not Supported:**
- Linux (may work with modifications, but untested)
- Windows (including WSL)
- macOS Monterey (12.x) or earlier

**Note:** For Linux users, consider using [yadm](https://yadm.io/), [chezmoi](https://www.chezmoi.io/), or [dotbot](https://github.com/anishathalye/dotbot) directly.

### Required Tools

- Git
- Xcode Command Line Tools (`xcode-select --install`)

## 🛠 Installation

### For New Users (Public Template)

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
   cd ~/.dotfiles
   ```

2. Run the installation script:
   ```bash
   ./install bootstrap
   ```

3. Set up your personal configurations:
   ```bash
   ./scripts/setup-new-user.sh
   ```

4. Install the default profile:
   ```bash
   ./install profile default
   ```

### For Existing Users (With Private Files)

If you have a private repository with your personal configurations:

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
   cd ~/.dotfiles
   ```

2. Bootstrap the system:
   ```bash
   ./install bootstrap
   ```

3. Set up your private files:
   ```bash
   PRIVATE_REPO_URL=https://github.com/yourusername/dotfiles-private.git ./install private
   ```

4. Install your preferred profile:
   ```bash
   ./install profile default
   ```

### Complete Setup (Full + Private)

For a complete setup including private files, run both commands:

```bash
# Install the full profile (public configurations)
./install profile full

# Setup private files (requires private repository)
./install config private
```

**Note**: Private files are not included in the "full" profile by design - they must be set up separately for security and flexibility reasons.

## 🔒 Private File Management

This template supports secure handling of personal configurations through a separate private repository. This keeps your sensitive data separate while maintaining the benefits of dotfile management.

### What Goes Where?

- **Public (this template)**: Tool configurations, general aliases, scripts, setup automation
- **Private (your private repo)**: Git identity, SSH keys, API credentials, company-specific aliases

### Quick Private Setup

1. **Generate template:**
   ```bash
   ./install profile template
   ```
   This creates `~/.dotfiles-private/` with template files

2. **Edit your personal information:**
   - Git configs: `~/.dotfiles-private/git/gitconfig.user`
   - SSH config: `~/.dotfiles-private/ssh/config`
   - Company aliases: `~/.dotfiles-private/aliases/company-aliases.zsh`

3. **Create private GitHub repo** and push:
   ```bash
   cd ~/.dotfiles-private
   git remote add origin https://github.com/yourusername/dotfiles-private.git
   git push -u origin main
   ```

4. **Link to main dotfiles:**
   ```bash
   cd ~/.dotfiles
   cp config.json.example config.json
   # Edit config.json with your private repo URL
   ./install config private
   ```

📚 **Full guide:** [Private Setup Documentation](docs/private-setup.md)

## 🎯 Default Profile

The default profile includes essential development tools and configurations:

### Development Tools
- Homebrew package manager
- Git and GitHub CLI
- SSH configuration
- Version managers (asdf)
- Development environments:
  - Python (with pipx for isolated tool installation)
  - Node.js
  - Go
  - Ruby
  - Rust
  - Terraform

### Applications
- VS Code with curated extensions
- Docker
- Database tools (Postman, Insomnia, TablePlus)
- Productivity tools (1Password, Raycast, Slack, Zoom)
- Terminal tools:
  - ripgrep (fast code search)
  - htop (system monitoring)
  - tmux (terminal multiplexer)
  - sleepwatcher (power management)

### Shell & Terminal
- Zsh with Oh My Zsh
- Starship prompt
- Useful aliases and functions
- Terminal configuration

### macOS Configuration
- Developer-friendly defaults:
  - Dock and Mission Control optimizations
  - Keyboard and input settings
  - Display and screen settings
  - Finder preferences
  - Security and privacy settings
- Performance optimizations:
  - Disable unnecessary animations
  - Optimize window animations
  - Improve system responsiveness
  - Configure power management
- Security settings:
  - Enable FileVault
  - Configure firewall
  - Set up secure defaults
  - Manage privacy permissions

## 🔧 Customization

### Available Profiles

The repository includes several pre-configured profiles:

1. **default** - Essential development setup:
   - Homebrew
   - Git and GitHub CLI
   - SSH
   - Oh My Zsh
   - Starship prompt
   - Python
   - VS Code
   - tmux
   - ripgrep
   - AWS CLI

2. **minimal** - Lightweight setup for basic development:
   - Homebrew
   - Git
   - SSH
   - Basic shell configuration

3. **full** - Complete development environment:
   - All default tools
   - Additional development languages
   - Database tools
   - Cloud tools
   - Security tools

4. **devcontainer** - Development container configuration:
   - VS Code devcontainer settings
   - Container-specific tools
   - Development environment isolation

### Git Configuration Management

The dotfiles include a `git-config` function for easy switching between different git identities:

```bash
# Switch to personal git configuration
git-config user

# Switch to company git configuration  
git-config work

# List available configurations
git-config
```

This is particularly useful when working on multiple projects with different git identities. The function automatically:
- Lists available git configurations
- Creates symlinks to the specified configuration
- Shows the current git user and email

**Note:** Git configs should be stored in your private repository as `git/gitconfig.<name>` (e.g., `gitconfig.user`, `gitconfig.work`). The setup script will automatically link all git configs it finds.

### SSH Configuration Management

The dotfiles support dynamic SSH configuration selection for different environments. SSH configs must follow the naming convention `ssh-{name}.yaml` in your private repository.

**Setup:** Copy and edit the example config:
```bash
cp config.json.example config.json
# Edit with your private repository URL
```

**Usage:**
```bash
# Setup with all SSH configs (uses config file)
./install private

# Setup with specific SSH config
./install private personal
./install private work
```

The system automatically detects available SSH configs and links them to your dotfiles.

### Using as a Template

1. Fork this repository
2. Modify the following files to suit your needs:
   - `tools/homebrew/Brewfile`: Add/remove packages
   - `apps/vscode/settings.json.template`: Customize VS Code settings
   - `apps/vscode/extensions`: Modify VS Code extensions
   - `tools/macos`: Adjust macOS defaults
   - `shells/oh-my-zsh/zsh.after/`: Add custom shell configurations

### Adding New Configurations

1. Create a new profile in `.dotbot/profiles/`
2. Add your configuration files in the appropriate directory
3. Update the profile to include your new configurations

### Directory Structure

```
.
├── .dotbot/              # Dotbot configuration
├── apps/                 # Application configurations
│   └── vscode/          # VS Code settings and extensions
├── shells/              # Shell configurations
│   └── oh-my-zsh/       # Oh My Zsh customizations
├── tools/               # Tool configurations
│   ├── homebrew/        # Homebrew packages
│   ├── git/            # Git configurations
│   └── macos/          # macOS defaults
├── scripts/             # Utility scripts
└── install              # Installation script
```

## 🔄 Updating

To update your dotfiles:

```bash
cd ~/.dotfiles
git pull
./install bootstrap
```

If you have private files, also update them:

```bash
PRIVATE_REPO_URL=https://github.com/yourusername/dotfiles-private.git ./install private
```

## 🤝 Contributing

Please read our [Contributing Guide](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Dotbot](https://github.com/anishathalye/dotbot) for the installation framework
- [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh) for the shell framework
- [Starship](https://starship.rs/) for the shell prompt
