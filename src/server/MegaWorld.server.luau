local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

-- Giant blank foundation. 16,384 x 16,384 studs, centered at origin.
-- Built from 1,024-stud tiles so we stay well below per-part size limits.
local WORLD_SIZE = 16384
local TILE_SIZE = 1024
local HALF = WORLD_SIZE / 2
local GROUND_Y = 0

Workspace.StreamingEnabled = true
Workspace.StreamingMinRadius = 256
Workspace.StreamingTargetRadius = 1024
Workspace.FallenPartsDestroyHeight = -1000

local old = Workspace:FindFirstChild("MegaWorld")
if old then
	old:Destroy()
end

local world = Instance.new("Folder")
world.Name = "MegaWorld"
world.Parent = Workspace

local tiles = Instance.new("Folder")
tiles.Name = "GroundTiles"
tiles.Parent = world

for x = -HALF + TILE_SIZE / 2, HALF - TILE_SIZE / 2, TILE_SIZE do
	for z = -HALF + TILE_SIZE / 2, HALF - TILE_SIZE / 2, TILE_SIZE do
		local tile = Instance.new("Part")
		tile.Name = string.format("Ground_%d_%d", x, z)
		tile.Anchored = true
		tile.CanCollide = true
		tile.CanTouch = true
		tile.CanQuery = true
		tile.Size = Vector3.new(TILE_SIZE, 24, TILE_SIZE)
		tile.Position = Vector3.new(x, GROUND_Y - 12, z)
		tile.Material = Enum.Material.Grass
		tile.Color = Color3.fromRGB(92, 118, 74)
		tile.TopSurface = Enum.SurfaceType.Smooth
		tile.BottomSurface = Enum.SurfaceType.Smooth
		tile.Parent = tiles
	end
end

-- Ocean border, giving the continent a visible end while keeping the playable land enormous.
local border = 1536
local waterY = -8
local ocean = Instance.new("Folder")
ocean.Name = "OceanBorder"
ocean.Parent = world

local function oceanPart(name, size, pos)
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

oceanPart("NorthOcean", Vector3.new(WORLD_SIZE + border * 2, 12, border), Vector3.new(0, waterY, -HALF - border / 2))
oceanPart("SouthOcean", Vector3.new(WORLD_SIZE + border * 2, 12, border), Vector3.new(0, waterY, HALF + border / 2))
oceanPart("WestOcean", Vector3.new(border, 12, WORLD_SIZE), Vector3.new(-HALF - border / 2, waterY, 0))
oceanPart("EastOcean", Vector3.new(border, 12, WORLD_SIZE), Vector3.new(HALF + border / 2, waterY, 0))

-- Central spawn only. No buildings/gameplay yet.
local spawn = Instance.new("SpawnLocation")
spawn.Name = "CentralSpawn"
spawn.Anchored = true
spawn.Neutral = true
spawn.Size = Vector3.new(24, 1, 24)
spawn.Position = Vector3.new(0, 1, 0)
spawn.Material = Enum.Material.SmoothPlastic
spawn.Color = Color3.fromRGB(70, 70, 70)
spawn.Parent = world

Lighting.Brightness = 2.2
Lighting.ClockTime = 13.5
Lighting.EnvironmentDiffuseScale = 0.35
Lighting.EnvironmentSpecularScale = 0.5
Lighting.GlobalShadows = true

world:SetAttribute("WorldSizeStuds", WORLD_SIZE)
world:SetAttribute("TileSizeStuds", TILE_SIZE)
print(string.format("MegaWorld ready: %d x %d studs (%d ground tiles)", WORLD_SIZE, WORLD_SIZE, (WORLD_SIZE / TILE_SIZE) ^ 2))
