local Lighting=game:GetService("Lighting")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Config=require(ReplicatedStorage:WaitForChild("GameConfig"))

local old=workspace:FindFirstChild("OpenWorldMilitary")
if old then old:Destroy() end
local world=Instance.new("Folder") world.Name="OpenWorldMilitary" world.Parent=workspace

local function part(name,size,pos,color,material,parent)
    local p=Instance.new("Part")
    p.Name=name p.Size=size p.Position=pos p.Anchored=true
    p.Color=color p.Material=material or Enum.Material.SmoothPlastic
    p.Parent=parent or world
    return p
end

local function label(partObj,text,color,offset,maxDistance)
    local gui=Instance.new("BillboardGui")
    gui.Name="WorldLabel" gui.Size=UDim2.fromOffset(190,42)
    gui.StudsOffset=offset or Vector3.new(0,4,0)
    gui.AlwaysOnTop=true gui.MaxDistance=maxDistance or 70 gui.LightInfluence=0.25 gui.Parent=partObj
    local bg=Instance.new("Frame") bg.Size=UDim2.fromScale(1,1) bg.BackgroundColor3=Color3.fromRGB(18,22,27) bg.BackgroundTransparency=0.16 bg.Parent=gui
    local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,8) c.Parent=bg
    local s=Instance.new("UIStroke") s.Color=color or Color3.new(1,1,1) s.Transparency=0.45 s.Parent=bg
    local t=Instance.new("TextLabel") t.Size=UDim2.new(1,-10,1,-4) t.Position=UDim2.fromOffset(5,2) t.BackgroundTransparency=1
    t.Text=text t.TextColor3=color or Color3.new(1,1,1) t.TextSize=17 t.Font=Enum.Font.GothamBold t.Parent=bg
end

local function prompt(obj,action,objectName,kind,value)
    local p=Instance.new("ProximityPrompt")
    p.ActionText=action p.ObjectText=objectName p.HoldDuration=0.4 p.MaxActivationDistance=13 p.Parent=obj
    p:SetAttribute("ActionKind",kind)
    if value~=nil then p:SetAttribute("ActionValue",value) end
    return p
end

local function stagePart(base,name,size,pos,color,required,material)
    local p=part(name,size,pos,color,material,base)
    p:SetAttribute("RequiredLevel",required)
    if required>0 then p.Transparency=1 p.CanCollide=false end
    return p
end

local function roadBetween(name,a,b,width,parent)
    local mid=(a+b)/2
    local dist=(b-a).Magnitude
    local r=part(name,Vector3.new(width,0.35,dist),Vector3.new(mid.X,0.18,mid.Z),Color3.fromRGB(45,47,51),Enum.Material.Asphalt,parent)
    r.CFrame=CFrame.lookAt(Vector3.new(mid.X,0.18,mid.Z),Vector3.new(b.X,0.18,b.Z))
    return r
end

local function lowBuilding(parent,name,pos,size,color)
    local b=part(name,size,pos+Vector3.new(0,size.Y/2,0),color,Enum.Material.Concrete,parent)
    part(name.."Roof",Vector3.new(size.X+1,0.8,size.Z+1),pos+Vector3.new(0,size.Y+0.4,0),Color3.fromRGB(59,64,70),Enum.Material.Metal,parent)
    local front=pos.Z-size.Z/2-0.2
    part(name.."Door",Vector3.new(6,7,0.4),Vector3.new(pos.X,3.5,front),Color3.fromRGB(42,48,55),Enum.Material.Metal,parent)
    for y=8,size.Y-4,8 do
        local w=part(name.."Window"..y,Vector3.new(size.X*0.65,1.8,0.2),Vector3.new(pos.X,y,front-0.1),Color3.fromRGB(135,187,215),Enum.Material.Glass,parent)
        w.Transparency=0.35
    end
    return b
end

local mapSize=Config.WORLD_SIZE or 2400
part("MainGround",Vector3.new(mapSize,4,mapSize),Vector3.new(0,-2,0),Color3.fromRGB(76,108,69),Enum.Material.Grass)

