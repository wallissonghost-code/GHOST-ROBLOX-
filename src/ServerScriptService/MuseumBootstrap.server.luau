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

local function waitForProfile(player)
    for _=1,100 do
        if DataService.get(player) then return true end
        task.wait(0.1)
    end
    return false
end

local function assign(player)
    task.spawn(function()
        if waitForProfile(player) then
            local index = MuseumService.assign(player)
            if index then
                Notify:FireClient(player, "🏛️ Seu museu pessoal é o lote #" .. index .. ". Use os pedestais para exibir suas relíquias.")
            else
                Notify:FireClient(player, "Todos os museus deste servidor estão ocupados.")
            end
        end
    end)
end

for _,player in ipairs(Players:GetPlayers()) do assign(player) end
Players.PlayerAdded:Connect(assign)
Players.PlayerRemoving:Connect(function(player)
    MuseumService.release(player)
end)
