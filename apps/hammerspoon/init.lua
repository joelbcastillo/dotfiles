-- Workspace Orchestration System
-- PREREQUISITE: Disable auto-rearrange spaces:
--   defaults write com.apple.dock mru-spaces -bool false && killall Dock
-- See profiles.json for profile definitions
-- See docs/plans/2026-02-18-workspace-orchestration-design.md for architecture

hs.window.animationDuration = 0

local helpers = require("helpers")
local spaces = require("spaces")
local watcher = require("watcher")
local server = require("server")

-- Guard against concurrent activations
local activating = false

-- The main profile activation handler
local function activateProfile(profileName, profile)
  if activating then
    helpers.notify("Activation already in progress, ignoring")
    return
  end
  activating = true
  helpers.notify("Activating profile: " .. profileName)

  local appNames = helpers.getProfileApps(profile)
  local missingApps = helpers.findMissingApps(appNames)

  local function proceed()
    spaces.applyProfile(profile, function()
      activating = false
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