-- Coast/ocean on the west side and a river crossing the south.
part("Ocean",Vector3.new(420,8,mapSize),Vector3.new(-mapSize/2-165,-2,0),Color3.fromRGB(57,125,164),Enum.Material.Glass)
part("River",Vector3.new(mapSize,5,150),Vector3.new(0,-0.8,560),Color3.fromRGB(66,134,171),Enum.Material.Glass)

-- Major highway network.
local roads=Instance.new("Folder") roads.Name="Highways" roads.Parent=world
roadBetween("CentralNS",Vector3.new(0,0,-1120),Vector3.new(0,0,1120),64,roads)
roadBetween("CentralEW",Vector3.new(-1120,0,0),Vector3.new(1120,0,0),64,roads)
roadBetween("NWDiagonal",Vector3.new(-1000,0,-820),Vector3.new(-80,0,-100),44,roads)
roadBetween("NEDiagonal",Vector3.new(1000,0,-820),Vector3.new(80,0,-100),44,roads)
roadBetween("SWDiagonal",Vector3.new(-980,0,780),Vector3.new(-100,0,120),44,roads)
roadBetween("SEDiagonal",Vector3.new(980,0,780),Vector3.new(100,0,120),44,roads)

local ring={Vector3.new(-650,0,-650),Vector3.new(650,0,-650),Vector3.new(830,0,0),Vector3.new(650,0,650),Vector3.new(-650,0,650),Vector3.new(-830,0,0)}
for i=1,#ring do roadBetween("Ring"..i,ring[i],ring[(i%#ring)+1],42,roads) end

-- CENTRAL CITY
local city=Instance.new("Folder") city.Name="City" city.Parent=world
part("CityPad",Vector3.new(680,1,620),Vector3.new(0,0.1,0),Color3.fromRGB(115,119,116),Enum.Material.Concrete,city)
local cityBlocks={
    {-250,-210,70,58,70},{-150,-215,80,42,60},{-40,-220,62,70,68},{85,-215,76,48,68},{205,-210,82,62,72},
    {-250,-90,72,46,78},{-140,-85,70,78,72},{140,-85,76,68,70},{250,-90,68,52,76},
    {-250,120,74,70,76},{-140,130,70,50,68},{140,130,72,82,72},{250,120,78,56,78},
    {-220,235,78,46,72},{-95,235,66,62,70},{75,235,70,54,70},{210,235,84,72,76}
}
for i,b in ipairs(cityBlocks) do lowBuilding(city,"Tower"..i,Vector3.new(b[1],0,b[2]),Vector3.new(b[3],b[4],b[5]),Color3.fromRGB(96+(i%4)*8,101+(i%3)*7,110+(i%5)*5)) end

local bank=lowBuilding(city,"Bank",Vector3.new(88,0,72),Vector3.new(54,24,42),Color3.fromRGB(183,185,189))
label(bank,"CITY BANK",Color3.fromRGB(255,214,72),Vector3.new(0,16,0),90)
local vault=part("BankVault",Vector3.new(10,9,2),Vector3.new(88,4.5,49.5),Color3.fromRGB(65,68,74),Enum.Material.Metal,city)
prompt(vault,"ROB BANK","VAULT","HEIST")

local mission=part("MissionTerminal",Vector3.new(5,6,5),Vector3.new(-95,3,75),Color3.fromRGB(35,94,132),Enum.Material.Metal,city)
label(mission,"CONTRACTS",Color3.fromRGB(105,210,255),Vector3.new(0,5,0),55)
prompt(mission,"SECURITY JOB","CONTRACT","MISSION","SECURITY")
local delivery=part("DeliveryTerminal",Vector3.new(5,6,5),Vector3.new(-95,3,-80),Color3.fromRGB(195,126,45),Enum.Material.Metal,city)
label(delivery,"DELIVERY",Color3.fromRGB(255,210,120),Vector3.new(0,5,0),55)
prompt(delivery,"DELIVER CARGO","CONTRACT","MISSION","DELIVERY")
local convoy=part("ConvoyTerminal",Vector3.new(5,6,5),Vector3.new(95,3,-80),Color3.fromRGB(112,57,48),Enum.Material.Metal,city)
label(convoy,"CONVOY RAID",Color3.fromRGB(255,140,115),Vector3.new(0,5,0),55)
prompt(convoy,"RAID CONVOY","CONTRACT","MISSION","CONVOY")

