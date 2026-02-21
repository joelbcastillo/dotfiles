# Workspace Orchestration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a Hammerspoon-based system that auto-arranges macOS fullscreen spaces and windows based on monitor configuration profiles, with Raycast for manual triggers.

**Architecture:** Hammerspoon loads a JSON config defining monitor profiles. A display watcher auto-detects monitor changes and applies the matching profile. Each profile fullscreens apps in order on the correct screen. An HTTP server exposes an API for Raycast script commands.

**Tech Stack:** Hammerspoon (Lua), AppleScript (System Events), Raycast (shell scripts), dotbot (symlinks)

**Design doc:** `docs/plans/2026-02-18-workspace-orchestration-design.md`

---

## Key API Reference (from research)

These are the verified Hammerspoon APIs used throughout. Refer back here during implementation:

```lua
-- Screen detection
hs.screen.allScreens()           -- table of hs.screen
hs.screen.mainScreen():name()    -- "LG HDR WQHD"
hs.screen.find("name")           -- hs.screen or nil

-- Screen watcher (callback takes NO arguments)
hs.screen.watcher.new(fn):start()

-- Windows
hs.window.animationDuration = 0  -- disable animation lag
win:moveToScreen(screen, false, true, 0)  -- instant move
win:setFullScreen(true/false)
win:isFullScreen()
win:screen():name()

-- Applications
hs.application.get("Name")      -- nil if not running
hs.application.open("Name")     -- launch + return app
app:allWindows()
app:mainWindow()

-- JSON
hs.json.read(path)              -- table or nil
hs.json.encode(table, true)     -- pretty-printed string

-- HTTP Server (no router — single callback)
server:setCallback(function(method, path, headers, body)
  return body, statusCode, headers
end)

-- Timer/debounce
hs.timer.delayed.new(seconds, fn)  -- call :start() to reset
hs.timer.doAfter(seconds, fn)      -- one-shot

-- Notifications
hs.notify.show(title, subtitle, text)

-- Chooser
hs.chooser.new(function(choice) end):choices({...}):show()

-- AppleScript
hs.osascript.applescript(source) -- returns ok, result, raw

-- CRITICAL: hs.spaces.moveWindowToSpace() is BROKEN on macOS 15+
-- Do NOT use for window-to-space assignment. Use fullscreen approach instead.
```

---

### Task 1: Bootstrap — Install Hammerspoon and Create Project Skeleton

**Files:**
- Create: `apps/hammerspoon/init.lua`
- Create: `apps/hammerspoon/profiles.json`
- Modify: `tools/homebrew/Brewfile`
- Create: `.dotbot/configs/hammerspoon.yaml`
- Modify: `.dotbot/profiles/full`

**Step 1: Add Hammerspoon to Brewfile**

In `tools/homebrew/Brewfile`, add after the existing cask entries (alphabetical):

```
cask "hammerspoon"
```

**Step 2: Install Hammerspoon**

Run: `brew install --cask hammerspoon`
Expected: Hammerspoon.app installed to /Applications

**Step 3: Create dotbot config for Hammerspoon**

Create `.dotbot/configs/hammerspoon.yaml`:

```yaml
- link:
    ~/.hammerspoon: apps/hammerspoon
```

**Step 4: Add hammerspoon to the full dotbot profile**

In `.dotbot/profiles/full`, add after `ghostty`:

```
hammerspoon
```

**Step 5: Create minimal init.lua**

Create `apps/hammerspoon/init.lua`:

```lua
-- Workspace Orchestration System
-- See profiles.json for profile definitions

hs.window.animationDuration = 0

local configDir = hs.configdir

hs.notify.show("Hammerspoon", "", "Config loaded")
```

**Step 6: Create profiles.json with both profiles**

Create `apps/hammerspoon/profiles.json`:

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

**Step 7: Run dotbot to create symlink**

Run: `cd ~/.dotfiles && ./install profile full` (or manually: `ln -sf ~/.dotfiles/apps/hammerspoon ~/.hammerspoon`)

**Step 8: Launch Hammerspoon and verify**

- Open Hammerspoon.app
- Grant Accessibility permissions when prompted (System Settings > Privacy & Security > Accessibility)
- Verify notification "Config loaded" appears
- Open Hammerspoon console (click menubar icon > Console)
- Type: `print(hs.configdir)` — should print `~/.hammerspoon` (or the symlink target)

**Step 9: Commit**

```bash
git add apps/hammerspoon/init.lua apps/hammerspoon/profiles.json \
  .dotbot/configs/hammerspoon.yaml tools/homebrew/Brewfile .dotbot/profiles/full
git commit -m "feat: bootstrap Hammerspoon workspace orchestration"
```

---

### Task 2: Helpers Module — Config Loading, App Detection, Notifications

**Files:**
- Create: `apps/hammerspoon/helpers.lua`
- Modify: `apps/hammerspoon/init.lua`

