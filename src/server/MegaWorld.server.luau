local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local WORLD_SIZE = 16384
local TILE_SIZE = 1024
local HALF = WORLD_SIZE / 2
local GROUND_Y = 0
local MAX_PART_SPAN = 1024

Workspace.FallenPartsDestroyHeight = -1000

local old = Workspace:FindFirstChild("MegaWorld")
if old then
	old:Destroy()
end

local world = Instance.new("Folder")
world.Name = "MegaWorld"
world.Parent = Workspace

-- Guaranteed center platform before any generated content.
local safePlatform = Instance.new("Part")
safePlatform.Name = "CentralSafePlatform"
safePlatform.Anchored = true
safePlatform.CanCollide = true
safePlatform.Size = Vector3.new(512, 32, 512)
safePlatform.Position = Vector3.new(0, -16, 0)
safePlatform.Material = Enum.Material.Concrete
safePlatform.Color = Color3.fromRGB(105, 108, 106)
safePlatform.TopSurface = Enum.SurfaceType.Smooth
safePlatform.BottomSurface = Enum.SurfaceType.Smooth
safePlatform.Parent = world

local spawn = Instance.new("SpawnLocation")
spawn.Name = "CentralSpawn"
spawn.Anchored = true
spawn.Neutral = true
spawn.Enabled = true
spawn.Size = Vector3.new(24, 1, 24)
spawn.Position = Vector3.new(0, 2, 0)
spawn.Material = Enum.Material.Neon
spawn.Color = Color3.fromRGB(80, 200, 255)
spawn.Parent = world

local tiles = Instance.new("Folder")
tiles.Name = "GroundTiles"
tiles.Parent = world

local regionsFolder = Instance.new("Folder")
regionsFolder.Name = "Regions"
regionsFolder.Parent = world

local REGIONS = {
	{ name = "CapitalCity", center = Vector3.new(0, 0, 0), size = Vector2.new(4096, 4096), color = Color3.fromRGB(105, 108, 110), material = Enum.Material.Concrete },
	{ name = "Forest", center = Vector3.new(-4608, 0, -4096), size = Vector2.new(5120, 5120), color = Color3.fromRGB(52, 102, 48), material = Enum.Material.Grass },
	{ name = "Desert", center = Vector3.new(4864, 0, -4096), size = Vector2.new(4864, 5120), color = Color3.fromRGB(190, 155, 92), material = Enum.Material.Sand },
	{ name = "Mountains", center = Vector3.new(4864, 0, 4352), size = Vector2.new(4864, 4608), color = Color3.fromRGB(89, 93, 91), material = Enum.Material.Slate },
	{ name = "Airport", center = Vector3.new(0, 0, -5632), size = Vector2.new(4096, 3072), color = Color3.fromRGB(65, 67, 68), material = Enum.Material.Concrete },
	{ name = "Harbor", center = Vector3.new(-5632, 0, 3072), size = Vector2.new(3072, 4096), color = Color3.fromRGB(88, 101, 106), material = Enum.Material.Concrete },
	{ name = "Industrial", center = Vector3.new(0, 0, 5632), size = Vector2.new(4096, 3072), color = Color3.fromRGB(111, 99, 78), material = Enum.Material.Concrete },
	{ name = "PlayerBases", center = Vector3.new(-4608, 0, 5376), size = Vector2.new(5120, 3072), color = Color3.fromRGB(70, 96, 60), material = Enum.Material.Grass },
}

local function regionFor(x, z)
	for _, r in ipairs(REGIONS) do
		local dx = math.abs(x - r.center.X)
		local dz = math.abs(z - r.center.Z)
		if dx <= r.size.X / 2 and dz <= r.size.Y / 2 then
			return r
		end
	end
	return nil
end

-- Store region metadata without creating oversized physical marker parts.
for _, r in ipairs(REGIONS) do
	local marker = Instance.new("Folder")
	marker.Name = r.name
	marker.Parent = regionsFolder
	marker:SetAttribute("RegionName", r.name)
	marker:SetAttribute("CenterX", r.center.X)
	marker:SetAttribute("CenterZ", r.center.Z)
	marker:SetAttribute("SizeX", r.size.X)
	marker:SetAttribute("SizeZ", r.size.Y)
end

local created = {}
local function tileKey(x, z)
	return tostring(x) .. ":" .. tostring(z)
end

