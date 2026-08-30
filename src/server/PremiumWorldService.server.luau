local Players = game:GetService("Players")
local InsertService = game:GetService("InsertService")
local ServerScriptService = game:GetService("ServerScriptService")

local Catalog = require(ServerScriptService:WaitForChild("PremiumAssetCatalog"))
local world = workspace:WaitForChild("OpenWorldMilitary")

local visualsRoot = workspace:FindFirstChild("PremiumVisuals") or Instance.new("Folder")
visualsRoot.Name = "PremiumVisuals"
visualsRoot.Parent = workspace

local templateCache = {}

local function sanitize(root, mode)
    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript")
            or obj:IsA("ProximityPrompt") or obj:IsA("ClickDetector") then
            obj:Destroy()
        elseif obj:IsA("BasePart") then
            obj.CanTouch = false
            if mode == "vehicle" or mode == "weapon" then
                obj.Anchored = false
                obj.CanCollide = false
                obj.Massless = true
            else
                obj.Anchored = true
            end
        elseif obj:IsA("Sound") and mode ~= "world" then
            obj:Destroy()
        end
    end
end

local function wrapContainer(container, name)
    local model = Instance.new("Model")
    model.Name = name
    for _, child in ipairs(container:GetChildren()) do
        child.Parent = model
    end
    container:Destroy()
    return model
end

local function loadTemplate(key)
    if templateCache[key] then
        return templateCache[key]
    end
    local cfg = Catalog[key]
    if not cfg then return nil end
    local ok, container = pcall(function()
        return InsertService:LoadAsset(cfg.assetId)
    end)
    if not ok or not container then return nil end
    local model = wrapContainer(container, "Template_" .. key)
    sanitize(model, "world")
    local hasPart = false
    for _, obj in ipairs(model:GetDescendants()) do
        if obj:IsA("BasePart") then hasPart = true break end
    end
    if not hasPart then model:Destroy() return nil end

    local okBox, _, size = pcall(function() return model:GetBoundingBox() end)
    if okBox and size then
        local longest = math.max(size.X, size.Y, size.Z)
        if longest > 0 and cfg.maxSize then
            local factor = math.min(1, cfg.maxSize / longest)
            pcall(function() model:ScaleTo(factor) end)
        end
    end
    model.Parent = nil
    templateCache[key] = model
    return model
end

local function cloneAsset(key, mode)
    local template = loadTemplate(key)
    if not template then return nil end
    local clone = template:Clone()
    sanitize(clone, mode or "world")
    return clone
end

local function groundPlace(model, x, z, groundY, yaw)
    model.Parent = visualsRoot
    local okBox, cf, size = pcall(function() return model:GetBoundingBox() end)
    if not okBox then
        model:PivotTo(CFrame.new(x, groundY, z) * CFrame.Angles(0, math.rad(yaw or 0), 0))
        return
    end
    local targetY = groundY + size.Y / 2
    local rotation = CFrame.Angles(0, math.rad(yaw or 0), 0)
    model:PivotTo(CFrame.new(x, targetY, z) * rotation)
    -- second pass compensates unusual pivots / nested offsets
    local _, newCf, newSize = pcall(function() return model:GetBoundingBox() end)
    if newCf and newSize then
        local bottom = newCf.Position.Y - newSize.Y / 2
        model:PivotTo(model:GetPivot() + Vector3.new(0, groundY - bottom, 0))
    end
end

local function hidePrototype(obj)
    if obj:IsA("BasePart") then
        obj.Transparency = 1
        obj.CanCollide = false
        obj.CanTouch = false
        local gui = obj:FindFirstChildOfClass("BillboardGui")
        if gui then gui.Enabled = false end
    end
end