**Step 1: Create helpers.lua**

Create `apps/hammerspoon/helpers.lua`:

```lua
local M = {}

-- Load profiles from JSON config file
function M.loadProfiles()
  local path = hs.configdir .. "/profiles.json"
  local data = hs.json.read(path)
  if not data then
    hs.notify.show("Workspace", "", "Failed to load profiles.json")
    return nil
  end
  return data.profiles
end

-- Get current screen names as a set-like table
function M.getScreenNames()
  local names = {}
  for _, screen in ipairs(hs.screen.allScreens()) do
    local name = screen:name()
    if name then
      names[name] = true
    end
  end
  return names
end

-- Get screen count
function M.getScreenCount()
  return #hs.screen.allScreens()
end

-- Find screen object by name
function M.findScreen(name)
  for _, screen in ipairs(hs.screen.allScreens()) do
    if screen:name() == name then
      return screen
    end
  end
  return nil
end

-- Match a profile against current screen config
-- Returns true if the profile's match rules are satisfied
function M.profileMatches(profile)
  local match = profile.match
  if not match or not match.screens then return false end

  if type(match.screens) == "number" then
    return M.getScreenCount() == match.screens
  end

  if type(match.screens) == "table" then
    local currentNames = M.getScreenNames()
    for _, requiredName in ipairs(match.screens) do
      if not currentNames[requiredName] then
        return false
      end
    end
    return true
  end

  return false
end

-- Find matching profile(s) for current screen config
-- Returns: matchedName, matchedProfile (or nil if no/multiple matches)
-- Also returns allMatches table for chooser when multiple match
function M.findMatchingProfile(profiles)
  local matches = {}
  for name, profile in pairs(profiles) do
    if M.profileMatches(profile) then
      table.insert(matches, { name = name, profile = profile })
    end
  end

  if #matches == 1 then
    return matches[1].name, matches[1].profile, matches
  elseif #matches > 1 then
    return nil, nil, matches
  else
    return nil, nil, {}
  end
end

-- Collect all unique app names from a profile (across all screens)
function M.getProfileApps(profile)
  local apps = {}
  local seen = {}
  for _, screenConfig in pairs(profile.screens) do
    for _, space in ipairs(screenConfig.spaces) do
      if space.app ~= "desktop" and not seen[space.app] then
        seen[space.app] = true
        table.insert(apps, space.app)
      end
    end
  end
  return apps
end

-- Check which apps from a list are not running
-- Returns table of app names that are not running
function M.findMissingApps(appNames)
  local missing = {}
  for _, name in ipairs(appNames) do
    if not hs.application.get(name) then
      table.insert(missing, name)
    end
  end
  return missing
end

-- Show a chooser to select which missing apps to launch
-- Calls callback with table of selected app names
function M.promptMissingApps(missingApps, callback)
  if #missingApps == 0 then
    callback({})
    return
  end

  -- Build choices with checkable items
  local choices = {}
  for _, appName in ipairs(missingApps) do
    table.insert(choices, {
      text = appName,
      subText = "Not running — select to launch",
      appName = appName,
    })
  end

  -- hs.chooser is single-select, so we use it to launch one at a time
  -- or launch all. Simpler approach: launch all missing with confirmation.
  local chooser
  chooser = hs.chooser.new(function(choice)
    if choice == nil then
      -- User cancelled — skip all missing apps
      callback({})
      return
    end
    if choice.launchAll then
      callback(missingApps)
    else
      callback({ choice.appName })
    end
  end)

  -- Add "Launch All" option at the top
  table.insert(choices, 1, {
    text = "Launch All (" .. #missingApps .. " apps)",
    subText = table.concat(missingApps, ", "),
    launchAll = true,
  })
  -- Add "Skip All" option
  table.insert(choices, {
    text = "Skip All",
    subText = "Continue without launching missing apps",
    appName = nil,
  })

  chooser:choices(choices)
  chooser:show()
end

-- Launch an app and wait for it to be ready (up to timeout seconds)
-- Returns the app object or nil
function M.launchAndWait(appName, timeout)
  timeout = timeout or 30
  local app = hs.application.open(appName)
  if not app then return nil end

  local startTime = hs.timer.secondsSinceEpoch()
  while hs.timer.secondsSinceEpoch() - startTime < timeout do
    app = hs.application.get(appName)
    if app and #app:allWindows() > 0 then
      return app
    end
    -- Yield briefly
    os.execute("sleep 0.5")
  end

  hs.notify.show("Workspace", "", appName .. " timed out after " .. timeout .. "s")
  return hs.application.get(appName)
end

-- Show a notification
function M.notify(message)
  hs.notify.show("Workspace", "", message)
end

return M
```

**Step 2: Update init.lua to load and test helpers**

Replace `apps/hammerspoon/init.lua` content:

