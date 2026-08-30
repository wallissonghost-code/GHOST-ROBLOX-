local Lighting=game:GetService("Lighting")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Config=require(ReplicatedStorage:WaitForChild("GameConfig"))

local old=workspace:FindFirstChild("OpenWorldMilitary")
if old then old:Destroy() end
local world=Instance.new("Folder") world.Name="OpenWorldMilitary" world.Parent=workspace

local function part(name,size,pos,color,material,parent)
    local p=Instance.new("Part") p.Name=name p.Size=size p.Position=pos p.Anchored=true
    p.Color=color p.Material=material or Enum.Material.SmoothPlastic p.Parent=parent or world return p
end
local function label(partObj,text,color)
    local gui=Instance.new("BillboardGui") gui.Size=UDim2.fromOffset(320,70) gui.StudsOffset=Vector3.new(0,4,0) gui.AlwaysOnTop=true gui.Parent=partObj
    local l=Instance.new("TextLabel") l.Size=UDim2.fromScale(1,1) l.BackgroundTransparency=0.2 l.BackgroundColor3=Color3.fromRGB(20,24,28)
    l.Text=text l.TextColor3=color or Color3.new(1,1,1) l.TextScaled=true l.Font=Enum.Font.GothamBlack l.Parent=gui
end
local function prompt(partObj,action,objectName,kind)
    local pr=Instance.new("ProximityPrompt") pr.ActionText=action pr.ObjectText=objectName pr.HoldDuration=0.5 pr.MaxActivationDistance=12 pr.Parent=partObj
    pr:SetAttribute("ActionKind",kind) return pr
end

part("Ground",Vector3.new(520,2,420),Vector3.new(0,-1,0),Color3.fromRGB(77,101,65),Enum.Material.Grass)
part("RoadNS",Vector3.new(54,0.3,420),Vector3.new(0,0.15,0),Color3.fromRGB(46,48,52),Enum.Material.Asphalt)
part("RoadEW",Vector3.new(520,0.3,54),Vector3.new(0,0.16,0),Color3.fromRGB(46,48,52),Enum.Material.Asphalt)
for z=-190,190,20 do part("RoadMark",Vector3.new(1,0.05,8),Vector3.new(0,0.36,z),Color3.fromRGB(235,210,70),Enum.Material.Neon) end
for x=-240,240,20 do part("RoadMark",Vector3.new(8,0.05,1),Vector3.new(x,0.37,0),Color3.fromRGB(235,210,70),Enum.Material.Neon) end

local city=Instance.new("Folder") city.Name="City" city.Parent=world
local buildings={
    {-80,70,34,32,48},{-120,65,28,38,34},{80,72,34,35,42},{125,75,30,45,30},
    {-85,-70,40,30,38},{-130,-75,28,42,46},{85,-75,38,36,40},{135,-72,26,30,34}
}
for i,b in ipairs(buildings) do
    local x,z,w,h,d=b[1],b[2],b[3],b[4],b[5]
    local tower=part("Building"..i,Vector3.new(w,h,d),Vector3.new(x,h/2,z),Color3.fromRGB(100+i*5,105+i*4,112+i*3),Enum.Material.Concrete,city)
    tower.CastShadow=true
    for y=6,h-4,8 do
        local glow=part("Window"..i.."_"..y,Vector3.new(w*0.72,2,0.15),Vector3.new(x,y,z-d/2-0.08),Color3.fromRGB(160,205,235),Enum.Material.Neon,city)
        glow.Transparency=0.25
    end
end

local bank=part("Bank",Vector3.new(42,18,32),Vector3.new(74,9,68),Color3.fromRGB(178,181,184),Enum.Material.Concrete,city)
label(bank,"CITY BANK",Color3.fromRGB(255,214,72))
local vault=part("BankVault",Vector3.new(8,8,2),Vector3.new(74,4,51),Color3.fromRGB(70,72,77),Enum.Material.Metal,city)
prompt(vault,"ROB BANK","VAULT","HEIST")

