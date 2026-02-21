local helpers = require("helpers")

local M = {}

function M.openMissionControl()
  local ok = hs.osascript.applescript([[
    tell application "System Events"
      key code 160
    end tell
  ]])

  if not ok then
    ok = hs.osascript.applescript([[
      tell application "Mission Control" to launch
    ]])
  end

  return ok
end

function M.closeMissionControl()
  hs.osascript.applescript([[
    tell application "System Events"
      key code 53
    end tell
  ]])
end

-- Attempt to reorder spaces in Mission Control
-- This is best-effort and may fail on different macOS versions
function M.reorderSpaces(desiredOrder)
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
