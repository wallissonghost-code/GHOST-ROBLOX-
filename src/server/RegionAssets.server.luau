local InsertService = game:GetService("InsertService")
local Workspace = game:GetService("Workspace")

local world = Workspace:WaitForChild("MegaWorld")
local regions = world:WaitForChild("Regions")

local imported = Instance.new("Folder")
imported.Name = "ImportedRegionAssets"
imported.Parent = world

local ASSETS = {
	CapitalCity = { id = 15351086718, name = "City Buildings", maxSize = 1300, offset = Vector3.new(0,0,0) },
	Forest = { id = 4456737684, name = "ForestMap", maxSize = 1800, offset = Vector3.new(-4500,0,-4050) },
	Desert = { id = 15990266983, name = "Desert Map", maxSize = 1800, offset = Vector3.new(4800,0,-4000) },
	Mountains = { id = 9437433680, name = "Mountain", maxSize = 1600, offset = Vector3.new(5000,0,4400) },
	Airport = { id = 6766877061, name = "Airport Map", maxSize = 1700, offset = Vector3.new(0,0,-5600) },
}

local function sanitize(root)
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") or d:IsA("ProximityPrompt") or d:IsA("ClickDetector") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CanTouch = false
		end
	end
end

local function groundModel(model, target, maxSize)
	local ok, size = pcall(function() return model:GetExtentsSize() end)
	if not ok or size.Magnitude <= 0 then return false end
	local largest = math.max(size.X,size.Y,size.Z)
	if largest > maxSize and model.ScaleTo then
		pcall(function() model:ScaleTo(maxSize/largest) end)
	end
	local ok2, cf, sz = pcall(function() return model:GetBoundingBox() end)
	if not ok2 then return false end
	local desiredY = 0 + sz.Y/2
	model:PivotTo(CFrame.new(target.X,desiredY,target.Z) * (cf-cf.Position))
	return true
end

local function loadRegion(regionName, data)
	local marker = regions:FindFirstChild(regionName.."RegionMarker")
	if not marker then return end
	local ok, container = pcall(function() return InsertService:LoadAsset(data.id) end)
	if not ok or not container then
		warn("Region asset failed",regionName,data.id)
		return
	end
	local model = container:FindFirstChildWhichIsA("Model") or container
	model.Name = regionName.."_"..data.name:gsub("%s+","_")
	model.Parent = imported
	sanitize(model)
	groundModel(model,data.offset,data.maxSize)
	if container ~= model then container:Destroy() end
	model:SetAttribute("SourceAssetId",data.id)
	model:SetAttribute("SourceName",data.name)
end

for regionName,data in pairs(ASSETS) do
	task.spawn(loadRegion,regionName,data)
end

-- Large reserved pads for future premium/base-area content.
local function reserve(name, center, size, color)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.Transparency = 0.72
	p.Material = Enum.Material.ForceField
	p.Color = color
	p.Size = Vector3.new(size.X,1,size.Y)
	p.Position = Vector3.new(center.X,0.6,center.Z)
	p.Parent = imported
end
reserve("HarborReserved",Vector3.new(-5632,0,3072),Vector2.new(2400,3200),Color3.fromRGB(45,145,190))
reserve("IndustrialReserved",Vector3.new(0,0,5632),Vector2.new(3200,2200),Color3.fromRGB(145,120,80))
reserve("PlayerBasesReserved",Vector3.new(-4608,0,5376),Vector2.new(4300,2200),Color3.fromRGB(80,180,85))
