local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Debris=game:GetService("Debris")

local remotes=ReplicatedStorage:FindFirstChild("CombatRemotes") or Instance.new("Folder")
remotes.Name="CombatRemotes"
remotes.Parent=ReplicatedStorage

local shoot=remotes:FindFirstChild("Shoot") or Instance.new("RemoteEvent")
shoot.Name="Shoot"
shoot.Parent=remotes

local WEAPONS={
    Pistol={damage=28,range=260,cooldown=0.34,color=Color3.fromRGB(255,220,120)},
    Rifle={damage=18,range=420,cooldown=0.11,color=Color3.fromRGB(120,210,255)},
}
local lastShot={}
local policeLastHit={}

local function makeTool(name)
    local cfg=WEAPONS[name]
    if not cfg then return end
    local tool=Instance.new("Tool")
    tool.Name=name
    tool.RequiresHandle=true
    tool.CanBeDropped=false
    tool:SetAttribute("WeaponType",name)
    local handle=Instance.new("Part")
    handle.Name="Handle"
    handle.Size=name=="Rifle" and Vector3.new(0.5,0.7,3.4) or Vector3.new(0.5,0.8,1.8)
    handle.Color=Color3.fromRGB(42,45,50)
    handle.Material=Enum.Material.Metal
    handle.CanCollide=false
    handle.Parent=tool
    local barrel=Instance.new("Part")
    barrel.Name="Barrel"
    barrel.Size=Vector3.new(0.22,0.22,name=="Rifle" and 2.6 or 1.2)
    barrel.Color=Color3.fromRGB(22,24,28)
    barrel.Material=Enum.Material.Metal
    barrel.CanCollide=false
    barrel.Massless=true
    barrel.CFrame=handle.CFrame*CFrame.new(0,0,-(name=="Rifle" and 2.6 or 1.4))
    barrel.Parent=tool
    local weld=Instance.new("WeldConstraint") weld.Part0=handle weld.Part1=barrel weld.Parent=handle
    return tool
end

local function giveWeapon(player,name)
    if not WEAPONS[name] then return end
    local backpack=player:FindFirstChildOfClass("Backpack")
    if not backpack then return end
    if backpack:FindFirstChild(name) or (player.Character and player.Character:FindFirstChild(name)) then return end
    local tool=makeTool(name)
    if tool then tool.Parent=backpack end
end

local function hookArmoryPrompts()
    local world=workspace:WaitForChild("OpenWorldMilitary")
    for _,base in ipairs(world:WaitForChild("Bases"):GetChildren()) do
        local command=base:FindFirstChild("CommandCenter")
        if command and not command:FindFirstChild("PistolPrompt") then
            local p=Instance.new("ProximityPrompt")
            p.Name="PistolPrompt" p.ActionText="EQUIP PISTOL" p.ObjectText="BASE ARMORY" p.MaxActivationDistance=11 p.HoldDuration=0.25 p.Parent=command
            p.Triggered:Connect(function(player)
                if player:GetAttribute("BaseId")==base:GetAttribute("BaseId") then giveWeapon(player,"Pistol") end
            end)
        end
        local armory=base:FindFirstChild("Armory")
        if armory and not armory:FindFirstChild("RiflePrompt") then
            local p=Instance.new("ProximityPrompt")
            p.Name="RiflePrompt" p.ActionText="EQUIP RIFLE" p.ObjectText="LEVEL 2 ARMORY" p.MaxActivationDistance=11 p.HoldDuration=0.35 p.Parent=armory
            p.Triggered:Connect(function(player)
                if player:GetAttribute("BaseId")==base:GetAttribute("BaseId") and (player:GetAttribute("BaseLevel") or 0)>=2 then giveWeapon(player,"Rifle") end
            end)
        end
    end
end

task.spawn(hookArmoryPrompts)

