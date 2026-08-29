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
local ProgressionService=require(script.Parent.ProgressionService)
local TradeService=require(script.Parent.TradeService)

DataService.init()
local world=WorldBuilder.build()

local oldRemotes=ReplicatedStorage:FindFirstChild("RelicRemotes")
if oldRemotes then oldRemotes:Destroy() end

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
local CancelListing=re("CancelListing")
local BuyListing=re("BuyListing")
local UpgradeLuck=re("UpgradeLuck")
local MarketChanged=re("MarketChanged")
local BiomeChanged=re("BiomeChanged")
local RollResult=re("RollResult")
local EquipItem=re("EquipItem")
local RecycleItem=re("RecycleItem")
local ClaimDaily=re("ClaimDaily")
local ClaimQuest=re("ClaimQuest")
local TradeOffer=re("TradeOffer")
local TradeIncoming=re("TradeIncoming")
local TradeRespond=re("TradeRespond")
local LeaderboardChanged=re("LeaderboardChanged")
local RequestLeaderboard=re("RequestLeaderboard")

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
TradeService.init({data=DataService,findPlayer=findPlayer})

local function isRare(item)
    return (item.baseOneIn or 1) >= 150
end

local function inventoryArray(profile)
    local inv={}
    for _,item in pairs(profile.inventory) do table.insert(inv,Util.deepCopy(item)) end
    table.sort(inv,function(a,b)
        if a.combinedOneIn==b.combinedOneIn then return (a.serial or 0)<(b.serial or 0) end
        return (a.combinedOneIn or 1)>(b.combinedOneIn or 1)
    end)
    return inv
end

local function playerDirectory()
    local out={}
    for _,p in Players:GetPlayers() do
        table.insert(out,{userId=p.UserId,name=p.DisplayName})
    end
    return out
end

local function sync(player)
    local p=DataService.get(player)
    if not p then return end

    Sync:FireClient(player,{
        coins=p.coins,
        luckLevel=p.luckLevel,
        autoRoll=p.autoRoll,
        quickRoll=p.quickRoll,
        pity=p.pity,
        inventory=inventoryArray(p),
        inventoryCap=cap(),
        index=p.index,
        collectionCount=ProgressionService.collectionCount(p),
        collectionTotal=#Config.RELICS,
        equippedUid=p.equippedUid,
        stats=p.stats,
        biome=currentBiome,
        quests=ProgressionService.questSnapshot(p),
        dailyRemaining=ProgressionService.dailyRemaining(p),
        dailyStreak=(p.daily and p.daily.streak) or 0,
        players=playerDirectory(),
        settings=p.settings,
    })
end

local function syncAll()
    for _,p in Players:GetPlayers() do sync(p) end
end

local function refreshMarket()
    MarketChanged:FireAllClients(MarketService.snapshot())
end

local function leaderboardPayload()
    local raw=DataService.getTopWealth(10)
    local out={}
    for _,entry in ipairs(raw) do
        local name=tostring(entry.userId)
        local online=findPlayer(entry.userId)
        if online then name=online.DisplayName end
        table.insert(out,{userId=entry.userId,name=name,coins=entry.coins})
    end
    return out
end

local function pushLeaderboard(player)
    if player then
        LeaderboardChanged:FireClient(player,leaderboardPayload())
    else
        LeaderboardChanged:FireAllClients(leaderboardPayload())
    end
end