local garage=lowBuilding(city,"Garage",Vector3.new(-210,0,-320),Vector3.new(58,16,42),Color3.fromRGB(67,70,76))
label(garage,"CITY GARAGE",Color3.fromRGB(235,240,245),Vector3.new(0,12,0),70)
local jeepPad=part("JeepPad",Vector3.new(14,0.5,9),Vector3.new(-225,0.5,-290),Color3.fromRGB(52,132,88),Enum.Material.Neon,city)
prompt(jeepPad,"SPAWN JEEP","FREE","VEHICLE","Jeep")
local pursuitPad=part("PursuitPad",Vector3.new(14,0.5,9),Vector3.new(-195,0.5,-290),Color3.fromRGB(60,90,175),Enum.Material.Neon,city)
prompt(pursuitPad,"BUY / SPAWN","PURSUIT $7K","VEHICLE","Pursuit")

local shop=lowBuilding(city,"SupplyShop",Vector3.new(245,0,310),Vector3.new(42,15,34),Color3.fromRGB(87,92,96))
label(shop,"SUPPLY SHOP",Color3.fromRGB(180,255,205),Vector3.new(0,11,0),70)
local medkit=part("MedkitCounter",Vector3.new(7,3,3),Vector3.new(245,1.5,289),Color3.fromRGB(185,55,55),Enum.Material.SmoothPlastic,city)
prompt(medkit,"BUY MEDKIT","$500","SHOP","MEDKIT")

local police=lowBuilding(city,"PoliceStation",Vector3.new(-275,0,310),Vector3.new(50,20,38),Color3.fromRGB(68,76,88))
label(police,"TACTICAL POLICE",Color3.fromRGB(120,190,255),Vector3.new(0,14,0),80)

-- NORTHERN MILITARY AIRFIELD
local airport=Instance.new("Folder") airport.Name="Airport" airport.Parent=world
part("AirfieldGround",Vector3.new(720,1,330),Vector3.new(0,0,-810),Color3.fromRGB(98,103,98),Enum.Material.Concrete,airport)
part("Runway",Vector3.new(650,0.6,52),Vector3.new(0,0.5,-860),Color3.fromRGB(55,58,62),Enum.Material.Asphalt,airport)
for x=-290,290,30 do
    part("RunwayLightA"..x,Vector3.new(3,0.2,0.6),Vector3.new(x,0.9,-884),Color3.fromRGB(238,238,190),Enum.Material.Neon,airport)
    part("RunwayLightB"..x,Vector3.new(3,0.2,0.6),Vector3.new(x,0.9,-836),Color3.fromRGB(238,238,190),Enum.Material.Neon,airport)
end
local terminal=lowBuilding(airport,"AirTerminal",Vector3.new(0,0,-710),Vector3.new(90,24,46),Color3.fromRGB(114,121,130))
label(terminal,"MILITARY AIRFIELD",Color3.fromRGB(220,235,255),Vector3.new(0,16,0),95)
local heliPad=part("HelicopterPad",Vector3.new(30,0.5,30),Vector3.new(155,0.6,-720),Color3.fromRGB(55,58,60),Enum.Material.Metal,airport)
prompt(heliPad,"BUY / SPAWN","HELICOPTER $50K","VEHICLE","Helicopter")
for i,x in ipairs({-250,-145,145,250}) do lowBuilding(airport,"Hangar"..i,Vector3.new(x,0,-740),Vector3.new(72,22,54),Color3.fromRGB(78,84,82)) end

-- WESTERN PORT
local port=Instance.new("Folder") port.Name="Port" port.Parent=world
part("PortPad",Vector3.new(360,1,470),Vector3.new(-950,0,40),Color3.fromRGB(104,107,103),Enum.Material.Concrete,port)
for i=1,5 do
    local c=part("Container"..i,Vector3.new(34,14,14),Vector3.new(-1030+(i%2)*40,7,-80+i*42),Color3.fromRGB(90+i*22,75+i*10,65+i*7),Enum.Material.Metal,port)
    c.Orientation=Vector3.new(0,(i%2)*90,0)
