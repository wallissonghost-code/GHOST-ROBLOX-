local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("RelicShared")
local Config = require(Shared.Config)
local Util = require(Shared.Util)

local DataService = {}
local PLAYER_STORE = "RelicMarketRNG_V5_Player"
local GLOBAL_STORE = "RelicMarketRNG_V5_Global"
local WEALTH_STORE = "RelicMarketRNG_V5_Wealth"

local profiles = {}
local useMock = true
local mockPlayers = {}
local mockGlobal = { market = {}, serials = {}, sales = {} }
local mockWealth = {}

local TEMPLATE = {
    coins = Config.START_COINS,
    luckLevel = 0,
    autoRoll = false,
    quickRoll = false,
    pity = 0,
    inventory = {},
    index = {},
    equippedUid = nil,
    daily = { lastClaim=0, streak=0 },
    questProgress = {},
    claimedQuests = {},
    unlockedZones = { starter=true },
    settings = { hideCommonReveal=false, music=true, effects=true },
    stats = {
        rolls=0,
        bestOneIn=1,
        totalSales=0,
        totalPurchases=0,
        trades=0,
        recycled=0,
        rareFinds=0,
    },
}

local function key(player) return "p_" .. player.UserId end

local function mergeDefaults(target, defaults)
    for k,v in pairs(defaults) do
        if target[k] == nil then
            target[k] = Util.deepCopy(v)
        elseif type(v) == "table" and type(target[k]) == "table" then
            mergeDefaults(target[k], v)
        end
    end
end

function DataService.init()
    local ok = pcall(function()
        DataStoreService:GetDataStore(PLAYER_STORE):GetAsync("__probe__")
    end)
    useMock = not ok
    if useMock then warn("[Relic Market RNG] DataStores unavailable; using memory mock.") end
end

function DataService.loadPlayer(player)
    local raw
    if useMock then
        raw = mockPlayers[key(player)]
    else
        local ok,res = pcall(function()
            return DataStoreService:GetDataStore(PLAYER_STORE):GetAsync(key(player))
        end)
        if ok then raw = res end
    end

    local p = type(raw)=="table" and raw or Util.deepCopy(TEMPLATE)
    mergeDefaults(p, TEMPLATE)
    profiles[player]=p
    return p
end

function DataService.get(player) return profiles[player] end

function DataService.savePlayer(player)
    local p = profiles[player]
    if not p then return false end

    if useMock then
        mockPlayers[key(player)] = Util.deepCopy(p)
        mockWealth[player.UserId] = p.coins or 0
        return true
    end

    local ok = pcall(function()
        DataStoreService:GetDataStore(PLAYER_STORE):SetAsync(key(player), p)
    end)

    pcall(function()
        DataStoreService:GetOrderedDataStore(WEALTH_STORE):SetAsync(tostring(player.UserId), math.max(0, math.floor(p.coins or 0)))
    end)

    return ok
end

function DataService.release(player)
    DataService.savePlayer(player)
    profiles[player]=nil
end

function DataService.nextSerial(relicId)
    if useMock then
        mockGlobal.serials[relicId]=(mockGlobal.serials[relicId] or 0)+1
        return mockGlobal.serials[relicId]
    end

    local result
    local ok=pcall(function()
        result=DataStoreService:GetDataStore(GLOBAL_STORE):UpdateAsync("serial_"..relicId,function(cur)
            return (tonumber(cur) or 0)+1
        end)
    end)
    return ok and result or math.floor(os.clock()*1000)
end

function DataService.loadMarket()
    if useMock then return Util.deepCopy(mockGlobal.market) end
    local ok,res=pcall(function()
        return DataStoreService:GetDataStore(GLOBAL_STORE):GetAsync("market")
    end)
    return (ok and type(res)=="table") and res or {}
end

function DataService.saveMarket(market)
    if useMock then
        mockGlobal.market=Util.deepCopy(market)
        return true
    end
    local ok=pcall(function()
        DataStoreService:GetDataStore(GLOBAL_STORE):SetAsync("market",market)
    end)
    return ok
end

function DataService.recordSale(relicId, price)
    local k="sales_"..relicId
    if useMock then
        local sales=mockGlobal.sales[k] or {}
        table.insert(sales,1,price)
        while #sales>20 do table.remove(sales) end
        mockGlobal.sales[k]=sales
        return
    end
    pcall(function()
        DataStoreService:GetDataStore(GLOBAL_STORE):UpdateAsync(k,function(cur)
            cur=type(cur)=="table" and cur or {}
            table.insert(cur,1,price)
            while #cur>20 do table.remove(cur) end
            return cur
        end)
    end)
end

function DataService.marketValue(relicId, fallback)
    local sales
    if useMock then
        sales=mockGlobal.sales["sales_"..relicId]
    else
        local ok,res=pcall(function()
            return DataStoreService:GetDataStore(GLOBAL_STORE):GetAsync("sales_"..relicId)
        end)
        if ok then sales=res end
    end
    if type(sales)~="table" or #sales==0 then return fallback end
    local total=0
    for _,v in ipairs(sales) do total+=v end
    return math.floor(total/#sales)
end

function DataService.getTopWealth(limit)
    limit = math.clamp(limit or 10, 1, 25)
    local out = {}

    if useMock then
        for userId,coins in pairs(mockWealth) do
            table.insert(out,{userId=userId,coins=coins})
        end
        table.sort(out,function(a,b) return a.coins>b.coins end)
        while #out>limit do table.remove(out) end
        return out
    end

    local ok,pages = pcall(function()
        return DataStoreService:GetOrderedDataStore(WEALTH_STORE):GetSortedAsync(false,limit)
    end)
    if not ok then return out end

    for _,entry in ipairs(pages:GetCurrentPage()) do
        table.insert(out,{userId=tonumber(entry.key) or 0,coins=entry.value or 0})
    end
    return out
end

function DataService.autosave()
    for p in pairs(profiles) do DataService.savePlayer(p) end
end

return DataService