```lua
-- Workspace Orchestration System
-- See profiles.json for profile definitions

hs.window.animationDuration = 0

local helpers = require("helpers")

-- Test: load profiles on startup
local profiles = helpers.loadProfiles()
if profiles then
  local count = 0
  for _ in pairs(profiles) do count = count + 1 end
  helpers.notify("Loaded " .. count .. " profiles")
else
  helpers.notify("ERROR: No profiles loaded")
end
```

**Step 3: Reload Hammerspoon and verify**

- Reload config (Cmd+Shift+R or click menubar > Reload Config)
- Expected notification: "Loaded 2 profiles"
- Open console and test:
  - `helpers = require("helpers")`
  - `print(helpers.getScreenCount())` — should print current screen count
  - `for name, _ in pairs(helpers.getScreenNames()) do print(name) end` — should print screen names

**Step 4: Commit**

```bash
git add apps/hammerspoon/helpers.lua apps/hammerspoon/init.lua
git commit -m "feat: add helpers module with config loading and app detection"
```

---

### Task 3: Window Assignment Module

**Files:**
- Create: `apps/hammerspoon/windows.lua`

**Step 1: Create windows.lua**

Create `apps/hammerspoon/windows.lua`:

```lua
local helpers = require("helpers")

local M = {}

-- Move all windows of an app to a target screen
-- Returns the windows that were moved (or already on that screen)
function M.moveAppToScreen(appName, targetScreen)
  local app = hs.application.get(appName)
  if not app then return {} end

  local windows = app:allWindows()
  local moved = {}

  for _, win in ipairs(windows) do
    -- Skip minimized windows and windows without a frame
    if win:isStandard() then
      local currentScreen = win:screen()
      if currentScreen and currentScreen:name() ~= targetScreen:name() then
        win:moveToScreen(targetScreen, false, true, 0)
      end
      table.insert(moved, win)
    end
  end

  return moved
end

-- Assign all apps in a profile's screen config to the correct screen
-- screenName: the key from profiles.json ("Color LCD", "LG HDR WQHD", or "any")
-- screenConfig: the {spaces: [...]} table
-- Returns table of {appName, windows} for apps that were processed
function M.assignWindowsToScreen(screenName, screenConfig)
  local targetScreen

  if screenName == "any" then
    -- Single-screen mode: use the main screen
    targetScreen = hs.screen.mainScreen()
  else
    targetScreen = helpers.findScreen(screenName)
  end

  if not targetScreen then
    helpers.notify("Screen not found: " .. screenName)
    return {}
  end

  local results = {}
  for _, space in ipairs(screenConfig.spaces) do
    if space.app ~= "desktop" then
      local windows = M.moveAppToScreen(space.app, targetScreen)
      if #windows > 0 then
        table.insert(results, {
          appName = space.app,
          windows = windows,
          multiWindow = space.multiWindow or false,
          screen = targetScreen,
        })
      end
    end
  end

  return results
end

-- Assign all windows for an entire profile to their correct screens
function M.assignAllWindows(profile)
  local allResults = {}
  for screenName, screenConfig in pairs(profile.screens) do
    local results = M.assignWindowsToScreen(screenName, screenConfig)
    for _, r in ipairs(results) do
      table.insert(allResults, r)
    end
  end
  return allResults
end

return M
```

**Step 2: Verify in console**

Reload config, then in console:

```lua
windows = require("windows")
helpers = require("helpers")
-- Test with an app that's currently open:
local s = hs.screen.mainScreen()
print(s:name())
-- Test moveAppToScreen with a running app (e.g., "Ghostty"):
local moved = windows.moveAppToScreen("Ghostty", s)
print(#moved, "windows found")
```

**Step 3: Commit**

```bash
git add apps/hammerspoon/windows.lua
git commit -m "feat: add windows module for screen assignment"
```

---

### Task 4: Fullscreen Orchestration Module

**Files:**
- Create: `apps/hammerspoon/spaces.lua`

**Step 1: Create spaces.lua**

Create `apps/hammerspoon/spaces.lua`:

