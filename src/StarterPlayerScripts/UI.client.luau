local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local RunService=game:GetService("RunService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local player=Players.LocalPlayer
local Shared=ReplicatedStorage:WaitForChild("RelicShared")
local RelicModelBuilder=require(Shared:WaitForChild("RelicModelBuilder"))
local remotes=ReplicatedStorage:WaitForChild("RelicRemotes")

local Roll=remotes.Roll
local ToggleAuto=remotes.ToggleAuto
local ToggleQuick=remotes.ToggleQuick
local Sync=remotes.Sync
local Notify=remotes.Notify
local ListItem=remotes.ListItem
local CancelListing=remotes.CancelListing
local BuyListing=remotes.BuyListing
local UpgradeLuck=remotes.UpgradeLuck
local MarketChanged=remotes.MarketChanged
local BiomeChanged=remotes.BiomeChanged
local RollResult=remotes.RollResult
local EquipItem=remotes.EquipItem

local state={coins=0,luckLevel=0,autoRoll=false,quickRoll=false,pity=0,inventory={},inventoryCap=50,market={},biome={name="Normal"},equippedUid=nil}
local equippedModel=nil
local listingItem=nil
local activePanel=nil

local function fmt(n)
    n=tonumber(n) or 0
    if n>=1e15 then return string.format("%.2fQa",n/1e15) end
    if n>=1e12 then return string.format("%.2fT",n/1e12) end
    if n>=1e9 then return string.format("%.2fB",n/1e9) end
    if n>=1e6 then return string.format("%.2fM",n/1e6) end
    if n>=1e3 then return string.format("%.1fK",n/1e3) end
    return tostring(math.floor(n))
end

local function corner(obj,r)
    local c=Instance.new("UICorner")
    c.CornerRadius=UDim.new(0,r or 10)
    c.Parent=obj
end

local function stroke(obj,t)
    local s=Instance.new("UIStroke")
    s.Thickness=t or 1
    s.Transparency=.45
    s.Parent=obj
end

local gui=Instance.new("ScreenGui")
gui.Name="RelicMarketRNGV5"
gui.ResetOnSpawn=false
gui.IgnoreGuiInset=false
gui.Parent=player:WaitForChild("PlayerGui")

local stats=Instance.new("TextLabel")
stats.AnchorPoint=Vector2.new(1,0)
stats.Position=UDim2.new(1,-16,0,12)
stats.Size=UDim2.fromOffset(430,42)
stats.BackgroundColor3=Color3.fromRGB(17,17,22)
stats.BackgroundTransparency=.12
stats.TextColor3=Color3.new(1,1,1)
stats.Font=Enum.Font.GothamBold
stats.TextSize=19
stats.TextXAlignment=Enum.TextXAlignment.Center
stats.Parent=gui
corner(stats,12)
stroke(stats,1)

local side=Instance.new("Frame")
side.Position=UDim2.fromOffset(14,90)
side.Size=UDim2.fromOffset(132,112)
side.BackgroundTransparency=1
side.Parent=gui

local function menuButton(text,y)
    local b=Instance.new("TextButton")
    b.Position=UDim2.fromOffset(0,y)
    b.Size=UDim2.fromOffset(132,48)
    b.BackgroundColor3=Color3.fromRGB(37,35,48)
    b.TextColor3=Color3.new(1,1,1)
    b.Font=Enum.Font.GothamBold
    b.TextSize=16
    b.Text=text
    b.Parent=side
    corner(b,10)
    stroke(b,1)
    return b
end

local invOpen=menuButton("🎒 INVENTÁRIO",0)
local marketOpen=menuButton("🏪 MERCADO",56)

local controls=Instance.new("Frame")
controls.AnchorPoint=Vector2.new(.5,1)
controls.Position=UDim2.new(.5,0,1,-18)
controls.Size=UDim2.fromOffset(474,58)
controls.BackgroundTransparency=1
controls.Parent=gui

local function control(text,x,w)
    local b=Instance.new("TextButton")
    b.Position=UDim2.fromOffset(x,0)
    b.Size=UDim2.fromOffset(w,54)
    b.BackgroundColor3=Color3.fromRGB(88,61,166)
    b.TextColor3=Color3.new(1,1,1)
    b.Font=Enum.Font.GothamBlack
    b.TextSize=19
    b.Text=text
    b.Parent=controls
    corner(b,12)
    return b
end

local rollBtn=control("ROLL",0,118)
local autoBtn=control("AUTO",126,105)
local quickBtn=control("QUICK",239,105)
local luckBtn=control("LUCK+",352,118)

local function makePanel(title)
    local p=Instance.new("Frame")
    p.AnchorPoint=Vector2.new(.5,.5)
    p.Position=UDim2.fromScale(.5,.5)
    p.Size=UDim2.new(0,520,0,520)
    p.BackgroundColor3=Color3.fromRGB(20,20,26)
    p.BackgroundTransparency=.04
    p.Visible=false
    p.ZIndex=10
    p.Parent=gui
    corner(p,16)
    stroke(p,1)

    local head=Instance.new("TextLabel")
    head.Position=UDim2.fromOffset(16,10)
    head.Size=UDim2.new(1,-70,0,42)
    head.BackgroundTransparency=1
    head.Text=title
    head.TextColor3=Color3.new(1,1,1)
    head.Font=Enum.Font.GothamBlack
    head.TextSize=24
    head.TextXAlignment=Enum.TextXAlignment.Left
    head.ZIndex=11
    head.Parent=p

    local close=Instance.new("TextButton")
    close.AnchorPoint=Vector2.new(1,0)
    close.Position=UDim2.new(1,-12,0,10)
    close.Size=UDim2.fromOffset(42,42)
    close.BackgroundColor3=Color3.fromRGB(70,55,80)
    close.Text="✕"
    close.TextColor3=Color3.new(1,1,1)
    close.Font=Enum.Font.GothamBold
    close.TextSize=20
    close.ZIndex=12
    close.Parent=p
    corner(close,10)

    local scroll=Instance.new("ScrollingFrame")
    scroll.Position=UDim2.fromOffset(12,64)
    scroll.Size=UDim2.new(1,-24,1,-76)
    scroll.BackgroundTransparency=1
    scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
    scroll.CanvasSize=UDim2.new()
    scroll.ScrollBarThickness=6
    scroll.ZIndex=11
    scroll.Parent=p

    local layout=Instance.new("UIListLayout")
    layout.Padding=UDim.new(0,8)
    layout.Parent=scroll

    close.MouseButton1Click:Connect(function()
        p.Visible=false
        if activePanel==p then activePanel=nil end
    end)

    return p,scroll
end

local invPanel,invScroll=makePanel("INVENTÁRIO")
local marketPanel,marketScroll=makePanel("MERCADO")

local function showPanel(panel)
    if activePanel and activePanel~=panel then activePanel.Visible=false end
    panel.Visible=not panel.Visible
    activePanel=panel.Visible and panel or nil
end

invOpen.MouseButton1Click:Connect(function() showPanel(invPanel) end)
marketOpen.MouseButton1Click:Connect(function() showPanel(marketPanel) end)

local notice=Instance.new("TextLabel")
notice.AnchorPoint=Vector2.new(.5,0)
notice.Position=UDim2.new(.5,0,0,66)
notice.Size=UDim2.new(0,560,0,46)
notice.BackgroundColor3=Color3.fromRGB(12,12,16)
notice.BackgroundTransparency=.08
notice.TextColor3=Color3.new(1,1,1)
notice.Font=Enum.Font.GothamBold
notice.TextSize=18
notice.Visible=false
notice.ZIndex=30
notice.Parent=gui
corner(notice,10)

local reveal=Instance.new("Frame")
reveal.AnchorPoint=Vector2.new(.5,.5)
reveal.Position=UDim2.fromScale(.5,.45)
reveal.Size=UDim2.fromOffset(360,180)
reveal.BackgroundColor3=Color3.fromRGB(20,20,28)
reveal.Visible=false
reveal.ZIndex=35
reveal.Parent=gui
corner(reveal,18)

local revealText=Instance.new("TextLabel")
revealText.Size=UDim2.fromScale(1,1)
revealText.BackgroundTransparency=1
revealText.TextColor3=Color3.new(1,1,1)
revealText.Font=Enum.Font.GothamBlack
revealText.TextSize=24
revealText.TextWrapped=true
revealText.ZIndex=36
revealText.Parent=reveal

local priceModal=Instance.new("Frame")
priceModal.AnchorPoint=Vector2.new(.5,.5)
priceModal.Position=UDim2.fromScale(.5,.5)
priceModal.Size=UDim2.fromOffset(390,230)
priceModal.BackgroundColor3=Color3.fromRGB(21,21,28)
priceModal.Visible=false
priceModal.ZIndex=40
priceModal.Parent=gui
corner(priceModal,16)

local priceTitle=Instance.new("TextLabel")
priceTitle.Position=UDim2.fromOffset(16,14)
priceTitle.Size=UDim2.new(1,-32,0,52)
priceTitle.BackgroundTransparency=1
priceTitle.TextColor3=Color3.new(1,1,1)
priceTitle.Font=Enum.Font.GothamBlack
priceTitle.TextSize=20
priceTitle.TextWrapped=true
priceTitle.ZIndex=41
priceTitle.Parent=priceModal

local priceBox=Instance.new("TextBox")
priceBox.Position=UDim2.fromOffset(24,82)
priceBox.Size=UDim2.new(1,-48,0,50)
priceBox.BackgroundColor3=Color3.fromRGB(39,39,48)
priceBox.TextColor3=Color3.new(1,1,1)
priceBox.Font=Enum.Font.GothamBold
priceBox.TextSize=20
priceBox.PlaceholderText="Preço em Coins"
priceBox.ClearTextOnFocus=false
priceBox.ZIndex=41
priceBox.Parent=priceModal
corner(priceBox,10)

local confirmList=Instance.new("TextButton")
confirmList.Position=UDim2.fromOffset(24,154)
confirmList.Size=UDim2.fromOffset(214,52)
confirmList.BackgroundColor3=Color3.fromRGB(65,145,90)
confirmList.Text="ANUNCIAR"
confirmList.TextColor3=Color3.new(1,1,1)
confirmList.Font=Enum.Font.GothamBlack
confirmList.TextSize=19
confirmList.ZIndex=41
confirmList.Parent=priceModal
corner(confirmList,10)

local cancelList=confirmList:Clone()
cancelList.AnchorPoint=Vector2.new(1,0)
cancelList.Position=UDim2.new(1,-24,0,154)
cancelList.Size=UDim2.fromOffset(120,52)
cancelList.BackgroundColor3=Color3.fromRGB(145,64,70)
cancelList.Text="CANCELAR"
cancelList.Parent=priceModal

local function clear(scroll)
    for _,c in scroll:GetChildren() do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end
end

local function row(scroll,text,actions)
    local f=Instance.new("Frame")
    f.Size=UDim2.new(1,-6,0,78)
    f.BackgroundColor3=Color3.fromRGB(37,37,45)
    f.ZIndex=12
    f.Parent=scroll
    corner(f,10)

    local label=Instance.new("TextLabel")
    label.Position=UDim2.fromOffset(10,6)
    label.Size=UDim2.new(1,-190,1,-12)
    label.BackgroundTransparency=1
    label.Text=text
    label.TextColor3=Color3.new(1,1,1)
    label.TextXAlignment=Enum.TextXAlignment.Left
    label.TextWrapped=true
    label.Font=Enum.Font.Gotham
    label.TextSize=17
    label.ZIndex=13
    label.Parent=f

    local x=1
    for i=#actions,1,-1 do
        local a=actions[i]
        local b=Instance.new("TextButton")
        b.AnchorPoint=Vector2.new(1,.5)
        b.Position=UDim2.new(x,-10,.5,0)
        b.Size=UDim2.fromOffset(a.w or 78,42)
        b.BackgroundColor3=a.disabled and Color3.fromRGB(66,66,72) or (a.color or Color3.fromRGB(87,61,160))
        b.Text=a.text
        b.TextColor3=Color3.new(1,1,1)
        b.Font=Enum.Font.GothamBold
        b.TextSize=14
        b.ZIndex=13
        b.AutoButtonColor=not a.disabled
        b.Parent=f
        corner(b,8)
        if not a.disabled then b.MouseButton1Click:Connect(a.cb) end
        x=x-((a.w or 78)+8)/math.max(f.AbsoluteSize.X,500)
    end
end

local function rebuildEquipped()
    if equippedModel then equippedModel:Destroy() equippedModel=nil end
    if not state.equippedUid then return end
    for _,item in ipairs(state.inventory) do
        if item.uid==state.equippedUid then
            equippedModel=RelicModelBuilder.build(item)
            equippedModel.Name="LocalEquippedRelic"
            equippedModel.Parent=workspace
            break
        end
    end
end

local function refresh()
    stats.Text=string.format("💰 %s   Luck %d   Pity %d   %d/%d   %s",fmt(state.coins),state.luckLevel,state.pity,#state.inventory,state.inventoryCap,state.biome.name or "Normal")
    autoBtn.Text=state.autoRoll and "AUTO ON" or "AUTO"
    quickBtn.Text=state.quickRoll and "QUICK ON" or "QUICK"

    clear(invScroll)
    for _,item in ipairs(state.inventory) do
        local equipped=state.equippedUid==item.uid
        row(invScroll,string.format("%s [%s] #%04d\n1/%s • MV %s",item.relicName,item.mutationName,item.serial,fmt(item.combinedOneIn),fmt(item.marketValue or item.baseValue)),{
            {text=equipped and "ON" or "EQUIP",w=72,disabled=false,cb=function() EquipItem:FireServer(item.uid) end},
            {text=item.listed and "LISTED" or "SELL",w=72,disabled=item.listed==true,cb=function()
                listingItem=item
                priceTitle.Text=string.format("ANUNCIAR %s #%04d",item.relicName,item.serial)
                priceBox.Text=tostring(math.max(1,math.floor(item.marketValue or item.baseValue or 1)))
                priceModal.Visible=true
            end}
        })
    end

    clear(marketScroll)
    for _,listing in ipairs(state.market) do
        local own=listing.sellerUserId==player.UserId
        row(marketScroll,string.format("%s [%s] #%04d\n%s Coins • %s",listing.item.relicName,listing.item.mutationName,listing.item.serial,fmt(listing.price),listing.sellerName),{
            {text=own and "CANCEL" or "BUY",w=88,color=own and Color3.fromRGB(145,64,70) or Color3.fromRGB(65,145,90),cb=function()
                if own then CancelListing:FireServer(listing.listingId) else BuyListing:FireServer(listing.listingId) end
            end}
        })
    end

    rebuildEquipped()
end

confirmList.MouseButton1Click:Connect(function()
    if not listingItem then return end
    local price=math.floor(tonumber(priceBox.Text) or 0)
    if price<=0 then
        notice.Text="Digite um preço válido."
        notice.Visible=true
        task.delay(2,function() notice.Visible=false end)
        return
    end
    ListItem:FireServer(listingItem.uid,price)
    priceModal.Visible=false
    listingItem=nil
end)

cancelList.MouseButton1Click:Connect(function()
    listingItem=nil
    priceModal.Visible=false
end)

rollBtn.MouseButton1Click:Connect(function() Roll:FireServer() end)
autoBtn.MouseButton1Click:Connect(function() ToggleAuto:FireServer() end)
quickBtn.MouseButton1Click:Connect(function() ToggleQuick:FireServer() end)
luckBtn.MouseButton1Click:Connect(function() UpgradeLuck:FireServer() end)

Sync.OnClientEvent:Connect(function(data)
    for k,v in pairs(data) do state[k]=v end
    refresh()
end)

MarketChanged.OnClientEvent:Connect(function(snapshot)
    state.market=snapshot
    refresh()
end)

BiomeChanged.OnClientEvent:Connect(function(b)
    state.biome=b
    refresh()
end)

Notify.OnClientEvent:Connect(function(text)
    notice.Text=tostring(text)
    notice.Visible=true
    task.delay(2.6,function() notice.Visible=false end)
end)

RollResult.OnClientEvent:Connect(function(item)
    reveal.Visible=true
    reveal.Size=UDim2.fromOffset(220,110)
    revealText.Text=string.format("%s\n[%s] #%04d\n1/%s",item.relicName,item.mutationName,item.serial,fmt(item.combinedOneIn))
    TweenService:Create(reveal,TweenInfo.new(.3,Enum.EasingStyle.Back),{Size=UDim2.fromOffset(380,190)}):Play()
    task.delay(state.quickRoll and .35 or 1.15,function() reveal.Visible=false end)
end)

RunService.RenderStepped:Connect(function()
    if not equippedModel or not equippedModel.Parent then return end
    local character=player.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local spin=os.clock()*1.4
    local hover=math.sin(os.clock()*2.2)*.3
    equippedModel:PivotTo(root.CFrame*CFrame.new(3.2,2.1+hover,0)*CFrame.Angles(0,spin,0))
end)

player.CharacterAdded:Connect(function()
    task.wait(1)
    rebuildEquipped()
end)

refresh()