local mission=part("MissionTerminal",Vector3.new(5,6,5),Vector3.new(-68,3,66),Color3.fromRGB(35,94,132),Enum.Material.Metal,city)
label(mission,"CONTRACTS",Color3.fromRGB(105,210,255))
prompt(mission,"START CONTRACT","SECURITY JOB","MISSION")

local garage=part("Garage",Vector3.new(36,12,28),Vector3.new(-82,6,-72),Color3.fromRGB(64,67,73),Enum.Material.Metal,city)
label(garage,"GARAGE",Color3.fromRGB(255,255,255))
local vehiclePad=part("VehiclePad",Vector3.new(18,0.5,10),Vector3.new(-82,0.4,-52),Color3.fromRGB(45,120,170),Enum.Material.Neon,city)
prompt(vehiclePad,"SPAWN JEEP","GARAGE","VEHICLE")

local baseFolder=Instance.new("Folder") baseFolder.Name="Bases" baseFolder.Parent=world
for i,pos in ipairs(Config.BASE_POSITIONS) do
    local base=Instance.new("Model") base.Name="Base"..i base:SetAttribute("BaseId",i) base.Parent=baseFolder
    part("BaseFloor",Vector3.new(105,1,82),pos+Vector3.new(0,0.5,0),Color3.fromRGB(88,92,80),Enum.Material.Concrete,base)
    local wallColor=Color3.fromRGB(75,82,68)
    part("WallN",Vector3.new(105,9,3),pos+Vector3.new(0,4.5,-40),wallColor,Enum.Material.Concrete,base)
    part("WallS",Vector3.new(105,9,3),pos+Vector3.new(0,4.5,40),wallColor,Enum.Material.Concrete,base)
    part("WallW",Vector3.new(3,9,82),pos+Vector3.new(-51,4.5,0),wallColor,Enum.Material.Concrete,base)
    part("WallE",Vector3.new(3,9,82),pos+Vector3.new(51,4.5,0),wallColor,Enum.Material.Concrete,base)
    local flag=part("ClaimPad",Vector3.new(12,1,12),pos+Vector3.new(0,1,28),Color3.fromRGB(75,160,90),Enum.Material.Neon,base)
    label(flag,"UNCLAIMED BASE",Color3.fromRGB(190,255,195)); prompt(flag,"CLAIM","MILITARY BASE","CLAIM")
    local upgrade=part("UpgradePad",Vector3.new(12,1,12),pos+Vector3.new(-23,1,25),Color3.fromRGB(65,115,190),Enum.Material.Neon,base)
    label(upgrade,"UPGRADE BASE",Color3.fromRGB(165,210,255)); prompt(upgrade,"UPGRADE","INCOME","UPGRADE")
    local armory=part("Armory",Vector3.new(20,10,18),pos+Vector3.new(-30,5,-18),Color3.fromRGB(60,64,58),Enum.Material.Metal,base)
    label(armory,"ARMORY",Color3.fromRGB(220,220,220))
    local hangar=part("Hangar",Vector3.new(28,12,24),pos+Vector3.new(27,6,-17),Color3.fromRGB(82,85,78),Enum.Material.Metal,base)
    label(hangar,"VEHICLES",Color3.fromRGB(220,220,220))
    part("Helipad",Vector3.new(20,0.5,20),pos+Vector3.new(27,1,18),Color3.fromRGB(55,58,55),Enum.Material.Metal,base)
end

local spawn=Instance.new("SpawnLocation") spawn.Name="CitySpawn" spawn.Size=Vector3.new(10,1,10) spawn.Position=Vector3.new(0,1,72)
spawn.Anchored=true spawn.Neutral=true spawn.Color=Color3.fromRGB(65,130,205) spawn.Material=Enum.Material.Neon spawn.Parent=world

Lighting.ClockTime=14.2 Lighting.Brightness=2.2 Lighting.Ambient=Color3.fromRGB(130,135,140) Lighting.OutdoorAmbient=Color3.fromRGB(150,155,160)
Lighting.EnvironmentDiffuseScale=0.6 Lighting.EnvironmentSpecularScale=0.5
