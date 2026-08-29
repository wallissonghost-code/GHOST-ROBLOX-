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
    Vector3.new(-110, 0, 105), Vector3.new(0, 0, 118), Vector3.new(110, 0, 105),
    Vector3.new(-118, 0, 0), Vector3.new(118, 0, 0),
    Vector3.new(-110, 0, -105), Vector3.new(0, 0, -125), Vector3.new(110, 0, -105),
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

local function surfaceSign(part, text, face)
    local gui = Instance.new("SurfaceGui")
    gui.Name = "MuseumSurfaceSign"
    gui.Face = face or Enum.NormalId.Front
    gui.AlwaysOnTop = false
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = 32
    gui.Parent = part

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1,1)
    label.BackgroundColor3 = Color3.fromRGB(14,14,20)
    label.BackgroundTransparency = 0.08
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.GothamBlack
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
        elseif obj:IsA("ProximityPrompt") or obj:IsA("ClickDetector") then
            obj:Destroy()
        elseif obj:IsA("Tool") then
            obj.Enabled = false
            obj.CanBeDropped = false
            obj.RequiresHandle = false
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
    local anchor = firstBasePart(model)
    if not anchor then return end

    local colors = {
        Normal=Color3.fromRGB(220,220,225),
        Shiny=Color3.fromRGB(255,225,85),
        Corrupted=Color3.fromRGB(175,35,45),
        Glitched=Color3.fromRGB(185,65,255),
        Celestial=Color3.fromRGB(130,215,255),
        Singularity=Color3.fromRGB(75,25,120),
    }
    local fxColor = colors[item.mutationName] or Color3.new(1,1,1)

    local highlight = Instance.new("Highlight")
    highlight.Name = "MutationHighlight"
    highlight.FillTransparency = item.mutationName == "Normal" and 1 or 0.82
    highlight.OutlineTransparency = 0.1
    highlight.OutlineColor = fxColor
    highlight.Adornee = model
    highlight.Parent = model

    if item.mutationName ~= "Normal" then
        local light = Instance.new("PointLight")
        light.Color = fxColor
        light.Range = 12
        light.Brightness = 1.1
        light.Parent = anchor
    end
end

local function normalizeModel(model, targetCFrame, desiredMaxSize)
    if not model:IsA("Model") then
        local wrap = Instance.new("Model")
        model.Parent = wrap
        model = wrap
    end
    sanitize(model)
    if not firstBasePart(model) then return nil end

    local ok, size = pcall(function()
        local _, s = model:GetBoundingBox()
        return s
    end)
    if ok and size then
        local largest = math.max(size.X, size.Y, size.Z)
        if largest > 0 then
            pcall(function() model:ScaleTo(desiredMaxSize / largest) end)
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
            local visual = normalizeModel(inserted, targetCFrame, 7.2 * (entry.scale or 1))
            if visual then
                visual.Name = "CreatorStore_" .. item.relicId
                applyMutationVisual(visual, item)
                return visual
            end
            inserted:Destroy()
        end
    end

    local fallback = RelicModelBuilder.build(item)
    fallback.Name = "Fallback_" .. item.relicId
    pcall(function() fallback:ScaleTo(1.15) end)
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

local function compactOdds(n)
    n = tonumber(n) or 1
    if n >= 1e9 then return string.format("%.1fB",n/1e9) end
    if n >= 1e6 then return string.format("%.1fM",n/1e6) end
    if n >= 1e3 then return string.format("%.1fK",n/1e3) end
    return tostring(math.floor(n))
end

