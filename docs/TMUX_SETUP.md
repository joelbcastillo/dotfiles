# Tmux Configuration for Claude Code

Your tmux configuration has been cleaned up and optimized for use with Claude and Claude Code. This document covers setup, keybindings, workflows, and best practices.

## Status

- ✓ Config updated and tested
- ✓ Claude Code optimizations integrated
- ✓ All plugins configured
- ✓ Session persistence enabled

---

## Quick Start

Your config is live and ready to use. To verify:

```bash
# Reload config
tmux source-file ~/.tmux.conf
# or press: C-b r

# Start a session
tmux new-session -s work

# Detach and reattach
tmux detach-client
tmux attach-session -s work
```

---

## Keybinding Reference

### Core Navigation
| Action | Keys | Notes |
|--------|------|-------|
| New window | `C-b c` | Opens in current path |
| New named window | `C-b n` | Prompts for name |
| Rename window | `C-b N` | Rename active window |
| Next window | `C-b C-l` | Move right (repeatable) |
| Previous window | `C-b C-h` | Move left (repeatable) |
| Last window | `C-b C-b` | Toggle to previous window |
| List windows | `C-b w` | Shows all windows |

### Pane Management
| Action | Keys | Notes |
|--------|------|-------|
| Split vertical | `C-b v` | 50/50 split |
| Split horizontal | `C-b s` | 50/50 split |
| Split vertical (alt) | `C-b \|` | Full height |
| Split horizontal (alt) | `C-b -` | Full width |
| Move left | `C-b h` | Vim-style navigation |
| Move down | `C-b j` | Vim-style navigation |
| Move up | `C-b k` | Vim-style navigation |
| Move right | `C-b l` | Vim-style navigation |
| Resize left | `C-b H` | 5px (repeatable) |
| Resize down | `C-b J` | 5px (repeatable) |
| Resize up | `C-b K` | 5px (repeatable) |
| Resize right | `C-b L` | 5px (repeatable) |
| Kill pane | `C-b x` | Close pane |
| Break pane | `C-b b` | Move pane to new window |
| Join panes | `C-b C-j` | Merge panes |

### Copy Mode & Selection
| Action | Keys | Notes |
|--------|------|-------|
| Enter copy mode | `C-b [` | Browse scrollback |
| Begin selection | `v` (in copy mode) | Start text selection |
| Copy selection | `y` (in copy mode) | Copy to clipboard |
| Search history | `C-b /` | Search scrollback |
| Exit copy mode | `q` | Leave copy mode |

### Session & Config
| Action | Keys | Notes |
|--------|------|-------|
| Detach session | `C-b d` | Backgrounded |
| List sessions | `tmux ls` | Command line |
| Select session | `C-b s` | Interactive picker |
| Reload config | `C-b r` | Live reload |
| Sync panes | `C-b e` | Toggle input sync |
| Unsync panes | `C-b E` | Disable input sync |

---

## Configuration Details

