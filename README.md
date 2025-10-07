# macOS Development Environment Template

This repository serves as a template for setting up a development environment on macOS. It provides a solid foundation with carefully selected tools and configurations that you can customize to your needs.

## 🚀 Quick Start

**New users:** See [QUICKSTART.md](QUICKSTART.md) for a complete setup guide.

**Quick setup:**
1. Click the "Use this template" button on GitHub to create your own repository
2. Clone your new repository:
   ```bash
   git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
   cd ~/.dotfiles
   ```
3. Run the installation script:
   ```bash
   ./install bootstrap
   ```

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

- macOS (tested on macOS Ventura and later)
- Git
- Xcode Command Line Tools

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

This template supports secure handling of personal configurations through a separate private repository.

For detailed instructions on setting up and managing your private repository, see [Private Setup Documentation](docs/private-setup.md).

### Quick Setup

1. **Create a private repository** on GitHub (e.g., `dotfiles-private`)
2. **Add your private files** to the private repository
3. **Pull in private files** during setup:
   ```bash
   PRIVATE_REPO_URL=https://github.com/yourusername/dotfiles-private.git ./install private
   ```

### What Should Be Private vs Public

- **Private**: Git configs with personal info, SSH keys, credentials, company-specific aliases
- **Public**: General aliases, VS Code settings (without personal data), tool configs (without credentials)

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

## 🧪 Testing

The repository includes a comprehensive testing framework to ensure code quality and compatibility across different macOS versions.

### Running Tests Locally

```bash
# Run all tests
./tests/run_all_tests.sh

# Run specific test suites
./tests/test_shell_scripts.sh      # Shell script tests
./tests/test_dotbot_config.sh      # Dotbot configuration tests
./tests/test_private_files.sh      # Private file handling tests
zsh tests/run_tests.zsh            # Shell function tests
./scripts/test.sh                  # Repository validation
```

### CI/CD

Tests run automatically on pull requests across multiple macOS versions (11, 12, and 13) using GitHub Actions. The workflow includes:
- Shell script linting with shellcheck
- Dotbot configuration validation
- Private file handling tests
- Shell function tests

For more details, see the [Testing Documentation](docs/testing.md).

## 🤝 Contributing

Please read our [Contributing Guide](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Dotbot](https://github.com/anishathalye/dotbot) for the installation framework
- [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh) for the shell framework
- [Starship](https://starship.rs/) for the shell prompt# Test commit