local function displayItemOnPedestal(plot, slotIndex, item)
    local pedestal = plot.pedestals[slotIndex]
    if not pedestal then return end
    clearPedestalVisual(pedestal)

    local holder = Instance.new("Model")
    holder.Name = "Display_" .. pedestal.Name
    holder.Parent = plot.model

    local visual = buildVisual(item, pedestal.CFrame * CFrame.new(0, 5.2, 0) * CFrame.Angles(0, math.rad(25), 0))
    visual.Parent = holder

    local gui = Instance.new("BillboardGui")
    gui.Name = "ItemLabel"
    gui.Adornee = pedestal
    gui.Size = UDim2.fromOffset(180, 56)
    gui.StudsOffset = Vector3.new(0, 8.2, 0)
    gui.MaxDistance = 55
    gui.AlwaysOnTop = false
    gui.Parent = pedestal

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1,1)
    label.BackgroundColor3 = Color3.fromRGB(12,12,18)
    label.BackgroundTransparency = 0.16
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextWrapped = true
    label.Text = string.format("%s [%s]\n#%04d  •  1/%s", item.relicName, item.mutationName, item.serial, compactOdds(item.combinedOneIn))
    label.Parent = gui
end

local function displayedSet(profile)
    local set = {}
    profile.museumSlots = profile.museumSlots or {}
    for _, uid in pairs(profile.museumSlots) do if uid then set[uid] = true end end
    return set
end

local function bestUndisplayed(profile)
    local used = displayedSet(profile)
    local best
    for uid, item in pairs(profile.inventory or {}) do
        if not item.listed and not used[uid] then
            if not best or (item.combinedOneIn or 1) > (best.combinedOneIn or 1) then best = item end
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
    plot.ownerLabel.Text = player and ("MUSEU DE\n" .. string.upper(player.DisplayName)) or "MUSEU\nDISPONÍVEL"
end

local function buildPlot(index, position)
    local model = Instance.new("Model")
    model.Name = "MuseumPlot" .. index
    model.Parent = rootFolder

    local floor = makePart(model,"Floor",Vector3.new(76,1,64),CFrame.new(position + Vector3.new(0,0.5,0)),Color3.fromRGB(48,49,56),Enum.Material.Marble)
    makePart(model,"FloorBorder",Vector3.new(80,0.35,68),CFrame.new(position + Vector3.new(0,0.2,0)),Color3.fromRGB(91,62,170),Enum.Material.Neon)

    local back = makePart(model,"BackWall",Vector3.new(76,20,2),CFrame.new(position + Vector3.new(0,10,-31)),Color3.fromRGB(28,29,36),Enum.Material.Slate)
    makePart(model,"LeftWall",Vector3.new(2,16,64),CFrame.new(position + Vector3.new(-37,8,0)),Color3.fromRGB(34,35,43),Enum.Material.Slate)
    makePart(model,"RightWall",Vector3.new(2,16,64),CFrame.new(position + Vector3.new(37,8,0)),Color3.fromRGB(34,35,43),Enum.Material.Slate)

    makePart(model,"RoofBeamBack",Vector3.new(76,2,3),CFrame.new(position + Vector3.new(0,19,-30)),Color3.fromRGB(82,58,145),Enum.Material.Metal)
    makePart(model,"RoofBeamFront",Vector3.new(76,2,3),CFrame.new(position + Vector3.new(0,19,30)),Color3.fromRGB(82,58,145),Enum.Material.Metal)
    makePart(model,"RoofBeamLeft",Vector3.new(3,2,60),CFrame.new(position + Vector3.new(-36,19,0)),Color3.fromRGB(82,58,145),Enum.Material.Metal)
    makePart(model,"RoofBeamRight",Vector3.new(3,2,60),CFrame.new(position + Vector3.new(36,19,0)),Color3.fromRGB(82,58,145),Enum.Material.Metal)

    local ownerBoard = makePart(model,"OwnerBoard",Vector3.new(30,8,1),CFrame.new(position + Vector3.new(0,14,-29.8)),Color3.fromRGB(18,18,24),Enum.Material.SmoothPlastic)
    local ownerLabel = surfaceSign(ownerBoard,"MUSEU DISPONÍVEL",Enum.NormalId.Front)

    local entrance = makePart(model,"EntranceSign",Vector3.new(28,5,1),CFrame.new(position + Vector3.new(0,4.5,30.8)),Color3.fromRGB(28,22,42),Enum.Material.SmoothPlastic)
    surfaceSign(entrance,"EXPOSIÇÃO DE RELÍQUIAS",Enum.NormalId.Back)

    local pedestals = {}
    local slot = 0
    for row=1,3 do
        for col=1,4 do
            slot += 1
            local x = -25.5 + (col-1)*17
            local z = -15 + (row-1)*15

            local base = makePart(model,"PedestalBase"..slot,Vector3.new(9,1,9),CFrame.new(position + Vector3.new(x,1.0,z)),Color3.fromRGB(60,61,70),Enum.Material.Marble)
            local pedestal = makePart(model,"Pedestal"..slot,Vector3.new(6.8,4.2,6.8),CFrame.new(position + Vector3.new(x,3.5,z)),Color3.fromRGB(88,90,104),Enum.Material.Marble)
            makePart(model,"PedestalTop"..slot,Vector3.new(7.6,0.55,7.6),CFrame.new(position + Vector3.new(x,5.8,z)),Color3.fromRGB(120,122,140),Enum.Material.Metal)

            pedestal:SetAttribute("MuseumSlot",slot)
            pedestals[slot]=pedestal

            local prompt = Instance.new("ProximityPrompt")
            prompt.Name="MuseumPrompt"
            prompt.ActionText="EXIBIR / REMOVER"
            prompt.ObjectText="Pedestal "..slot
            prompt.HoldDuration=0.25
            prompt.MaxActivationDistance=9
            prompt.Parent=pedestal

            prompt.Triggered:Connect(function(player)
                if playerPlot[player] ~= index then return end
                local profile = deps.data.get(player)
                if not profile then return end

                profile.museumSlots = profile.museumSlots or {}
                local key = tostring(slot)
                if profile.museumSlots[key] then
                    profile.museumSlots[key] = nil
                    refreshSlot(player,slot)
                    if deps.notify then deps.notify(player,"Item removido do pedestal.") end
                else
                    local item = bestUndisplayed(profile)
                    if not item then
                        if deps.notify then deps.notify(player,"Você não tem relíquia livre para exibir.") end
                        return
                    end
                    profile.museumSlots[key] = item.uid
                    refreshSlot(player,slot)
                    if deps.notify then deps.notify(player,item.relicName.." foi colocado no museu.") end
                end
                deps.data.savePlayer(player)
            end)
        end
    end

    return {
        model=model,
        floor=floor,
        ownerLabel=ownerLabel,
        pedestals=pedestals,
        owner=nil,
        position=position,
    }
