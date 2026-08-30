local Players = game:GetService("Players")
local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "LicensedOpenWorldHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(280,132)
panel.Position = UDim2.fromOffset(18,70)
panel.BackgroundColor3 = Color3.fromRGB(15,18,23)
panel.BackgroundTransparency = 0.08
panel.BorderSizePixel = 0
panel.Parent = gui
local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(0,12); corner.Parent=panel
local stroke=Instance.new("UIStroke"); stroke.Thickness=2; stroke.Color=Color3.fromRGB(58,185,255); stroke.Parent=panel

local title=Instance.new("TextLabel")
title.BackgroundTransparency=1; title.Size=UDim2.new(1,-24,0,30); title.Position=UDim2.fromOffset(12,8)
title.Text="MILITARY OPEN WORLD"; title.TextColor3=Color3.new(1,1,1); title.TextXAlignment=Enum.TextXAlignment.Left; title.Font=Enum.Font.GothamBold; title.TextSize=18; title.Parent=panel
local stats=Instance.new("TextLabel")
stats.BackgroundTransparency=1; stats.Size=UDim2.new(1,-24,0,78); stats.Position=UDim2.fromOffset(12,42); stats.TextColor3=Color3.fromRGB(215,225,235); stats.TextXAlignment=Enum.TextXAlignment.Left; stats.TextYAlignment=Enum.TextYAlignment.Top; stats.Font=Enum.Font.GothamMedium; stats.TextSize=16; stats.Parent=panel

local function update()
	local cash=player:GetAttribute("Cash") or 0
	local base=player:GetAttribute("BaseIndex") or 0
	local purchases=player:GetAttribute("Purchases") or 0
	stats.Text=string.format("CASH  $%s\nBASE  #%s\nUPGRADES  %s / 4", tostring(math.floor(cash)), tostring(base), tostring(purchases))
end
for _,name in ipairs({"Cash","BaseIndex","Purchases"}) do player:GetAttributeChangedSignal(name):Connect(update) end
update()