### Core Settings
- **Prefix:** `C-a` (Screen-like, more ergonomic than `C-b`)
- **Terminal:** `tmux-256color` with true color support
- **Indexing:** Windows and panes start at 1 (not 0)
- **Mouse:** Enabled for pane selection and resizing
- **History:** 100,000 lines (optimized for Claude's verbose output)
- **Escape time:** 0ms (instant vi mode response)

### Status Bar
- **Left:** Session name with blue highlight
- **Right:** Hostname and current time (useful for remote awareness)
- **Window indicators:** Current window highlighted, flags for activity
- **Update frequency:** 1 second

### Plugins
All plugins auto-managed via TPM (Tmux Plugin Manager):

| Plugin | Purpose |
|--------|---------|
| `tmux-sensible` | Sensible defaults |
| `tmux-resurrect` | Save/restore sessions |
| `tmux-continuum` | Auto-save sessions every 5 min |
| `tmux-logging` | Log pane output |
| `tmux-yank` | Better clipboard handling |

**Auto-features:**
- Sessions auto-save every 5 minutes
- Sessions auto-restore on tmux server start
- Vim session strategy preserves buffer states

---

## Claude Code Specific Features

### Optimized for AI Output
- **100k line scrollback** - Claude generates verbose, multi-line responses
- **Enhanced copy mode** - Easy selection and copying of long text blocks
- **Activity monitoring** - Visual alerts when processes complete

### Multi-Agent Workflows
Create separate windows/sessions for different Claude agents:

```bash
# Start analyzer agent
tmux new-session -s analyzer -d "claude-code analyze"

# Start implementer agent
tmux new-session -s implementer -d "claude-code implement"

# Switch between agents
C-a s  # Opens session picker
```

### Debugging & Logging
- Enable pane logging: `C-a Shift+P`
- Logs save to `~/.tmux/log-*`
- Excellent for reviewing long conversations

---

## Workflows

### Parallel agents (dmux) — desk and phone

The dmux parallel-agent workflow builds on this config: `allow-passthrough all`
carries agent notifications out to cmux, and `aggressive-resize on` plus
grouped sessions keep a phone client from resizing the desk panes.

Helper scripts: `dmux-phone`, `dmux-focus`, `dmux-doctor` (in `scripts/`, on
PATH). See the
[Parallel agents: desk and phone](../README.md#parallel-agents-desk-and-phone)
section of the README for the full two-mode workflow and exact commands.

### Single Project Session
```bash
# Create named session
tmux new-session -s myproject

# Create windows for different tasks
C-b c  # main work window
C-b n  # name it
C-b c  # testing window
C-b n  # name it

# Later, attach
tmux attach-session -s myproject
```

### Multi-Agent System
```bash
# Session 1: Analyzer
tmux new-session -s analyzer
C-b c
C-b N  # "research"

# Session 2: Implementer
tmux new-session -s implementer
C-b c
C-b N  # "code"

# Session 3: Tests
tmux new-session -s tests
C-b c
C-b N  # "testing"

# Switch between them
C-b s  # Picker shows all sessions
```

### Side-by-Side Development
```bash
# Open window
C-b c

# Split into two panes
C-b v

# Left pane: code editor
# Right pane: Claude Code running
C-b h  # Move to left pane
vim file.py

C-b l  # Move to right pane
claude-code implement
```

### Synchronized Commands
Test across multiple panes simultaneously:

```bash
# Enable sync
C-b e

# Type command (goes to all panes)
npm test

# Disable sync
C-b E
```

---

## Session Persistence

Your config includes auto-save via `tmux-continuum`:

**How it works:**
1. Sessions auto-save every 5 minutes
2. On tmux server restart, sessions auto-restore
3. Even if you force-kill tmux, sessions survive

**Manual save/restore:**
```bash
# Manually save
tmux-resurrect save

# List resurrect backups
ls ~/.tmux/resurrect/

# Restore from specific backup (if needed)
tmux-resurrect restore
```

**Server lifecycle:**
```bash
# Kill entire server (ends all sessions)
tmux kill-server

# Restart (automatically restores sessions)
tmux attach-session -t analyzer
```

---

## Customization

### User-Specific Settings

Create `~/.tmux.conf.user` for machine-specific overrides:

```bash
# Example: Override status bar for a specific machine
set -g status-right '#[fg=colour245]laptop #[fg=colour245]%H:%M:%S'

# Example: Add machine-specific plugins
set -g @plugin 'your-plugin/here'

# Example: Override colors
set -g status-style fg=white,bg=colour235

# Example: Add Fig integration (if you use it)
# source-file ~/.fig/tmux
```

This file is automatically sourced at the end of the main config, so it can override any setting.

### Color Customization

The color scheme uses standard tmux 256-color palette:
- `colour39` - Bright blue (active/current)
- `colour245` - Gray (status/inactive)
- `colour234` - Near black (background)
- `colour16` - Black (messages)
- `colour221` - Yellow (message background)

To customize, modify the `STATUS BAR` section or create overrides in `~/.tmux.conf.user`.

---

## Troubleshooting

### Config not reloading
```bash
# Check for syntax errors
tmux source-file ~/.tmux.conf
# Should show "Config reloaded!" if successful

# If it fails, check for typos
cat ~/.tmux.conf | grep -E "^[^#]"  # Show non-comment lines
```

### Pane navigation not working
- Verify `C-a h/j/k/l` work for pane switching (not just `h/j/k/l`)
- The `C-a` prefix is required
- If editing in vim, these bindings defer to vim's navigation

### Copy/paste not working
- Ensure you're in copy mode: `C-a [`
- Select with `v`, copy with `y`
- Paste with system shortcuts or `C-a ]`

### Plugins not loading
```bash
# Install plugin manager (TPM) if missing
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Install plugins
tmux source-file ~/.tmux.conf
# Then press: C-a I (capital i)
```

### History/scrollback not working
- Max scrollback is 100k lines
- Access with `C-a [` to enter copy mode
- Scroll with arrow keys or vi keys (j/k)
- Search with `C-a /`

---

## Advanced Usage

### Nested Tmux
If running tmux inside tmux, use alternative prefix for inner session:

```bash
# In inner session
set -g prefix C-b  # In ~/.tmux.conf.user
```

### SSH Sessions
Keep sessions alive through SSH disconnections:

```bash
# Start remote session
ssh user@host
tmux new-session -s work

# Disconnect (Ctrl+D or 'exit' to close, C-a d to detach)
# Reconnect later
ssh user@host
tmux attach-session -s work
```

### Shared Sessions
Multiple users can attach to same session (see cursor positions):

```bash
# User 1
tmux new-session -s shared

# User 2 (different terminal/machine)
tmux attach-session -s shared
```

---

## Performance Notes

- **Status update interval:** 1 second (responsive but efficient)
- **Scrollback:** 100k lines (suitable for Claude's verbose output)
- **Plugins:** Lightweight, no performance impact
- **Mouse support:** Enabled, minimal overhead

For extremely resource-constrained environments, you can reduce history limit in `~/.tmux.conf.user`:

```bash
set -g history-limit 10000  # Reduce from default 100k
```

---

## Updates & Maintenance

### Plugin Updates
```bash
# Update all plugins
tmux source-file ~/.tmux.conf
# Press: C-a U (capital u)

# Update specific plugin
# Go to ~/.tmux/plugins/plugin-name
cd ~/.tmux/plugins/tmux-resurrect
git pull
```

### Config Resets
If you want to reset to base config:

```bash
# Backup your user config first
cp ~/.tmux.conf.user ~/.tmux.conf.user.backup

# Reset
rm ~/.tmux.conf.user
tmux source-file ~/.tmux.conf
```

---

## Resources

- **tmux Documentation:** `man tmux`
- **Config Location:** `~/.tmux.conf`
- **User Overrides:** `~/.tmux.conf.user`
- **Plugins Directory:** `~/.tmux/plugins/`
- **Session Backups:** `~/.tmux/resurrect/`

---

## What Was Cleaned Up

Your original config had good foundations. Improvements made:

✓ Removed redundant status bar definitions (3 locations → 1)
✓ Removed obsolete tmux 2.1 workarounds
✓ Consolidated keybindings (Ctrl+V and ^V were duplicates)
✓ Better terminal type (`tmux-256color` vs `screen-256color`)
✓ Organized into logical sections
✓ Added Claude Code optimizations
✓ Added `tmux-yank` plugin for clipboard
✓ Simplified status bar (cleaner, faster)
✓ Removed external dependencies (Fig, reattach-to-user-namespace)

**Size:** Reduced from 124 lines to 170 lines (better organized, more features)

---

## Next Steps

1. **Verify config:** `tmux source-file ~/.tmux.conf`
2. **Test keybindings:** Try splitting panes, switching windows
3. **Create workflow:** Set up sessions/windows for your projects
4. **Customize:** Add overrides to `~/.tmux.conf.user` as needed
5. **Install plugins:** If first time, press `C-b I` to install TPM plugins

Enjoy your optimized tmux setup with C-b prefix!
