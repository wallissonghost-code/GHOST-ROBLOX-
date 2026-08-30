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
local function label(partObj,text,color,offset)
    local gui=Instance.new("BillboardGui") gui.Size=UDim2.fromOffset(300,64) gui.StudsOffset=offset or Vector3.new(0,4,0) gui.AlwaysOnTop=true gui.Parent=partObj
    local l=Instance.new("TextLabel") l.Size=UDim2.fromScale(1,1) l.BackgroundTransparency=0.15 l.BackgroundColor3=Color3.fromRGB(20,24,28)
    l.Text=text l.TextColor3=color or Color3.new(1,1,1) l.TextScaled=true l.Font=Enum.Font.GothamBlack l.Parent=gui
end
local function prompt(partObj,action,objectName,kind,value)
    local pr=Instance.new("ProximityPrompt") pr.ActionText=action pr.ObjectText=objectName pr.HoldDuration=0.45 pr.MaxActivationDistance=13 pr.Parent=partObj
    pr:SetAttribute("ActionKind",kind)
    if value~=nil then pr:SetAttribute("ActionValue",value) end
    return pr
end
local function stagePart(base,name,size,pos,color,requiredLevel,material)
    local p=part(name,size,pos,color,material,base)
    p:SetAttribute("RequiredLevel",requiredLevel)
    if requiredLevel>0 then p.Transparency=1 p.CanCollide=false end
    return p
end

part("Ground",Vector3.new(600,2,500),Vector3.new(0,-1,0),Color3.fromRGB(78,106,67),Enum.Material.Grass)
part("RoadNS",Vector3.new(58,0.3,500),Vector3.new(0,0.15,0),Color3.fromRGB(45,47,51),Enum.Material.Asphalt)
part("RoadEW",Vector3.new(600,0.3,58),Vector3.new(0,0.16,0),Color3.fromRGB(45,47,51),Enum.Material.Asphalt)
for z=-230,230,20 do part("RoadMark",Vector3.new(1,0.05,8),Vector3.new(0,0.36,z),Color3.fromRGB(235,210,70),Enum.Material.Neon) end
for x=-280,280,20 do part("RoadMark",Vector3.new(8,0.05,1),Vector3.new(x,0.37,0),Color3.fromRGB(235,210,70),Enum.Material.Neon) end

local city=Instance.new("Folder") city.Name="City" city.Parent=world
local buildings={
    {-85,78,38,36,46},{-135,72,30,42,34},{90,80,38,39,44},{140,78,32,50,32},
    {-88,-82,42,34,40},{-140,-80,30,48,48},{90,-82,40,40,42},{145,-80,30,34,36}
}
for i,b in ipairs(buildings) do
    local x,z,w,h,d=b[1],b[2],b[3],b[4],b[5]
    local tower=part("Building"..i,Vector3.new(w,h,d),Vector3.new(x,h/2,z),Color3.fromRGB(94+i*5,100+i*4,108+i*3),Enum.Material.Concrete,city)
    tower.CastShadow=true
    for y=6,h-4,8 do
        local glow=part("Window"..i.."_"..y,Vector3.new(w*0.72,2,0.15),Vector3.new(x,y,z-d/2-0.08),Color3.fromRGB(160,205,235),Enum.Material.Neon,city)
        glow.Transparency=0.3
    end
end

local bank=part("Bank",Vector3.new(44,20,34),Vector3.new(78,10,74),Color3.fromRGB(184,186,190),Enum.Material.Concrete,city)
label(bank,"CITY BANK",Color3.fromRGB(255,214,72))
local vault=part("BankVault",Vector3.new(9,9,2),Vector3.new(78,4.5,56),Color3.fromRGB(68,70,76),Enum.Material.Metal,city)
prompt(vault,"ROB BANK","VAULT","HEIST")

local mission=part("MissionTerminal",Vector3.new(5,6,5),Vector3.new(-72,3,72),Color3.fromRGB(35,94,132),Enum.Material.Metal,city)
label(mission,"CONTRACTS",Color3.fromRGB(105,210,255))
prompt(mission,"SECURITY JOB","CONTRACT","MISSION","SECURITY")

local delivery=part("DeliveryTerminal",Vector3.new(5,6,5),Vector3.new(-72,3,-76),Color3.fromRGB(195,126,45),Enum.Material.Metal,city)
label(delivery,"DELIVERY",Color3.fromRGB(255,210,120))
prompt(delivery,"DELIVER CARGO","CONTRACT","MISSION","DELIVERY")

