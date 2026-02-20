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
