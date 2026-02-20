local helpers = require("helpers")
local windows = require("windows")

local M = {}

M.FULLSCREEN_DELAY = 0.8
M.MOVE_SETTLE_DELAY = 0.3

function M.fullscreenWindow(win)
  if not win then return false end
  if win:isFullScreen() then return true end
  win:setFullScreen(true)
  -- Note: setFullScreen is async; caller relies on queue delay
  -- for the animation to complete. Actual success is not verified here.
  return true
end

function M.processSpaceEntry(entry, targetScreen, queue)
  if entry.app == "desktop" then return 0 end

  local app = hs.application.get(entry.app)
  if not app then return 0 end

  local wins = {}
  if entry.multiWindow then
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

  local count = 0
  for _, win in ipairs(wins) do
    local winScreen = win:screen()
    if win:isFullScreen() and winScreen and winScreen:name() == targetScreen:name() then
      -- Already correct
    else
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

function M.buildFullscreenQueue(profile)
  local queue = {}

  local screenNames = {}
  for screenName in pairs(profile.screens) do
    table.insert(screenNames, screenName)
  end
  table.sort(screenNames)

  for _, screenName in ipairs(screenNames) do
    local screenConfig = profile.screens[screenName]
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

function M.applyFullscreen(profile, onComplete)
  windows.assignAllWindows(profile)

  hs.timer.doAfter(M.MOVE_SETTLE_DELAY, function()
    local queue = M.buildFullscreenQueue(profile)
    helpers.notify("Fullscreening " .. #queue .. " windows...")
    M.executeFullscreenQueue(queue, function()
      helpers.notify("Fullscreen complete")
      if onComplete then onComplete() end
    end)
  end)
end

return M
