local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local Shared=ReplicatedStorage:WaitForChild("RelicShared")
local Config=require(Shared.Config)
local Util=require(Shared.Util)

local DataService=require(script.Parent.DataService)
local RNGService=require(script.Parent.RNGService)
local MarketService=require(script.Parent.MarketService)
local WorldBuilder=require(script.Parent.WorldBuilder)
local BiomeService=require(script.Parent.BiomeService)

DataService.init()
local world=WorldBuilder.build()

local remotes=Instance.new("Folder")
remotes.Name="RelicRemotes"
remotes.Parent=ReplicatedStorage

local function re(name)
    local r=Instance.new("RemoteEvent")
    r.Name=name
    r.Parent=remotes
    return r
end

local Roll=re("Roll")
local ToggleAuto=re("ToggleAuto")
local ToggleQuick=re("ToggleQuick")
local Sync=re("Sync")
local Notify=re("Notify")
local ListItem=re("ListItem")
local BuyListing=re("BuyListing")
local UpgradeLuck=re("UpgradeLuck")
local MarketChanged=re("MarketChanged")
local BiomeChanged=re("BiomeChanged")
local RollResult=re("RollResult")
local EquipItem=re("EquipItem")

local rollClock={}
local autoToken={}
local currentBiome=Config.BIOMES[1]

local function cap() return Config.BASE_INVENTORY_SLOTS end
local function findPlayer(uid)
    for _,p in Players:GetPlayers() do
        if p.UserId==uid then return p end
    end
end

MarketService.init({data=DataService,findPlayer=findPlayer})

local function sync(player)
    local p=DataService.get(player)
    if not p then return end
    local inv={}
    for _,item in pairs(p.inventory) do table.insert(inv,Util.deepCopy(item)) end
    table.sort(inv,function(a,b) return a.combinedOneIn>b.combinedOneIn end)

    Sync:FireClient(player,{
        coins=p.coins,
        luckLevel=p.luckLevel,
        autoRoll=p.autoRoll,
        quickRoll=p.quickRoll,
        pity=p.pity,
        inventory=inv,
        inventoryCap=cap(),
        index=p.index,
        equippedUid=p.equippedUid,
        stats=p.stats,
        biome=currentBiome,
    })
end

local function refreshMarket()
    MarketChanged:FireAllClients(MarketService.snapshot())
end

local function performRoll(player)
    local p=DataService.get(player)
    if not p then return end
    if Util.count(p.inventory)>=cap() then
        Notify:FireClient(player,"Inventário cheio.")
        return
    end

    local cd=p.quickRoll and Config.QUICK_ROLL_COOLDOWN or Config.BASE_ROLL_COOLDOWN
    local now=os.clock()
    if now-(rollClock[player] or 0)<cd then return end
    rollClock[player]=now

    local item=RNGService.roll(
        p,
        currentBiome,
        function(id) return DataService.nextSerial(id) end,
        function(id,fallback) return DataService.marketValue(id,fallback) end
    )

    p.inventory[item.uid]=item
    WorldBuilder.showDrop(item)
    RollResult:FireClient(player,item)
    sync(player)

    if item.combinedOneIn>=100_000 then
        Notify:FireAllClients(string.format(
            "%s conseguiu %s [%s] #%04d • 1/%s",
            player.DisplayName,item.relicName,item.mutationName,item.serial,Util.formatNumber(item.combinedOneIn)
        ))
    end
end

world.prompt.Triggered:Connect(performRoll)
Roll.OnServerEvent:Connect(performRoll)

ToggleAuto.OnServerEvent:Connect(function(player)
    local p=DataService.get(player)
    if not p then return end
    p.autoRoll=not p.autoRoll
    sync(player)

    autoToken[player]=(autoToken[player] or 0)+1
    local token=autoToken[player]

    if p.autoRoll then
        task.spawn(function()
            while player.Parent and DataService.get(player) and DataService.get(player).autoRoll and autoToken[player]==token do
                performRoll(player)
                task.wait(DataService.get(player).quickRoll and Config.QUICK_ROLL_COOLDOWN or Config.BASE_ROLL_COOLDOWN)
            end
        end)
    end
end)

ToggleQuick.OnServerEvent:Connect(function(player)
    local p=DataService.get(player)
    if not p then return end
    p.quickRoll=not p.quickRoll
    sync(player)
end)

UpgradeLuck.OnServerEvent:Connect(function(player)
    local p=DataService.get(player)
    if not p then return end
    local nextCfg=Config.LUCK_UPGRADES[(p.luckLevel or 0)+1]
    if not nextCfg then
        Notify:FireClient(player,"Luck máximo.")
        return
    end
    if p.coins<nextCfg.cost then
        Notify:FireClient(player,"Coins insuficientes.")
        return
    end
    p.coins-=nextCfg.cost
    p.luckLevel+=1
    sync(player)
end)

ListItem.OnServerEvent:Connect(function(player,uid,price)
    local ok,err=MarketService.listItem(player,uid,price)
    if ok then
        sync(player)
        refreshMarket()
    else
        Notify:FireClient(player,"Falha: "..tostring(err))
    end
end)

BuyListing.OnServerEvent:Connect(function(player,id)
    local ok,result=MarketService.buy(player,id)
    if not ok then
        Notify:FireClient(player,"Compra falhou: "..tostring(result))
        return
    end
    for _,p in Players:GetPlayers() do sync(p) end
    refreshMarket()
end)

EquipItem.OnServerEvent:Connect(function(player,uid)
    local p=DataService.get(player)
    if p and p.inventory[uid] then
        p.equippedUid=uid
        sync(player)
    end
end)

BiomeService.init(function(b)
    currentBiome=b
    BiomeChanged:FireAllClients(b)
    Notify:FireAllClients("BIOME EVENT • "..b.name)
end)

Players.PlayerAdded:Connect(function(player)
    DataService.loadPlayer(player)
    task.defer(function()
        sync(player)
        MarketChanged:FireClient(player,MarketService.snapshot())
        BiomeChanged:FireClient(player,currentBiome)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    DataService.release(player)
    rollClock[player]=nil
    autoToken[player]=nil
end)

task.spawn(function()
    while true do
        task.wait(60)
        DataService.autosave()
    end
end)

game:BindToClose(function()
    DataService.autosave()
    DataService.saveMarket(MarketService.snapshot())
end)
