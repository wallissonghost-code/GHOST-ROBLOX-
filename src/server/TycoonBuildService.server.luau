local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local InsertService = game:GetService("InsertService")
local ServerScriptService = game:GetService("ServerScriptService")

local Catalog = require(ServerScriptService:WaitForChild("PremiumAssetCatalog"))
local world = workspace:WaitForChild("OpenWorldMilitary")
local basesFolder = world:WaitForChild("Bases")
local store = DataStoreService:GetDataStore("PremiumBaseTycoon_v1")

local profiles = {}
local activeByBase = {}

local GROUND_Y = 0

local NODES = {
    {id="OfficerQuarters", name="ALOJAMENTO", cost=650, income=20, offset=Vector3.new(-36,0,-12), requires=nil},
    {id="Barracks", name="QUARTEL", cost=1600, income=35, offset=Vector3.new(34,0,-14), requires="OfficerQuarters"},
    {id="CommandHQ", name="CENTRO DE COMANDO", cost=4200, income=60, offset=Vector3.new(0,0,-24), requires="Barracks"},
    {id="AdminBuilding", name="INTEL / ADMIN", cost=8500, income=95, offset=Vector3.new(-34,0,18), requires="CommandHQ"},
    {id="Airbase", name="HANGAR", cost=18000, income=160, offset=Vector3.new(36,0,18), requires="AdminBuilding"},
    {id="MilitaryCompound", name="COMPLEXO MILITAR", cost=42000, income=300, offset=Vector3.new(0,0,8), requires="Airbase"},
}

local function defaultData()
    return {coins=0, bank=0, purchased={}}
end

local function baseGroundPosition(base)
    local pivot = base:GetPivot().Position
    return Vector3.new(pivot.X, GROUND_Y, pivot.Z)
end

local function groundModelAt(model, target)
    -- First align the model horizontally. Then use its real bounding box to place
    -- the lowest visible geometry directly on the base floor.
    pcall(function()
        model:PivotTo(CFrame.new(target.X, target.Y, target.Z))
    end)

    local ok, boxCf, boxSize = pcall(function()
        return model:GetBoundingBox()
    end)
    if not ok or not boxCf or not boxSize then return end

    local bottomY = boxCf.Position.Y - (boxSize.Y / 2)
    local deltaY = (GROUND_Y + 0.05) - bottomY
    pcall(function()
        model:PivotTo(model:GetPivot() + Vector3.new(0, deltaY, 0))
    end)
end

local function loadPlayer(player)
    local data
    pcall(function() data = store:GetAsync("p_"..player.UserId) end)
    if type(data) ~= "table" then data = defaultData() end
    data.coins = tonumber(data.coins) or 0
    data.bank = tonumber(data.bank) or 0
    if type(data.purchased) ~= "table" then data.purchased = {} end
    profiles[player] = data
    player:SetAttribute("TycoonCoins", data.coins)
    player:SetAttribute("TycoonBank", data.bank)
end

local function savePlayer(player)
    local data = profiles[player]
    if not data then return end
    pcall(function() store:SetAsync("p_"..player.UserId, data) end)
end

local function incomePerSecond(player)
    local data = profiles[player]
    if not data then return 60 end
    local total = 60
    for _,node in ipairs(NODES) do
        if data.purchased[node.id] then total += node.income end
    end
    return total
end

local function sanitize(root)
    for _,obj in ipairs(root:GetDescendants()) do
        if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") or obj:IsA("ProximityPrompt") or obj:IsA("ClickDetector") then
            obj:Destroy()
        elseif obj:IsA("BasePart") then
            obj.Anchored = true
            obj.CanTouch = false
        end
    end
end

local function fallbackBuilding(name, color)
    local m = Instance.new("Model") m.Name = name
    local floor = Instance.new("Part") floor.Name="Floor" floor.Size=Vector3.new(28,1,20) floor.Position=Vector3.new(0,0.5,0) floor.Anchored=true floor.Material=Enum.Material.Concrete floor.Color=color floor.Parent=m
    for _,entry in ipairs({
        {Vector3.new(28,9,1),Vector3.new(0,5,-9.5)},
        {Vector3.new(28,9,1),Vector3.new(0,5,9.5)},
        {Vector3.new(1,9,20),Vector3.new(-13.5,5,0)},
        {Vector3.new(1,9,20),Vector3.new(13.5,5,0)},
    }) do
        local p=Instance.new("Part") p.Size=entry[1] p.Position=entry[2] p.Anchored=true p.Material=Enum.Material.Metal p.Color=color p.Parent=m
    end
    local roof=Instance.new("Part") roof.Size=Vector3.new(30,1,22) roof.Position=Vector3.new(0,10,0) roof.Anchored=true roof.Material=Enum.Material.Metal roof.Color=color:Lerp(Color3.new(0,0,0),0.2) roof.Parent=m
    m.PrimaryPart=floor
    return m
