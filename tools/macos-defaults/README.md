# macOS Defaults Configuration

This directory contains scripts for configuring macOS defaults optimized for development environments.

## Supported macOS Versions

- **macOS 26 (Sequoia)** - 2025+
- **macOS 15 (Sonoma)** - 2024
- **macOS 14 (Ventura)** - 2023

## Structure

- `macos-common.sh` - Common settings that work across all macOS versions
- `run.sh` - Version detection and execution wrapper
- `versions/` - Version-specific overrides (if needed)

## Usage

```bash
#Run defaults for current macOS version
./tools/macos-defaults/run.sh

# Or run common defaults only
./tools/macos-defaults/macos-common.sh
```

## What Gets Configured

### General UI/UX
- Disable boot sound effects
- Disable transparency for better performance
- Show scrollbars always
- Expand save/print panels by default
- Save to disk (not iCloud) by default

### Trackpad & Keyboard
- Enable tap to click
- Fast keyboard repeat rate
- Disable automatic capitalization/smart quotes (better for coding)
- Full keyboard access for all controls

### Screen & Display
- Require password immediately after sleep
- Screenshots in PNG format
- No shadow in screenshots

### Finder
- Show all filename extensions
- Show status and path bars
- Keep folders on top when sorting
- Avoid creating .DS_Store on network/USB volumes
- Show ~/Library folder

### Dock
- Minimize windows to application icon
- Speed up Mission Control animations
- Remove auto-hide delay
- Show indicators for open applications

### Terminal
- UTF-8 only
- Enable "focus follows mouse"
- Disable annoying line marks

### Development-Specific
- Disable "Are you sure you want to open this application?" dialog
- Disable automatic termination of inactive apps
- Fast window resize speed

## Version-Specific Considerations

### macOS 26 (Sequoia)
- Uses latest System Settings structure
- Some preference domains may have changed

### macOS 15 (Sonoma)
- Intermediate structure
- Most defaults from macOS 14 still work

### macOS 14 (Ventura)
- Legacy System Preferences support
- Stable preference domains

## Notes

- Requires `sudo` access for some system-level changes
- Some changes require logout/restart to take effect
- Run `killall` commands will restart affected applications
- Always review settings before running on a new machine

## Customization

To add your own defaults:

1. Find the setting you want using `defaults read` or `defaults read-type`
2. Add it to `macos-common.sh` if it works across versions
3. Or add version-specific logic in the wrapper script

## Resources

- [macOS defaults reference](https://macos-defaults.com/)
- [defaults command documentation](https://ss64.com/osx/defaults.html)
