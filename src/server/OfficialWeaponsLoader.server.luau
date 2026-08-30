local InsertService = game:GetService("InsertService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPack = game:GetService("StarterPack")

-- Official Roblox Weapons Kit: Auto Rifle.
-- Roblox documentation states this kit is available under Roblox's Limited Use License.
local AUTO_RIFLE_ASSET_ID = 4842207161

local ok, container = pcall(function()
	return InsertService:LoadAsset(AUTO_RIFLE_ASSET_ID)
end)
if not ok or not container then
	warn("[OfficialWeaponsLoader] Auto Rifle could not be loaded", container)
	return
end

local installedTools = {}
for _, d in ipairs(container:GetDescendants()) do
	if d:IsA("Tool") then
		local clone = d:Clone()
		clone.Name = d.Name
		clone.Parent = StarterPack
		table.insert(installedTools, clone)
	elseif d.Name == "WeaponsSystem" and (d:IsA("Folder") or d:IsA("Model")) then
		if not ServerScriptService:FindFirstChild("WeaponsSystem") then
			d.Parent = ServerScriptService
		end
	end
end

local function give(player)
	local backpack = player:FindFirstChildOfClass("Backpack") or player:WaitForChild("Backpack",10)
	if not backpack then return end
	for _, tool in ipairs(installedTools) do
		if not backpack:FindFirstChild(tool.Name) then tool:Clone().Parent = backpack end
	end
end
for _, p in ipairs(Players:GetPlayers()) do task.defer(give,p) end
Players.PlayerAdded:Connect(function(p)
	p.CharacterAdded:Connect(function() task.wait(1); give(p) end)
end)

container:Destroy()
print("[OfficialWeaponsLoader] official Roblox Auto Rifle installed")
