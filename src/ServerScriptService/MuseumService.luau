local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("RelicShared")
local AssetCatalog = require(Shared:WaitForChild("AssetCatalog"))
local RelicModelBuilder = require(Shared:WaitForChild("RelicModelBuilder"))

local MuseumService = {}

local deps
local rootFolder
local plots = {}
local playerPlot = {}
local MAX_PLOTS = 8
local SLOTS_PER_PLOT = 12

local PLOT_POSITIONS = {
    Vector3.new(-110, 0, 105),
    Vector3.new(0, 0, 118),
    Vector3.new(110, 0, 105),
    Vector3.new(-118, 0, 0),
    Vector3.new(118, 0, 0),
    Vector3.new(-110, 0, -105),
    Vector3.new(0, 0, -125),
    Vector3.new(110, 0, -105),
}

local function makePart(parent, name, size, cframe, color, material)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cframe
    p.Anchored = true
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    p.Parent = parent
    return p
end

local function addBillboard(adornee, text, offset, size)
    local gui = Instance.new("BillboardGui")
    gui.Name = "MuseumLabel"
    gui.Adornee = adornee
    gui.Size = size or UDim2.fromOffset(280, 70)
    gui.StudsOffset = offset or Vector3.new(0, 5, 0)
    gui.AlwaysOnTop = true
    gui.Parent = adornee

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
    label.BackgroundTransparency = 0.12
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.TextWrapped = true
    label.Text = text
    label.Parent = gui
    return label
end

local function sanitize(container)
    for _, obj in ipairs(container:GetDescendants()) do
        if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
            obj:Destroy()
        elseif obj:IsA("Tool") or obj:IsA("ProximityPrompt") or obj:IsA("ClickDetector") then
            obj:Destroy()
        elseif obj:IsA("BasePart") then
            obj.Anchored = true
            obj.CanCollide = false
            obj.CanTouch = false
            obj.CanQuery = true
        end
    end
end

local function firstBasePart(model)
    if model:IsA("BasePart") then return model end
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BasePart") then return d end
    end
end

local function applyMutationVisual(model, item)
    local part = firstBasePart(model)
    if not part then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "MutationHighlight"
    highlight.FillTransparency = 0.72
    highlight.OutlineTransparency = 0.12
    highlight.Adornee = model
    highlight.Parent = model

    local colors = {
        Normal = Color3.fromRGB(230,230,230),
        Shiny = Color3.fromRGB(255,235,110),
        Corrupted = Color3.fromRGB(150,35,45),
        Glitched = Color3.fromRGB(190,60,255),
        Celestial = Color3.fromRGB(150,220,255),
        Singularity = Color3.fromRGB(45,20,80),
    }
    highlight.OutlineColor = colors[item.mutationName] or Color3.new(1,1,1)

    if item.mutationName ~= "Normal" then
        local light = Instance.new("PointLight")
        light.Color = highlight.OutlineColor
        light.Range = 10
        light.Brightness = 1.4
        light.Parent = part
    end
end

local function normalizeModel(model, targetCFrame, desiredMaxSize)
    if not model:IsA("Model") then
        local wrap = Instance.new("Model")
        model.Parent = wrap
        model = wrap
    end

    sanitize(model)

    local ok, size = pcall(function()
        local _, s = model:GetBoundingBox()
        return s
    end)

    if ok and size then
        local largest = math.max(size.X, size.Y, size.Z)
        if largest > 0 then
            local factor = desiredMaxSize / largest
            pcall(function() model:ScaleTo(factor) end)
        end
    end

    pcall(function() model:PivotTo(targetCFrame) end)
    return model
end

local function buildVisual(item, targetCFrame)
    local entry = AssetCatalog.get(item.relicId)
    if entry and entry.assetId and entry.assetId > 0 then
        local ok, inserted = pcall(function()
            return InsertService:LoadAsset(entry.assetId)
        end)
        if ok and inserted then
            local visual = normalizeModel(inserted, targetCFrame, 5.2 * (entry.scale or 1))
            visual.Name = "CreatorStore_" .. item.relicId
            applyMutationVisual(visual, item)
            return visual
        end
    end

    local fallback = RelicModelBuilder.build(item)
    fallback.Name = "Fallback_" .. item.relicId
    fallback:PivotTo(targetCFrame)
    applyMutationVisual(fallback, item)
    return fallback
