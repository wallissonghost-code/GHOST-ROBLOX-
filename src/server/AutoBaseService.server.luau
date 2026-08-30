local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))

local world = workspace:WaitForChild("OpenWorldMilitary")
local basesFolder = world:WaitForChild("Bases")

local assignments = {}
local owners = {}

local function setBaseVisual(base, level)
    for _, obj in ipairs(base:GetDescendants()) do
        if obj:IsA("BasePart") then
            local required = obj:GetAttribute("RequiredLevel")
            if required ~= nil then
                local visible = level >= required
                obj.Transparency = visible and 0 or 1
                obj.CanCollide = visible
                local prompt = obj:FindFirstChildOfClass("ProximityPrompt")
                if prompt then
                    prompt.Enabled = visible and prompt:GetAttribute("ActionKind") ~= "CLAIM"
                end
            end
        elseif obj:IsA("ProximityPrompt") and obj:GetAttribute("ActionKind") == "CLAIM" then
            obj.Enabled = false
        end
    end
end

local function updateBaseLabel(base, player)
    local pad = base:FindFirstChild("ClaimPad")
    if not pad then return end
    local gui = pad:FindFirstChildOfClass("BillboardGui")
    if not gui then return end
    local label = gui:FindFirstChildWhichIsA("TextLabel", true)
    if label then
        label.Text = player and (string.upper(player.DisplayName) .. " BASE") or "AVAILABLE BASE"
    end
end

local function spawnCFrame(baseId)
    local pos = Config.BASE_POSITIONS[baseId]
    if not pos then return nil end
    -- Inside the front gate, facing toward the center of the base.
    return CFrame.lookAt(pos + Vector3.new(0, 5, 38), pos + Vector3.new(0, 5, 0))
end

local function moveCharacterToBase(player, character)
    local baseId = assignments[player] or player:GetAttribute("BaseId") or 0
    if baseId <= 0 then return end
    local target = spawnCFrame(baseId)
    if not target then return end
    task.wait(0.15)
    if character and character.Parent then
        character:PivotTo(target)
    end
end

local function reserveBase(player)
    if assignments[player] then
        return assignments[player]
    end

    for id = 1, #Config.BASE_POSITIONS do
        if not owners[id] then
            local base = basesFolder:FindFirstChild("Base" .. id)
            if base then
                owners[id] = player
                assignments[player] = id
                player:SetAttribute("BaseId", id)
                base:SetAttribute("OwnerUserId", player.UserId)
                base:SetAttribute("OwnerName", player.Name)
                updateBaseLabel(base, player)
                setBaseVisual(base, player:GetAttribute("BaseLevel") or 0)
                return id
            end
        end
    end

    player:SetAttribute("BaseId", 0)
    return nil
end

local function releaseBase(player)
    local id = assignments[player]
    if not id then return end

    local base = basesFolder:FindFirstChild("Base" .. id)
    if base then
        base:SetAttribute("OwnerUserId", 0)
        base:SetAttribute("OwnerName", "")
        updateBaseLabel(base, nil)
        setBaseVisual(base, 0)
    end

    owners[id] = nil
    assignments[player] = nil
end

-- Claiming is automatic in this game mode.
for _, obj in ipairs(basesFolder:GetDescendants()) do
    if obj:IsA("ProximityPrompt") and obj:GetAttribute("ActionKind") == "CLAIM" then
        obj.Enabled = false
    end
end
basesFolder.DescendantAdded:Connect(function(obj)
    if obj:IsA("ProximityPrompt") and obj:GetAttribute("ActionKind") == "CLAIM" then
        obj.Enabled = false
    end
end)

local function setupPlayer(player)
    -- GameService initializes profile attributes first; give it a brief moment.
    task.spawn(function()
        local deadline = os.clock() + 8
        while player.Parent and player:GetAttribute("BaseLevel") == nil and os.clock() < deadline do
            task.wait(0.1)
        end
        if not player.Parent then return end

        reserveBase(player)

        player.CharacterAdded:Connect(function(character)
            moveCharacterToBase(player, character)
        end)

        if player.Character then
            moveCharacterToBase(player, player.Character)
        end
    end)
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(releaseBase)

for _, player in ipairs(Players:GetPlayers()) do
    setupPlayer(player)
end