local function hideNamedVisuals(folder, prefixes, except)
    if not folder then return end
    for _, obj in ipairs(folder:GetDescendants()) do
        local keep = except and except[obj.Name]
        if not keep then
            for _, prefix in ipairs(prefixes) do
                if string.sub(obj.Name, 1, #prefix) == prefix then
                    hidePrototype(obj)
                    break
                end
            end
        end
    end
end

local function installWorldVisuals()
    visualsRoot:ClearAllChildren()

    local city = world:FindFirstChild("City")
    hideNamedVisuals(city, {"Tower", "Bank", "Garage", "SupplyShop", "PoliceStation"}, {
        BankVault=true, MissionTerminal=true, DeliveryTerminal=true, ConvoyTerminal=true,
        JeepPad=true, PursuitPad=true, MedkitCounter=true,
    })

    local cityPack = cloneAsset("CityPack", "world")
    if cityPack then groundPlace(cityPack, 0, 0, 0.55, 0) end

    local police = cloneAsset("PoliceStation", "world")
    if police then groundPlace(police, -275, 310, 0.55, 180) end

    for i, pos in ipairs({
        Vector3.new(-360,0,220), Vector3.new(355,0,220),
        Vector3.new(-360,0,-220), Vector3.new(355,0,-220),
    }) do
        local house = cloneAsset("ModernHouse", "world")
        if house then groundPlace(house, pos.X, pos.Z, 0.55, i % 2 == 0 and 180 or 0) end
    end

    local airport = world:FindFirstChild("Airport")
    hideNamedVisuals(airport, {"Hangar", "AirTerminal"})
    for i, x in ipairs({-245,-125,125,245}) do
        local hangar = cloneAsset("Hangar", "world")
        if hangar then groundPlace(hangar, x, -735, 0.55, 180) end
    end

    local port = world:FindFirstChild("Port")
    if port then
        for i, pos in ipairs({
            Vector3.new(-1015,0,-80),Vector3.new(-980,0,-45),Vector3.new(-1020,0,20),
            Vector3.new(-980,0,65),Vector3.new(-1015,0,120),
        }) do
            local crates = cloneAsset("MilitaryCrates", "world")
            if crates then groundPlace(crates, pos.X, pos.Z, 0.55, (i*35)%180) end
        end
    end

    local bases = world:FindFirstChild("Bases")
    if bases then
        for _, base in ipairs(bases:GetChildren()) do
            local bp = base:GetPivot().Position
            local crates = cloneAsset("MilitaryCrates", "world")
            if crates then groundPlace(crates, bp.X + 50, bp.Z - 35, 0.55, 90) end
        end
    end
end

local vehicleVisualKeys = {
    Jeep = "ArmyJeepVisual",
    Pursuit = "ArmyJeepVisual",
    Armored = "TankVisual",
    Helicopter = "HelicopterVisual",
}

local function vehicleTypeFromName(name)
    for vehicleName in pairs(vehicleVisualKeys) do
        if string.find(name, "_" .. vehicleName, 1, true) then
            return vehicleName
        end
    end
end

local function attachVehicleVisual(model)
    if model:GetAttribute("PremiumVisualAttached") then return end
    local vehicleType = vehicleTypeFromName(model.Name)
    if not vehicleType then return end
    local body = model:FindFirstChild("Body") or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not body then return end
    local visual = cloneAsset(vehicleVisualKeys[vehicleType], "vehicle")
    if not visual then return end
    visual.Name = "PremiumVehicleVisual"
    visual.Parent = model
    local okBox, _, size = pcall(function() return visual:GetBoundingBox() end)
    if okBox and size then
        local target = vehicleType == "Helicopter" and 18 or (vehicleType == "Armored" and 14 or 12)
        local longest = math.max(size.X,size.Y,size.Z)
        if longest > 0 then pcall(function() visual:ScaleTo(target/longest) end) end
    end
    visual:PivotTo(body.CFrame)
    for _, part in ipairs(visual:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = false
            part.CanCollide = false
            part.Massless = true
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = body
            weld.Part1 = part
            weld.Parent = part
        end
    end
    -- Hide the blockout chassis while preserving seat/physics.
    for _, part in ipairs(model:GetChildren()) do
        if part:IsA("BasePart") and part ~= body and not part:IsA("VehicleSeat") then
            part.Transparency = 1
        end
    end
    body.Transparency = 1
    model:SetAttribute("PremiumVisualAttached", true)
end

local function attachWeaponVisual(tool)
    if not tool:IsA("Tool") or tool:GetAttribute("PremiumVisualAttached") then return end
    local lower = string.lower(tool.Name)
    local key
    if string.find(lower, "rifle") or string.find(lower, "fuzil") then
        key = "RifleVisual"
    elseif string.find(lower, "pistol") or string.find(lower, "gun") then
        key = "AssaultRifleVisual"
    end
    if not key then return end
    local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
    if not handle then return end
    local visual = cloneAsset(key, "weapon")
    if not visual then return end
    visual.Name = "PremiumWeaponVisual"
    visual.Parent = tool
    local okBox, _, size = pcall(function() return visual:GetBoundingBox() end)
    if okBox and size then
        local longest = math.max(size.X,size.Y,size.Z)
        if longest > 0 then pcall(function() visual:ScaleTo(4.8/longest) end) end
    end
    visual:PivotTo(handle.CFrame * CFrame.Angles(0, math.rad(90), 0))
    for _, part in ipairs(visual:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = false
            part.CanCollide = false
            part.Massless = true
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = handle
            weld.Part1 = part
            weld.Parent = part
        end
    end
    handle.Transparency = 1
    tool:SetAttribute("PremiumVisualAttached", true)
end

local function watchPlayer(player)
    local function scan(container)
        if not container then return end
        for _, obj in ipairs(container:GetChildren()) do attachWeaponVisual(obj) end
        container.ChildAdded:Connect(function(obj) task.defer(attachWeaponVisual, obj) end)
    end
    task.spawn(function()
        scan(player:WaitForChild("Backpack"))
        player.CharacterAdded:Connect(function(char) scan(char) end)
        if player.Character then scan(player.Character) end
    end)
end

installWorldVisuals()

workspace.ChildAdded:Connect(function(obj)
    if obj:IsA("Model") then task.delay(0.4, attachVehicleVisual, obj) end
end)
for _, obj in ipairs(workspace:GetChildren()) do
    if obj:IsA("Model") then task.defer(attachVehicleVisual, obj) end
end

Players.PlayerAdded:Connect(watchPlayer)
for _, player in ipairs(Players:GetPlayers()) do watchPlayer(player) end