end

local function loadVisual(assetKey)
    local cfg = Catalog[assetKey]
    if not cfg then return fallbackBuilding(assetKey, Color3.fromRGB(75,82,75)) end
    local ok,container = pcall(function() return InsertService:LoadAsset(cfg.assetId) end)
    if not ok or not container then return fallbackBuilding(assetKey, Color3.fromRGB(75,82,75)) end
    sanitize(container)

    local parts = {}
    for _,obj in ipairs(container:GetDescendants()) do if obj:IsA("BasePart") then table.insert(parts,obj) end end
    if #parts == 0 then container:Destroy() return fallbackBuilding(assetKey, Color3.fromRGB(75,82,75)) end

    local model = Instance.new("Model") model.Name = assetKey
    for _,child in ipairs(container:GetChildren()) do child.Parent = model end
    container:Destroy()
    sanitize(model)

    local okBox,_,size = pcall(function() return model:GetBoundingBox() end)
    if okBox and size then
        local longest = math.max(size.X,size.Y,size.Z)
        if longest > 0 then pcall(function() model:ScaleTo(math.min(1,cfg.maxSize/longest)) end) end
    end
    return model
end

local function addText(partObj, text, color)
    local gui=Instance.new("BillboardGui") gui.Size=UDim2.fromOffset(190,52) gui.StudsOffset=Vector3.new(0,3.3,0) gui.AlwaysOnTop=true gui.MaxDistance=55 gui.Parent=partObj
    local label=Instance.new("TextLabel") label.Size=UDim2.fromScale(1,1) label.BackgroundColor3=Color3.fromRGB(20,24,28) label.BackgroundTransparency=0.12 label.TextColor3=color label.TextScaled=true label.Font=Enum.Font.GothamBlack label.Text=text label.Parent=gui
end

local function makePad(parent, base, node, index)
    local pad=Instance.new("Part") pad.Name="TycoonPad_"..node.id pad.Size=Vector3.new(9,0.7,9) pad.Anchored=true pad.Material=Enum.Material.Neon pad.Color=Color3.fromRGB(25,235,65)
    local basePos = baseGroundPosition(base)
    pad.Position = basePos + Vector3.new(-50 + ((index-1)%3)*18, 0.38, 39 - math.floor((index-1)/3)*14)
    pad.Parent=parent
    pad:SetAttribute("NodeId",node.id)
    pad:SetAttribute("Cost",node.cost)
    addText(pad,node.name.."\n$"..node.cost,Color3.fromRGB(160,255,175))
    return pad
end

local function makeCollector(parent, base)
    local basePos=baseGroundPosition(base)
    local console=Instance.new("Part") console.Name="TycoonCollector" console.Size=Vector3.new(10,8,5) console.Position=basePos+Vector3.new(-57,4,23) console.Anchored=true console.Material=Enum.Material.Metal console.Color=Color3.fromRGB(40,46,50) console.Parent=parent
    local screen=Instance.new("SurfaceGui") screen.Face=Enum.NormalId.Front screen.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud screen.PixelsPerStud=35 screen.Parent=console
    local text=Instance.new("TextLabel") text.Name="BankText" text.Size=UDim2.fromScale(1,1) text.BackgroundColor3=Color3.fromRGB(0,145,35) text.TextColor3=Color3.new(1,1,1) text.Font=Enum.Font.GothamBlack text.TextScaled=true text.Text="MOEDAS\n$0" text.Parent=screen
    local collect=Instance.new("Part") collect.Name="CollectPad" collect.Size=Vector3.new(9,0.6,8) collect.Position=basePos+Vector3.new(-57,0.32,31) collect.Anchored=true collect.Material=Enum.Material.Neon collect.Color=Color3.fromRGB(20,240,55) collect.Parent=parent
    addText(collect,"COLETAR",Color3.fromRGB(160,255,175))
    return console,collect,text
end

local function renderPurchased(player, base, tycoonFolder)
    local data=profiles[player] if not data then return end
    local visuals=tycoonFolder:FindFirstChild("Purchased") or Instance.new("Folder") visuals.Name="Purchased" visuals.Parent=tycoonFolder
    visuals:ClearAllChildren()
    local basePos = baseGroundPosition(base)
    for _,node in ipairs(NODES) do
        if data.purchased[node.id] then
            local model=loadVisual(node.id)
            model.Parent=visuals
            local target=basePos+node.offset
            groundModelAt(model,target)
        end
    end
