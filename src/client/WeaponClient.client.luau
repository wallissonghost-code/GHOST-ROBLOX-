local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local UserInputService=game:GetService("UserInputService")

local player=Players.LocalPlayer
local mouse=player:GetMouse()
local shoot=ReplicatedStorage:WaitForChild("CombatRemotes"):WaitForChild("Shoot")

local function fire()
    local char=player.Character
    local tool=char and char:FindFirstChildOfClass("Tool")
    if not tool or not tool:GetAttribute("WeaponType") then return end
    shoot:FireServer(mouse.Hit.Position)
end

mouse.Button1Down:Connect(fire)

UserInputService.TouchTapInWorld:Connect(function(position,processed)
    if processed then return end
    local camera=workspace.CurrentCamera
    if not camera then return end
    local ray=camera:ViewportPointToRay(position.X,position.Y)
    shoot:FireServer(ray.Origin+ray.Direction*400)
end)