local convoy=part("ConvoyTerminal",Vector3.new(5,6,5),Vector3.new(72,3,-74),Color3.fromRGB(112,57,48),Enum.Material.Metal,city)
label(convoy,"CONVOY RAID",Color3.fromRGB(255,140,115))
prompt(convoy,"RAID CONVOY","CONTRACT","MISSION","CONVOY")

local garage=part("Garage",Vector3.new(42,13,30),Vector3.new(-90,6.5,-95),Color3.fromRGB(64,67,73),Enum.Material.Metal,city)
label(garage,"CITY GARAGE",Color3.fromRGB(255,255,255))
local jeepPad=part("JeepPad",Vector3.new(14,0.5,9),Vector3.new(-102,0.4,-74),Color3.fromRGB(52,132,88),Enum.Material.Neon,city)
prompt(jeepPad,"SPAWN JEEP","FREE","VEHICLE","Jeep")
local pursuitPad=part("PursuitPad",Vector3.new(14,0.5,9),Vector3.new(-82,0.4,-74),Color3.fromRGB(60,90,175),Enum.Material.Neon,city)
prompt(pursuitPad,"BUY / SPAWN","PURSUIT $7K","VEHICLE","Pursuit")

local shop=part("SupplyShop",Vector3.new(28,12,24),Vector3.new(116,6,98),Color3.fromRGB(88,91,96),Enum.Material.Brick,city)
label(shop,"SUPPLY SHOP",Color3.fromRGB(180,255,205))
local medkit=part("MedkitCounter",Vector3.new(7,3,3),Vector3.new(116,1.5,84),Color3.fromRGB(185,55,55),Enum.Material.SmoothPlastic,city)
prompt(medkit,"BUY MEDKIT","$500","SHOP","MEDKIT")

local policeStation=part("PoliceStation",Vector3.new(38,17,30),Vector3.new(-120,8.5,102),Color3.fromRGB(68,76,88),Enum.Material.Concrete,city)
label(policeStation,"TACTICAL POLICE",Color3.fromRGB(120,190,255))

local airport=Instance.new("Folder") airport.Name="Airport" airport.Parent=world
part("Runway",Vector3.new(210,0.5,34),Vector3.new(0,0.25,-205),Color3.fromRGB(58,60,64),Enum.Material.Asphalt,airport)
for x=-90,90,18 do part("RunwayLight"..x,Vector3.new(3,0.15,0.5),Vector3.new(x,0.6,-205),Color3.fromRGB(235,235,190),Enum.Material.Neon,airport) end
local terminal=part("Terminal",Vector3.new(48,18,32),Vector3.new(0,9,-172),Color3.fromRGB(118,124,132),Enum.Material.Concrete,airport)
label(terminal,"MILITARY AIRFIELD",Color3.fromRGB(220,235,255))
local heliPad=part("HelicopterPad",Vector3.new(22,0.5,22),Vector3.new(78,0.5,-205),Color3.fromRGB(55,58,60),Enum.Material.Metal,airport)
prompt(heliPad,"BUY / SPAWN","HELICOPTER $50K","VEHICLE","Helicopter")