end
local portHQ=lowBuilding(port,"PortHQ",Vector3.new(-875,0,50),Vector3.new(54,20,42),Color3.fromRGB(92,98,105))
label(portHQ,"NAVAL PORT",Color3.fromRGB(145,220,255),Vector3.new(0,14,0),90)
for i,z in ipairs({-160,-60,40,140}) do part("Dock"..i,Vector3.new(150,1,22),Vector3.new(-1110,0.5,z),Color3.fromRGB(105,88,67),Enum.Material.WoodPlanks,port) end

-- EASTERN DESERT / MISSILE RANGE
local desert=Instance.new("Folder") desert.Name="Desert" desert.Parent=world
part("DesertGround",Vector3.new(530,1,690),Vector3.new(910,0,0),Color3.fromRGB(194,158,92),Enum.Material.Sand,desert)
for i=1,22 do
    local x=700+((i*83)%390)
    local z=-300+((i*137)%600)
    local rock=part("DesertRock"..i,Vector3.new(16+(i%4)*8,12+(i%5)*6,18+(i%3)*10),Vector3.new(x,7+(i%5)*3,z),Color3.fromRGB(148,105,67),Enum.Material.Sandstone,desert)
    rock.Orientation=Vector3.new((i*11)%20,(i*37)%180,(i*7)%15)
end
local rangeHQ=lowBuilding(desert,"RangeHQ",Vector3.new(790,0,-180),Vector3.new(60,19,44),Color3.fromRGB(112,101,80))
label(rangeHQ,"MISSILE RANGE",Color3.fromRGB(255,205,120),Vector3.new(0,13,0),90)
for i=1,4 do
    local silo=part("Silo"..i,Vector3.new(18,8,18),Vector3.new(880+(i-2.5)*46,4,140),Color3.fromRGB(84,87,81),Enum.Material.Metal,desert)
    silo.Shape=Enum.PartType.Cylinder
end

-- SOUTHWEST FOREST
local forest=Instance.new("Folder") forest.Name="Forest" forest.Parent=world
part("ForestGround",Vector3.new(650,1,600),Vector3.new(-650,0,720),Color3.fromRGB(57,91,55),Enum.Material.Grass,forest)
for i=1,70 do
    local x=-930+((i*97)%560)
    local z=470+((i*151)%500)
    local trunk=part("TreeTrunk"..i,Vector3.new(5,20+(i%4)*5,5),Vector3.new(x,10+(i%4)*2.5,z),Color3.fromRGB(93,67,45),Enum.Material.Wood,forest)
    local crown=part("TreeCrown"..i,Vector3.new(18+(i%3)*5,20+(i%4)*4,18+(i%3)*5),Vector3.new(x,27+(i%4)*4,z),Color3.fromRGB(45,89+(i%3)*9,49),Enum.Material.Grass,forest)
    crown.Shape=Enum.PartType.Ball crown.CanCollide=false
end
local bunker=lowBuilding(forest,"ForestBunker",Vector3.new(-640,0,680),Vector3.new(62,15,46),Color3.fromRGB(72,82,68))
label(bunker,"FOREST BUNKER",Color3.fromRGB(175,235,175),Vector3.new(0,11,0),85)

-- SOUTHEAST MOUNTAINS
local mountains=Instance.new("Folder") mountains.Name="Mountains" mountains.Parent=world
part("MountainGround",Vector3.new(650,1,600),Vector3.new(650,0,720),Color3.fromRGB(93,103,86),Enum.Material.Ground,mountains)
for i=1,30 do
    local x=400+((i*113)%520)
    local z=470+((i*167)%500)
    local h=45+(i%7)*18
    local rock=part("Mountain"..i,Vector3.new(55+(i%4)*18,h,55+(i%5)*15),Vector3.new(x,h/2,z),Color3.fromRGB(103+(i%3)*8,99+(i%2)*7,92),Enum.Material.Rock,mountains)
    rock.Orientation=Vector3.new((i*9)%18,(i*31)%180,(i*13)%14)
end
local radar=lowBuilding(mountains,"RadarOutpost",Vector3.new(640,0,680),Vector3.new(52,17,42),Color3.fromRGB(82,88,86))
label(radar,"RADAR OUTPOST",Color3.fromRGB(190,220,255),Vector3.new(0,12,0),85)
local mast=part("RadarMast",Vector3.new(3,55,3),Vector3.new(640,27.5,720),Color3.fromRGB(115,120,122),Enum.Material.Metal,mountains)