local function createTile(x, z)
	local key = tileKey(x, z)
	if created[key] then return end
	created[key] = true

	local tile = Instance.new("Part")
	tile.Name = string.format("Ground_%d_%d", x, z)
	tile.Anchored = true
	tile.CanCollide = true
	tile.CanTouch = true
	tile.CanQuery = true
	tile.Size = Vector3.new(TILE_SIZE, 24, TILE_SIZE)
	tile.Position = Vector3.new(x, GROUND_Y - 12, z)

	local r = regionFor(x, z)
	if r then
		tile.Material = r.material
		tile.Color = r.color
		tile:SetAttribute("Region", r.name)
	else
		tile.Material = Enum.Material.Grass
		tile.Color = Color3.fromRGB(92, 118, 74)
		tile:SetAttribute("Region", "Wilderness")
	end

	tile.TopSurface = Enum.SurfaceType.Smooth
	tile.BottomSurface = Enum.SurfaceType.Smooth
	tile.Parent = tiles
end

-- Central land first.
for _, pos in ipairs({
	Vector2.new(-512, -512),
	Vector2.new(512, -512),
	Vector2.new(-512, 512),
	Vector2.new(512, 512),
}) do
	createTile(pos.X, pos.Y)
end

for x = -HALF + TILE_SIZE / 2, HALF - TILE_SIZE / 2, TILE_SIZE do
	for z = -HALF + TILE_SIZE / 2, HALF - TILE_SIZE / 2, TILE_SIZE do
		createTile(x, z)
	end
end

-- Visible regional road network.
local roads = Instance.new("Folder")
roads.Name = "RegionalRoads"
roads.Parent = world

local function road(name, size, position)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = true
	p.Size = size
	p.Position = position
	p.Material = Enum.Material.Concrete
	p.Color = Color3.fromRGB(42, 44, 46)
	p.TopSurface = Enum.SurfaceType.Smooth
	p.Parent = roads
end

-- All road pieces stay below 1024 studs per axis.
for z = -7168, 7168, 1024 do
	road("NorthSouth_" .. tostring(z), Vector3.new(96, 2, 1024), Vector3.new(0, 1, z))
end
for x = -7168, 7168, 1024 do
	road("EastWest_" .. tostring(x), Vector3.new(1024, 2, 96), Vector3.new(x, 1, 0))
end

-- Region name beacons visible from a distance.
local beacons = Instance.new("Folder")
beacons.Name = "RegionBeacons"
beacons.Parent = world

for _, r in ipairs(REGIONS) do
	local pole = Instance.new("Part")
	pole.Name = r.name .. "Beacon"
	pole.Anchored = true
	pole.CanCollide = false
	pole.Size = Vector3.new(10, 120, 10)
	pole.Position = Vector3.new(r.center.X, 60, r.center.Z)
	pole.Material = Enum.Material.Neon
	pole.Color = r.color
	pole.Parent = beacons

	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.AlwaysOnTop = true
	gui.MaxDistance = 6000
	gui.Size = UDim2.fromOffset(420, 90)
	gui.StudsOffset = Vector3.new(0, 70, 0)
	gui.Parent = pole

	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 0.2
	text.BackgroundColor3 = Color3.fromRGB(10, 12, 14)
	text.Size = UDim2.fromScale(1, 1)
	text.Text = r.name
	text.TextScaled = true
	text.TextColor3 = Color3.new(1, 1, 1)
	text.Font = Enum.Font.GothamBold
	text.Parent = gui
end

-- Ocean border split into legal 1024-stud chunks.
local ocean = Instance.new("Folder")
ocean.Name = "OceanBorder"
ocean.Parent = world

local function oceanChunk(name, size, pos)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Material = Enum.Material.Glass
	p.Transparency = 0.28
	p.Color = Color3.fromRGB(43, 139, 191)
	p.Size = size
	p.Position = pos
	p.Parent = ocean
end

local waterY = -8
local oceanWidth = 1024
for x = -HALF + 512, HALF - 512, 1024 do
	oceanChunk("North_" .. x, Vector3.new(1024, 12, oceanWidth), Vector3.new(x, waterY, -HALF - 512))
	oceanChunk("South_" .. x, Vector3.new(1024, 12, oceanWidth), Vector3.new(x, waterY, HALF + 512))
end
for z = -HALF + 512, HALF - 512, 1024 do
	oceanChunk("West_" .. z, Vector3.new(oceanWidth, 12, 1024), Vector3.new(-HALF - 512, waterY, z))
	oceanChunk("East_" .. z, Vector3.new(oceanWidth, 12, 1024), Vector3.new(HALF + 512, waterY, z))
end

Lighting.Brightness = 2.2
Lighting.ClockTime = 13.5
Lighting.EnvironmentDiffuseScale = 0.35
Lighting.EnvironmentSpecularScale = 0.5
Lighting.GlobalShadows = true

world:SetAttribute("WorldSizeStuds", WORLD_SIZE)
world:SetAttribute("TileSizeStuds", TILE_SIZE)
world:SetAttribute("RegionCount", #REGIONS)
world:SetAttribute("Ready", true)

print(string.format("MegaWorld ready: %dx%d studs, %d regions", WORLD_SIZE, WORLD_SIZE, #REGIONS))