```lua
local helpers = require("helpers")
local windows = require("windows")

local M = {}

-- Delay between fullscreen operations (seconds)
-- macOS needs time for the fullscreen animation
M.FULLSCREEN_DELAY = 0.8

-- Fullscreen a single window, with idempotency check
-- Returns true if the window was fullscreened (or already was)
function M.fullscreenWindow(win)
  if not win then return false end

  if win:isFullScreen() then
    return true -- already fullscreened
  end

  win:setFullScreen(true)
  return true
end

-- Process a single space entry from the profile
-- Returns number of windows fullscreened
function M.processSpaceEntry(entry, targetScreen, queue)
  if entry.app == "desktop" then
    return 0
  end

  local app = hs.application.get(entry.app)
  if not app then return 0 end

  local wins = {}
  if entry.multiWindow then
    -- Get all standard windows, sorted by window ID for consistent ordering
    for _, win in ipairs(app:allWindows()) do
      if win:isStandard() then
        table.insert(wins, win)
      end
    end
    table.sort(wins, function(a, b) return a:id() < b:id() end)
  else
    local mainWin = app:mainWindow()
    if mainWin and mainWin:isStandard() then
      wins = { mainWin }
    end
  end

  -- Queue each window for fullscreening
  local count = 0
  for _, win in ipairs(wins) do
    -- Check if already fullscreened on correct screen
    if win:isFullScreen() and win:screen():name() == targetScreen:name() then
      -- Already correct, skip
    else
      -- If fullscreened on wrong screen, exit fullscreen first
      if win:isFullScreen() then
        win:setFullScreen(false)
        table.insert(queue, { win = win, needsDelay = true, exitedFullscreen = true })
      end
      table.insert(queue, { win = win, needsDelay = true })
    end
    count = count + 1
  end

  return count
end

-- Build the fullscreen queue for an entire profile
-- Returns a table of operations to execute sequentially
function M.buildFullscreenQueue(profile)
  local queue = {}

  for screenName, screenConfig in pairs(profile.screens) do
    local targetScreen
    if screenName == "any" then
      targetScreen = hs.screen.mainScreen()
    else
      targetScreen = helpers.findScreen(screenName)
    end

    if targetScreen then
      for _, space in ipairs(screenConfig.spaces) do
        M.processSpaceEntry(space, targetScreen, queue)
      end
    end
  end

  return queue
end

-- Execute the fullscreen queue with delays between operations
-- Uses hs.timer.doAfter for non-blocking sequential execution
-- Calls onComplete when all operations are done
function M.executeFullscreenQueue(queue, onComplete)
  if #queue == 0 then
    if onComplete then onComplete() end
    return
  end

  local index = 0

  local function processNext()
    index = index + 1
    if index > #queue then
      if onComplete then onComplete() end
      return
    end

    local op = queue[index]

    if op.exitedFullscreen then
      -- Wait for exit animation, then move on
      hs.timer.doAfter(M.FULLSCREEN_DELAY, processNext)
      return
    end

    if op.win and not op.win:isFullScreen() then
      M.fullscreenWindow(op.win)
    end

    if op.needsDelay then
      hs.timer.doAfter(M.FULLSCREEN_DELAY, processNext)
    else
      processNext()
    end
  end

  processNext()
end

-- Main entry: fullscreen all apps in profile order
function M.applyFullscreen(profile, onComplete)
  -- Step 1: Move windows to correct screens
  windows.assignAllWindows(profile)

  -- Small delay to let moves settle
  hs.timer.doAfter(0.3, function()
    -- Step 2: Build and execute fullscreen queue
    local queue = M.buildFullscreenQueue(profile)
    helpers.notify("Fullscreening " .. #queue .. " windows...")
    M.executeFullscreenQueue(queue, function()
      helpers.notify("Fullscreen complete")
      if onComplete then onComplete() end
    end)
  end)
end

return M
```

**Step 2: Verify in console**

Reload config. Then test building a queue (without executing):

```lua
spaces = require("spaces")
helpers = require("helpers")
local profiles = helpers.loadProfiles()
local queue = spaces.buildFullscreenQueue(profiles["single-screen"])
print("Queue has " .. #queue .. " operations")
```

**Step 3: Commit**

```bash
git add apps/hammerspoon/spaces.lua
git commit -m "feat: add spaces module for fullscreen orchestration"
```

---

### Task 5: Display Watcher Module

**Files:**
- Create: `apps/hammerspoon/watcher.lua`

**Step 1: Create watcher.lua**

Create `apps/hammerspoon/watcher.lua`:

