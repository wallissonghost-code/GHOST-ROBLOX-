local Players=game:GetService("Players")
local player=Players.LocalPlayer

local gui=Instance.new("ScreenGui") gui.Name="OpenWorldHUD" gui.ResetOnSpawn=false gui.Parent=player:WaitForChild("PlayerGui")
local frame=Instance.new("Frame") frame.Position=UDim2.fromOffset(18,64) frame.Size=UDim2.fromOffset(270,116) frame.BackgroundColor3=Color3.fromRGB(18,22,26) frame.BackgroundTransparency=0.08 frame.Parent=gui
local corner=Instance.new("UICorner") corner.CornerRadius=UDim.new(0,12) corner.Parent=frame
local stroke=Instance.new("UIStroke") stroke.Color=Color3.fromRGB(70,145,210) stroke.Thickness=2 stroke.Parent=frame
local title=Instance.new("TextLabel") title.BackgroundTransparency=1 title.Position=UDim2.fromOffset(12,8) title.Size=UDim2.new(1,-24,0,24) title.Text="OPEN WORLD OPS" title.TextColor3=Color3.new(1,1,1) title.Font=Enum.Font.GothamBlack title.TextSize=18 title.TextXAlignment=Enum.TextXAlignment.Left title.Parent=frame
local info=Instance.new("TextLabel") info.BackgroundTransparency=1 info.Position=UDim2.fromOffset(12,38) info.Size=UDim2.new(1,-24,0,68) info.TextColor3=Color3.fromRGB(218,224,230) info.Font=Enum.Font.GothamMedium info.TextSize=14 info.TextXAlignment=Enum.TextXAlignment.Left info.TextYAlignment=Enum.TextYAlignment.Top info.Parent=frame
local wanted=Instance.new("TextLabel") wanted.AnchorPoint=Vector2.new(0.5,0) wanted.Position=UDim2.new(0.5,0,0,18) wanted.Size=UDim2.fromOffset(300,36) wanted.BackgroundColor3=Color3.fromRGB(20,20,22) wanted.BackgroundTransparency=0.12 wanted.TextColor3=Color3.fromRGB(255,205,70) wanted.Font=Enum.Font.GothamBlack wanted.TextSize=17 wanted.Parent=gui
local wc=Instance.new("UICorner") wc.CornerRadius=UDim.new(0,10) wc.Parent=wanted

local function money(n)
    local s=tostring(math.floor(n or 0))
    while true do local r,k=s:gsub("^(%-?%d+)(%d%d%d)","%1.%2") s=r if k==0 then break end end
    return "$"..s
end
local function update()
    local cash=player:GetAttribute("Cash") or 0
    local level=player:GetAttribute("BaseLevel") or 0
    local baseId=player:GetAttribute("BaseId") or 0
    local w=player:GetAttribute("Wanted") or 0
    info.Text="CASH  "..money(cash).."\nBASE  "..(baseId>0 and ("#"..baseId.."  LV."..level) or "UNCLAIMED").."\nExplore • Upgrade • Missions • Heists"
    wanted.Visible=w>0
    wanted.Text="WANTED  "..string.rep("★",w)..string.rep("☆",5-w)
end
for _,a in ipairs({"Cash","BaseLevel","BaseId","Wanted"}) do player:GetAttributeChangedSignal(a):Connect(update) end
update()