end

local function clearPedestalVisual(pedestal)
    local existing = pedestal.Parent:FindFirstChild("Display_" .. pedestal.Name)
    if existing then existing:Destroy() end
    local oldLabel = pedestal:FindFirstChild("ItemLabel")
    if oldLabel then oldLabel:Destroy() end
end

local function displayItemOnPedestal(plot, slotIndex, item)
    local pedestal = plot.pedestals[slotIndex]
    if not pedestal then return end
    clearPedestalVisual(pedestal)

    local holder = Instance.new("Model")
    holder.Name = "Display_" .. pedestal.Name
    holder.Parent = plot.model

    local visual = buildVisual(item, pedestal.CFrame * CFrame.new(0, 4.2, 0))
    visual.Parent = holder

    local gui = Instance.new("BillboardGui")
    gui.Name = "ItemLabel"
    gui.Adornee = pedestal
    gui.Size = UDim2.fromOffset(230, 74)
    gui.StudsOffset = Vector3.new(0, 7.6, 0)
    gui.AlwaysOnTop = true
    gui.Parent = pedestal

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1,1)
    label.BackgroundColor3 = Color3.fromRGB(12,12,18)
    label.BackgroundTransparency = 0.18
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.TextWrapped = true
    label.Text = string.format("%s [%s]\n#%04d • 1/%s", item.relicName, item.mutationName, item.serial, tostring(item.combinedOneIn))
    label.Parent = gui
end

local function displayedSet(profile)
    local set = {}
    profile.museumSlots = profile.museumSlots or {}
    for _, uid in pairs(profile.museumSlots) do
        if uid then set[uid] = true end
    end
    return set
end

local function bestUndisplayed(profile)
    local used = displayedSet(profile)
    local best
    for uid, item in pairs(profile.inventory or {}) do
        if not item.listed and not used[uid] then
            if not best or (item.combinedOneIn or 1) > (best.combinedOneIn or 1) then
                best = item
            end
        end
    end
    return best
end

local function refreshSlot(player, slotIndex)
    local plotIndex = playerPlot[player]
    local plot = plotIndex and plots[plotIndex]
    local profile = deps.data.get(player)
    if not plot or not profile then return end

    profile.museumSlots = profile.museumSlots or {}
    local uid = profile.museumSlots[tostring(slotIndex)]
    local pedestal = plot.pedestals[slotIndex]
    clearPedestalVisual(pedestal)

    local item = uid and profile.inventory[uid]
    if item then
        displayItemOnPedestal(plot, slotIndex, item)
    elseif uid then
        profile.museumSlots[tostring(slotIndex)] = nil
    end
end

local function updateOwnerSign(plot, player)
    plot.ownerLabel.Text = player and ("MUSEU DE " .. string.upper(player.DisplayName)) or "MUSEU DISPONÍVEL"
end