local function performRoll(player)
    local p=DataService.get(player)
    if not p then return end
    if Util.count(p.inventory)>=cap() then
        Notify:FireClient(player,"Inventário cheio. Venda ou recicle itens.")
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
    ProgressionService.addProgress(p,"rolls",1)
    if isRare(item) then
        p.stats.rareFinds=(p.stats.rareFinds or 0)+1
        ProgressionService.addProgress(p,"rare",1)
    end

    WorldBuilder.showDrop(item)
    RollResult:FireClient(player,item)
    sync(player)

    if item.combinedOneIn>=100_000 then
        Notify:FireAllClients(string.format(
            "🌎 %s conseguiu %s [%s] #%04d • 1/%s",
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
        Notify:FireClient(player,"Coins insuficientes. Precisa de "..Util.formatNumber(nextCfg.cost)..".")
        return
    end
    p.coins-=nextCfg.cost
    p.luckLevel+=1
    Notify:FireClient(player,"Luck atualizado para nível "..p.luckLevel.."!")
    sync(player)
end)

ListItem.OnServerEvent:Connect(function(player,uid,price)
    local ok,err=MarketService.listItem(player,uid,price)
    if ok then
        Notify:FireClient(player,"Item anunciado no mercado.")
        sync(player)
        refreshMarket()
    else
        Notify:FireClient(player,"Falha: "..tostring(err))
    end
end)

CancelListing.OnServerEvent:Connect(function(player,id)
    local ok,err=MarketService.cancel(player,id)
    if ok then
        Notify:FireClient(player,"Anúncio cancelado.")
        sync(player)
        refreshMarket()
    else
        Notify:FireClient(player,"Falha ao cancelar: "..tostring(err))
    end
end)

BuyListing.OnServerEvent:Connect(function(player,id)
    local listingBefore
    for _,listing in ipairs(MarketService.snapshot()) do
        if listing.listingId==id then listingBefore=listing break end
    end

    local ok,result=MarketService.buy(player,id)
    if not ok then
        Notify:FireClient(player,"Compra falhou: "..tostring(result))
        return
    end

    local seller=listingBefore and findPlayer(listingBefore.sellerUserId)
    if seller then
        local sellerProfile=DataService.get(seller)
        if sellerProfile then ProgressionService.addProgress(sellerProfile,"sales",1) end
        Notify:FireClient(seller,"Seu item foi vendido!")
    end

    Notify:FireClient(player,"Compra concluída!")
    syncAll()
    refreshMarket()
    pushLeaderboard()
end)

EquipItem.OnServerEvent:Connect(function(player,uid)
    local p=DataService.get(player)
    if p and p.inventory[uid] then
        p.equippedUid=uid
        sync(player)
    end
end)

RecycleItem.OnServerEvent:Connect(function(player,uid)
    local p=DataService.get(player)
    if not p then return end
    local ok,result=ProgressionService.recycle(p,uid)
    if ok then
        p.stats.recycled=(p.stats.recycled or 0)+1
        Notify:FireClient(player,"♻️ Item reciclado por "..Util.formatNumber(result).." Coins.")
        sync(player)
        pushLeaderboard()
    else
        Notify:FireClient(player,"Não foi possível reciclar: "..tostring(result))
    end
end)

ClaimDaily.OnServerEvent:Connect(function(player)
    local p=DataService.get(player)
    if not p then return end
    local ok,result=ProgressionService.claimDaily(p)
    if ok then
        Notify:FireClient(player,"🎁 Recompensa diária: +"..Util.formatNumber(result).." Coins!")
        sync(player)
        pushLeaderboard()
    else
        Notify:FireClient(player,"Recompensa diária ainda não está disponível.")
    end
end)

ClaimQuest.OnServerEvent:Connect(function(player,questId)
    if type(questId)~="string" then return end
    local p=DataService.get(player)
    if not p then return end
    local ok,result=ProgressionService.claimQuest(p,questId)
    if ok then
        Notify:FireClient(player,"✅ Missão concluída: +"..Util.formatNumber(result).." Coins!")
        sync(player)
        pushLeaderboard()
    else
        Notify:FireClient(player,"Missão ainda não concluída.")
    end
end)

TradeOffer.OnServerEvent:Connect(function(player,targetUserId,myUid,wantedUid)
    targetUserId=tonumber(targetUserId)
    if not targetUserId or type(myUid)~="string" or type(wantedUid)~="string" then return end
    local ok,result=TradeService.createOffer(player,targetUserId,myUid,wantedUid)
    if not ok then
        Notify:FireClient(player,"Trade falhou: "..tostring(result))
        return
    end
    local target=findPlayer(targetUserId)
    if target then
        TradeIncoming:FireClient(target,result)
        Notify:FireClient(player,"Oferta de trade enviada para "..target.DisplayName..".")
    end
end)

TradeRespond.OnServerEvent:Connect(function(player,offerId,accept)
    if type(offerId)~="string" then return end
    local ok,result=TradeService.respond(player,offerId,accept==true)
    if not ok then
        Notify:FireClient(player,"Trade falhou: "..tostring(result))
        return
    end
    if result=="declined" then
        Notify:FireClient(player,"Trade recusado.")
        return
    end
    Notify:FireClient(result.targetPlayer,"✅ Trade concluído!")
    Notify:FireClient(result.fromPlayer,"✅ Trade concluído!")
    sync(result.targetPlayer)
    sync(result.fromPlayer)
end)

RequestLeaderboard.OnServerEvent:Connect(function(player)
    pushLeaderboard(player)
end)

BiomeService.init(function(b)
    currentBiome=b
    BiomeChanged:FireAllClients(b)
    Notify:FireAllClients("🌌 BIOME EVENT • "..b.name.." • Luck x"..tostring(b.luckMult))
end)

Players.PlayerAdded:Connect(function(player)
    DataService.loadPlayer(player)
    task.defer(function()
        syncAll()
        MarketChanged:FireClient(player,MarketService.snapshot())
        BiomeChanged:FireClient(player,currentBiome)
        pushLeaderboard(player)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    TradeService.clearPlayer(player.UserId)
    DataService.release(player)
    rollClock[player]=nil
    autoToken[player]=nil
    task.defer(syncAll)
end)

task.spawn(function()
    while true do
        task.wait(60)
        DataService.autosave()
    end
end)

task.spawn(function()
    while true do
        task.wait(120)
        pushLeaderboard()
    end
end)

game:BindToClose(function()
    DataService.autosave()
    DataService.saveMarket(MarketService.snapshot())
end)
