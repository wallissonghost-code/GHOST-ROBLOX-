local Lighting=game:GetService("Lighting")

local hub=workspace:FindFirstChild("GhostRNGHub")
if hub then hub:Destroy() end
hub=Instance.new("Folder")
hub.Name="GhostRNGHub"
hub.Parent=workspace

local function make(name,size,pos,color,material,parent)
	local p=Instance.new("Part")
	p.Name=name
	p.Size=size
	p.Position=pos
	p.Color=color
	p.Material=material or Enum.Material.SmoothPlastic
	p.Anchored=true
	p.Parent=parent
	return p
end

-- Base arena: still dark, but readable on normal monitors/mobile screens.
local floor=make("ArenaFloor",Vector3.new(180,1,180),Vector3.new(0,-0.5,0),Color3.fromRGB(25,28,40),Enum.Material.Slate,hub)
floor.Reflectance=0.03

-- Large inset platform and concentric detail make the center readable from a distance.
local platform=make("CentralPlatform",Vector3.new(54,1.2,54),Vector3.new(0,0.2,5),Color3.fromRGB(35,38,55),Enum.Material.Metal,hub)
platform.Reflectance=0.08

for i=1,3 do
	local radius=18+i*8
	local thickness=1.2
	for j=1,24 do
		local angle=(j/24)*math.pi*2
		local pos=Vector3.new(math.cos(angle)*radius,0.88,5+math.sin(angle)*radius)
		local seg=make("FloorRing_"..i.."_"..j,Vector3.new(thickness,0.16,3.4),pos,Color3.fromRGB(66,50,108),Enum.Material.Neon,hub)
		seg.CFrame=CFrame.new(pos)*CFrame.Angles(0,-angle,0)
		seg.Transparency=0.2+0.12*i
		seg.CastShadow=false
	end
end

-- Raised RNG altar instead of a flat glowing rectangle.
local altar=Instance.new("Model")
altar.Name="RollAltar"
altar.Parent=hub
make("Base",Vector3.new(18,1.5,14),Vector3.new(0,1.0,18),Color3.fromRGB(31,34,49),Enum.Material.Metal,altar)
make("Step",Vector3.new(13,0.8,10),Vector3.new(0,2.1,18),Color3.fromRGB(48,42,76),Enum.Material.SmoothPlastic,altar)
local pad=make("RollPad",Vector3.new(10,0.45,7),Vector3.new(0,2.75,18),Color3.fromRGB(145,75,245),Enum.Material.Neon,altar)
pad.CastShadow=false
local core=make("Core",Vector3.new(3.8,3.8,3.8),Vector3.new(0,5.4,18),Color3.fromRGB(185,94,255),Enum.Material.Neon,altar)
core.Shape=Enum.PartType.Ball
core.CastShadow=false
local coreLight=Instance.new("PointLight")
coreLight.Color=Color3.fromRGB(177,105,255)
coreLight.Brightness=2.2
coreLight.Range=26
coreLight.Shadows=true
coreLight.Parent=core

if not hub:FindFirstChild("Spawn") then
	local spawn=Instance.new("SpawnLocation")
	spawn.Name="Spawn"
	spawn.Size=Vector3.new(9,1,9)
	spawn.Position=Vector3.new(0,1.1,34)
	spawn.Anchored=true
	spawn.Neutral=true
	spawn.CanCollide=true
	spawn.Material=Enum.Material.Neon
	spawn.Color=Color3.fromRGB(92,60,180)
	spawn.Transparency=0.28
	spawn.Parent=hub
end

local pillarPositions={Vector3.new(-30,7,-18),Vector3.new(30,7,-18),Vector3.new(-30,7,30),Vector3.new(30,7,30)}
for i,pos in pillarPositions do
	local pillar=make("Pillar"..i,Vector3.new(3.2,14,3.2),pos,Color3.fromRGB(43,46,64),Enum.Material.Metal,hub)
	local cap=make("PillarGlow"..i,Vector3.new(4.6,0.55,4.6),pos+Vector3.new(0,7.2,0),Color3.fromRGB(172,92,255),Enum.Material.Neon,hub)
	pillar.CastShadow=true
	cap.CastShadow=false
	local light=Instance.new("PointLight")
	light.Color=Color3.fromRGB(158,95,255)
	light.Brightness=1.2
	light.Range=20
	light.Parent=cap
