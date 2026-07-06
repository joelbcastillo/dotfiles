# macOS Development Environment Template

This repository serves as a template for setting up a development environment on macOS. It provides a solid foundation with carefully selected tools and configurations that you can customize to your needs.

## 🚀 Quick Start

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
- 🤖 **AI Tools Integration**: Claude CLI, Claude Code, Cursor Agent, MCP servers
- 🎨 **Curated Configurations**:
  - Shell (Zsh with Oh My Zsh + Starship prompt)
  - Git (with 1Password SSH signing)
  - VS Code and Cursor editors
  - Ghostty terminal
  - Homebrew
  - tmux
  - macOS defaults
  - Hammerspoon automation
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

### Auto-install on pull

Both `~/.dotfiles` and `~/.dotfiles-private` ship a tracked git hook at
`scripts/git-hooks/post-merge`. The hook is enabled per-clone via
`git config --local core.hooksPath scripts/git-hooks`, which
`./install private` sets automatically (so existing clones pick it up
on the next install cycle; fresh clones get it on first run).

What it does:
- After any `git pull` whose changes touched paths that
  `setup-private-files.sh` materializes (apps/, shells/, tools/git/,
  tools/ssh/, dotbot/, etc.), the hook re-runs `./install private` so
  symlinks stay current. Idempotent; a few seconds; no network calls.
- On the private side, the hook also `chmod 600`s `ssh/config` after
  every merge — git uses the user's umask when materializing merged
  files, which can produce `0664` perms that OpenSSH refuses (the
  failure surfaces as `Bad owner or permissions on ~/.ssh/config` and
  silently breaks subsequent git-over-ssh fetches).

Symlinks created by `setup-private-files.sh` use **relative** targets
(computed via `perl File::Spec`), so they're portable across machines
and committed values match what the script generates — no spurious
diffs in `git status` after install.

## 🎯 Default Profile

The default profile includes essential development tools and configurations:

### Development Tools
- Homebrew package manager
- Git configuration
- SSH configuration
- Version managers (asdf)
- VS Code with curated extensions

### Shell & Terminal
- Zsh with Oh My Zsh
- Starship prompt
- Useful aliases and functions
- tmux (terminal multiplexer)
- ripgrep (fast code search)

### System
- TouchID for sudo authentication
- neofetch (system info display)
- General utilities

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

## 🖥 Workspace Orchestration

The full profile includes workspace automation tools:

- **Hammerspoon**: macOS automation for window management, keyboard shortcuts, and workspace switching
- **dmux**: Workspace management with worktree isolation and auto-resume sessions

## 🔧 Customization

### Available Profiles

The repository includes several pre-configured profiles:

1. **default** - Essential development setup:
   - Homebrew, Git, SSH
   - Oh My Zsh + Starship prompt
   - Zsh configuration
   - asdf (version manager)
   - VS Code
   - tmux, ripgrep, utils
   - neofetch, TouchID for sudo

2. **full** - Complete development environment:
   - All default tools, plus:
   - Colima (Docker runtime)
   - 1Password CLI
   - Languages: Python, Node.js, Go, Ruby, Rust
   - GitHub CLI, AWS CLI, DigitalOcean CLI
   - Cursor editor, Ghostty terminal
   - Hammerspoon automation
   - AI tools: Claude CLI, Claude Code, Cursor Agent, MCP servers, API keys

3. **ai-tools** - AI and Claude-focused setup:
   - Claude CLI and Claude Code
   - Cursor Agent
   - Claude companion tools (dmux, happy, Paseo, ccs, ccr)
   - MCP server configuration
   - API key management (via 1Password)

4. **template** - Starter kit for customization:
   - Generates template files for creating your own private repo

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
├── .dotbot/              # Dotbot framework, profiles, and configs
│   ├── configs/          # Tool configuration YAML files
│   ├── profiles/         # Installation profiles (default, full, ai-tools, template)
│   └── plugins/          # Dotbot plugins
├── apps/                 # Application configurations
│   ├── claude/           # Claude Desktop settings
│   ├── cursor/           # Cursor editor settings
│   ├── ghostty/          # Ghostty terminal config
│   ├── hammerspoon/      # Hammerspoon automation
│   └── vscode/           # VS Code settings and extensions
├── shells/               # Shell configurations
│   ├── zsh/              # Zsh config and custom functions
│   ├── oh-my-zsh/        # Oh My Zsh plugins and themes
│   └── starship/         # Starship prompt config
├── tools/                # Tool configurations
│   ├── 1password/        # 1Password CLI integration
│   ├── git/              # Git config and hooks
│   ├── homebrew/         # Brewfile and package management
│   ├── mcp/              # MCP server configurations
│   ├── ssh/              # SSH config templates
│   └── ...               # Python, Node.js, Go, Ruby, Rust, etc.
├── .dmux/                # dmux workspace orchestration
├── scripts/              # Utility and setup scripts
├── docs/                 # Documentation and guides
├── templates/            # Configuration templates for new users
├── tests/                # Test suite
└── install               # Main installation script
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
