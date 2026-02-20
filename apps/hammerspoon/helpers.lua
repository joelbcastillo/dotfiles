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

  local choices = {}
  for _, appName in ipairs(missingApps) do
    table.insert(choices, {
      text = appName,
      subText = "Not running — select to launch",
      appName = appName,
    })
  end

  local chooser
  chooser = hs.chooser.new(function(choice)
    if choice == nil then
      callback({})
      return
    end
    if choice.skipAll then
      callback({})
    elseif choice.launchAll then
      callback(missingApps)
    else
      callback({ choice.appName })
    end
  end)

  table.insert(choices, 1, {
    text = "Launch All (" .. #missingApps .. " apps)",
    subText = table.concat(missingApps, ", "),
    launchAll = true,
  })
  table.insert(choices, {
    text = "Skip All",
    subText = "Continue without launching missing apps",
    skipAll = true,
  })

  chooser:choices(choices)
  chooser:show()
end

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
      M.notify(appName .. " timed out after " .. timeout .. "s")
      if callback then callback(hs.application.get(appName)) end
      return
    end
    hs.timer.doAfter(checkInterval, check)
  end

  hs.timer.doAfter(checkInterval, check)
end

-- Show a notification
function M.notify(message)
  hs.notify.show("Workspace", "", message)
end

return M