end

-- Entry path from spawn to altar.
for i=0,5 do
	local z=31-i*3.8
	local tile=make("EntryTile"..i,Vector3.new(6.2,0.16,2.2),Vector3.new(0,0.66,z),Color3.fromRGB(79,58,129),Enum.Material.Neon,hub)
	tile.Transparency=0.2
	tile.CastShadow=false
end

local titleAnchor=make("TitleAnchor",Vector3.new(1,1,1),Vector3.new(0,10,5),Color3.new(1,1,1),Enum.Material.SmoothPlastic,hub)
titleAnchor.Transparency=1
titleAnchor.CanCollide=false
local gui=Instance.new("BillboardGui")
gui.Name="TitleGui"
gui.Size=UDim2.fromOffset(600,125)
gui.AlwaysOnTop=true
gui.MaxDistance=150
gui.Parent=titleAnchor
local title=Instance.new("TextLabel")
title.Size=UDim2.fromScale(1,0.66)
title.BackgroundTransparency=1
title.Text="GHOST RNG"
title.TextColor3=Color3.fromRGB(240,234,255)
title.TextStrokeTransparency=0.72
title.TextScaled=true
title.Font=Enum.Font.GothamBlack
title.Parent=gui
local sub=Instance.new("TextLabel")
sub.Position=UDim2.fromScale(0,0.7)
sub.Size=UDim2.fromScale(1,0.25)
sub.BackgroundTransparency=1
sub.Text="ROLL  •  COLLECT  •  HUNT THE IMPOSSIBLE"
sub.TextColor3=Color3.fromRGB(190,158,255)
sub.TextScaled=true
sub.Font=Enum.Font.GothamBold
sub.Parent=gui

local stand=Instance.new("Model")
stand.Name="LatestRelicStand"
stand.Parent=hub
make("Base",Vector3.new(9,1,9),Vector3.new(0,1,-10),Color3.fromRGB(33,36,51),Enum.Material.Slate,stand)
make("Column",Vector3.new(5.8,1.3,5.8),Vector3.new(0,2.0,-10),Color3.fromRGB(44,40,68),Enum.Material.Metal,stand)
local top=make("Top",Vector3.new(5.3,0.32,5.3),Vector3.new(0,2.82,-10),Color3.fromRGB(133,78,225),Enum.Material.Neon,stand)
top.CastShadow=false
local standLight=Instance.new("PointLight")
standLight.Color=Color3.fromRGB(145,91,235)
standLight.Brightness=1.1
standLight.Range=14
standLight.Parent=top

Lighting.Brightness=2.8
Lighting.ClockTime=19.2
Lighting.Ambient=Color3.fromRGB(78,75,102)
Lighting.OutdoorAmbient=Color3.fromRGB(52,55,76)
Lighting.EnvironmentDiffuseScale=0.55
Lighting.EnvironmentSpecularScale=0.7
Lighting.ExposureCompensation=0.25
Lighting.GlobalShadows=true

local atmosphere=Lighting:FindFirstChild("GhostAtmosphere") or Instance.new("Atmosphere")
atmosphere.Name="GhostAtmosphere"
atmosphere.Density=0.16
atmosphere.Offset=0.08
atmosphere.Color=Color3.fromRGB(150,145,185)
atmosphere.Decay=Color3.fromRGB(58,48,80)
atmosphere.Glare=0.04
atmosphere.Haze=0.65
atmosphere.Parent=Lighting

local bloom=Lighting:FindFirstChild("GhostBloom") or Instance.new("BloomEffect")
bloom.Name="GhostBloom"
bloom.Intensity=0.55
bloom.Size=24
bloom.Threshold=1.35
bloom.Parent=Lighting

local cc=Lighting:FindFirstChild("GhostColor") or Instance.new("ColorCorrectionEffect")
cc.Name="GhostColor"
cc.Brightness=0.04
cc.Contrast=0.08
cc.Saturation=-0.04
cc.TintColor=Color3.fromRGB(232,224,255)
cc.Parent=Lighting
