-- Creator Store visual integration. Asset-specific terms remain with their publishers.
local InsertService = game:GetService("InsertService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local ASSETS = {
	{ key="CityMap", id=13293134923, center=Vector3.new(0,0,0), targetSpan=3600 },
	{ key="AirportMap", id=6766877061, center=Vector3.new(0,0,-5600), targetSpan=2800 },
	{ key="ForestMap", id=4456737684, center=Vector3.new(-4600,0,-4100), targetSpan=3900 },
	{ key="DesertMap", id=15990266983, center=Vector3.new(4800,0,-4100), targetSpan=3600 },
	{ key="PoliceStation", id=33847327, center=Vector3.new(850,0,500), targetSpan=520 },
	{ key="Barracks", id=90332800671052, template=true, targetSpan=360 },
	{ key="MilitaryBase", id=30356632, template=true, targetSpan=700 },
	{ key="ArmyJeep", id=11361934938, template=true, targetSpan=22 },
	{ key="Helicopter", id=6722486398, template=true, targetSpan=34 },
}

local BASE_POSITIONS = {
	Vector3.new(-6900,0,-6500), Vector3.new(-2600,0,-6900),
	Vector3.new(2600,0,-6900), Vector3.new(6900,0,-5600),
	Vector3.new(6900,0,5600), Vector3.new(2600,0,6900),
	Vector3.new(-2600,0,6900), Vector3.new(-6900,0,5600),
}

local old = Workspace:FindFirstChild("PremiumWorld")
if old then old:Destroy() end
local premiumWorld = Instance.new("Folder")
premiumWorld.Name = "PremiumWorld"
premiumWorld.Parent = Workspace

local templates = ServerStorage:FindFirstChild("PremiumTemplates")
if templates then templates:Destroy() end
templates = Instance.new("Folder")
templates.Name = "PremiumTemplates"
templates.Parent = ServerStorage

local function sanitize(root)
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then
			d:Destroy()
		elseif d:IsA("ProximityPrompt") or d:IsA("ClickDetector") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CanTouch = false
			d.CanQuery = true
		end
	end
end

local function normalize(model, targetSpan)
	local _, size = model:GetBoundingBox()
	local span = math.max(size.X, size.Y, size.Z)
	if span > 0 and targetSpan and targetSpan > 0 then
		local factor = math.clamp(targetSpan / span, 0.05, 20)
		pcall(function() model:ScaleTo(model:GetScale() * factor) end)
	end
end

local function groundAt(model, center)
	local cf, size = model:GetBoundingBox()
	local bottom = cf.Position.Y - size.Y/2
	local delta = Vector3.new(center.X - cf.Position.X, center.Y - bottom, center.Z - cf.Position.Z)
	model:PivotTo(model:GetPivot() + delta)
end

local function load(id)
	local ok, container = pcall(function() return InsertService:LoadAsset(id) end)
	if not ok or not container then
		warn("[PremiumAssetLoader] failed asset", id, container)
		return nil
	end
	sanitize(container)
	return container
end

local loaded = {}
for _, spec in ipairs(ASSETS) do
	local model = load(spec.id)
	if model then
		model.Name = spec.key
		normalize(model, spec.targetSpan)
		if spec.template then
			model.Parent = templates
		else
			groundAt(model, spec.center)
			model.Parent = premiumWorld
		end
		loaded[spec.key] = model
	end
	task.wait(0.2)
end

local baseTemplate = loaded.MilitaryBase or loaded.Barracks
if baseTemplate then
	for i, pos in ipairs(BASE_POSITIONS) do
		local clone = baseTemplate:Clone()
		clone.Name = "MilitaryBase_" .. i
		groundAt(clone, pos)
		clone.Parent = premiumWorld
		clone:SetAttribute("BaseIndex", i)
	end
end

premiumWorld:SetAttribute("Ready", true)
premiumWorld:SetAttribute("LoadedAssetCount", #premiumWorld:GetChildren())
print("[PremiumAssetLoader] ready", #premiumWorld:GetChildren())
