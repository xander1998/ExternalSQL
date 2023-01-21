local function AsyncQuery(queryData)
  local p = promise.new()

  exports[GetCurrentResourceName()]:SendQuery(queryData.query, queryData.data, function(results)
    p:resolve(results)
  end)

  return Citizen.Await(p)
end

exports("AsyncQuery", AsyncQuery)