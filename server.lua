local resource = GetCurrentResourceName()
local config = json.decode(LoadResourceFile(resource, "config.json"))
local authToken = nil

Citizen.CreateThread(function()
  if config.createtokenonstart then
    CreateToken()
  end
end)

function AsyncQueryCallback(queryData, callback)
  Citizen.CreateThread(function()
    if authToken then
      PerformHttpRequest("http://" .. config.api.host .. ":" .. config.api.port .. config.api.route .. "/query", function(code, text, headers)
        local decode = json.decode(text)
        if decode.status then
          callback({ status = true, data = decode.results })
        else
          error("[ExternalSQL]: " .. json.encode(decode.error))
        end
      end, "POST", json.encode({
        query = queryData.query,
        data = queryData.data or {},
        secret = config.api.secret
      }), {
        ["Content-Type"] = "application/json",
        ["authorization"] = tostring("Bearer " .. authToken)
      })
    else
      while not authToken do
        Citizen.Wait(100)
      end
      
      if authToken then
        AsyncQueryCallback(queryData, callback)
      end
    end
  end)
end
exports("AsyncQueryCallback", AsyncQueryCallback)

function AsyncQuery(queryData, p)
  if not p then p = promise.new() end
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
      data = queryData.data or {},
      secret = config.api.secret
    }), {
      ["Content-Type"] = "application/json",
      ["authorization"] = tostring("Bearer " .. authToken)
    })
  else
    while not authToken do
      Citizen.Wait(100)
    end
    
    if authToken then
      return AsyncQuery(queryData)
    end
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
exports("CreateToken", CreateToken)

function CreateTokenAsync()
  local p = promise.new()

  PerformHttpRequest("http://" .. config.api.host .. ":" .. config.api.port .. config.api.route .. "/auth", function(code, text, headers)
    local decode = json.decode(text)
    if decode.status then
      authToken = decode.token
      p:resolve()
    else
      error("[ExternalSQL]: " .. decode.error)
      p:reject("[ExternalSQL]: " .. decode.error)
    end
  end, "POST", json.encode({
    community = config.api.community,
    secret = config.api.secret
  }), {
    ["Content-Type"] = "application/json"
  })

  return Citizen.Await(p)
end
exports("CreateTokenAsync", CreateTokenAsync)