```lua
local helpers = require("helpers")

local M = {}

-- Currently active profile name (nil if none)
M.activeProfile = nil

-- Debounce timer (3 seconds — macOS fires multiple events per display change)
M.DEBOUNCE_SECONDS = 3

-- The screen watcher object (must be module-level to prevent GC)
M._screenWatcher = nil

-- The debounce timer (must be module-level to prevent GC)
M._debounceTimer = nil

-- Callback for when a profile should be activated
-- Set this from init.lua
M.onProfileActivate = nil

-- Handle a display change event (called after debounce)
function M._onScreenChange()
  local profiles = helpers.loadProfiles()
  if not profiles then return end

  local matchedName, matchedProfile, allMatches = helpers.findMatchingProfile(profiles)

  if matchedName then
    -- Exactly one match — check if it's already active
    if matchedName == M.activeProfile then
      -- Same profile, no change needed
      return
    end
    helpers.notify("Display change detected: applying '" .. matchedName .. "'")
    M.activeProfile = matchedName
    if M.onProfileActivate then
      M.onProfileActivate(matchedName, matchedProfile)
    end
  elseif #allMatches > 1 then
    -- Multiple matches — show chooser
    local choices = {}
    for _, m in ipairs(allMatches) do
      table.insert(choices, {
        text = m.name,
        subText = "Profile matches current display config",
        profileName = m.name,
        profile = m.profile,
      })
    end

    local chooser = hs.chooser.new(function(choice)
      if choice then
        M.activeProfile = choice.profileName
        if M.onProfileActivate then
          M.onProfileActivate(choice.profileName, choice.profile)
        end
      end
    end)
    chooser:choices(choices)
    chooser:show()
  else
    -- No match
    local screenNames = {}
    for name in pairs(helpers.getScreenNames()) do
      table.insert(screenNames, name)
    end
    helpers.notify("No profile matches: " .. table.concat(screenNames, ", "))
    M.activeProfile = nil
  end
end

-- Start watching for display changes
function M.start()
  M._debounceTimer = hs.timer.delayed.new(M.DEBOUNCE_SECONDS, M._onScreenChange)

  M._screenWatcher = hs.screen.watcher.new(function()
    -- Reset debounce timer on each event
    M._debounceTimer:start()
  end)

  M._screenWatcher:start()
end

-- Stop watching
function M.stop()
  if M._screenWatcher then
    M._screenWatcher:stop()
  end
  if M._debounceTimer then
    M._debounceTimer:stop()
  end
end

-- Manually trigger a profile by name
function M.activateProfile(profileName)
  local profiles = helpers.loadProfiles()
  if not profiles then return false end

  local profile = profiles[profileName]
  if not profile then
    helpers.notify("Unknown profile: " .. profileName)
    return false
  end

  M.activeProfile = profileName
  if M.onProfileActivate then
    M.onProfileActivate(profileName, profile)
  end
  return true
end

-- Get list of available profile names
function M.getProfileNames()
  local profiles = helpers.loadProfiles()
  if not profiles then return {} end
  local names = {}
  for name in pairs(profiles) do
    table.insert(names, name)
  end
  table.sort(names)
  return names
end

return M
```

**Step 2: Verify in console**

Reload config and test:

```lua
watcher = require("watcher")
print(#watcher.getProfileNames(), "profiles available")
-- Don't start the watcher yet — we'll wire it in init.lua
```

**Step 3: Commit**

```bash
git add apps/hammerspoon/watcher.lua
git commit -m "feat: add display watcher with debounce and profile matching"
```

---

### Task 6: HTTP Server Module for Raycast

**Files:**
- Create: `apps/hammerspoon/server.lua`

**Step 1: Create server.lua**

Create `apps/hammerspoon/server.lua`:

```lua
local helpers = require("helpers")

local M = {}

M.PORT = 17421
M._server = nil

-- Reference to watcher module (set from init.lua to avoid circular require)
M.watcher = nil

-- Simple path matching: "/profiles/work-dual/activate" -> "work-dual"
local function extractProfileName(path)
  return path:match("^/profiles/([^/]+)/activate$")
end

-- Handle incoming HTTP requests
function M._handleRequest(method, path, headers, body)
  local json = function(data, code)
    return hs.json.encode(data), code or 200, { ["Content-Type"] = "application/json" }
  end

  -- GET /profiles — list available profiles
  if method == "GET" and path == "/profiles" then
    local names = M.watcher and M.watcher.getProfileNames() or {}
    return json({ profiles = names })
  end

  -- GET /status — current state
  if method == "GET" and path == "/status" then
    local screenNames = {}
    for name in pairs(helpers.getScreenNames()) do
      table.insert(screenNames, name)
    end
    return json({
      activeProfile = M.watcher and M.watcher.activeProfile or nil,
      screens = screenNames,
      screenCount = helpers.getScreenCount(),
    })
  end

  -- POST /profiles/:name/activate — trigger a profile
  if method == "POST" then
    local profileName = extractProfileName(path)
    if profileName then
      if M.watcher then
        local ok = M.watcher.activateProfile(profileName)
        if ok then
          return json({ status = "activated", profile = profileName })
        else
          return json({ error = "Unknown profile: " .. profileName }, 404)
        end
      else
        return json({ error = "Watcher not initialized" }, 500)
      end
    end
  end

  return json({ error = "Not found" }, 404)
end

-- Start the HTTP server
function M.start(watcherModule)
  M.watcher = watcherModule

  M._server = hs.httpserver.new()
  M._server:setPort(M.PORT)
  M._server:setCallback(M._handleRequest)
  M._server:start()

  helpers.notify("HTTP server on port " .. M.PORT)
end

-- Stop the HTTP server
function M.stop()
  if M._server then
    M._server:stop()
    M._server = nil
  end
end

return M
```

**Step 2: Verify in console**

Reload config. Then test from terminal:

```bash
curl -s http://localhost:17421/profiles | jq .
curl -s http://localhost:17421/status | jq .
```

Expected: JSON responses with profile names and current screen info.

**Step 3: Commit**