-- INDUSTRIAL SOUTH
local industry=Instance.new("Folder") industry.Name="Industry" industry.Parent=world
part("IndustrialPad",Vector3.new(620,1,310),Vector3.new(0,0,870),Color3.fromRGB(108,108,101),Enum.Material.Concrete,industry)
for i=1,6 do lowBuilding(industry,"Factory"..i,Vector3.new(-230+(i-1)*92,0,850+(i%2)*70),Vector3.new(70,20+(i%3)*7,54),Color3.fromRGB(86,91,94)) end
for i=1,4 do
    local tank=part("FuelTank"..i,Vector3.new(30,30,30),Vector3.new(-150+(i-1)*100,15,1000),Color3.fromRGB(152,154,150),Enum.Material.Metal,industry)
    tank.Shape=Enum.PartType.Cylinder
end

-- Eight military player bases around the world perimeter.
local bases=Instance.new("Folder") bases.Name="Bases" bases.Parent=world
for i,pos in ipairs(Config.BASE_POSITIONS) do
    local base=Instance.new("Model") base.Name="Base"..i base:SetAttribute("BaseId",i) base.Parent=bases
    part("BaseFloor",Vector3.new(150,1,120),pos+Vector3.new(0,0.5,0),Color3.fromRGB(91,96,84),Enum.Material.Concrete,base)
    local wall=Color3.fromRGB(72,80,67)
    part("WallN",Vector3.new(150,11,3),pos+Vector3.new(0,5.5,-59),wall,Enum.Material.Concrete,base)
    part("WallSLeft",Vector3.new(58,11,3),pos+Vector3.new(-46,5.5,59),wall,Enum.Material.Concrete,base)
    part("WallSRight",Vector3.new(58,11,3),pos+Vector3.new(46,5.5,59),wall,Enum.Material.Concrete,base)
    part("WallW",Vector3.new(3,11,120),pos+Vector3.new(-74,5.5,0),wall,Enum.Material.Concrete,base)
    part("WallE",Vector3.new(3,11,120),pos+Vector3.new(74,5.5,0),wall,Enum.Material.Concrete,base)
    part("GateL",Vector3.new(4,15,4),pos+Vector3.new(-16,7.5,59),Color3.fromRGB(54,61,53),Enum.Material.Metal,base)
    part("GateR",Vector3.new(4,15,4),pos+Vector3.new(16,7.5,59),Color3.fromRGB(54,61,53),Enum.Material.Metal,base)
    part("GateHeader",Vector3.new(36,2,4),pos+Vector3.new(0,14,59),Color3.fromRGB(50,56,49),Enum.Material.Metal,base)

    local claim=part("ClaimPad",Vector3.new(14,1,14),pos+Vector3.new(0,1,43),Color3.fromRGB(75,160,90),Enum.Material.Neon,base)
    label(claim,"UNCLAIMED BASE",Color3.fromRGB(190,255,195),Vector3.new(0,3.2,0),50)
    prompt(claim,"CLAIM","MILITARY BASE","CLAIM")
    local upgrade=part("UpgradePad",Vector3.new(14,1,14),pos+Vector3.new(-30,1,40),Color3.fromRGB(65,115,190),Enum.Material.Neon,base)
    label(upgrade,"UPGRADE",Color3.fromRGB(165,210,255),Vector3.new(0,3,0),42)
    prompt(upgrade,"UPGRADE","INCOME + BASE","UPGRADE")

    stagePart(base,"CommandCenter",Vector3.new(32,13,26),pos+Vector3.new(-42,6.5,-27),Color3.fromRGB(57,65,58),0,Enum.Material.Metal)
    stagePart(base,"GarageShell",Vector3.new(38,13,28),pos+Vector3.new(42,6.5,-25),Color3.fromRGB(78,82,75),0,Enum.Material.Metal)
    local jeep=stagePart(base,"BaseJeepPad",Vector3.new(16,0.5,10),pos+Vector3.new(42,1,20),Color3.fromRGB(50,130,78),0,Enum.Material.Neon)
    prompt(jeep,"SPAWN JEEP","BASE GARAGE","VEHICLE","Jeep")

    stagePart(base,"Barracks",Vector3.new(34,13,24),pos+Vector3.new(-3,6.5,-30),Color3.fromRGB(69,76,66),1,Enum.Material.Concrete)
    stagePart(base,"WatchTowerA",Vector3.new(7,24,7),pos+Vector3.new(-62,12,-45),Color3.fromRGB(60,66,59),1,Enum.Material.Metal)
    stagePart(base,"WatchTowerB",Vector3.new(7,24,7),pos+Vector3.new(62,12,-45),Color3.fromRGB(60,66,59),1,Enum.Material.Metal)
    stagePart(base,"Armory",Vector3.new(28,13,24),pos+Vector3.new(-43,6.5,6),Color3.fromRGB(55,61,56),2,Enum.Material.Metal)
    stagePart(base,"RadarPole",Vector3.new(2,28,2),pos+Vector3.new(2,14,-40),Color3.fromRGB(72,75,73),2,Enum.Material.Metal)
    stagePart(base,"RadarDish",Vector3.new(12,3,12),pos+Vector3.new(2,29,-40),Color3.fromRGB(140,148,145),2,Enum.Material.Metal).Shape=Enum.PartType.Cylinder
    stagePart(base,"HeavyGarage",Vector3.new(40,15,30),pos+Vector3.new(42,7.5,5),Color3.fromRGB(65,69,64),3,Enum.Material.Metal)
    local armored=stagePart(base,"ArmoredPad",Vector3.new(18,0.5,11),pos+Vector3.new(42,1,38),Color3.fromRGB(142,98,44),3,Enum.Material.Neon)
    prompt(armored,"BUY / SPAWN","ARMORED $25K","VEHICLE","Armored")
    stagePart(base,"Helipad",Vector3.new(30,0.5,30),pos+Vector3.new(-28,1,32),Color3.fromRGB(58,61,58),4,Enum.Material.Metal)
    local heli=stagePart(base,"BaseHelicopterPad",Vector3.new(22,0.2,22),pos+Vector3.new(-28,1.3,32),Color3.fromRGB(65,105,165),4,Enum.Material.Neon)
    prompt(heli,"BUY / SPAWN","HELICOPTER $50K","VEHICLE","Helicopter")