local baseFolder=Instance.new("Folder") baseFolder.Name="Bases" baseFolder.Parent=world
for i,pos in ipairs(Config.BASE_POSITIONS) do
    local base=Instance.new("Model") base.Name="Base"..i base:SetAttribute("BaseId",i) base.Parent=baseFolder
    part("BaseFloor",Vector3.new(110,1,88),pos+Vector3.new(0,0.5,0),Color3.fromRGB(91,96,84),Enum.Material.Concrete,base)
    local wallColor=Color3.fromRGB(72,80,67)
    part("WallN",Vector3.new(110,9,3),pos+Vector3.new(0,4.5,-43),wallColor,Enum.Material.Concrete,base)
    part("WallS",Vector3.new(110,9,3),pos+Vector3.new(0,4.5,43),wallColor,Enum.Material.Concrete,base)
    part("WallW",Vector3.new(3,9,88),pos+Vector3.new(-54,4.5,0),wallColor,Enum.Material.Concrete,base)
    part("WallE",Vector3.new(3,9,88),pos+Vector3.new(54,4.5,0),wallColor,Enum.Material.Concrete,base)

    local flag=part("ClaimPad",Vector3.new(12,1,12),pos+Vector3.new(0,1,31),Color3.fromRGB(75,160,90),Enum.Material.Neon,base)
    label(flag,"UNCLAIMED BASE",Color3.fromRGB(190,255,195)); prompt(flag,"CLAIM","MILITARY BASE","CLAIM")
    local upgrade=part("UpgradePad",Vector3.new(12,1,12),pos+Vector3.new(-24,1,29),Color3.fromRGB(65,115,190),Enum.Material.Neon,base)
    label(upgrade,"UPGRADE BASE",Color3.fromRGB(165,210,255)); prompt(upgrade,"UPGRADE","INCOME + BASE","UPGRADE")

    stagePart(base,"CommandCenter",Vector3.new(25,10,20),pos+Vector3.new(-29,5,-19),Color3.fromRGB(57,65,58),0,Enum.Material.Metal)
    stagePart(base,"GarageShell",Vector3.new(30,11,22),pos+Vector3.new(28,5.5,-18),Color3.fromRGB(78,82,75),0,Enum.Material.Metal)
    local baseJeep=stagePart(base,"BaseJeepPad",Vector3.new(14,0.5,9),pos+Vector3.new(29,1,12),Color3.fromRGB(50,130,78),0,Enum.Material.Neon)
    prompt(baseJeep,"SPAWN JEEP","BASE GARAGE","VEHICLE","Jeep")

    stagePart(base,"Barracks",Vector3.new(28,11,18),pos+Vector3.new(-5,5.5,-18),Color3.fromRGB(69,76,66),1,Enum.Material.Concrete)
    stagePart(base,"WatchTowerA",Vector3.new(6,19,6),pos+Vector3.new(-43,9.5,-30),Color3.fromRGB(60,66,59),1,Enum.Material.Metal)
    stagePart(base,"WatchTowerB",Vector3.new(6,19,6),pos+Vector3.new(43,9.5,-30),Color3.fromRGB(60,66,59),1,Enum.Material.Metal)

    stagePart(base,"Armory",Vector3.new(24,11,20),pos+Vector3.new(-31,5.5,5),Color3.fromRGB(55,61,56),2,Enum.Material.Metal)
    stagePart(base,"RadarPole",Vector3.new(2,22,2),pos+Vector3.new(4,11,-23),Color3.fromRGB(72,75,73),2,Enum.Material.Metal)
    local dish=stagePart(base,"RadarDish",Vector3.new(10,2,10),pos+Vector3.new(4,22,-23),Color3.fromRGB(140,148,145),2,Enum.Material.Metal)
    dish.Shape=Enum.PartType.Cylinder

    stagePart(base,"HeavyGarage",Vector3.new(34,13,26),pos+Vector3.new(28,6.5,5),Color3.fromRGB(65,69,64),3,Enum.Material.Metal)
    local armoredPad=stagePart(base,"ArmoredPad",Vector3.new(16,0.5,10),pos+Vector3.new(28,1,25),Color3.fromRGB(142,98,44),3,Enum.Material.Neon)
    prompt(armoredPad,"BUY / SPAWN","ARMORED $25K","VEHICLE","Armored")

    stagePart(base,"Helipad",Vector3.new(24,0.5,24),pos+Vector3.new(-22,1,21),Color3.fromRGB(58,61,58),4,Enum.Material.Metal)
    local baseHeli=stagePart(base,"BaseHelicopterPad",Vector3.new(18,0.2,18),pos+Vector3.new(-22,1.3,21),Color3.fromRGB(65,105,165),4,Enum.Material.Neon)
    prompt(baseHeli,"BUY / SPAWN","HELICOPTER $50K","VEHICLE","Helicopter")
end

local spawn=Instance.new("SpawnLocation") spawn.Name="CitySpawn" spawn.Size=Vector3.new(10,1,10) spawn.Position=Vector3.new(0,1,92)
spawn.Anchored=true spawn.Neutral=true spawn.Color=Color3.fromRGB(65,130,205) spawn.Material=Enum.Material.Neon spawn.Parent=world

Lighting.ClockTime=14.2 Lighting.Brightness=2.4 Lighting.Ambient=Color3.fromRGB(135,140,146) Lighting.OutdoorAmbient=Color3.fromRGB(155,160,166)
Lighting.EnvironmentDiffuseScale=0.65 Lighting.EnvironmentSpecularScale=0.55
