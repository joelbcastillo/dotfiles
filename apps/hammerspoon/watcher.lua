local helpers = require("helpers")

local M = {}

M.activeProfile = nil
M.DEBOUNCE_SECONDS = 3
M._screenWatcher = nil
M._debounceTimer = nil
M.onProfileActivate = nil

function M._onScreenChange()
  local profiles = helpers.loadProfiles()
  if not profiles then return end

  local matchedName, matchedProfile, allMatches = helpers.findMatchingProfile(profiles)

  if matchedName then
    if matchedName == M.activeProfile then
      return
    end
    helpers.notify("Display change detected: applying '" .. matchedName .. "'")
    if M.onProfileActivate then
      local accepted = M.onProfileActivate(matchedName, matchedProfile)
      if accepted ~= false then
        M.activeProfile = matchedName
      end
    else
      M.activeProfile = matchedName
    end
  elseif #allMatches > 1 then
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
        if M.onProfileActivate then
          local accepted = M.onProfileActivate(choice.profileName, choice.profile)
          if accepted ~= false then
            M.activeProfile = choice.profileName
          end
        else
          M.activeProfile = choice.profileName
        end
      end
    end)
    chooser:choices(choices)
    chooser:show()
  else
    local screenNames = {}
    for name in pairs(helpers.getScreenNames()) do
      table.insert(screenNames, name)
    end
    helpers.notify("No profile matches: " .. table.concat(screenNames, ", "))
    M.activeProfile = nil
  end
end

function M.start()
  M._debounceTimer = hs.timer.delayed.new(M.DEBOUNCE_SECONDS, M._onScreenChange)

  M._screenWatcher = hs.screen.watcher.new(function()
    M._debounceTimer:start()
  end)

  M._screenWatcher:start()
end

function M.stop()
  if M._screenWatcher then
    M._screenWatcher:stop()
  end
  if M._debounceTimer then
    M._debounceTimer:stop()
  end
end

function M.activateProfile(profileName)
  local profiles = helpers.loadProfiles()
  if not profiles then return false end

  local profile = profiles[profileName]
  if not profile then
    helpers.notify("Unknown profile: " .. profileName)
    return false
  end

  local activated = true
  if M.onProfileActivate then
    local accepted = M.onProfileActivate(profileName, profile)
    if accepted == false then
      activated = false
    end
  end

  if activated then
    M.activeProfile = profileName
  end
  return true, activated
end

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
