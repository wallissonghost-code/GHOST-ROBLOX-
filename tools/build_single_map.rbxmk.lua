local inputPath, outputPath = ...

local asset = fs.read(inputPath, "rbxm")
asset[sym.RawDesc] = rbxmk.globalDesc

local dataModel = Instance.new("DataModel")
local workspace = Instance.new("Workspace")
workspace.Name = "Workspace"
workspace.Parent = dataModel

for _, child in ipairs(asset:GetChildren()) do
	child.Parent = workspace
end

-- Remove executable/interactive content from the public model. Keep only visual/world content.
for _, inst in ipairs(workspace:GetDescendants()) do
	if inst:IsA("Script") or inst:IsA("LocalScript") or inst:IsA("ModuleScript") then
		inst:Destroy()
	elseif inst:IsA("ProximityPrompt") or inst:IsA("ClickDetector") then
		inst:Destroy()
	end
end

-- Reuse an existing spawn when available. Otherwise place one above the largest floor-like BasePart.
local spawn = nil
local largestPart = nil
local largestArea = 0
for _, inst in ipairs(workspace:GetDescendants()) do
	if inst:IsA("SpawnLocation") then
		spawn = inst
	elseif inst:IsA("BasePart") then
		local size = inst.Size
		local area = size.X * size.Z
		if area > largestArea then
			largestArea = area
			largestPart = inst
		end
	end
end

if not spawn and largestPart then
	spawn = Instance.new("SpawnLocation")
	spawn.Name = "MainSpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.CanCollide = true
	spawn.Size = Vector3.new(20, 2, 20)
	spawn.Position = largestPart.Position + Vector3.new(0, largestPart.Size.Y / 2 + 4, 0)
	spawn.Parent = workspace
end

fs.write(outputPath, dataModel, "rbxlx")
print("single-map place written", outputPath, "workspace children", #workspace:GetChildren())
