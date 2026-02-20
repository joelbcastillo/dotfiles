local helpers = require("helpers")

local M = {}

M.PORT = 17421
M._server = nil
M.watcher = nil

local function extractProfileName(path)
  return path:match("^/profiles/([^/]+)/activate$")
end

function M._handleRequest(method, path, headers, body)
  local json = function(data, code)
    return hs.json.encode(data), code or 200, { ["Content-Type"] = "application/json" }
  end

  if method == "GET" and path == "/profiles" then
    local names = M.watcher and M.watcher.getProfileNames() or {}
    return json({ profiles = names })
  end

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

function M.start(watcherModule)
  M.watcher = watcherModule

  M._server = hs.httpserver.new()
  M._server:setPort(M.PORT)
  M._server:setCallback(M._handleRequest)
  M._server:start()
end

function M.stop()
  if M._server then
    M._server:stop()
    M._server = nil
  end
end

return M
