local Lighting=game:GetService("Lighting")

local hub=workspace:FindFirstChild("GhostRNGHub")
if not hub then
	hub=Instance.new("Folder")
	hub.Name="GhostRNGHub"
	hub.Parent=workspace
end

local function make(name,size,pos,color,material,parent)
	local old=parent:FindFirstChild(name)
	if old then return old end
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

make("ArenaFloor",Vector3.new(180,1,180),Vector3.new(0,-0.5,0),Color3.fromRGB(14,16,23),Enum.Material.Slate,hub)
make("CentralPlatform",Vector3.new(42,1.2,42),Vector3.new(0,0.2,5),Color3.fromRGB(27,29,42),Enum.Material.Metal,hub)
make("RollPad",Vector3.new(18,0.4,12),Vector3.new(0,1,18),Color3.fromRGB(111,65,205),Enum.Material.Neon,hub)

if not hub:FindFirstChild("Spawn") then
	local spawn=Instance.new("SpawnLocation")
	spawn.Name="Spawn"
	spawn.Size=Vector3.new(9,1,9)
	spawn.Position=Vector3.new(0,1.1,31)
	spawn.Anchored=true
	spawn.Neutral=true
	spawn.CanCollide=true
	spawn.Material=Enum.Material.Neon
	spawn.Color=Color3.fromRGB(92,60,180)
	spawn.Transparency=0.12
	spawn.Parent=hub
end

local pillarPositions={Vector3.new(-28,7,-16),Vector3.new(28,7,-16),Vector3.new(-28,7,26),Vector3.new(28,7,26)}
for i,pos in pillarPositions do
	local pillar=make("Pillar"..i,Vector3.new(3,14,3),pos,Color3.fromRGB(36,38,55),Enum.Material.Metal,hub)
	local cap=make("PillarGlow"..i,Vector3.new(4.2,0.5,4.2),pos+Vector3.new(0,7.2,0),Color3.fromRGB(168,92,255),Enum.Material.Neon,hub)
	pillar.CastShadow=true
	cap.CastShadow=false
end

for i=1,16 do
	local angle=(i/16)*math.pi*2
	local p=make("RingLight"..i,Vector3.new(2.2,0.28,0.45),Vector3.new(math.cos(angle)*24,1.05+math.sin(i*1.7)*0.05,5+math.sin(angle)*24),Color3.fromRGB(126,69,240),Enum.Material.Neon,hub)
	p.CFrame=CFrame.new(p.Position)*CFrame.Angles(0,-angle,0)
end

local titleAnchor=make("TitleAnchor",Vector3.new(1,1,1),Vector3.new(0,9,8),Color3.new(1,1,1),Enum.Material.SmoothPlastic,hub)
titleAnchor.Transparency=1
titleAnchor.CanCollide=false
if not titleAnchor:FindFirstChild("TitleGui") then
	local gui=Instance.new("BillboardGui")
	gui.Name="TitleGui"
	gui.Size=UDim2.fromOffset(700,150)
	gui.AlwaysOnTop=true
	gui.Parent=titleAnchor
	local title=Instance.new("TextLabel")
	title.Size=UDim2.fromScale(1,0.68)
	title.BackgroundTransparency=1
	title.Text="GHOST RNG"
	title.TextColor3=Color3.fromRGB(235,225,255)
	title.TextStrokeTransparency=0.55
	title.TextScaled=true
	title.Font=Enum.Font.GothamBlack
	title.Parent=gui
	local sub=Instance.new("TextLabel")
	sub.Position=UDim2.fromScale(0,0.7)
	sub.Size=UDim2.fromScale(1,0.3)
	sub.BackgroundTransparency=1
	sub.Text="ROLL • COLLECT • HUNT THE IMPOSSIBLE"
	sub.TextColor3=Color3.fromRGB(185,150,255)
	sub.TextScaled=true
	sub.Font=Enum.Font.GothamBold
	sub.Parent=gui
end

if not hub:FindFirstChild("LatestRelicStand") then
	local stand=Instance.new("Model")
	stand.Name="LatestRelicStand"
	stand.Parent=hub
	make("Base",Vector3.new(8,1,8),Vector3.new(0,1,-10),Color3.fromRGB(28,30,42),Enum.Material.Slate,stand)
	make("Top",Vector3.new(5.5,0.35,5.5),Vector3.new(0,1.68,-10),Color3.fromRGB(126,75,220),Enum.Material.Neon,stand)
end

Lighting.Brightness=2
Lighting.ClockTime=20
Lighting.Ambient=Color3.fromRGB(55,52,75)
Lighting.OutdoorAmbient=Color3.fromRGB(34,36,52)
Lighting.EnvironmentDiffuseScale=0.35
Lighting.EnvironmentSpecularScale=0.6

if not Lighting:FindFirstChild("GhostAtmosphere") then
	local atmosphere=Instance.new("Atmosphere")
	atmosphere.Name="GhostAtmosphere"
	atmosphere.Density=0.23
	atmosphere.Offset=0.05
	atmosphere.Color=Color3.fromRGB(130,125,170)
	atmosphere.Decay=Color3.fromRGB(48,38,70)
	atmosphere.Glare=0.08
	atmosphere.Haze=1.2
	atmosphere.Parent=Lighting
end
