local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("RelicShared")
local Config = require(Shared:WaitForChild("Config"))
local CrateConfig = require(Shared:WaitForChild("CrateConfig"))
local Util = require(Shared:WaitForChild("Util"))

local DataService = require(script.Parent:WaitForChild("DataService"))
local MuseumService = require(script.Parent:WaitForChild("MuseumService"))
local ProgressionService = require(script.Parent:WaitForChild("ProgressionService"))

local remotes = ReplicatedStorage:WaitForChild("RelicRemotes")
local Sync = remotes:WaitForChild("Sync")
local Notify = remotes:WaitForChild("Notify")
local RollResult = remotes:WaitForChild("RollResult")

local museumsFolder = workspace:WaitForChild("RelicWorld"):WaitForChild("PlayerMuseums")

local PLOT_POSITIONS = {
    Vector3.new(-110, 0, 105), Vector3.new(0, 0, 118), Vector3.new(110, 0, 105),
    Vector3.new(-118, 0, 0), Vector3.new(118, 0, 0),
    Vector3.new(-110, 0, -105), Vector3.new(0, 0, -125), Vector3.new(110, 0, -105),
}

local runtime = {}

local function makePart(parent, name, size, position, color, material)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Position = position
    part.Anchored = true
    part.Color = color
    part.Material = material or Enum.Material.SmoothPlastic
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

