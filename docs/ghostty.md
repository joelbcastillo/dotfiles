# Ghostty Configuration

This document describes the Ghostty terminal configuration included in this dotfiles setup.

## Overview

Ghostty is a modern, GPU-accelerated terminal emulator that provides excellent performance and features. This configuration is designed to work seamlessly with your existing development environment.

## Configuration File

The Ghostty configuration is located at `tools/ghostty/config.toml`. This file contains all the settings for your terminal emulator.

## Key Features

### Font and Typography
- **Font**: JetBrains Mono (matching your VS Code and development setup)
- **Size**: 14px (matching your VS Code terminal settings)
- **Ligatures**: Enabled for better code readability
- **Antialiasing**: Subpixel antialiasing enabled for crisp text

### Color Scheme
- **Background**: Dark theme (#1e1e1e) matching modern development environments
- **Foreground**: Light gray (#d4d4d4) for good contrast
- **ANSI Colors**: Full 16-color palette with bright variants
- **Selection**: Blue highlight (#264f78) for selected text

### Window Settings
- **Size**: 120x30 columns/rows (good for development work)
- **Padding**: 8px for comfortable text spacing
- **Opacity**: Full opacity (can be adjusted if needed)
- **Decorations**: Enabled for window controls

### Performance
- **GPU Acceleration**: Enabled for smooth rendering
- **VSync**: Enabled to prevent screen tearing
- **Triple Buffering**: Enabled for better performance
- **Render Threads**: Auto-detected for optimal performance

### Key Bindings
The configuration includes common key bindings that match iTerm2 and other terminal emulators:

- **Copy/Paste**: Cmd+C/Cmd+V
- **New Tab**: Cmd+T
- **Close Tab**: Cmd+W
- **Split Panes**: Cmd+D (horizontal), Cmd+Shift+D (vertical)
- **Font Size**: Cmd+Plus/Minus for zoom
- **Full Screen**: Cmd+Ctrl+F
- **Find**: Cmd+F

### Advanced Features
- **Scrollback**: 10,000 lines of history
- **Mouse Support**: Enabled with hide-when-typing
- **Bell**: System sound with visual feedback
- **Unicode/Emoji**: Full support enabled
- **Logging**: Configurable debug logging

## Installation

Ghostty is managed through your dotbot configuration system.

### Using dotbot (Recommended)
```bash
# Install with your default profile
./install

# Or install with macOS profile
./install-profile macos
```

### Manual Installation
```bash
brew install --cask ghostty
```

## Configuration Setup

The configuration is automatically managed by dotbot:

1. **Ghostty is included in your Brewfile** - it will be installed via Homebrew
2. **Configuration is symlinked** - `~/.config/ghostty/config.toml` → `tools/ghostty/config.toml`
3. **Available in profiles** - both `default` and `macos` profiles include Ghostty

### Manual Configuration (if not using dotbot)
```bash
mkdir -p ~/.config/ghostty
ln -s ~/.dotfiles/tools/ghostty/config.toml ~/.config/ghostty/config.toml
```

## Integration with Your Development Environment

### Shell Integration
Ghostty works seamlessly with your existing shell setup:
- **Zsh**: Your oh-my-zsh configuration will work as expected
- **Starship**: Your starship prompt will render correctly
- **Tmux**: All tmux key bindings and configuration will work

### VS Code Integration
- **Terminal Font**: Matches your VS Code terminal font (JetBrains Mono)
- **Font Size**: Consistent 14px across both environments
- **Color Scheme**: Dark theme that complements VS Code

### Development Tools
- **Git**: All git operations work normally
- **Docker**: Container terminal sessions work perfectly
- **SSH**: Remote terminal sessions supported
- **Tmux**: Full tmux compatibility with your existing configuration

## Customization

### Color Scheme
To modify colors, edit the `[colors]` section in `config.toml`:
```toml
[colors]
background = "#your-color"
foreground = "#your-color"
# ... other color settings
```

### Font Settings
To change font settings:
```toml
[font]
family = "Your Font Name"
size = 16
weight = "bold"
```

### Key Bindings
To modify key bindings, edit the `[key_bindings]` section:
```toml
[key_bindings]
new_tab = "Cmd+Shift+T"  # Custom key binding
```

## Troubleshooting

### Performance Issues
- Ensure GPU acceleration is enabled
- Check that your graphics drivers are up to date
- Reduce update frequency if needed

### Font Rendering
- Verify that JetBrains Mono is installed
- Check that ligatures are enabled in the config
- Ensure subpixel antialiasing is enabled

### Key Binding Conflicts
- Check for conflicts with other applications
- Modify key bindings in the config file
- Restart Ghostty after configuration changes

## Comparison with iTerm2

This Ghostty configuration provides similar functionality to iTerm2 with these advantages:
- **Performance**: GPU acceleration for smoother rendering
- **Memory**: Lower memory usage
- **Speed**: Faster startup and rendering
- **Modern**: Built with modern technologies
- **Cross-platform**: Works on macOS, Linux, and Windows

## Additional Resources

- [Ghostty Documentation](https://github.com/mitchellh/ghostty)
- [Ghostty Configuration Reference](https://github.com/mitchellh/ghostty/blob/main/docs/config.md)
- [Ghostty Key Bindings](https://github.com/mitchellh/ghostty/blob/main/docs/key-bindings.md)
