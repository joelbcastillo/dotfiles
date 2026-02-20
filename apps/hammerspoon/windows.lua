local helpers = require("helpers")

local M = {}

-- Move all windows of an app to a target screen
function M.moveAppToScreen(appName, targetScreen)
  local app = hs.application.get(appName)
  if not app then return {} end

  local windows = app:allWindows()
  local moved = {}

  for _, win in ipairs(windows) do
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

-- Assign all apps in a screen config to the correct screen
function M.assignWindowsToScreen(screenName, screenConfig)
  local targetScreen

  if screenName == "any" then
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
