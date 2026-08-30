local Players=game:GetService("Players")
local DataStoreService=game:GetService("DataStoreService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local Config=require(ReplicatedStorage:WaitForChild("GameConfig"))

local store=DataStoreService:GetDataStore("OpenWorldMilitary_v2")
local profiles={}
local baseOwners={}
local lastHeist={}
local activeVehicles={}
local policeFolder=workspace:FindFirstChild("PoliceNPCs") or Instance.new("Folder")
policeFolder.Name="PoliceNPCs" policeFolder.Parent=workspace

local function defaultProfile()
    return {cash=Config.START_CASH,baseLevel=0,wanted=0,missions=0,ownedVehicles={Jeep=true}}
end
local function loadProfile(player)
    local data
    pcall(function() data=store:GetAsync("p_"..player.UserId) end)
    if type(data)~="table" then data=defaultProfile() end
    data.cash=tonumber(data.cash) or Config.START_CASH
    data.baseLevel=tonumber(data.baseLevel) or 0
    data.wanted=tonumber(data.wanted) or 0
    data.missions=tonumber(data.missions) or 0
    if type(data.ownedVehicles)~="table" then data.ownedVehicles={Jeep=true} end
    data.ownedVehicles.Jeep=true
    profiles[player]=data
    player:SetAttribute("Cash",data.cash)
    player:SetAttribute("Wanted",data.wanted)
    player:SetAttribute("BaseLevel",data.baseLevel)
    player:SetAttribute("BaseId",0)
    player:SetAttribute("Missions",data.missions)
end
local function saveProfile(player)
    local data=profiles[player] if not data then return end
    pcall(function() store:SetAsync("p_"..player.UserId,data) end)
end
local function sync(player)
    local d=profiles[player] if not d then return end
    player:SetAttribute("Cash",d.cash)
    player:SetAttribute("Wanted",d.wanted)
    player:SetAttribute("BaseLevel",d.baseLevel)
    player:SetAttribute("Missions",d.missions)
end
local function addCash(player,amount)
    local d=profiles[player] if not d then return false end
    d.cash=math.max(0,d.cash+amount) sync(player) return true
end
local function spendCash(player,amount)
    local d=profiles[player] if not d or d.cash<amount then return false end
    d.cash-=amount sync(player) return true
end
local function setWanted(player,value)
    local d=profiles[player] if not d then return end
    d.wanted=math.clamp(value,0,Config.WANTED_MAX) sync(player)
end

local function updateBaseVisual(base,level)
    for _,obj in ipairs(base:GetDescendants()) do
        if obj:IsA("BasePart") then
            local required=obj:GetAttribute("RequiredLevel")
            if required~=nil then
                local visible=level>=required
                obj.Transparency=visible and 0 or 1
                obj.CanCollide=visible
                local pr=obj:FindFirstChildOfClass("ProximityPrompt")
                if pr then pr.Enabled=visible end
            end
        end
    end
    base:SetAttribute("CurrentLevel",level)
end

local function claimBase(player,base)
    local id=base:GetAttribute("BaseId")
    if baseOwners[id] and baseOwners[id]~=player then return end
    local oldId=player:GetAttribute("BaseId") or 0
    if oldId>0 then baseOwners[oldId]=nil end
    baseOwners[id]=player player:SetAttribute("BaseId",id)
    updateBaseVisual(base,profiles[player].baseLevel or 0)
    local pad=base:FindFirstChild("ClaimPad")
    if pad then
        local gui=pad:FindFirstChildOfClass("BillboardGui")
        if gui and gui:FindFirstChildOfClass("TextLabel") then gui:FindFirstChildOfClass("TextLabel").Text=string.upper(player.DisplayName).." BASE" end
    end
    local char=player.Character
    if char then char:PivotTo(CFrame.new(base:GetPivot().Position+Vector3.new(0,5,28))) end
end
local function upgradeBase(player)
    local d=profiles[player] if not d then return end
    local baseId=player:GetAttribute("BaseId") or 0
    if baseId==0 or d.baseLevel>=#Config.UPGRADE_COSTS then return end
    local cost=Config.UPGRADE_COSTS[d.baseLevel+1]
    if not spendCash(player,cost) then return end
    d.baseLevel+=1 sync(player)
    local world=workspace:FindFirstChild("OpenWorldMilitary")
    local bases=world and world:FindFirstChild("Bases")
    local base=bases and bases:FindFirstChild("Base"..baseId)
    if base then updateBaseVisual(base,d.baseLevel) end
end

local function clearVehicle(player)
    local old=activeVehicles[player]
    if old and old.Parent then old:Destroy() end
    activeVehicles[player]=nil
end
local function wheel(model,pos)
    local p=Instance.new("Part") p.Size=Vector3.new(1.2,2.4,2.4) p.Shape=Enum.PartType.Cylinder p.Color=Color3.fromRGB(24,24,24) p.Material=Enum.Material.Rubber p.Position=pos p.Anchored=false p.CanCollide=true p.Parent=model
    p.CFrame=CFrame.new(pos)*CFrame.Angles(0,0,math.rad(90))
    return p
end
local function weld(a,b)
    local w=Instance.new("WeldConstraint") w.Part0=a w.Part1=b w.Parent=a
end
local function createGroundVehicle(player,vehicleName,origin,config)
    local model=Instance.new("Model") model.Name=player.Name.."_"..vehicleName model.Parent=workspace
    local body=Instance.new("Part") body.Name="Body" body.Size=vehicleName=="Armored" and Vector3.new(9,2.5,14) or Vector3.new(7.5,1.8,11.5)
    body.Position=origin body.Color=config.color body.Material=Enum.Material.Metal body.Anchored=false body.Parent=model
    local cabin=Instance.new("Part") cabin.Size=Vector3.new(body.Size.X*0.72,2.2,body.Size.Z*0.48) cabin.Position=origin+Vector3.new(0,2,0.5) cabin.Color=config.color:Lerp(Color3.new(1,1,1),0.1) cabin.Material=Enum.Material.Metal cabin.Anchored=false cabin.Parent=model weld(body,cabin)
    local seat=Instance.new("VehicleSeat") seat.Name="DriverSeat" seat.Size=Vector3.new(2,1,2) seat.Position=origin+Vector3.new(0,1.8,0.4) seat.Anchored=false seat.MaxSpeed=config.maxSpeed seat.Torque=45000 seat.TurnSpeed=1.8 seat.Parent=model weld(body,seat)
    for _,off in ipairs({Vector3.new(-body.Size.X/2, -0.5,-body.Size.Z*0.3),Vector3.new(body.Size.X/2,-0.5,-body.Size.Z*0.3),Vector3.new(-body.Size.X/2,-0.5,body.Size.Z*0.3),Vector3.new(body.Size.X/2,-0.5,body.Size.Z*0.3)}) do local wh=wheel(model,origin+off) weld(body,wh) end
    if vehicleName=="Armored" then
        local turret=Instance.new("Part") turret.Size=Vector3.new(3.5,1.2,3.5) turret.Position=origin+Vector3.new(0,3.7,-1.8) turret.Color=Color3.fromRGB(52,58,50) turret.Material=Enum.Material.Metal turret.Anchored=false turret.Parent=model weld(body,turret)
        local barrel=Instance.new("Part") barrel.Size=Vector3.new(0.7,0.7,6) barrel.Position=origin+Vector3.new(0,3.7,-5.2) barrel.Color=turret.Color barrel.Material=Enum.Material.Metal barrel.Anchored=false barrel.Parent=model weld(body,barrel)
    end
    model.PrimaryPart=body activeVehicles[player]=model
end
local function createHelicopter(player,origin,config)
    local model=Instance.new("Model") model.Name=player.Name.."_Helicopter" model.Parent=workspace
    local body=Instance.new("Part") body.Size=Vector3.new(7,3,12) body.Position=origin+Vector3.new(0,4,0) body.Color=config.color body.Material=Enum.Material.Metal body.Anchored=false body.Parent=model
    local seat=Instance.new("VehicleSeat") seat.Size=Vector3.new(2,1,2) seat.Position=body.Position+Vector3.new(0,1,1) seat.Anchored=false seat.MaxSpeed=config.maxSpeed seat.Torque=55000 seat.Parent=model weld(body,seat)
    local tail=Instance.new("Part") tail.Size=Vector3.new(2,2,9) tail.Position=body.Position+Vector3.new(0,0,8) tail.Color=config.color tail.Material=Enum.Material.Metal tail.Anchored=false tail.Parent=model weld(body,tail)
    local rotor=Instance.new("Part") rotor.Size=Vector3.new(22,0.3,1) rotor.Position=body.Position+Vector3.new(0,3,0) rotor.Color=Color3.fromRGB(35,35,35) rotor.Material=Enum.Material.Metal rotor.Anchored=false rotor.Parent=model weld(body,rotor)
    local stabilizer=Instance.new("BodyGyro") stabilizer.MaxTorque=Vector3.new(1e6,1e6,1e6) stabilizer.P=5000 stabilizer.Parent=body
    local lift=Instance.new("BodyVelocity") lift.MaxForce=Vector3.new(0,1.2e5,0) lift.Velocity=Vector3.zero lift.Parent=body
    seat:GetPropertyChangedSignal("ThrottleFloat"):Connect(function() lift.Velocity=Vector3.new(0,seat.ThrottleFloat*35,0) end)
    model.PrimaryPart=body activeVehicles[player]=model
end
local function spawnVehicle(player,vehicleName)
    local d=profiles[player] if not d then return end
    local cfg=Config.VEHICLES[vehicleName] if not cfg then return end
    if not d.ownedVehicles[vehicleName] then
        if not spendCash(player,cfg.cost) then return end
        d.ownedVehicles[vehicleName]=true
    end
    clearVehicle(player)
    local baseId=player:GetAttribute("BaseId") or 0
    local origin=Vector3.new(-92,2,-68)
    if baseId>0 and Config.BASE_POSITIONS[baseId] then origin=Config.BASE_POSITIONS[baseId]+Vector3.new(28,2,16) end
    if vehicleName=="Helicopter" then createHelicopter(player,origin+Vector3.new(0,3,0),cfg) else createGroundVehicle(player,vehicleName,origin,cfg) end
end

local function completeMission(player,missionType)
    local d=profiles[player] if not d then return end
    if missionType=="DELIVERY" then addCash(player,Config.DELIVERY_REWARD) setWanted(player,math.max(0,d.wanted-1))
    elseif missionType=="CONVOY" then addCash(player,Config.CONVOY_REWARD) setWanted(player,d.wanted+1)
    else addCash(player,Config.MISSION_REWARD) setWanted(player,math.max(0,d.wanted-1)) end
    d.missions+=1 sync(player)
end
local function buyShop(player,item)
    if item=="MEDKIT" and spendCash(player,Config.SHOP_MEDKIT_COST) then
        local char=player.Character local hum=char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health=hum.MaxHealth end
    end
end

local function onPrompt(prompt,player)
    local kind=prompt:GetAttribute("ActionKind") local value=prompt:GetAttribute("ActionValue")
    if kind=="CLAIM" then local base=prompt:FindFirstAncestorOfClass("Model") if base then claimBase(player,base) end
    elseif kind=="UPGRADE" then upgradeBase(player)
    elseif kind=="HEIST" then
        local now=os.time() local last=lastHeist[player.UserId] or 0
        if now-last>=Config.HEIST_COOLDOWN then lastHeist[player.UserId]=now addCash(player,Config.HEIST_REWARD) setWanted(player,(profiles[player].wanted or 0)+2) end
    elseif kind=="MISSION" then completeMission(player,tostring(value or "SECURITY"))
    elseif kind=="VEHICLE" then spawnVehicle(player,tostring(value or "Jeep"))
    elseif kind=="SHOP" then buyShop(player,tostring(value or "")) end
end
local function hookPrompts(root)
    for _,obj in ipairs(root:GetDescendants()) do if obj:IsA("ProximityPrompt") then obj.Triggered:Connect(function(player) onPrompt(obj,player) end) end end
    root.DescendantAdded:Connect(function(obj) if obj:IsA("ProximityPrompt") then obj.Triggered:Connect(function(player) onPrompt(obj,player) end) end end)
end

local function createPoliceNPC(index)
    local model=Instance.new("Model") model.Name="Officer"..index model.Parent=policeFolder
    local hum=Instance.new("Humanoid") hum.WalkSpeed=18 hum.MaxHealth=100 hum.Health=100 hum.Parent=model
    local root=Instance.new("Part") root.Name="HumanoidRootPart" root.Size=Vector3.new(2,2,1) root.Position=Vector3.new(-120+index*4,3,118) root.Transparency=1 root.CanCollide=false root.Parent=model
    local torso=Instance.new("Part") torso.Name="Torso" torso.Size=Vector3.new(2.2,2.5,1.2) torso.Position=root.Position torso.Color=Color3.fromRGB(35,45,62) torso.Parent=model
    local head=Instance.new("Part") head.Name="Head" head.Size=Vector3.new(2,1,1) head.Position=root.Position+Vector3.new(0,1.8,0) head.Color=Color3.fromRGB(224,180,145) head.Parent=model
    weld(root,torso) weld(root,head) model.PrimaryPart=root
    return model
end
for i=1,6 do createPoliceNPC(i) end

task.spawn(function()
    local world=workspace:WaitForChild("OpenWorldMilitary") hookPrompts(world)
    local bases=world:WaitForChild("Bases")
    for _,base in ipairs(bases:GetChildren()) do updateBaseVisual(base,0) end
end)

Players.PlayerAdded:Connect(function(player)
    loadProfile(player)
    player.CharacterAdded:Connect(function(char)
        task.wait(0.25)
        local baseId=player:GetAttribute("BaseId") or 0
        if baseId>0 and Config.BASE_POSITIONS[baseId] then char:PivotTo(CFrame.new(Config.BASE_POSITIONS[baseId]+Vector3.new(0,5,28))) end
    end)
end)
Players.PlayerRemoving:Connect(function(player)
    local id=player:GetAttribute("BaseId") or 0 if id>0 and baseOwners[id]==player then baseOwners[id]=nil end
    clearVehicle(player) saveProfile(player) profiles[player]=nil
end)

task.spawn(function()
    while true do
        task.wait(Config.PASSIVE_INTERVAL)
        for player,d in pairs(profiles) do
            if player.Parent and (player:GetAttribute("BaseId") or 0)>0 then addCash(player,Config.UPGRADE_INCOME[d.baseLevel] or Config.BASE_INCOME) end
        end
    end
end)
task.spawn(function()
    while true do task.wait(Config.WANTED_DECAY_SECONDS)
        for player,d in pairs(profiles) do if d.wanted>0 then setWanted(player,d.wanted-1) end end
    end
end)
task.spawn(function()
    while true do
        task.wait(1.25)
        local target
        local highest=0
        for player,d in pairs(profiles) do
            if d.wanted>highest and player.Character and player.Character.PrimaryPart then target=player highest=d.wanted end
        end
        for _,npc in ipairs(policeFolder:GetChildren()) do
            local hum=npc:FindFirstChildOfClass("Humanoid")
            if hum and npc.PrimaryPart then
                if target and highest>0 then hum:MoveTo(target.Character.PrimaryPart.Position) else hum:MoveTo(Vector3.new(-120+math.random(-18,18),2,102+math.random(-18,18))) end
            end
        end
    end
end)

game:BindToClose(function() for player in pairs(profiles) do saveProfile(player) end end)
