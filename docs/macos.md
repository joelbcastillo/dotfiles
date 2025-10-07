# macOS Defaults Configuration

This document describes the macOS defaults configuration included in this template. These settings are designed to optimize your Mac for development work.

## General UI/UX

- Disable sound effects on boot
- Disable transparency in menu bar and system-wide
- Set sidebar icon size to medium
- Always show scrollbars
- Disable focus ring animation
- Increase window resize speed for Cocoa applications
- Expand save/print panels by default
- Save to disk (not iCloud) by default
- Disable "Are you sure you want to open this application?" dialog
- Remove duplicates in the "Open With" menu
- Display ASCII control characters using caret notation
- Disable automatic termination of inactive apps
- Set Help Viewer to non-floating mode

## Trackpad & Keyboard

- Enable tap to click for user and login screen
- Map bottom right corner to right-click
- Disable "natural" (Lion-style) scrolling
- Enable full keyboard access for all controls
- Disable press-and-hold for key repeat
- Set fast keyboard repeat rate (1ms delay, 10ms initial delay)
- Disable automatic capitalization
- Disable smart dashes
- Disable automatic period substitution
- Disable smart quotes
- Disable auto-correct

## Screen

- Require password immediately after sleep or screen saver begins
- Save screenshots in PNG format
- Disable shadow in screenshots
- Enable subpixel font rendering on non-Apple LCDs

## Finder

- Show all filename extensions
- Show status bar
- Show path bar
- Keep folders on top when sorting by name
- Search current folder by default
- Disable extension change warning
- Enable spring loading for directories
- Remove spring loading delay
- Avoid creating .DS_Store files on network/USB volumes
- Automatically open new Finder window for mounted volumes
- Show ~/Library folder

## Dock & Mission Control

- Enable highlight hover effect for Dock stacks
- Set Dock icon size to 36 pixels
- Minimize windows into application icon
- Show indicator lights for open applications
- Disable opening animations
- Speed up Mission Control animations (0.1s duration)
- Don't group windows by application
- Disable Dashboard
- Don't show Dashboard as a Space
- Don't rearrange Spaces based on use
- Remove Dock hiding delay
- Remove Dock hiding animation
- Automatically hide Dock
- Make hidden application icons translucent

## Terminal

- Use UTF-8 encoding
- Enable focus follows mouse
- Disable line marks

## Time Machine

- Prevent prompting for new backup volumes

## Activity Monitor

- Show main window on launch
- Visualize CPU usage in Dock icon
- Show all processes
- Sort by CPU usage

## Customization

To customize macOS defaults:

1. Edit `tools/macos` to modify settings
2. Run `./install bootstrap` to apply changes

## Best Practices

1. Test changes in a safe environment first
2. Keep a backup of your original settings
3. Document any non-obvious settings
4. Consider the impact on system performance
5. Be cautious with security-related settings

## Troubleshooting

If you encounter issues after applying these settings:

1. Check the system logs for errors
2. Try resetting specific settings to defaults
3. Restart the affected applications
4. In extreme cases, restart your computer

## Security Considerations

These settings prioritize development convenience while maintaining reasonable security:

1. Password protection is enabled for sleep/screensaver
2. File extension warnings are disabled for development
3. System transparency is reduced for better performance
4. Automatic termination of inactive apps is disabled for development work

## Performance Impact

These settings are optimized for development work:

1. Reduced animations for better performance
2. Fast keyboard repeat rate for coding
3. Disabled transparency for better rendering
4. Optimized Dock behavior for productivity
5. Minimized system interruptions during development 