end

-- Strategic landmarks visible when approached.
local strategic={
    {"CENTRAL CITY",Vector3.new(0,0,0),Color3.fromRGB(230,230,235)},
    {"AIRFIELD",Vector3.new(0,0,-780),Color3.fromRGB(190,220,255)},
    {"NAVAL PORT",Vector3.new(-950,0,40),Color3.fromRGB(130,215,255)},
    {"MISSILE RANGE",Vector3.new(900,0,0),Color3.fromRGB(255,205,125)},
    {"FOREST ZONE",Vector3.new(-650,0,720),Color3.fromRGB(160,235,165)},
    {"MOUNTAIN ZONE",Vector3.new(650,0,720),Color3.fromRGB(210,220,225)},
}
for i,d in ipairs(strategic) do
    local marker=part("ZoneMarker"..i,Vector3.new(4,18,4),d[2]+Vector3.new(0,9,0),d[3],Enum.Material.Neon,world)
    marker.Transparency=0.35 marker.CanCollide=false
    label(marker,d[1],d[3],Vector3.new(0,5,0),110)
end

local spawn=Instance.new("SpawnLocation")
spawn.Name="CitySpawn" spawn.Size=Vector3.new(12,1,12) spawn.Position=Vector3.new(0,1,360)
spawn.Anchored=true spawn.Neutral=true spawn.Color=Color3.fromRGB(65,130,205) spawn.Material=Enum.Material.Neon spawn.Parent=world

Lighting.ClockTime=14.2 Lighting.Brightness=2.6
Lighting.Ambient=Color3.fromRGB(136,142,148) Lighting.OutdoorAmbient=Color3.fromRGB(155,162,168)
Lighting.EnvironmentDiffuseScale=0.68 Lighting.EnvironmentSpecularScale=0.58
Lighting.FogEnd=4200