local function buildPlot(index, position)
    local model = Instance.new("Model")
    model.Name = "MuseumPlot" .. index
    model.Parent = rootFolder

    local floor = makePart(model, "Floor", Vector3.new(70,1,58), CFrame.new(position + Vector3.new(0,0.5,0)), Color3.fromRGB(54,55,62), Enum.Material.Marble)
    local back = makePart(model, "BackWall", Vector3.new(70,18,2), CFrame.new(position + Vector3.new(0,9,-28)), Color3.fromRGB(31,32,40), Enum.Material.Slate)
    local ownerLabel = addBillboard(back, "MUSEU DISPONÍVEL", Vector3.new(0,7,0), UDim2.fromOffset(360,80))

    local accent = makePart(model, "Accent", Vector3.new(28,1.2,8), CFrame.new(position + Vector3.new(0,1,23)), Color3.fromRGB(91,62,170), Enum.Material.Neon)
    addBillboard(accent, "EXPOSIÇÃO DE RELÍQUIAS", Vector3.new(0,3,0), UDim2.fromOffset(260,55))

    local pedestals = {}
    local slot = 0
    for row=1,3 do
        for col=1,4 do
            slot += 1
            local x = -24 + (col-1)*16
            local z = -13 + (row-1)*14
            local pedestal = makePart(model, "Pedestal"..slot, Vector3.new(7,2.4,7), CFrame.new(position + Vector3.new(x,1.7,z)), Color3.fromRGB(80,82,94), Enum.Material.Marble)
            pedestal:SetAttribute("MuseumSlot", slot)
            pedestals[slot] = pedestal

            local prompt = Instance.new("ProximityPrompt")
            prompt.Name = "MuseumPrompt"
            prompt.ActionText = "EXIBIR / REMOVER"
            prompt.ObjectText = "Pedestal "..slot
            prompt.HoldDuration = 0.35
            prompt.MaxActivationDistance = 10
            prompt.Parent = pedestal

            prompt.Triggered:Connect(function(player)
                if playerPlot[player] ~= index then
                    return
                end
                local profile = deps.data.get(player)
                if not profile then return end
                profile.museumSlots = profile.museumSlots or {}
                local key = tostring(slot)
                if profile.museumSlots[key] then
                    profile.museumSlots[key] = nil
                    refreshSlot(player, slot)
                    if deps.notify then deps.notify(player, "Item removido do pedestal.") end
                else
                    local item = bestUndisplayed(profile)
                    if not item then
                        if deps.notify then deps.notify(player, "Você não tem relíquia livre para exibir.") end
                        return
                    end
                    profile.museumSlots[key] = item.uid
                    refreshSlot(player, slot)
                    if deps.notify then deps.notify(player, item.relicName .. " foi colocado no museu.") end
                end
                deps.data.savePlayer(player)
                if deps.sync then deps.sync(player) end
            end)
        end
    end

    return {
        model = model,
        floor = floor,
        ownerLabel = ownerLabel,
        pedestals = pedestals,
        owner = nil,
        position = position,
    }
end

function MuseumService.init(d, worldFolder)
    deps = d
    rootFolder = Instance.new("Folder")
    rootFolder.Name = "PlayerMuseums"
    rootFolder.Parent = worldFolder or workspace

    for i=1,MAX_PLOTS do
        plots[i] = buildPlot(i, PLOT_POSITIONS[i])
    end
end

function MuseumService.assign(player)
    if playerPlot[player] then return playerPlot[player] end
    for i=1,MAX_PLOTS do
        if not plots[i].owner then
            plots[i].owner = player
            playerPlot[player] = i
            updateOwnerSign(plots[i], player)

            local profile = deps.data.get(player)
            if profile then
                profile.museumSlots = profile.museumSlots or {}
                for slot=1,SLOTS_PER_PLOT do refreshSlot(player, slot) end
            end
            return i
        end
    end
    return nil
end

function MuseumService.release(player)
    local idx = playerPlot[player]
    if not idx then return end
    local plot = plots[idx]
    if plot then
        for slot=1,SLOTS_PER_PLOT do
            clearPedestalVisual(plot.pedestals[slot])
        end
        plot.owner = nil
        updateOwnerSign(plot, nil)
    end
    playerPlot[player] = nil
end

function MuseumService.getPlotIndex(player)
    return playerPlot[player]
end

function MuseumService.getMuseumScore(player)
    local profile = deps.data.get(player)
    if not profile then return 0 end
    local total = 0
    for _,uid in pairs(profile.museumSlots or {}) do
        local item = profile.inventory and profile.inventory[uid]
        if item then
            total += math.log10(math.max(10, item.combinedOneIn or 1)) * 100
            if (item.serial or 9999) <= 10 then total += 250 end
        end
    end
    return math.floor(total)
end

return MuseumService