end

local function refreshPads(player, base, tycoonFolder)
    local pads=tycoonFolder:FindFirstChild("Pads") or Instance.new("Folder") pads.Name="Pads" pads.Parent=tycoonFolder
    pads:ClearAllChildren()
    local data=profiles[player] if not data then return end
    local visibleIndex=0
    for _,node in ipairs(NODES) do
        local unlocked=(not node.requires) or data.purchased[node.requires]
        if unlocked and not data.purchased[node.id] then
            visibleIndex+=1
            local pad=makePad(pads,base,node,visibleIndex)
            local debounce={}
            pad.Touched:Connect(function(hit)
                local char=hit:FindFirstAncestorOfClass("Model")
                local p=char and Players:GetPlayerFromCharacter(char)
                if p~=player or debounce[p] then return end
                debounce[p]=true
                local d=profiles[p]
                if d and not d.purchased[node.id] and d.coins>=node.cost then
                    d.coins-=node.cost
                    d.purchased[node.id]=true
                    p:SetAttribute("TycoonCoins",d.coins)
                    renderPurchased(p,base,tycoonFolder)
                    refreshPads(p,base,tycoonFolder)
                    task.spawn(savePlayer,p)
                end
                task.delay(0.6,function() debounce[p]=nil end)
            end)
        end
    end
end

local function setupBaseForPlayer(player, base)
    if activeByBase[base] == player then return end
    if activeByBase[base] and activeByBase[base] ~= player then return end
    activeByBase[base]=player
    local old=base:FindFirstChild("PremiumTycoon") if old then old:Destroy() end
    local folder=Instance.new("Folder") folder.Name="PremiumTycoon" folder.Parent=base
    local console,collect,bankText=makeCollector(folder,base)
    renderPurchased(player,base,folder)
    refreshPads(player,base,folder)

    local debounce=false
    collect.Touched:Connect(function(hit)
        if debounce then return end
        local char=hit:FindFirstAncestorOfClass("Model")
        local p=char and Players:GetPlayerFromCharacter(char)
        if p~=player then return end
        debounce=true
        local d=profiles[player]
        if d and d.bank>0 then
            d.coins+=math.floor(d.bank)
            d.bank=0
            player:SetAttribute("TycoonCoins",d.coins)
            player:SetAttribute("TycoonBank",0)
            bankText.Text="MOEDAS\n$0"
            task.spawn(savePlayer,player)
        end
        task.delay(0.5,function() debounce=false end)
    end)
end

local function watchAssignment(player)
    local function apply()
        local id=player:GetAttribute("BaseId") or 0
        if id<=0 then return end
        local base=basesFolder:FindFirstChild("Base"..id)
        if base and (base:GetAttribute("OwnerUserId") or 0)==player.UserId then setupBaseForPlayer(player,base) end
    end
    player:GetAttributeChangedSignal("BaseId"):Connect(function() task.delay(0.25,apply) end)
    task.delay(0.8,apply)
end

Players.PlayerAdded:Connect(function(player)
    loadPlayer(player)
    watchAssignment(player)
end)
Players.PlayerRemoving:Connect(function(player)
    savePlayer(player)
    profiles[player]=nil
    for base,owner in pairs(activeByBase) do if owner==player then activeByBase[base]=nil local t=base:FindFirstChild("PremiumTycoon") if t then t:Destroy() end end end
end)
for _,player in ipairs(Players:GetPlayers()) do loadPlayer(player) watchAssignment(player) end

task.spawn(function()
    while true do
        task.wait(1)
        for player,data in pairs(profiles) do
            if player.Parent and (player:GetAttribute("BaseId") or 0)>0 then
                data.bank += incomePerSecond(player)
                player:SetAttribute("TycoonBank",math.floor(data.bank))
                local id=player:GetAttribute("BaseId")
                local base=basesFolder:FindFirstChild("Base"..id)
                local tycoon=base and base:FindFirstChild("PremiumTycoon")
                local collector=tycoon and tycoon:FindFirstChild("TycoonCollector")
                local gui=collector and collector:FindFirstChildOfClass("SurfaceGui")
                local label=gui and gui:FindFirstChild("BankText")
                if label then label.Text="MOEDAS\n$"..math.floor(data.bank).."\n$"..incomePerSecond(player).."/s" end
            end
        end
    end
end)

game:BindToClose(function() for p in pairs(profiles) do savePlayer(p) end end)