local function addLabel(part, text, color)
    local gui = Instance.new("BillboardGui")
    gui.Name = "CrateLabel"
    gui.Adornee = part
    gui.Size = UDim2.fromOffset(180, 54)
    gui.StudsOffset = Vector3.new(0, 4.2, 0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = 65
    gui.Parent = part

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = Color3.fromRGB(14,14,20)
    label.BackgroundTransparency = 0.12
    label.TextColor3 = color or Color3.new(1,1,1)
    label.Font = Enum.Font.GothamBlack
    label.TextScaled = true
    label.TextWrapped = true
    label.Text = text
    label.Parent = gui
    return label
end

local function getOwner(plotIndex)
    for _,player in ipairs(Players:GetPlayers()) do
        if MuseumService.getPlotIndex(player) == plotIndex then
            return player
        end
    end
end

local function countInventory(profile)
    local n = 0
    for _ in pairs(profile.inventory or {}) do n += 1 end
    return n
end

local function collectionCount(profile)
    local n = 0
    for _,found in pairs(profile.index or {}) do
        if found then n += 1 end
    end
    return n
end

local function inventoryArray(profile)
    local inv = {}
    for _,item in pairs(profile.inventory or {}) do
        table.insert(inv, Util.deepCopy(item))
    end
    table.sort(inv, function(a,b)
        if a.combinedOneIn == b.combinedOneIn then
            return (a.serial or 0) < (b.serial or 0)
        end
        return (a.combinedOneIn or 1) > (b.combinedOneIn or 1)
    end)
    return inv
end

local function syncInventory(player, profile)
    Sync:FireClient(player, {
        inventory = inventoryArray(profile),
        inventoryCap = Config.BASE_INVENTORY_SLOTS,
        index = profile.index,
        collectionCount = collectionCount(profile),
        stats = profile.stats,
        pity = profile.pity,
    })
end

local function luckMultiplier(profile)
    local level = profile.luckLevel or 0
    if level <= 0 then return 1 end
    local upgrade = Config.LUCK_UPGRADES[level]
    return upgrade and upgrade.multiplier or 1
end

local function chooseCrate(profile)
    local luck = luckMultiplier(profile)
    local total = 0
    local weights = {}
    for i,tier in ipairs(CrateConfig.TIERS) do
        local rarityFactor = 1 + math.max(0, luck - 1) * ((i - 1) / math.max(1, #CrateConfig.TIERS - 1))
        local w = tier.weight * rarityFactor
        weights[i] = w
        total += w
    end

    local roll = math.random() * total
    local cursor = 0
    for i,tier in ipairs(CrateConfig.TIERS) do
        cursor += weights[i]
        if roll <= cursor then return tier end
    end
    return CrateConfig.TIERS[1]
end

local function chooseRelic(crateTier)
    local candidates = {}
    for _,relic in ipairs(Config.RELICS) do
        if relic.oneIn >= crateTier.minOneIn and relic.oneIn <= crateTier.maxOneIn then
            table.insert(candidates, relic)
        end
    end

    if #candidates == 0 then
        local closest = Config.RELICS[1]
        local target = math.sqrt(crateTier.minOneIn * crateTier.maxOneIn)
        for _,relic in ipairs(Config.RELICS) do
            if math.abs(math.log(relic.oneIn) - math.log(target)) < math.abs(math.log(closest.oneIn) - math.log(target)) then
                closest = relic
            end
        end
        return closest
    end

    local total = 0
    local weights = {}
    for i,relic in ipairs(candidates) do
        local w = 1 / math.sqrt(math.max(1, relic.oneIn))
        weights[i] = w
        total += w
    end
    local roll = math.random() * total
    local cursor = 0
    for i,relic in ipairs(candidates) do
        cursor += weights[i]
        if roll <= cursor then return relic end
    end
    return candidates[1]
end

local function chooseMutation(crateTier)
    local selected = Config.MUTATIONS[1]
    for i=#Config.MUTATIONS,2,-1 do
        local mutation = Config.MUTATIONS[i]
        local chance = math.clamp(crateTier.mutationBoost / math.max(1, mutation.oneIn), 0, 0.65)
        if math.random() < chance then
            selected = mutation
            break
        end
    end
    return selected
end

local function createItem(profile, crateTier)
    local relic = chooseRelic(crateTier)
    local mutation = chooseMutation(crateTier)
    local item = {
        uid = Util.guid(),
        relicId = relic.id,
        relicName = relic.name,
        tier = relic.tier,
        serial = DataService.nextSerial(relic.id),
        baseOneIn = relic.oneIn,
        mutationId = mutation.id,
        mutationName = mutation.name,
        mutationOneIn = mutation.oneIn,
        mutationValueMult = mutation.valueMult or 1,
        combinedOneIn = relic.oneIn * math.max(1, mutation.oneIn),
        baseValue = relic.baseValue,
        marketValue = DataService.marketValue(relic.id, relic.baseValue),
        createdAt = os.time(),
        biomeFound = "crate_" .. crateTier.id,
        sourceCrate = crateTier.id,
        listed = false,
    }

    profile.inventory[item.uid] = item
    profile.stats.rolls = (profile.stats.rolls or 0) + 1
    profile.stats.bestOneIn = math.max(profile.stats.bestOneIn or 1, item.combinedOneIn)
    profile.index[relic.id] = true
    ProgressionService.addProgress(profile, "rolls", 1)
    if relic.oneIn >= 150 then
        profile.stats.rareFinds = (profile.stats.rareFinds or 0) + 1
        ProgressionService.addProgress(profile, "rare", 1)
    end
    return item
end

local function buildConveyor(plotIndex)
    local plotModel = museumsFolder:WaitForChild("MuseumPlot" .. plotIndex)
    local center = PLOT_POSITIONS[plotIndex]

    local old = plotModel:FindFirstChild("CrateConveyorSystem")
    if old then old:Destroy() end

    local folder = Instance.new("Folder")
    folder.Name = "CrateConveyorSystem"
    folder.Parent = plotModel

    -- The museum entrance/front is +Z. Keep the conveyor just outside the facade
    -- so it is the first system the owner sees when arriving at the base.
    local conveyorZ = 38
    local belt = makePart(folder, "ConveyorBelt", Vector3.new(45,1,9), center + Vector3.new(0,1.25,conveyorZ), Color3.fromRGB(35,36,42), Enum.Material.Metal)
    belt:SetAttribute("Conveyor", true)
    makePart(folder, "RailBack", Vector3.new(45,2,0.6), center + Vector3.new(0,2.1,conveyorZ - 4.9), Color3.fromRGB(91,62,170), Enum.Material.Neon)
    makePart(folder, "RailFront", Vector3.new(45,2,0.6), center + Vector3.new(0,2.1,conveyorZ + 4.9), Color3.fromRGB(91,62,170), Enum.Material.Neon)

    for x=-18,18,6 do
        makePart(folder, "BeltSlat", Vector3.new(0.45,0.18,8.2), center + Vector3.new(x,1.82,conveyorZ), Color3.fromRGB(82,84,94), Enum.Material.Metal)
    end

    local station = makePart(folder, "ConveyorStation", Vector3.new(5,7,10), center + Vector3.new(-23.5,4,conveyorZ), Color3.fromRGB(49,42,68), Enum.Material.Metal)
    addLabel(station, "📦 ESTEIRA DE CAIXAS", Color3.fromRGB(230,220,255))

    local openingPositions = {
        center + Vector3.new(-30,1.0,23),
        center + Vector3.new(-20,1.0,23),
        center + Vector3.new(-10,1.0,23),
    }

    local openingParts = {}
    for i,pos in ipairs(openingPositions) do
        local pad = makePart(folder, "OpeningSlot"..i, Vector3.new(8,0.8,8), pos, Color3.fromRGB(64,58,80), Enum.Material.Marble)
        pad:SetAttribute("OpeningSlot", i)
        addLabel(pad, "ABERTURA "..i, Color3.fromRGB(220,220,235))
        openingParts[i] = pad
    end

    runtime[plotIndex] = {
        folder = folder,
        activeBelt = {},
        activeCount = 0,
        openings = {},
        openingParts = openingParts,
        startPosition = center + Vector3.new(-20,4.2,conveyorZ),
        endPosition = center + Vector3.new(20,4.2,conveyorZ),
    }
end

local function clearOpening(plotIndex, slotIndex)
    local rt = runtime[plotIndex]
    if not rt then return end
    local state = rt.openings[slotIndex]
    if state and state.visual and state.visual.Parent then state.visual:Destroy() end
    rt.openings[slotIndex] = nil
end

local function beginOpening(player, plotIndex, slotIndex, crateTier)
    local rt = runtime[plotIndex]
    if not rt then return end
    local pad = rt.openingParts[slotIndex]
    if not pad then return end

    local box = makePart(rt.folder, "OpeningCrate"..slotIndex, Vector3.new(5.5,5.5,5.5), pad.Position + Vector3.new(0,3.2,0), crateTier.color, Enum.Material.Metal)
    local label = addLabel(box, crateTier.name .. "\n" .. crateTier.openSeconds .. "s", Color3.new(1,1,1))
    rt.openings[slotIndex] = { playerUserId=player.UserId, visual=box, tier=crateTier }

    task.spawn(function()
        for remaining=crateTier.openSeconds,1,-1 do
            local owner = getOwner(plotIndex)
            local state = rt.openings[slotIndex]
            if not state or state.playerUserId ~= player.UserId or owner ~= player then
                clearOpening(plotIndex, slotIndex)
                return
            end
            label.Text = crateTier.name .. "\nABRINDO: " .. remaining .. "s"
            task.wait(1)
        end

        local profile = DataService.get(player)
        if not profile or getOwner(plotIndex) ~= player then
            clearOpening(plotIndex, slotIndex)
            return
        end

        local waited = 0
        while countInventory(profile) >= Config.BASE_INVENTORY_SLOTS and waited < 300 and player.Parent do
            label.Text = "INVENTÁRIO CHEIO\nLIBERE 1 ESPAÇO"
            task.wait(3)
            waited += 3
            profile = DataService.get(player)
            if not profile then break end
        end

        if not profile or countInventory(profile) >= Config.BASE_INVENTORY_SLOTS then
            Notify:FireClient(player, "📦 A caixa não abriu porque seu inventário está cheio.")
            clearOpening(plotIndex, slotIndex)
            return
        end

        local item = createItem(profile, crateTier)
        DataService.savePlayer(player)
        syncInventory(player, profile)
        RollResult:FireClient(player, item)
        Notify:FireClient(player, string.format("📦 %s abriu: %s [%s] #%04d", crateTier.name, item.relicName, item.mutationName, item.serial))
        clearOpening(plotIndex, slotIndex)
    end)
end

local function pickupCrate(player, plotIndex, crateId)
    if MuseumService.getPlotIndex(player) ~= plotIndex then
        Notify:FireClient(player, "Essa caixa pertence à esteira de outro museu.")
        return
    end

    local rt = runtime[plotIndex]
    local state = rt and rt.activeBelt[crateId]
    if not state or state.claimed then return end

    local freeSlot
    for i=1,CrateConfig.OPENING_SLOTS do
        if not rt.openings[i] then freeSlot = i break end
    end
    if not freeSlot then
        Notify:FireClient(player, "Seus 3 slots de abertura estão ocupados.")
        return
    end

    state.claimed = true
    if state.tween then state.tween:Cancel() end
    if state.visual and state.visual.Parent then state.visual:Destroy() end
    rt.activeBelt[crateId] = nil
    rt.activeCount = math.max(0, rt.activeCount - 1)

    Notify:FireClient(player, state.tier.name .. " enviada para o slot de abertura " .. freeSlot .. ".")
    beginOpening(player, plotIndex, freeSlot, state.tier)
end

local function spawnCrate(plotIndex)
    local rt = runtime[plotIndex]
    local owner = getOwner(plotIndex)
    if not rt or not owner or rt.activeCount >= CrateConfig.MAX_ACTIVE_ON_BELT then return end
    local profile = DataService.get(owner)
    if not profile then return end

    local tier = chooseCrate(profile)
    local id = Util.guid()
    local box = makePart(rt.folder, "MovingCrate", Vector3.new(5.2,5.2,5.2), rt.startPosition, tier.color, Enum.Material.Metal)
    box:SetAttribute("CrateId", id)
    box:SetAttribute("CrateTier", tier.id)

    local trim = Instance.new("Highlight")
    trim.FillTransparency = 0.82
    trim.OutlineTransparency = 0.05
    trim.OutlineColor = tier.color
    trim.Adornee = box
    trim.Parent = box

    addLabel(box, tier.name .. "\nPEGUE!", Color3.new(1,1,1))

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "TakeCrate"
    prompt.ActionText = "PEGAR CAIXA"
    prompt.ObjectText = tier.name
    prompt.HoldDuration = 0.15
    prompt.MaxActivationDistance = 11
    prompt.RequiresLineOfSight = false
    prompt.Parent = box

    local tween = TweenService:Create(box, TweenInfo.new(CrateConfig.TRAVEL_SECONDS, Enum.EasingStyle.Linear), {Position=rt.endPosition})
    rt.activeBelt[id] = { visual=box, tier=tier, tween=tween, claimed=false }
    rt.activeCount += 1

    prompt.Triggered:Connect(function(player)
        pickupCrate(player, plotIndex, id)
    end)

    tween.Completed:Connect(function()
        local state = rt.activeBelt[id]
        if state then
            if state.visual and state.visual.Parent then state.visual:Destroy() end
            rt.activeBelt[id] = nil
            rt.activeCount = math.max(0, rt.activeCount - 1)
        end
    end)
    tween:Play()
end

for i=1,#PLOT_POSITIONS do
    buildConveyor(i)
    task.spawn(function()
        while museumsFolder.Parent do
            task.wait(math.random(CrateConfig.SPAWN_MIN_SECONDS, CrateConfig.SPAWN_MAX_SECONDS))
            spawnCrate(i)
        end
    end)
end

Players.PlayerRemoving:Connect(function(player)
    local plotIndex = MuseumService.getPlotIndex(player)
    local rt = plotIndex and runtime[plotIndex]
    if not rt then return end
    for i=1,CrateConfig.OPENING_SLOTS do
        local state = rt.openings[i]
        if state and state.playerUserId == player.UserId then
            clearOpening(plotIndex, i)
        end
    end
end)