local function tracer(a,b,color)
    local dist=(b-a).Magnitude
    if dist<=0.1 then return end
    local beam=Instance.new("Part")
    beam.Name="Tracer"
    beam.Anchored=true beam.CanCollide=false beam.CanTouch=false beam.CanQuery=false
    beam.Material=Enum.Material.Neon beam.Color=color beam.Size=Vector3.new(0.08,0.08,dist)
    beam.CFrame=CFrame.lookAt((a+b)/2,b)
    beam.Parent=workspace
    Debris:AddItem(beam,0.07)
end

shoot.OnServerEvent:Connect(function(player,targetPosition)
    if typeof(targetPosition)~="Vector3" then return end
    local char=player.Character
    local root=char and char:FindFirstChild("HumanoidRootPart")
    if not char or not root then return end
    local tool=char:FindFirstChildOfClass("Tool")
    local weaponName=tool and tool:GetAttribute("WeaponType")
    local cfg=weaponName and WEAPONS[weaponName]
    if not cfg then return end

    local now=os.clock()
    local key=tostring(player.UserId)..":"..weaponName
    if now-(lastShot[key] or 0)<cfg.cooldown then return end
    lastShot[key]=now

    local handle=tool:FindFirstChild("Handle")
    local origin=handle and handle.Position or (root.Position+Vector3.new(0,1.5,0))
    local dir=targetPosition-origin
    if dir.Magnitude<1 then return end
    dir=dir.Unit*math.min(dir.Magnitude,cfg.range)

    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances={char,tool}
    params.IgnoreWater=true
    local result=workspace:Raycast(origin,dir,params)
    local hitPos=result and result.Position or (origin+dir)
    tracer(origin,hitPos,cfg.color)

    if result then
        local model=result.Instance:FindFirstAncestorOfClass("Model")
        local hum=model and model:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health>0 and model~=char then
            local before=hum.Health
            hum:TakeDamage(cfg.damage)
            if before>0 and hum.Health<=0 then
                player:SetAttribute("CombatKills",(player:GetAttribute("CombatKills") or 0)+1)
                local pending=player:GetAttribute("CombatRewardPending") or 0
                player:SetAttribute("CombatRewardPending",pending+750)
            end
        end
    end
end)

Players.PlayerAdded:Connect(function(player)
    player:SetAttribute("CombatKills",0)
    player:SetAttribute("CombatRewardPending",0)
end)

-- Police only retaliate against wanted players and use short controlled bursts.
task.spawn(function()
    while true do
        task.wait(0.35)
        local folder=workspace:FindFirstChild("PoliceNPCs")
        if folder then
            for _,officer in ipairs(folder:GetChildren()) do
                local officerHum=officer:FindFirstChildOfClass("Humanoid")
                local officerRoot=officer:FindFirstChild("HumanoidRootPart")
                if officerHum and officerHum.Health>0 and officerRoot then
                    local closestPlayer=nil
                    local closestDist=50
                    for _,player in ipairs(Players:GetPlayers()) do
                        if (player:GetAttribute("Wanted") or 0)>0 then
                            local char=player.Character
                            local hum=char and char:FindFirstChildOfClass("Humanoid")
                            local root=char and char:FindFirstChild("HumanoidRootPart")
                            if hum and hum.Health>0 and root then
                                local dist=(root.Position-officerRoot.Position).Magnitude
                                if dist<closestDist then
                                    closestDist=dist
                                    closestPlayer=player
                                end
                            end
                        end
                    end
                    if closestPlayer then
                        local targetRoot=closestPlayer.Character and closestPlayer.Character:FindFirstChild("HumanoidRootPart")
                        local targetHum=closestPlayer.Character and closestPlayer.Character:FindFirstChildOfClass("Humanoid")
                        if targetRoot and targetHum then
                            local key=officer:GetDebugId()..":"..closestPlayer.UserId
                            local now=os.clock()
                            if now-(policeLastHit[key] or 0)>=1.15 then
                                policeLastHit[key]=now
                                tracer(officerRoot.Position+Vector3.new(0,1.2,0),targetRoot.Position+Vector3.new(0,1,0),Color3.fromRGB(255,90,90))
                                targetHum:TakeDamage(8+math.min(10,(closestPlayer:GetAttribute("Wanted") or 1)*2))
                            end
                        end
                    end
                end
            end
        end
    end
end)