```bash
git add apps/hammerspoon/server.lua
git commit -m "feat: add HTTP server for Raycast integration"
```

---

### Task 7: Wire Everything Together in init.lua

**Files:**
- Modify: `apps/hammerspoon/init.lua`

**Step 1: Rewrite init.lua as the main orchestrator**

Replace `apps/hammerspoon/init.lua` with:

```lua
-- Workspace Orchestration System
-- See profiles.json for profile definitions
-- See docs/plans/2026-02-18-workspace-orchestration-design.md for architecture

hs.window.animationDuration = 0

local helpers = require("helpers")
local windows = require("windows")
local spaces = require("spaces")
local watcher = require("watcher")
local server = require("server")

-- The main profile activation handler
-- Called by watcher on display change or manual trigger
local function activateProfile(profileName, profile)
  helpers.notify("Activating profile: " .. profileName)

  -- Step 1: Check for missing apps
  local appNames = helpers.getProfileApps(profile)
  local missingApps = helpers.findMissingApps(appNames)

  if #missingApps > 0 then
    -- Prompt user about missing apps, then continue
    helpers.promptMissingApps(missingApps, function(appsToLaunch)
      -- Launch selected apps
      for _, appName in ipairs(appsToLaunch) do
        helpers.launchAndWait(appName, 30)
      end

      -- Continue with fullscreen orchestration
      spaces.applyFullscreen(profile, function()
        helpers.notify("Profile '" .. profileName .. "' applied")
      end)
    end)
  else
    -- All apps running, proceed directly
    spaces.applyFullscreen(profile, function()
      helpers.notify("Profile '" .. profileName .. "' applied")
    end)
  end
end

-- Connect watcher to activation handler
watcher.onProfileActivate = activateProfile

-- Start display watcher
watcher.start()

-- Start HTTP server for Raycast
server.start(watcher)

-- Load and validate profiles on startup
local profiles = helpers.loadProfiles()
if profiles then
  local count = 0
  for _ in pairs(profiles) do count = count + 1 end
  helpers.notify("Workspace ready — " .. count .. " profiles, port " .. server.PORT)
else
  helpers.notify("ERROR: Failed to load profiles.json")
end
```

**Step 2: Reload and verify end-to-end**

- Reload Hammerspoon config
- Expected notification: "Workspace ready — 2 profiles, port 17421"
- Test HTTP endpoints:

```bash
curl -s http://localhost:17421/profiles | jq .
curl -s http://localhost:17421/status | jq .
```

- Test manual activation (with a few apps open):

```bash
curl -s -X POST http://localhost:17421/profiles/single-screen/activate | jq .
```

Expected: apps start fullscreening sequentially with notifications.

**Step 3: Commit**

```bash
git add apps/hammerspoon/init.lua
git commit -m "feat: wire orchestration system together in init.lua"
```

---

### Task 8: Raycast Script Command

**Files:**
- Create: `scripts/raycast/workspace-profile.sh`

**Step 1: Create Raycast script command**

Create `scripts/raycast/workspace-profile.sh`:

```bash
#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Switch Workspace Profile
# @raycast.mode silent
# @raycast.packageName Workspace

# Optional parameters:
# @raycast.icon 🖥️
# @raycast.argument1 { "type": "text", "placeholder": "Profile name (or 'list')" }

HAMMERSPOON_PORT=17421
BASE_URL="http://localhost:${HAMMERSPOON_PORT}"

PROFILE="$1"

if [ -z "$PROFILE" ] || [ "$PROFILE" = "list" ]; then
  PROFILES=$(curl -s "${BASE_URL}/profiles" 2>/dev/null)
  if [ $? -ne 0 ]; then
    echo "Error: Hammerspoon not responding on port ${HAMMERSPOON_PORT}"
    exit 1
  fi
  echo "$PROFILES" | python3 -c "import sys,json; [print(p) for p in json.load(sys.stdin)['profiles']]"
  exit 0
fi

RESULT=$(curl -s -X POST "${BASE_URL}/profiles/${PROFILE}/activate" 2>/dev/null)
if [ $? -ne 0 ]; then
  echo "Error: Hammerspoon not responding"
  exit 1
fi

STATUS=$(echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status','error'))" 2>/dev/null)

if [ "$STATUS" = "activated" ]; then
  echo "Activated profile: ${PROFILE}"
else
  ERROR=$(echo "$RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('error','Unknown error'))" 2>/dev/null)
  echo "Error: ${ERROR}"
  exit 1
fi
```

**Step 2: Make executable**

Run: `chmod +x ~/.dotfiles/scripts/raycast/workspace-profile.sh`

**Step 3: Test from terminal**

```bash
~/.dotfiles/scripts/raycast/workspace-profile.sh list
~/.dotfiles/scripts/raycast/workspace-profile.sh single-screen
```

**Step 4: Add to Raycast**

