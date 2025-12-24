# Tool Configurations

This document details the default configurations for all tools in the dotfiles template, explaining why specific defaults were chosen and how to customize them.

## Development Tools

### ASDF Version Manager

**Location**: `tools/asdf/`

1. **asdfrc** (`~/.asdfrc`):
   ```toml
   legacy_version_file = yes
   ```
   - Enables legacy version file support for better compatibility
   - Edit this file to change ASDF behavior globally

2. **tool-versions** (`~/.tool-versions`):
   ```
   nodejs 20.11.1
   python 3.12.2
   ruby 3.3.0
   ```
   - Specifies default versions for common development tools
   - Edit to change default versions or add new tools

### GitHub CLI

**Location**: `tools/gh/`

**config.yml** (`~/.config/gh/config.yml`):
```yaml
# Default editor
editor: code

# Default browser
browser: open

# Common aliases
aliases:
  co: pr checkout
  pr: pr create
  view: repo view
```
- Sets VS Code as default editor for better integration
- Uses system default browser
- Includes common aliases for frequent operations
- Edit to add custom aliases or change defaults

### SSH Configuration

**Location**: `tools/ssh/`

**config** (`~/.ssh/config`):
```
# GitHub
Host github.com
    IdentityFile ~/.ssh/github
    User git

# Default settings for all hosts
Host *
    AddKeysToAgent yes
    UseKeychain yes
    IdentityFile ~/.ssh/id_ed25519
```
- Optimized for GitHub usage
- Enables keychain integration for better security
- Edit to add new hosts or change authentication methods

### AWS Configuration

**Location**: `tools/aws/`

1. **credentials** (`~/.aws/credentials`):
   ```
   [default]
   aws_access_key_id = YOUR_ACCESS_KEY
   aws_secret_access_key = YOUR_SECRET_KEY
   ```
   - Template for AWS credentials
   - **IMPORTANT**: Replace with your actual credentials
   - Add more profiles as needed

2. **config** (`~/.aws/config`):
   ```
   [default]
   region = us-west-2
   output = json
   ```
   - Sets default region and output format
   - Edit to change region or add profile-specific settings

### Tmux Configuration

**Location**: `tools/tmux/`

**tmux.conf** (`~/.tmux.conf`):
```
# Prefix key
set -g prefix C-a
unbind C-b
bind C-a send-prefix

# Status bar
set -g status-style bg=black,fg=white
set -g status-right "#[fg=green]#H #[fg=black]• #[fg=green]#(uname -r | cut -c 1-6)#[default]"

# Window management
set -g base-index 1
setw -g pane-base-index 1

# Mouse support
set -g mouse on
```
- Uses `Ctrl-a` as prefix for better ergonomics
- Custom status bar with system info
- Enables mouse support
- Edit to customize key bindings or appearance

## Python Tools

### Pipx

**Location**: `tools/pipx/`

**config.json** (`~/.config/pipx/config.json`):
```json
{
  "venvs_dir": "~/.local/pipx/venvs",
  "bin_dir": "~/.local/bin",
  "python": "python3"
}
```
- Uses local directory for virtual environments
- Ensures Python 3 is used
- Edit to change installation locations

### Python Configuration

**Location**: `tools/python/`

1. **pip.conf** (`~/.pip/pip.conf`):
   ```
   [global]
   index-url = https://pypi.org/simple
   timeout = 120
   ```
   - Uses official PyPI mirror
   - Increased timeout for better reliability
   - Edit to change package source or add options

2. **pythonrc** (`~/.pythonrc`):
   ```python
   import readline
   import rlcompleter
   readline.parse_and_bind("tab: complete")
   ```
   - Enables tab completion in Python REPL
   - Edit to add custom REPL enhancements

## System Tools

### Finicky

**Location**: `tools/finicky/` (template in public repo, actual config in `~/.dotfiles-private/tools/finicky/`)

**finicky.js** (`~/.finicky.js` - symlinked from private repo):
- Routes Microsoft Teams and Outlook links to Microsoft Edge with domain account profile
- **Configuration is stored in private repository** at `~/.dotfiles-private/tools/finicky/finicky.js`
- Template available at `tools/finicky/finicky.js.template` in public repo
- Edit the private config to change Edge profile directory or add more routing rules
- **Important**: Update `--profile-directory` with your actual Edge profile name (find it at `edge://version/`)
- See [Finicky Documentation](finicky.md) for detailed setup and customization

### Htop

**Location**: `tools/htop/`

**htoprc** (`~/.config/htop/htoprc`):
```
fields=0 48 17 18 38 39 40 2 46 47 49 1
sort_key=46
sort_direction=1
hide_threads=0
hide_kernel_threads=1
hide_userland_threads=0
shadow_other_users=0
show_thread_names=0
show_program_path=1
highlight_base_name=0
highlight_megabytes=1
highlight_threads=1
```
- Shows most relevant process information
- Sorts by CPU usage by default
- Highlights important information
- Edit to change display options or sorting

### Ripgrep

**Location**: `tools/ripgrep/`

**ripgreprc** (`~/.ripgreprc`):
```
--smart-case
--hidden
--glob '!.git/*'
--glob '!node_modules/*'
```
- Case-insensitive search by default
- Includes hidden files
- Excludes common directories
- Edit to change search behavior or exclusions

### Sleepwatcher

**Location**: `tools/sleepwatcher/`

1. **sleep** (`~/.sleep`):
   ```bash
   # Commands to run before sleep
   pmset displaysleepnow
   ```
   - Handles display sleep
   - Edit to add pre-sleep commands

2. **wakeup** (`~/.wakeup`):
   ```bash
   # Commands to run after wake
   osascript -e 'tell application "Music" to pause'
   ```
   - Pauses media playback on wake
   - Edit to add post-wake commands

## Customization Guide

To customize any of these configurations:

1. **Locate the Configuration File**:
   - Check the `Location` section for each tool
   - Files are organized in the `tools/` directory

2. **Edit the Configuration**:
   - Make changes to the appropriate file
   - Follow the format of the existing configuration
   - Test changes before committing

3. **Apply Changes**:
   - Use the install script to apply changes:
     ```bash
     ./install profile your-profile
     ```

4. **Best Practices**:
   - Keep sensitive data out of version control
   - Document custom changes
   - Test configurations on a clean system
   - Use environment variables for sensitive values
