local Players=game:GetService("Players")
local DataStoreService=game:GetService("DataStoreService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Config=require(ReplicatedStorage:WaitForChild("GameConfig"))

local store=DataStoreService:GetDataStore("OpenWorldMilitary_v1")
local profiles={}
local baseOwners={}
local lastHeist={}

local function defaultProfile()
    return {cash=Config.START_CASH,baseLevel=0,wanted=0,missions=0}
end
local function loadProfile(player)
    local data
    pcall(function() data=store:GetAsync("p_"..player.UserId) end)
    if type(data)~="table" then data=defaultProfile() end
    data.cash=tonumber(data.cash) or Config.START_CASH
    data.baseLevel=tonumber(data.baseLevel) or 0
    data.wanted=tonumber(data.wanted) or 0
    data.missions=tonumber(data.missions) or 0
    profiles[player]=data
    player:SetAttribute("Cash",data.cash)
    player:SetAttribute("Wanted",data.wanted)
    player:SetAttribute("BaseLevel",data.baseLevel)
    player:SetAttribute("BaseId",0)
end
local function saveProfile(player)
    local data=profiles[player]
    if not data then return end
    pcall(function() store:SetAsync("p_"..player.UserId,data) end)
end
local function sync(player)
    local d=profiles[player] if not d then return end
    player:SetAttribute("Cash",d.cash)
    player:SetAttribute("Wanted",d.wanted)
    player:SetAttribute("BaseLevel",d.baseLevel)
end
local function addCash(player,amount)
    local d=profiles[player] if not d then return end
    d.cash=math.max(0,d.cash+amount) sync(player)
end
local function setWanted(player,value)
    local d=profiles[player] if not d then return end
    d.wanted=math.clamp(value,0,Config.WANTED_MAX) sync(player)
end
local function claimBase(player,base)
    local id=base:GetAttribute("BaseId")
    if baseOwners[id] and baseOwners[id]~=player then return end
    local oldId=player:GetAttribute("BaseId") or 0
    if oldId>0 then baseOwners[oldId]=nil end
    baseOwners[id]=player player:SetAttribute("BaseId",id)
    local pad=base:FindFirstChild("ClaimPad")
    if pad then
        local gui=pad:FindFirstChildOfClass("BillboardGui")
        if gui and gui:FindFirstChildOfClass("TextLabel") then gui:FindFirstChildOfClass("TextLabel").Text=string.upper(player.DisplayName).." BASE" end
    end
    local char=player.Character
    if char and char.PrimaryPart then char:PivotTo(CFrame.new(base:GetPivot().Position+Vector3.new(0,5,24))) end
end
local function upgradeBase(player)
    local d=profiles[player] if not d then return end
    if (player:GetAttribute("BaseId") or 0)==0 then return end
    if d.baseLevel>=#Config.UPGRADE_COSTS then return end
    local cost=Config.UPGRADE_COSTS[d.baseLevel+1]
    if d.cash<cost then return end
    d.cash-=cost d.baseLevel+=1 sync(player)
end
local function spawnJeep(player)
    local baseId=player:GetAttribute("BaseId") or 0
    local origin=Vector3.new(-82,2,-48)
    if baseId>0 then origin=Config.BASE_POSITIONS[baseId]+Vector3.new(25,2,-3) end
    local model=Instance.new("Model") model.Name=player.Name.."_Jeep" model.Parent=workspace
    local body=Instance.new("Part") body.Size=Vector3.new(7,1.5,11) body.Position=origin body.Color=Color3.fromRGB(48,72,50) body.Material=Enum.Material.Metal body.Anchored=false body.Parent=model
    local seat=Instance.new("VehicleSeat") seat.Size=Vector3.new(2,1,2) seat.Position=origin+Vector3.new(0,1.4,0) seat.Anchored=false seat.MaxSpeed=70 seat.Torque=32000 seat.Parent=model
    local weld=Instance.new("WeldConstraint") weld.Part0=body weld.Part1=seat weld.Parent=body
    model.PrimaryPart=body
end

local function onPrompt(prompt,player)
    local kind=prompt:GetAttribute("ActionKind")
    if kind=="CLAIM" then
        local base=prompt:FindFirstAncestorOfClass("Model") if base then claimBase(player,base) end
    elseif kind=="UPGRADE" then upgradeBase(player)
    elseif kind=="HEIST" then
        local now=os.time() local last=lastHeist[player.UserId] or 0
        if now-last>=Config.HEIST_COOLDOWN then lastHeist[player.UserId]=now addCash(player,Config.HEIST_REWARD) setWanted(player,(profiles[player].wanted or 0)+2) end
    elseif kind=="MISSION" then
        addCash(player,Config.MISSION_REWARD) profiles[player].missions+=1 setWanted(player,math.max(0,(profiles[player].wanted or 0)-1))
    elseif kind=="VEHICLE" then spawnJeep(player) end
end

local function hookPrompts(root)
    for _,obj in ipairs(root:GetDescendants()) do if obj:IsA("ProximityPrompt") then obj.Triggered:Connect(function(player) onPrompt(obj,player) end) end end
    root.DescendantAdded:Connect(function(obj) if obj:IsA("ProximityPrompt") then obj.Triggered:Connect(function(player) onPrompt(obj,player) end) end end)
end

task.spawn(function()
    local world=workspace:WaitForChild("OpenWorldMilitary") hookPrompts(world)
end)

Players.PlayerAdded:Connect(function(player)
    loadProfile(player)
    player.CharacterAdded:Connect(function(char)
        task.wait(0.25)
        local baseId=player:GetAttribute("BaseId") or 0
        if baseId>0 and Config.BASE_POSITIONS[baseId] then char:PivotTo(CFrame.new(Config.BASE_POSITIONS[baseId]+Vector3.new(0,5,25))) end
    end)
end)
Players.PlayerRemoving:Connect(function(player)
    local id=player:GetAttribute("BaseId") or 0 if id>0 and baseOwners[id]==player then baseOwners[id]=nil end
    saveProfile(player) profiles[player]=nil
end)

task.spawn(function()
    while true do
        task.wait(Config.PASSIVE_INTERVAL)
        for player,d in pairs(profiles) do
            if player.Parent and (player:GetAttribute("BaseId") or 0)>0 then
                local income=Config.BASE_INCOME
                if d.baseLevel>0 then income=Config.UPGRADE_INCOME[d.baseLevel] or income end
                addCash(player,income)
            end
        end
    end
end)

task.spawn(function()
    while true do task.wait(35)
        for player,d in pairs(profiles) do if d.wanted>0 then setWanted(player,d.wanted-1) end end
    end
end)

game:BindToClose(function() for player in pairs(profiles) do saveProfile(player) end end)