end

function MuseumService.init(d, worldFolder)
    deps = d
    rootFolder = Instance.new("Folder")
    rootFolder.Name = "PlayerMuseums"
    rootFolder.Parent = worldFolder or workspace
    for i=1,MAX_PLOTS do plots[i] = buildPlot(i,PLOT_POSITIONS[i]) end
end

function MuseumService.assign(player)
    if playerPlot[player] then return playerPlot[player] end
    for i=1,MAX_PLOTS do
        if not plots[i].owner then
            plots[i].owner = player
            playerPlot[player] = i
            updateOwnerSign(plots[i],player)
            local profile = deps.data.get(player)
            if profile then
                profile.museumSlots = profile.museumSlots or {}
                for slot=1,SLOTS_PER_PLOT do refreshSlot(player,slot) end
            end
            return i
        end
    end
end

function MuseumService.release(player)
    local idx = playerPlot[player]
    if not idx then return end
    local plot = plots[idx]
    if plot then
        for slot=1,SLOTS_PER_PLOT do clearPedestalVisual(plot.pedestals[slot]) end
        plot.owner=nil
        updateOwnerSign(plot,nil)
    end
    playerPlot[player]=nil
end

function MuseumService.getPlotIndex(player) return playerPlot[player] end

function MuseumService.getMuseumScore(player)
    local profile = deps.data.get(player)
    if not profile then return 0 end
    local total=0
    for _,uid in pairs(profile.museumSlots or {}) do
        local item = profile.inventory and profile.inventory[uid]
        if item then
            total += math.log10(math.max(10,item.combinedOneIn or 1))*100
            if (item.serial or 9999)<=10 then total += 250 end
        end
    end
    return math.floor(total)
end

return MuseumService
