local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local WORLD_SIZE = 16384
local TILE_SIZE = 1024
local HALF = WORLD_SIZE / 2
local GROUND_Y = 0

Workspace.StreamingEnabled = true
Workspace.StreamingMinRadius = 256
Workspace.StreamingTargetRadius = 1280
Workspace.FallenPartsDestroyHeight = -1000

local old = Workspace:FindFirstChild("MegaWorld")
if old then old:Destroy() end

local world = Instance.new("Folder")
world.Name = "MegaWorld"
world.Parent = Workspace

local tiles = Instance.new("Folder")
tiles.Name = "GroundTiles"
tiles.Parent = world

local regionsFolder = Instance.new("Folder")
regionsFolder.Name = "Regions"
regionsFolder.Parent = world

local REGIONS = {
	{ name = "CapitalCity", center = Vector3.new(0,0,0), size = Vector2.new(4096,4096), color = Color3.fromRGB(104,108,106), material = Enum.Material.Concrete },
	{ name = "Forest", center = Vector3.new(-4608,0,-4096), size = Vector2.new(5120,5120), color = Color3.fromRGB(60,104,55), material = Enum.Material.Grass },
	{ name = "Desert", center = Vector3.new(4864,0,-4096), size = Vector2.new(4864,5120), color = Color3.fromRGB(186,153,96), material = Enum.Material.Sand },
	{ name = "Mountains", center = Vector3.new(4864,0,4352), size = Vector2.new(4864,4608), color = Color3.fromRGB(95,101,91), material = Enum.Material.Slate },
	{ name = "Airport", center = Vector3.new(0,0,-5632), size = Vector2.new(4096,3072), color = Color3.fromRGB(89,92,91), material = Enum.Material.Asphalt },
	{ name = "Harbor", center = Vector3.new(-5632,0,3072), size = Vector2.new(3072,4096), color = Color3.fromRGB(97,103,100), material = Enum.Material.Concrete },
	{ name = "Industrial", center = Vector3.new(0,0,5632), size = Vector2.new(4096,3072), color = Color3.fromRGB(104,99,89), material = Enum.Material.Concrete },
	{ name = "PlayerBases", center = Vector3.new(-4608,0,5376), size = Vector2.new(5120,3072), color = Color3.fromRGB(74,91,66), material = Enum.Material.Grass },
}

local function regionFor(x,z)
	for _, r in ipairs(REGIONS) do
		local dx = math.abs(x-r.center.X)
		local dz = math.abs(z-r.center.Z)
		if dx <= r.size.X/2 and dz <= r.size.Y/2 then return r end
	end
	return nil
end

for _,r in ipairs(REGIONS) do
	local marker = Instance.new("Part")
	marker.Name = r.name.."RegionMarker"
	marker.Anchored = true
	marker.CanCollide = false
	marker.CanTouch = false
	marker.CanQuery = false
	marker.Transparency = 1
	marker.Size = Vector3.new(r.size.X,2,r.size.Y)
	marker.Position = Vector3.new(r.center.X,2,r.center.Z)
	marker.Parent = regionsFolder
	marker:SetAttribute("RegionName",r.name)
	marker:SetAttribute("CenterX",r.center.X)
	marker:SetAttribute("CenterZ",r.center.Z)
	marker:SetAttribute("SizeX",r.size.X)
	marker:SetAttribute("SizeZ",r.size.Y)
end

for x = -HALF + TILE_SIZE/2, HALF - TILE_SIZE/2, TILE_SIZE do
	for z = -HALF + TILE_SIZE/2, HALF - TILE_SIZE/2, TILE_SIZE do
		local tile = Instance.new("Part")
		tile.Name = string.format("Ground_%d_%d",x,z)
		tile.Anchored = true
		tile.CanCollide = true
		tile.Size = Vector3.new(TILE_SIZE,24,TILE_SIZE)
		tile.Position = Vector3.new(x,GROUND_Y-12,z)
		local r = regionFor(x,z)
		if r then
			tile.Material = r.material
			tile.Color = r.color
			tile:SetAttribute("Region",r.name)
		else
			tile.Material = Enum.Material.Grass
			tile.Color = Color3.fromRGB(92,118,74)
			tile:SetAttribute("Region","Wilderness")
		end
		tile.TopSurface = Enum.SurfaceType.Smooth
		tile.BottomSurface = Enum.SurfaceType.Smooth
		tile.Parent = tiles
	end
end

local border = 1536
local waterY = -8
local ocean = Instance.new("Folder")
ocean.Name = "OceanBorder"
ocean.Parent = world
local function oceanPart(name,size,pos)
	local p = Instance.new("Part")
	p.Name=name p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false
	p.Material=Enum.Material.Glass p.Transparency=.28 p.Color=Color3.fromRGB(43,139,191)
	p.Size=size p.Position=pos p.Parent=ocean
end
oceanPart("NorthOcean",Vector3.new(WORLD_SIZE+border*2,12,border),Vector3.new(0,waterY,-HALF-border/2))
oceanPart("SouthOcean",Vector3.new(WORLD_SIZE+border*2,12,border),Vector3.new(0,waterY,HALF+border/2))
oceanPart("WestOcean",Vector3.new(border,12,WORLD_SIZE),Vector3.new(-HALF-border/2,waterY,0))
oceanPart("EastOcean",Vector3.new(border,12,WORLD_SIZE),Vector3.new(HALF+border/2,waterY,0))

local spawn = Instance.new("SpawnLocation")
spawn.Name="CentralSpawn" spawn.Anchored=true spawn.Neutral=true
spawn.Size=Vector3.new(24,1,24) spawn.Position=Vector3.new(0,1,0)
spawn.Material=Enum.Material.SmoothPlastic spawn.Color=Color3.fromRGB(70,70,70)
spawn.Parent=world

Lighting.Brightness=2.2
Lighting.ClockTime=13.5
Lighting.EnvironmentDiffuseScale=.35
Lighting.EnvironmentSpecularScale=.5
Lighting.GlobalShadows=true

world:SetAttribute("WorldSizeStuds",WORLD_SIZE)
world:SetAttribute("TileSizeStuds",TILE_SIZE)
world:SetAttribute("RegionCount",#REGIONS)
print(string.format("MegaWorld ready: %dx%d studs, %d regions",WORLD_SIZE,WORLD_SIZE,#REGIONS))
