local config = {}
local authToken = nil
local StoredQueries = {}

OnReadyQueue = {
  CREATE_TOKEN = {
      handler = function()
          if config.createtokenonstart then
            CreateToken()
          end
      end
  }
}

AddEventHandler('ExternalSQL:ConfigLoaded', function (data)
  config = data
end)

AddEventHandler('ExternalSQL:APIReady', function()
  for k,v in pairs(OnReadyQueue) do
      v.handler()
  end
end)

function AsyncQueryCallback(queryData, callback)
  Citizen.CreateThread(function()
    if authToken then
      PerformHttpRequest("http://" .. config.api.host .. ":" .. config.api.port .. config.api.route .. "/query", function(code, text, headers)
        local decode = json.decode(text)
        if decode.ok then
          callback({ ok = true, data = decode.results })
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
      if decode.ok then
        p:resolve({ ok = true, data = decode.results })
      else
        error("[ExternalSQL]: " .. json.encode(decode.error))
        p:reject({ ok = false, error = decode.error })
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
    error("[ExternalSQL]: AsyncQuery can't be called until authToken is created!")
    p:reject({ ok = false, error = "[ExternalSQL]: AsyncQuery can't be called until authToken is created!" })
  end
  return Citizen.Await(p)
end
exports("AsyncQuery", AsyncQuery)

function CreateToken()
  PerformHttpRequest("http://" .. config.api.host .. ":" .. config.api.port .. config.api.route .. "/auth", function(code, text, headers)
    local decode = json.decode(text)
    if decode.ok then
      authToken = decode.token
    else
      error("[ExternalSQL]: " .. tostring(decode.error))
    end
  end, "POST", json.encode({
    community = config.api.community,
    secret = config.api.secret
  }), {
    ["Content-Type"] = "application/json"
  })
end

function StoreQuery(name, query)
  StoredQueries[name] = query
end
exports("StoreQuery", StoreQuery)

function CallQuery(name, args)
  local query = StoredQueries[name]
  if not query then return nil end
  return AsyncQuery({
    query = query,
    data = args
  })
end
exports("CallQuery", CallQuery)