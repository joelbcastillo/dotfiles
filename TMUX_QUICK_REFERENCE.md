# Tmux Quick Reference

## Essential Commands

**Prefix:** All commands start with `C-b` (Ctrl+B)

### Windows
```
C-b c          Create new window
C-b n          Create new named window
C-b N          Rename current window
C-b C-h        Previous window
C-b C-l        Next window
C-b C-b        Last window
C-b w          List all windows
```

### Panes
```
C-b v          Split vertical (50/50)
C-b s          Split horizontal (50/50)
C-b h/j/k/l    Navigate left/down/up/right
C-b H/J/K/L    Resize pane (repeatable)
C-b x          Kill current pane
C-b b          Break pane to new window
C-b C-j        Join panes
```

### Copy Mode
```
C-b [          Enter copy mode
v              Begin selection
y              Copy selection
C-b ]          Paste
C-b /          Search history
q              Exit copy mode
```

### Sessions
```
C-b d          Detach session
C-b s          Select session
tmux ls        List all sessions
tmux attach -t name    Reattach to session
```

### Misc
```
C-b e/E        Toggle pane sync on/off
C-b r          Reload config
C-b :          Open tmux command prompt
```

---

## Common Workflows

### New Project Session
```bash
tmux new-session -s myproject
C-b c          # Create code window
C-b N          # Name it "code"
C-b c          # Create test window
C-b N          # Name it "tests"
C-b C-h        # Switch to code
```

### Split Pane Layout
```
C-b v          # Split left/right
C-b s          # Split current in half
C-b h/l        # Switch between panes
C-b H/L        # Resize horizontally
```

### Multi-Agent Work
```bash
# Terminal 1
tmux new-session -s agent1

# Terminal 2
tmux new-session -s agent2

# Switch between
C-b s          # Shows list, select with arrows, Enter
```

### Copy Long Output
```
C-b [          # Enter copy mode
gg             # Go to top (vim-like)
Shift+G        # Go to bottom
v              # Start selection
G              # Select to end
y              # Copy
C-b ]          # Paste elsewhere
```

---

## Status Bar Info

```
[session-name]  ... [window#  name] ... [hostname  HH:MM:SS]
```

- **Blue (left):** Current session name
- **Gray:** Window numbers and names
- **Gray (right):** Hostname and time

---

## Configuration Files

- **Main config:** `~/.tmux.conf` (active, tested)
- **User config:** `~/.tmux.conf.user` (optional, for overrides)
- **Plugins:** `~/.tmux/plugins/`
- **Session backups:** `~/.tmux/resurrect/`

---

## Pro Tips

1. **Naming windows** - Use descriptive names with `C-b N` for quick identification
2. **Keyboard over mouse** - Much faster once muscle memory builds
3. **Vi keys** - All navigation uses vim keys (h/j/k/l)
4. **Pane sync** - Use `C-b e` to send same input to all panes simultaneously
5. **Copy/paste** - `C-b [` to enter copy mode, `v` to select, `y` to copy, `C-b ]` to paste
6. **Persist sessions** - Detach with `C-b d`, reattach with `tmux attach`
7. **Search output** - `C-b /` in copy mode to search scrollback

---

## Session Persistence

Sessions auto-save every 5 minutes. If tmux crashes:

```bash
# Sessions automatically restore on next start
tmux attach-session -s name
```

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Keys not working | Prefix is `C-a`, not `Ctrl-a` alone |
| Can't paste | Ensure you're in copy mode first: `C-a [` |
| Panes synced unexpectedly | Check sync status: `C-a e` to toggle |
| Config won't load | Run: `tmux source-file ~/.tmux.conf` |
| Plugin not found | Run: `C-a I` to install plugins |

---

## One-Liners

```bash
# List all tmux sessions
tmux ls

# Create session named "work" with window "code"
tmux new-session -s work -n code

# Attach to specific session
tmux attach -t work

# Kill specific window
tmux kill-window -t work:1

# Send command to specific pane
tmux send-keys -t session:window.pane "command" Enter

# Rename current window
tmux rename-window -t session:window newname

# Kill all sessions
tmux kill-server
```

---

## What's Inside

- ✓ Optimized for Claude Code (100k scrollback, enhanced copy mode)
- ✓ 5 productivity plugins auto-installed
- ✓ Session auto-save/restore
- ✓ Vi keybindings throughout
- ✓ Mouse support enabled
- ✓ Vim-aware pane navigation
- ✓ Activity monitoring for background windows
- ✓ C-b prefix for comfortable key access

Ready to use - no additional setup needed!
