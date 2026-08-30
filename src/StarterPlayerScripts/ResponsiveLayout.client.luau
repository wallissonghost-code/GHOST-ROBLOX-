local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local gui = playerGui:WaitForChild("RelicMarketRNGFullUI")

local function begins(text, prefix)
    return type(text)=="string" and text:sub(1,#prefix)==prefix
end

local function findButton(prefix)
    for _,obj in ipairs(gui:GetDescendants()) do
        if obj:IsA("TextButton") and begins(obj.Text, prefix) then
            return obj
        end
    end
end

local function findTopLabelBySize(width, height)
    for _,obj in ipairs(gui:GetChildren()) do
        if obj:IsA("TextLabel") and obj.Size.X.Offset==width and obj.Size.Y.Offset==height then
            return obj
        end
    end
end

local rollButton = findButton("ROLL")
local autoButton = findButton("AUTO")
local quickButton = findButton("QUICK")
local luckButton = findButton("LUCK+")
local controls = luckButton and luckButton.Parent

-- The conveyor is now the acquisition loop. Keep Luck because it improves crate rarity.
if rollButton then rollButton.Visible=false end
if autoButton then autoButton.Visible=false end
if quickButton then quickButton.Visible=false end
if controls and luckButton then
    controls.Size=UDim2.fromOffset(120,54)
    luckButton.Position=UDim2.fromOffset(0,0)
    luckButton.Size=UDim2.fromOffset(120,50)
end

local stats = findTopLabelBySize(520,40)
local biome = findTopLabelBySize(220,40)

local function findMenu()
    local inventory = findButton("🎒")
    return inventory and inventory.Parent
end

local menu = findMenu()
local daily = findButton("🎁")

local menuOrder = {
    {prefix="🎒", y=0},
    {prefix="🏪", y=40},
    {prefix="✅", y=80},
    {prefix="📚", y=120},
    {prefix="🔄", y=160},
    {prefix="🏆", y=200},
}

local function viewport()
    local camera = Workspace.CurrentCamera
    return camera and camera.ViewportSize or Vector2.new(1280,720)
end

local function isMobile()
    local v = viewport()
    return UserInputService.TouchEnabled or v.X <= 900 or v.Y <= 520
end

local function topLevelPanels()
    local result = {}
    for _,obj in ipairs(gui:GetChildren()) do
        if obj:IsA("Frame") and obj.ZIndex==10 then
            table.insert(result,obj)
        end
    end
    return result
end

local function adjustRows()
    for _,scroll in ipairs(gui:GetDescendants()) do
        if scroll:IsA("ScrollingFrame") then
            for _,row in ipairs(scroll:GetChildren()) do
                if row:IsA("Frame") and row.ZIndex==12 then
                    local label
                    local buttons = {}
                    for _,child in ipairs(row:GetChildren()) do
                        if child:IsA("TextLabel") then label=child end
                        if child:IsA("TextButton") then table.insert(buttons,child) end
                    end

                    if #buttons>0 then
                        row.Size=UDim2.new(1,-6,0,104)
                        if label then
                            label.Position=UDim2.fromOffset(10,5)
                            label.Size=UDim2.new(1,-20,0,54)
                            label.TextSize=13
                            label.TextYAlignment=Enum.TextYAlignment.Top
                        end

                        local available = math.max(180,row.AbsoluteSize.X-20)
                        local gap=5
                        local buttonWidth=math.floor((available-gap*(#buttons-1))/#buttons)
                        buttonWidth=math.clamp(buttonWidth,58,105)
                        for i,b in ipairs(buttons) do
                            b.AnchorPoint=Vector2.new(0,1)
                            b.Position=UDim2.new(0,10+(i-1)*(buttonWidth+gap),1,-7)
                            b.Size=UDim2.fromOffset(buttonWidth,34)
                            b.TextSize=11
                        end
                    else
                        row.Size=UDim2.new(1,-6,0,70)
                        if label then
                            label.Position=UDim2.fromOffset(10,5)
                            label.Size=UDim2.new(1,-20,1,-10)
                            label.TextSize=13
                        end
                    end
                end
            end
        end
    end
end

local function applyMobile()
    local v=viewport()

    if stats then
        stats.AnchorPoint=Vector2.new(.5,0)
        stats.Position=UDim2.new(.5,0,0,6)
        stats.Size=UDim2.fromOffset(math.max(260,v.X-16),42)
        stats.TextSize=12
        stats.TextWrapped=true
    end

    if biome then
        biome.Position=UDim2.new(.5,0,0,51)
        biome.Size=UDim2.fromOffset(math.min(190,v.X-40),30)
        biome.TextSize=11
    end

    if menu then
        menu.Position=UDim2.fromOffset(8,88)
        menu.Size=UDim2.fromOffset(112,244)
    end
    for _,entry in ipairs(menuOrder) do
        local b=findButton(entry.prefix)
        if b then
            b.Position=UDim2.fromOffset(0,entry.y)
            b.Size=UDim2.fromOffset(112,35)
            b.TextSize=10
        end
    end

    if daily then
        daily.Position=UDim2.new(0,8,1,-8)
        daily.Size=UDim2.fromOffset(112,38)
        daily.TextSize=10
    end

    if controls and luckButton then
        controls.AnchorPoint=Vector2.new(1,1)
        controls.Position=UDim2.new(1,-8,1,-8)
        controls.Size=UDim2.fromOffset(104,42)
        luckButton.Size=UDim2.fromOffset(104,40)
        luckButton.TextSize=13
    end

    for _,panel in ipairs(topLevelPanels()) do
        panel.Position=UDim2.fromScale(.5,.54)
        panel.Size=UDim2.fromOffset(math.max(280,v.X-28),math.max(230,v.Y-118))
        for _,child in ipairs(panel:GetChildren()) do
            if child:IsA("TextLabel") and child.ZIndex==11 then
                child.TextSize=18
                child.Position=UDim2.fromOffset(14,8)
                child.Size=UDim2.new(1,-62,0,38)
            elseif child:IsA("TextButton") and child.ZIndex==12 then
                child.Size=UDim2.fromOffset(36,36)
                child.Position=UDim2.new(1,-8,0,8)
            elseif child:IsA("ScrollingFrame") then
                child.Position=UDim2.fromOffset(8,52)
                child.Size=UDim2.new(1,-16,1,-60)
                child.ScrollBarThickness=4
            end
        end
    end

    for _,obj in ipairs(gui:GetChildren()) do
        if obj:IsA("TextLabel") and obj.Size.X.Offset==620 and obj.Position.Y.Offset==62 then
            obj.Size=UDim2.fromOffset(math.max(260,v.X-24),40)
            obj.Position=UDim2.new(.5,0,0,84)
            obj.TextSize=13
        elseif obj:IsA("Frame") and obj.ZIndex==50 then
            obj.Size=UDim2.fromOffset(math.max(280,math.min(390,v.X-24)),220)
        elseif obj:IsA("Frame") and obj.ZIndex==55 then
            obj.Size=UDim2.fromOffset(math.max(280,math.min(430,v.X-24)),238)
        end
    end

    local announce=findButton("ANUNCIAR")
    local cancel=findButton("CANCELAR")
    if announce and announce.Parent and announce.Parent.ZIndex==50 then
        announce.Position=UDim2.new(0,18,1,-64)
        announce.Size=UDim2.new(.58,-22,0,46)
        announce.TextSize=14
    end
    if cancel and cancel.Parent and cancel.Parent.ZIndex==50 then
        cancel.AnchorPoint=Vector2.new(1,0)
        cancel.Position=UDim2.new(1,-18,1,-64)
        cancel.Size=UDim2.new(.38,-10,0,46)
        cancel.TextSize=12
    end

    local accept=findButton("ACEITAR")
    local decline=findButton("RECUSAR")
    if accept and accept.Parent and accept.Parent.ZIndex==55 then
        accept.Position=UDim2.new(0,18,1,-58)
        accept.Size=UDim2.new(.56,-22,0,42)
        accept.TextSize=14
    end
    if decline and decline.Parent and decline.Parent.ZIndex==55 then
        decline.AnchorPoint=Vector2.new(1,0)
        decline.Position=UDim2.new(1,-18,1,-58)
        decline.Size=UDim2.new(.4,-8,0,42)
        decline.TextSize=12
    end

    adjustRows()
end

local function applyDesktop()
    if controls and luckButton then
        controls.AnchorPoint=Vector2.new(.5,1)
        controls.Position=UDim2.new(.5,0,1,-18)
        controls.Size=UDim2.fromOffset(120,54)
        luckButton.Position=UDim2.fromOffset(0,0)
        luckButton.Size=UDim2.fromOffset(120,50)
    end
end

local lastSize=Vector2.zero
local function apply()
    local v=viewport()
    if isMobile() then applyMobile() else applyDesktop() end
    lastSize=v
end

apply()

task.spawn(function()
    while gui.Parent do
        task.wait(.45)
        local v=viewport()
        if isMobile() then
            applyMobile()
        elseif v~=lastSize then
            applyDesktop()
        end
        lastSize=v
    end
end)
