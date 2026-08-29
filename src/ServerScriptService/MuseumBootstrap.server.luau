local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent:WaitForChild("DataService"))
local MuseumService = require(script.Parent:WaitForChild("MuseumService"))

local world = workspace:WaitForChild("RelicWorld")
local remotes = ReplicatedStorage:WaitForChild("RelicRemotes")
local Notify = remotes:WaitForChild("Notify")

MuseumService.init({
    data = DataService,
    notify = function(player, text)
        Notify:FireClient(player, text)
    end,
}, world)

local PLOT_POSITIONS = {
    Vector3.new(-110, 0, 105),
    Vector3.new(0, 0, 118),
    Vector3.new(110, 0, 105),
    Vector3.new(-118, 0, 0),
    Vector3.new(118, 0, 0),
    Vector3.new(-110, 0, -105),
    Vector3.new(0, 0, -125),
    Vector3.new(110, 0, -105),
}

local plotByPlayer = {}
local spawnConnections = {}

local function waitForProfile(player)
    for _ = 1, 100 do
        if DataService.get(player) then
            return true
        end
        task.wait(0.1)
    end
    return false
end

local function moveToMuseum(player, character)
    local index = plotByPlayer[player]
    local center = index and PLOT_POSITIONS[index]
    if not center then return end

    task.spawn(function()
        local root = character:WaitForChild("HumanoidRootPart", 10)
        if not root then return end
        task.wait(0.2)
        local spawnPosition = center + Vector3.new(0, 4, 23)
        local lookTarget = center + Vector3.new(0, 4, -8)
        character:PivotTo(CFrame.lookAt(spawnPosition, lookTarget))
    end)
end

local function assign(player)
    task.spawn(function()
        if not waitForProfile(player) then return end

        local index = MuseumService.assign(player)
        if not index then
            Notify:FireClient(player, "Todos os museus deste servidor estão ocupados.")
            return
        end

        plotByPlayer[player] = index

        if spawnConnections[player] then
            spawnConnections[player]:Disconnect()
        end
        spawnConnections[player] = player.CharacterAdded:Connect(function(character)
            moveToMuseum(player, character)
        end)

        if player.Character then
            moveToMuseum(player, player.Character)
        end

        Notify:FireClient(player, "🏛️ Seu museu é o lote #" .. index .. ". Você sempre renasce aqui.")
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    assign(player)
end

Players.PlayerAdded:Connect(assign)

Players.PlayerRemoving:Connect(function(player)
    if spawnConnections[player] then
        spawnConnections[player]:Disconnect()
        spawnConnections[player] = nil
    end
    plotByPlayer[player] = nil
    MuseumService.release(player)
end)
