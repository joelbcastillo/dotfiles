# Mac Workspace Orchestration System — Design

## Summary

A Hammerspoon-based system that detects monitor configurations and arranges macOS fullscreen spaces, windows, and apps accordingly. Raycast provides manual profile triggering.

## Stack

- **Hammerspoon** — monitor detection, window management, fullscreen orchestration, HTTP server
- **Raycast** — manual profile trigger via script command
- **AppleScript (System Events)** — Mission Control space reordering

Keyboard Maestro and the Workspaces app were evaluated and dropped as unnecessary. Hammerspoon handles all orchestration natively.

## Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Multi-window apps | Dynamic window count | Detect how many windows each app has; create one fullscreen space per window |
| Space creation | Fullscreen each app | Reliable; avoids private API dependency. No manual desktop creation via UI scripting |
| Space ordering | UI scripting reorder in Mission Control | After fullscreening, drag thumbnails into correct order. Fragile but isolated — failure doesn't break fullscreening |
| Missing apps | Prompt to launch | Show chooser listing missing apps; user selects which to launch |
| Empty desktop | Use macOS default | Don't create/remove desktops. Use whatever exists |
| Config format | Separate JSON file | profiles.json next to init.lua. Easier to edit without Lua knowledge |
| Project location | ~/.dotfiles/apps/hammerspoon/ | Symlinked to ~/.hammerspoon/ via dotbot |

## Project Structure

```
~/.dotfiles/apps/hammerspoon/
├── init.lua              # Main entry — loads modules, starts watcher and server
├── profiles.json         # Profile definitions (edit this to add profiles)
├── spaces.lua            # Fullscreen + Mission Control reorder logic
├── windows.lua           # Window-to-screen assignment
├── watcher.lua           # Display change watcher with debounce
├── server.lua            # HTTP server for Raycast triggers
└── helpers.lua           # App detection, notifications, utilities

~/.dotfiles/scripts/raycast/
└── workspace-profile.sh  # Raycast script command
```

## Config Format (profiles.json)

```json
{
  "profiles": {
    "single-screen": {
      "match": { "screens": 1 },
      "screens": {
        "any": {
          "spaces": [
            { "app": "Spotify" },
            { "app": "Messages" },
            { "app": "WhatsApp" },
            { "app": "Microsoft Outlook" },
            { "app": "Microsoft Teams" },
            { "app": "Slack" },
            { "app": "Microsoft Edge", "multiWindow": true },
            { "app": "Google Chrome", "multiWindow": true },
            { "app": "Claude" },
            { "app": "Notion" },
            { "app": "desktop" },
            { "app": "Ghostty" },
            { "app": "Conductor" },
            { "app": "Nimbalyst", "multiWindow": true }
          ]
        }
      }
    },
    "work-dual": {
      "match": { "screens": ["Color LCD", "LG HDR WQHD"] },
      "screens": {
        "Color LCD": {
          "spaces": [
            { "app": "Microsoft Outlook" },
            { "app": "Microsoft Teams" },
            { "app": "Slack" },
            { "app": "Messages" },
            { "app": "WhatsApp" },
            { "app": "Spotify" }
          ]
        },
        "LG HDR WQHD": {
          "spaces": [
            { "app": "Microsoft Edge", "multiWindow": true },
            { "app": "Google Chrome", "multiWindow": true },
            { "app": "Claude" },
            { "app": "Notion" },
            { "app": "desktop" },
            { "app": "Ghostty" },
            { "app": "Conductor" },
            { "app": "Nimbalyst", "multiWindow": true }
          ]
        }
      }
    }
  }
}
```

- `"desktop"` — use the existing macOS desktop in this position
- `"multiWindow": true` — one fullscreen space per window of this app
- `match.screens` — number (count) or array of screen names for auto-detection
- Adding a profile = adding a new key under `profiles`

## Orchestration Flow

```
1. DETECT
   ├── Read profiles.json
   ├── Match current screen config to a profile
   └── No match → do nothing (or show chooser)

2. CHECK APPS
   ├── For each app in profile's space list: is it running?
   ├── Collect missing apps
   ├── Show hs.chooser for missing apps
   ├── Launch user-selected apps, wait for ready (30s timeout)
   └── Remove unchecked apps from active profile

3. ASSIGN WINDOWS TO SCREENS
   └── Move each app's window(s) to the correct screen (before fullscreening)

4. FULLSCREEN IN ORDER
   ├── For each app in profile order, per screen:
   │   ├── "desktop" → skip
   │   ├── multiWindow → fullscreen each window sequentially
   │   └── single window → fullscreen main window
   ├── ~0.5s delay between each for macOS animation
   └── Skip already-fullscreened apps on correct monitor (idempotency)

5. REORDER SPACES (optional, per-profile flag)
   ├── Open Mission Control via System Events
   ├── Read thumbnail positions
   ├── Drag thumbnails to match profile order
   └── Close Mission Control

6. DONE
   └── Notification: "Profile 'work-dual' applied"
```

## Display Watcher

- Uses `hs.screen.watcher` for display connect/disconnect events
- 3-second debounce (macOS fires multiple events during resolution negotiation)
- Matches current screens against profile `match` rules
- Exactly one match → auto-apply
- Multiple matches → show chooser
- No match → notification with manual trigger hint
- Tracks active profile to avoid redundant re-application

## Raycast Integration

HTTP server on `localhost:17421`:

| Endpoint | Method | Description |
|---|---|---|
| `/profiles` | GET | List profile names |
| `/profiles/:name/activate` | POST | Trigger profile activation |
| `/status` | GET | Current profile and screen info |

Raycast script command calls these endpoints via curl.

## Error Handling

| Scenario | Handling |
|---|---|
| App takes too long to launch | 30-second timeout, skip with notification |
| Fullscreen fails (app resists) | Detect via frame check, skip and notify |
| Mission Control reorder fails | pcall wrapper; notify "spaces may be out of order"; don't roll back |
| hs.spaces unavailable on macOS 26 | Design doesn't depend on it; used only for optional verification |
| Multiple windows of same app | Ordered by window ID (creation order) |

## Idempotency

Running a profile twice is safe:
- Step 4 checks if an app is already fullscreened on the correct monitor and skips it
- Step 5 verifies space order before attempting reorder
- No spaces are created or destroyed — only fullscreen toggling and dragging

## Requirements

- macOS 26+ (Tahoe)
- Hammerspoon (installed via Homebrew)
- Accessibility permissions for Hammerspoon (System Events / Mission Control)
- Raycast (already installed)
