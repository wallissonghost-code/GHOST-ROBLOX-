local HttpService = game:GetService("HttpService")
local Util = {}

function Util.guid() return HttpService:GenerateGUID(false) end

function Util.deepCopy(v)
    if type(v) ~= "table" then return v end
    local out = {}
    for k,val in pairs(v) do out[Util.deepCopy(k)] = Util.deepCopy(val) end
    return out
end

function Util.count(t)
    local n = 0
    for _ in pairs(t or {}) do n += 1 end
    return n
end

function Util.formatNumber(n)
    n = tonumber(n) or 0
    if n >= 1e15 then return string.format("%.2fQa", n/1e15) end
    if n >= 1e12 then return string.format("%.2fT", n/1e12) end
    if n >= 1e9 then return string.format("%.2fB", n/1e9) end
    if n >= 1e6 then return string.format("%.2fM", n/1e6) end
    if n >= 1e3 then return string.format("%.1fK", n/1e3) end
    return tostring(math.floor(n))
end

return Util