- Open Raycast > Extensions > Script Commands > Add Script Directory
- Point to `~/.dotfiles/scripts/raycast/`
- Verify "Switch Workspace Profile" appears in Raycast search

**Step 5: Commit**

```bash
git add scripts/raycast/workspace-profile.sh
git commit -m "feat: add Raycast script command for workspace profiles"
```

---

### Task 9: Mission Control Space Reorder (Optional/Best-Effort)

**Files:**
- Create: `apps/hammerspoon/reorder.lua`
- Modify: `apps/hammerspoon/spaces.lua`

> **Important context:** Research confirms this is fragile on macOS 26 Tahoe. Mission Control
> accessibility hierarchy changes between OS versions. The approach uses `hs.osascript` +
> Hammerspoon's `hs.eventtap` for mouse dragging. This module is wrapped in pcall and
> failure does not break the rest of the system.

**Step 1: Create reorder.lua**

Create `apps/hammerspoon/reorder.lua`:

```lua
local helpers = require("helpers")

local M = {}

-- Open Mission Control and wait for it to render
function M.openMissionControl()
  -- Use key code 160 (Mission Control key) via System Events
  local ok = hs.osascript.applescript([[
    tell application "System Events"
      key code 160
    end tell
  ]])

  if not ok then
    -- Fallback: try launching Mission Control app directly
    ok = hs.osascript.applescript([[
      tell application "Mission Control" to launch
    ]])
  end

  return ok
end

-- Close Mission Control
function M.closeMissionControl()
  -- Press Escape to close Mission Control
  hs.osascript.applescript([[
    tell application "System Events"
      key code 53
    end tell
  ]])
end

-- Attempt to reorder spaces in Mission Control
-- This is best-effort and may fail on different macOS versions
-- desiredOrder: table of app names in the desired left-to-right order
function M.reorderSpaces(desiredOrder)
  -- This is a placeholder for the actual implementation.
  -- The Mission Control accessibility hierarchy is version-dependent
  -- and requires empirical testing on the target macOS version.
  --
  -- On macOS 26 Tahoe, the accessibility tree for Mission Control
  -- is accessed via the "Dock" process:
  --   process "Dock" > group "Mission Control" > group 1 > group "Spaces Bar"
  --
  -- Space thumbnails are buttons within the Spaces Bar group.
  -- Reordering requires:
  --   1. Open Mission Control
  --   2. Read positions of space thumbnails
  --   3. Use CGEvent mouse drag to move thumbnails
  --   4. Close Mission Control
  --
  -- Due to version fragility, this is logged but not executed
  -- until empirically verified on the target system.

  helpers.notify("Space reorder: not yet calibrated for this macOS version. Skipping.")
  return false
end

-- Safe wrapper that catches errors
function M.safeReorder(desiredOrder)
  local ok, err = pcall(function()
    return M.reorderSpaces(desiredOrder)
  end)

  if not ok then
    helpers.notify("Space reorder failed: " .. tostring(err))
    return false
  end

  return err
end

return M
```

**Step 2: Integrate reorder into spaces.lua**

In `apps/hammerspoon/spaces.lua`, add after the `M.applyFullscreen` function:

```lua
local reorder = require("reorder")

-- Full orchestration: fullscreen + optional reorder
function M.applyProfile(profile, onComplete)
  M.applyFullscreen(profile, function()
    -- Attempt space reorder (best-effort, failure is OK)
    -- Build desired order from profile
    local desiredOrder = {}
    for _, screenConfig in pairs(profile.screens) do
      for _, space in ipairs(screenConfig.spaces) do
        if space.app ~= "desktop" then
          table.insert(desiredOrder, space.app)
        end
      end
    end

    reorder.safeReorder(desiredOrder)

    if onComplete then onComplete() end
  end)
end
```

**Step 3: Update init.lua to use applyProfile instead of applyFullscreen**

In `apps/hammerspoon/init.lua`, change the `activateProfile` function to call `spaces.applyProfile` instead of `spaces.applyFullscreen`.

Replace:
```lua
spaces.applyFullscreen(profile, function()
```
With:
```lua
spaces.applyProfile(profile, function()
```

(Two occurrences — in both the missing-apps branch and the direct branch.)

**Step 4: Reload and verify**

- Reload config
- Activate a profile
- Expected: fullscreening works, then notification "Space reorder: not yet calibrated..."
- This is correct — the reorder module is a placeholder for future macOS-version-specific calibration

**Step 5: Commit**

```bash
git add apps/hammerspoon/reorder.lua apps/hammerspoon/spaces.lua apps/hammerspoon/init.lua
git commit -m "feat: add space reorder module (best-effort, requires calibration)"
```

---

### Task 10: Integration Testing and Final Polish

**Files:**
- Modify: `apps/hammerspoon/helpers.lua` (fix launchAndWait blocking)
- Verify all endpoints and flows

**Step 1: Fix launchAndWait to be non-blocking**

