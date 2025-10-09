# Customizing Your Dotfiles Template

This document provides detailed instructions on how to customize your dotfiles template to suit your needs.

## Profiles

### Minimal Profile

The minimal profile includes only essential configurations:

- **Shell**: Basic Zsh and Oh My Zsh setup.
- **Git**: Basic Git configuration.
- **VS Code**: Essential VS Code settings and extensions.
- **Homebrew**: Basic Homebrew package management.

### Full Profile

The full profile includes all configurations:

- **Shell**: Comprehensive Zsh and Oh My Zsh setup.
- **Git**: Detailed Git configuration.
- **VS Code**: Complete VS Code settings and extensions.
- **Homebrew**: Comprehensive Homebrew package management.
- **macOS Defaults**: Developer-friendly macOS settings.
- **Additional Tools**: SSH, AWS, and other tools.
- **Extra Settings**: Additional configurations like WakaTime.

## Customizing Shells

### Zsh Configuration

The shell configuration is located in `shells/zsh/`:

1. **Main Configuration** (`zshrc`):
   - Edit `zshrc` to modify shell behavior
   - Add or remove plugins
   - Change theme settings
   - Modify environment variables

2. **Custom Aliases** (`aliases.zsh`):
   - Add new aliases in `aliases.zsh`
   - Example:
     ```bash
     # Add a new alias
     alias myalias='my command'
     ```

3. **Custom Functions** (`functions.zsh`):
   - Add shell functions in `functions.zsh`
   - Example:
     ```bash
     # Add a new function
     function myfunction() {
         # Function code here
     }
     ```

4. **Oh My Zsh Customization**:
   - Custom plugins go in `~/.oh-my-zsh/custom/plugins/`
   - Custom themes go in `~/.oh-my-zsh/custom/themes/`
   - Modify `zshrc` to enable new plugins/themes

### Bash Configuration

If you prefer Bash, you can customize it in `shells/bash/`:

1. **Main Configuration** (`bashrc`):
   - Edit `bashrc` for shell behavior
   - Add environment variables
   - Configure shell options

2. **Custom Aliases** (`aliases.bash`):
   - Add Bash-specific aliases
   - Example:
     ```bash
     # Add a new alias
     alias myalias='my command'
     ```

## Customizing Tools

### Git Configuration

1. **Global Git Config** (`gitconfig`):
   - Edit `gitconfig` to set global Git options
   - Configure user information
   - Set default behaviors
   - Example:
     ```ini
     [user]
         name = Your Name
         email = your.email@example.com
     ```

2. **Global Git Ignore** (`gitignore_global`):
   - Add patterns to ignore globally
   - Example:
     ```
     # Add new patterns
     *.log
     .env
     ```

### VS Code Configuration

1. **Settings** (`settings.json`):
   - Edit `settings.json` to customize VS Code
   - Add new settings
   - Modify existing settings
   - Example:
     ```json
     {
         "editor.fontSize": 14,
         "editor.fontFamily": "Your Font"
     }
     ```

2. **Extensions**:
   - Add new extensions to `extensions.txt`
   - Remove unwanted extensions
   - Example:
     ```
     # Add new extension
     ms-python.python
     ```

### Homebrew Configuration

1. **Brewfile**:
   - Edit `Brewfile` to manage packages
   - Add new packages
   - Remove unwanted packages
   - Example:
     ```
     # Add new package
     brew "package-name"
     cask "application-name"
     ```

### Additional Tools

#### ASDF Version Manager

1. **Configuration** (`tools/asdf/`):
   - Manage multiple runtime versions
   - Add new plugins
   - Configure global versions
   - Example:
     ```bash
     # Add a new plugin
     asdf plugin add nodejs
     asdf install nodejs latest
     asdf set -u nodejs latest
     ```

#### AWS CLI

1. **Configuration** (`tools/aws/`):
   - Configure AWS credentials
   - Set up profiles
   - Configure default region
   - Example:
     ```ini
     [profile myprofile]
     region = us-west-2
     output = json
     ```

#### GitHub CLI

1. **Configuration** (`tools/gh/`):
   - Authenticate with GitHub
   - Configure default settings
   - Set up aliases
   - Example:
     ```yaml
     # ~/.config/gh/config.yml
     aliases:
       co: pr checkout
     ```

#### SSH Configuration

1. **Configuration** (`tools/ssh/`):
   - Manage SSH keys
   - Configure hosts
   - Set up SSH config
   - Example:
     ```
     # ~/.ssh/config
     Host github.com
         IdentityFile ~/.ssh/github
         User git
     ```

#### Tmux Configuration

1. **Configuration** (`tools/tmux/`):
   - Customize key bindings
   - Configure status bar
   - Set up plugins
   - Example:
     ```tmux
     # Prefix key
     set -g prefix C-a
     
     # Status bar
     set -g status-style bg=black,fg=white
     ```

#### Python Tools

1. **Pipx** (`tools/pipx/`):
   - Install Python applications
   - Manage virtual environments
   - Example:
     ```bash
     # Install a Python application
     pipx install black
     ```

2. **Python Configuration** (`tools/python/`):
   - Configure pip
   - Set up virtual environments
   - Manage Python versions
   - Example:
     ```ini
     # ~/.pip/pip.conf
     [global]
     index-url = https://pypi.org/simple
     ```

#### System Tools

1. **Htop** (`tools/htop/`):
   - Customize process viewer
   - Configure display options
   - Example:
     ```
     # ~/.config/htop/htoprc
     fields=0 48 17 18 38 39 40 2 46 47 49 1
     sort_key=46
     ```

2. **Ripgrep** (`tools/ripgrep/`):
   - Configure search behavior
   - Set up ignore patterns
   - Example:
     ```
     # ~/.ripgreprc
     --smart-case
     --hidden
     ```

3. **Sleepwatcher** (`tools/sleepwatcher/`):
   - Configure sleep/wake actions
   - Set up system events
   - Example:
     ```bash
     # ~/.sleep
     # Commands to run before sleep
     pmset displaysleepnow
     ```

#### macOS Configuration

1. **System Settings** (`tools/macos/`):
   - Customize system preferences
   - Configure security settings
   - Optimize for development
   - Example:
     ```bash
     # Disable automatic capitalization
     defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
     ```

## Customizing Configurations

### Adding New Configurations

1. **Create a New Configuration File**: Add your new configuration file to the appropriate directory (e.g., `shells/`, `tools/`, etc.).
2. **Update the Profile**: Modify your profile to include the new configuration.
3. **Install the Profile**: Apply the updated profile using the install script:
   ```bash
   ./install profile your-profile
   ```

### Modifying Existing Configurations

1. **Edit the Configuration File**: Modify the existing configuration file to suit your needs.
2. **Test the Changes**: Ensure the changes work as expected.
3. **Install the Profile**: Apply the updated profile using the install script.

## Best Practices

- **Keep It Clean**: Ensure your configurations are free of personal or sensitive data.
- **Document Changes**: Clearly document any changes or additions to the configurations.
- **Test Thoroughly**: Test your customized profiles to ensure they work as expected.
- **Version Control**: Keep track of your changes using Git.
- **Backup**: Always backup your configurations before making major changes.

By following these guidelines, you can easily customize and extend your dotfiles setup. 