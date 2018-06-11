function split(s, delimiter)
    local result = { }
    local from  = 1
    local delim_from, delim_to = string.find( s, delimiter, from  )
    while delim_from do
      table.insert( result, string.sub( s, from , delim_from-1 ) )
      from  = delim_to + 1
      delim_from, delim_to = string.find( s, delimiter, from  )
    end
    table.insert( result, string.sub( s, from  ) )
    return result
  end

local _, formatNameID_PlayerServer
function getPlayerServer()
    if formatNameID_PlayerServer then return formatNameID_PlayerServer end
    _, formatNameID_PlayerServer = UnitFullName("player")
    return formatNameID_PlayerServer
end

function formatNameID(fullName)
    m = split(fullName, "-")
    local name, realm = m[1], m[2]
    if not realm then
        realm = getPlayerServer()
    end
    return name .. "-" .. realm
end

function timeToID(time)
    return time * 1000
end