local Players=game:GetService("Players")
local player=Players.LocalPlayer

local gui=Instance.new("ScreenGui")
gui.Name="GhostRNGStats"
gui.ResetOnSpawn=false
gui.IgnoreGuiInset=false
gui.DisplayOrder=20
gui.Parent=player:WaitForChild("PlayerGui")

local frame=Instance.new("Frame")
frame.AnchorPoint=Vector2.new(1,0)
frame.Position=UDim2.new(1,-18,0,18)
frame.Size=UDim2.fromOffset(190,72)
frame.BackgroundColor3=Color3.fromRGB(13,15,23)
frame.BackgroundTransparency=0.08
frame.Parent=gui
local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,11);corner.Parent=frame
local stroke=Instance.new("UIStroke");stroke.Color=Color3.fromRGB(162,96,255);stroke.Thickness=1.6;stroke.Transparency=0.22;stroke.Parent=frame

local title=Instance.new("TextLabel")
title.BackgroundTransparency=1
title.Position=UDim2.fromOffset(12,7)
title.Size=UDim2.new(1,-24,0,18)
title.Text="GHOST RNG"
title.TextColor3=Color3.fromRGB(236,229,255)
title.TextSize=15
title.TextXAlignment=Enum.TextXAlignment.Left
title.Font=Enum.Font.GothamBlack
title.Parent=frame

local stats=Instance.new("TextLabel")
stats.BackgroundTransparency=1
stats.Position=UDim2.fromOffset(12,28)
stats.Size=UDim2.new(1,-24,0,35)
stats.TextColor3=Color3.fromRGB(205,208,225)
stats.TextSize=12
stats.TextXAlignment=Enum.TextXAlignment.Left
stats.TextYAlignment=Enum.TextYAlignment.Top
stats.Font=Enum.Font.GothamMedium
stats.Parent=frame

local last=Instance.new("TextLabel")
last.AnchorPoint=Vector2.new(0.5,0)
last.Position=UDim2.new(0.5,0,0,18)
last.Size=UDim2.fromOffset(430,28)
last.BackgroundColor3=Color3.fromRGB(14,16,24)
last.BackgroundTransparency=0.08
last.TextColor3=Color3.fromRGB(220,205,255)
last.TextSize=12
last.Font=Enum.Font.GothamBold
last.Text="ROLL TO DISCOVER A RELIC"
last.TextTruncate=Enum.TextTruncate.AtEnd
last.Parent=gui
local lc=Instance.new("UICorner");lc.CornerRadius=UDim.new(0,8);lc.Parent=last
local ls=Instance.new("UIStroke");ls.Color=Color3.fromRGB(105,65,190);ls.Thickness=1.2;ls.Transparency=0.4;ls.Parent=last

local function formatOneIn(value)
	value=tonumber(value) or 0
	if value<=0 then return "—" end
	if value>=1000000 then
		return string.format("1/%.2fM",value/1000000)
	elseif value>=1000 then
		return string.format("1/%.1fK",value/1000)
	end
	return "1/"..tostring(math.floor(value+0.5))
end

local function update()
	local rolls=player:GetAttribute("RNG_Rolls") or 0
	local best=player:GetAttribute("RNG_BestOneIn") or 0
	local relic=player:GetAttribute("RNG_LastRelic")
	stats.Text="ROLLS  "..tostring(rolls).."\nBEST   "..formatOneIn(best)
	if relic and relic~="" then
		last.Text="LAST  •  "..string.upper(relic)
	else
		last.Text="ROLL TO DISCOVER A RELIC"
	end
end

player:GetAttributeChangedSignal("RNG_Rolls"):Connect(update)
player:GetAttributeChangedSignal("RNG_BestOneIn"):Connect(update)
player:GetAttributeChangedSignal("RNG_LastRelic"):Connect(update)
update()
