local resource = GetCurrentResourceName()
local config = json.decode(LoadResourceFile(resource, "config.json"))
local authToken = nil

AddEventHandler("onResourceStart", function(startingResource)
  if resource == startingResource then
    if config.createtokenonstart then
      CreateToken()
    end
  end
end)

function AsyncQueryCallback(queryData, callback)
  Citizen.CreateThread(function()
    if authToken then
      queryData.data = queryData.data or {}
      PerformHttpRequest("http://" .. config.api.host .. ":" .. config.api.port .. config.api.route .. "/query", function(code, text, headers)
        local decode = json.decode(text)
        if decode.status then
          callback({ status = true, data = decode.results })
        else
          error("[ExternalSQL]: " .. json.encode(decode.error))
        end
      end, "POST", json.encode({
        query = queryData.query,
        data = queryData.data,
        secret = config.api.secret
      }), {
        ["Content-Type"] = "application/json",
        ["authorization"] = tostring("Bearer " .. authToken)
      })
    else
      error("[ExternalSQL]: AsyncQueryCallback can't be called until authToken is created!")
    end
  end)
end
exports("AsyncQueryCallback", AsyncQueryCallback)

function AsyncQuery(queryData)
  local p = promise.new()
  if authToken then
    PerformHttpRequest("http://" .. config.api.host .. ":" .. config.api.port .. config.api.route .. "/query", function(code, text, headers)
      local decode = json.decode(text)
      if decode.status then
        p:resolve({ status = true, data = decode.results })
      else
        error("[ExternalSQL]: " .. json.encode(decode.error))
        p:reject({ status = false, error = decode.error })
      end
    end, "POST", json.encode({
      query = queryData.query,
      data = queryData.data,
      secret = config.api.secret
    }), {
      ["Content-Type"] = "application/json",
      ["authorization"] = tostring("Bearer " .. authToken)
    })
  else
    error("[ExternalSQL]: AsyncQuery can't be called until authToken is created!")
    p:reject({ status = false, error = "[ExternalSQL]: AsyncQuery can't be called until authToken is created!" })
  end
  return Citizen.Await(p)
end
exports("AsyncQuery", AsyncQuery)

function CreateToken()
  PerformHttpRequest("http://" .. config.api.host .. ":" .. config.api.port .. config.api.route .. "/auth", function(code, text, headers)
    local decode = json.decode(text)
    if decode.status then
      authToken = decode.token
    else
      error("[ExternalSQL]: " .. decode.error)
    end
  end, "POST", json.encode({
    community = config.api.community,
    secret = config.api.secret
  }), {
    ["Content-Type"] = "application/json"
  })
end