The `os.execute("sleep 0.5")` in `helpers.launchAndWait` blocks the Hammerspoon event loop. Replace it with a timer-based approach.

In `apps/hammerspoon/helpers.lua`, replace the `launchAndWait` function:

```lua
-- Launch an app and call back when it has windows (or timeout)
-- Non-blocking: uses hs.timer
function M.launchAndWait(appName, timeout, callback)
  timeout = timeout or 30
  hs.application.open(appName)

  local elapsed = 0
  local checkInterval = 0.5

  local function check()
    elapsed = elapsed + checkInterval
    local app = hs.application.get(appName)
    if app and #app:allWindows() > 0 then
      if callback then callback(app) end
      return
    end
    if elapsed >= timeout then
      helpers.notify(appName .. " timed out after " .. timeout .. "s")
      if callback then callback(hs.application.get(appName)) end
      return
    end
    hs.timer.doAfter(checkInterval, check)
  end

  hs.timer.doAfter(checkInterval, check)
end
```

**Step 2: Update init.lua to use async launchAndWait**

In `apps/hammerspoon/init.lua`, update the `activateProfile` function to launch apps sequentially using callbacks:

```lua
local function activateProfile(profileName, profile)
  helpers.notify("Activating profile: " .. profileName)

  local appNames = helpers.getProfileApps(profile)
  local missingApps = helpers.findMissingApps(appNames)

  local function proceed()
    spaces.applyProfile(profile, function()
      helpers.notify("Profile '" .. profileName .. "' applied")
    end)
  end

  if #missingApps > 0 then
    helpers.promptMissingApps(missingApps, function(appsToLaunch)
      if #appsToLaunch == 0 then
        proceed()
        return
      end

      -- Launch apps sequentially, then proceed
      local launched = 0
      local function launchNext()
        launched = launched + 1
        if launched > #appsToLaunch then
          proceed()
          return
        end
        helpers.launchAndWait(appsToLaunch[launched], 30, function()
          launchNext()
        end)
      end
      launchNext()
    end)
  else
    proceed()
  end
end
```

**Step 3: End-to-end test**

1. Reload Hammerspoon config
2. Open a few apps (Ghostty, Chrome, etc.)
3. Test via Raycast or curl:
   ```bash
   curl -s http://localhost:17421/status | jq .
   curl -s -X POST http://localhost:17421/profiles/single-screen/activate | jq .
   ```
4. Verify:
   - Apps move to correct screen
   - Apps fullscreen sequentially with ~0.8s delays
   - Notification appears when complete
   - Running the same profile again is a no-op (already fullscreened)

**Step 4: Test with display disconnect (if possible)**

- Unplug external monitor
- Verify debounced watcher fires after 3s
- Verify either auto-applies single-screen profile or shows notification

**Step 5: Commit**

```bash
git add apps/hammerspoon/helpers.lua apps/hammerspoon/init.lua
git commit -m "fix: make app launching non-blocking, polish integration"
```

---

### Task 11: Disable Auto-Rearrange Spaces System Preference

**Step 1: Set the macOS defaults preference**

This prevents macOS from rearranging your spaces by most-recently-used:

Run: `defaults write com.apple.dock mru-spaces -bool false && killall Dock`

**Step 2: Document in README or config**

Add a comment to `apps/hammerspoon/init.lua` at the top:

```lua
-- PREREQUISITE: Disable auto-rearrange spaces:
--   defaults write com.apple.dock mru-spaces -bool false && killall Dock
```

**Step 3: Commit**

```bash
git add apps/hammerspoon/init.lua
git commit -m "docs: add prerequisite for disabling space auto-rearrange"
```

---

## Summary

| Task | Description | Files |
|------|-------------|-------|
| 1 | Bootstrap: Hammerspoon install, dotbot, skeleton | init.lua, profiles.json, Brewfile, hammerspoon.yaml |
| 2 | Helpers: config loading, app detection, notifications | helpers.lua |
| 3 | Windows: move apps to correct screens | windows.lua |
| 4 | Spaces: fullscreen orchestration with delays | spaces.lua |
| 5 | Watcher: display change detection with debounce | watcher.lua |
| 6 | Server: HTTP API for Raycast | server.lua |
| 7 | Init: wire all modules together | init.lua |
| 8 | Raycast: script command | workspace-profile.sh |
| 9 | Reorder: Mission Control space reorder (best-effort) | reorder.lua |
| 10 | Polish: async app launching, integration test | helpers.lua, init.lua |
| 11 | Prerequisite: disable space auto-rearrange | init.lua comment |

**Total estimated commits:** 11 incremental commits, each adding one working piece.

**Known limitation:** The space reorder module (Task 9) is a calibration placeholder. The actual drag coordinates and accessibility paths need to be empirically determined on the target macOS version by inspecting Mission Control with Accessibility Inspector. This is intentionally deferred — the system works fully without reordering.
