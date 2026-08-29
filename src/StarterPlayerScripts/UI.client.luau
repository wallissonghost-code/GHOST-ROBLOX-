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
local BuyListing=remotes.BuyListing
local UpgradeLuck=remotes.UpgradeLuck
local MarketChanged=remotes.MarketChanged
local BiomeChanged=remotes.BiomeChanged
local RollResult=remotes.RollResult
local EquipItem=remotes.EquipItem

local state={
    coins=0,luckLevel=0,autoRoll=false,quickRoll=false,pity=0,
    inventory={},inventoryCap=50,market={},biome={name="Normal"},equippedUid=nil
}

local equippedModel=nil
local equippedItem=nil
local listingItem=nil

local function fmt(n)
    n=tonumber(n) or 0
    if n>=1e15 then return string.format("%.2fQa",n/1e15) end
    if n>=1e12 then return string.format("%.2fT",n/1e12) end
    if n>=1e9 then return string.format("%.2fB",n/1e9) end
    if n>=1e6 then return string.format("%.2fM",n/1e6) end
    if n>=1e3 then return string.format("%.1fK",n/1e3) end
    return tostring(math.floor(n))
end

local function corner(instance,radius)
    local c=Instance.new("UICorner")
    c.CornerRadius=UDim.new(0,radius or 10)
    c.Parent=instance
end

local gui=Instance.new("ScreenGui")
gui.Name="RelicMarketRNGV4"
gui.ResetOnSpawn=false
gui.IgnoreGuiInset=false
gui.Parent=player:WaitForChild("PlayerGui")

local top=Instance.new("TextLabel")
top.Size=UDim2.new(1,0,0,66)
top.BackgroundColor3=Color3.fromRGB(18,18,24)
top.TextColor3=Color3.new(1,1,1)
top.Font=Enum.Font.GothamBold
top.TextScaled=true
top.Parent=gui

local controls=Instance.new("Frame")
controls.AnchorPoint=Vector2.new(0.5,1)
controls.Position=UDim2.fromScale(0.5,0.98)
controls.Size=UDim2.fromOffset(620,66)
controls.BackgroundTransparency=1
controls.Parent=gui

local function button(txt,x)
    local b=Instance.new("TextButton")
    b.Size=UDim2.fromOffset(145,58)
    b.Position=UDim2.fromOffset(x,4)
    b.Text=txt
    b.Font=Enum.Font.GothamBlack
    b.TextScaled=true
    b.TextColor3=Color3.new(1,1,1)
    b.BackgroundColor3=Color3.fromRGB(86,62,160)
    b.Parent=controls
    corner(b,12)
    return b
end

local rollBtn=button("ROLL",0)
local autoBtn=button("AUTO",155)
local quickBtn=button("QUICK",310)
local luckBtn=button("LUCK+",465)

local function panelTitle(text,pos,size)
    local t=Instance.new("TextLabel")
    t.Position=pos
    t.Size=size
    t.BackgroundTransparency=1
    t.Text=text
    t.TextColor3=Color3.new(1,1,1)
    t.Font=Enum.Font.GothamBlack
    t.TextScaled=true
    t.Parent=gui
    return t
end

panelTitle("INVENTÁRIO",UDim2.fromOffset(10,72),UDim2.new(0.49,-15,0,32))
panelTitle("MERCADO",UDim2.new(0.51,5,0,72),UDim2.new(0.49,-15,0,32))

local left=Instance.new("ScrollingFrame")
left.Position=UDim2.fromOffset(10,108)
left.Size=UDim2.new(0.49,-15,1,-196)
left.BackgroundColor3=Color3.fromRGB(27,27,33)
left.AutomaticCanvasSize=Enum.AutomaticSize.Y
left.CanvasSize=UDim2.new()
left.ScrollBarThickness=6
left.Parent=gui
corner(left,12)

local right=left:Clone()
right.AnchorPoint=Vector2.new(1,0)
right.Position=UDim2.new(1,-10,0,108)
right.Parent=gui

local ll=Instance.new("UIListLayout")
ll.Padding=UDim.new(0,6)
ll.Parent=left
ll:Clone().Parent=right

local notice=Instance.new("TextLabel")
notice.AnchorPoint=Vector2.new(0.5,0)
notice.Position=UDim2.fromScale(0.5,0.105)
notice.Size=UDim2.new(0.75,0,0,48)
notice.BackgroundColor3=Color3.fromRGB(10,10,12)
notice.TextColor3=Color3.new(1,1,1)
notice.Font=Enum.Font.GothamBold
notice.TextScaled=true
notice.Visible=false
notice.ZIndex=20
notice.Parent=gui
corner(notice,10)

local reveal=Instance.new("Frame")
reveal.AnchorPoint=Vector2.new(0.5,0.5)
reveal.Position=UDim2.fromScale(0.5,0.5)
reveal.Size=UDim2.fromOffset(420,220)
reveal.BackgroundColor3=Color3.fromRGB(20,20,28)
reveal.Visible=false
reveal.ZIndex=30
reveal.Parent=gui
corner(reveal,18)

local revealText=Instance.new("TextLabel")
revealText.BackgroundTransparency=1
revealText.Size=UDim2.fromScale(1,1)
revealText.TextColor3=Color3.new(1,1,1)
revealText.Font=Enum.Font.GothamBlack
revealText.TextScaled=true
revealText.TextWrapped=true
revealText.ZIndex=31
revealText.Parent=reveal

local priceModal=Instance.new("Frame")
priceModal.AnchorPoint=Vector2.new(0.5,0.5)
priceModal.Position=UDim2.fromScale(0.5,0.5)
priceModal.Size=UDim2.fromOffset(430,250)
priceModal.BackgroundColor3=Color3.fromRGB(21,21,28)
priceModal.Visible=false
priceModal.ZIndex=40
priceModal.Parent=gui
corner(priceModal,18)

local priceTitle=Instance.new("TextLabel")
priceTitle.Position=UDim2.fromOffset(16,14)
priceTitle.Size=UDim2.new(1,-32,0,65)
priceTitle.BackgroundTransparency=1
priceTitle.TextColor3=Color3.new(1,1,1)
priceTitle.Font=Enum.Font.GothamBlack
priceTitle.TextScaled=true
priceTitle.TextWrapped=true
priceTitle.ZIndex=41
priceTitle.Parent=priceModal

local priceBox=Instance.new("TextBox")
priceBox.Position=UDim2.fromOffset(25,92)
priceBox.Size=UDim2.new(1,-50,0,54)
priceBox.BackgroundColor3=Color3.fromRGB(38,38,48)
priceBox.TextColor3=Color3.new(1,1,1)
priceBox.PlaceholderText="Preço em Coins"
priceBox.ClearTextOnFocus=false
priceBox.Font=Enum.Font.GothamBold
priceBox.TextScaled=true
priceBox.ZIndex=41
priceBox.Parent=priceModal
corner(priceBox,10)

local confirmList=Instance.new("TextButton")
confirmList.Position=UDim2.fromOffset(25,166)
confirmList.Size=UDim2.new(0.58,-8,0,56)
confirmList.Text="ANUNCIAR"
confirmList.Font=Enum.Font.GothamBlack
confirmList.TextScaled=true
confirmList.TextColor3=Color3.new(1,1,1)
confirmList.BackgroundColor3=Color3.fromRGB(64,150,93)
confirmList.ZIndex=41
confirmList.Parent=priceModal
corner(confirmList,10)

local cancelList=confirmList:Clone()
cancelList.AnchorPoint=Vector2.new(1,0)
cancelList.Position=UDim2.new(1,-25,0,166)
cancelList.Size=UDim2.new(0.38,-8,0,56)
cancelList.Text="CANCELAR"
cancelList.BackgroundColor3=Color3.fromRGB(140,65,70)
cancelList.Parent=priceModal

local function clear(frame)
    for _,c in frame:GetChildren() do
        if not c:IsA("UIListLayout") and not c:IsA("UICorner") then c:Destroy() end
    end
end

local function actionButton(parent,text,xScale,widthScale,cb,disabled)
    local b=Instance.new("TextButton")
    b.AnchorPoint=Vector2.new(1,0.5)
    b.Position=UDim2.new(xScale,-8,0.5,0)
    b.Size=UDim2.new(widthScale,-4,0,46)
    b.Text=text
    b.Font=Enum.Font.GothamBold
    b.TextScaled=true
    b.TextColor3=Color3.new(1,1,1)
    b.BackgroundColor3=disabled and Color3.fromRGB(70,70,78) or Color3.fromRGB(82,62,150)
    b.AutoButtonColor=not disabled
    b.Parent=parent
    corner(b,8)
    if not disabled then b.MouseButton1Click:Connect(cb) end
    return b
end

local function inventoryRow(parent,item)
    local f=Instance.new("Frame")
    f.Size=UDim2.new(1,-8,0,86)
    f.BackgroundColor3=Color3.fromRGB(39,39,46)
    f.Parent=parent
    corner(f,10)

    local l=Instance.new("TextLabel")
    l.BackgroundTransparency=1
    l.Position=UDim2.fromOffset(8,5)
    l.Size=UDim2.new(0.58,-10,1,-10)
    l.TextWrapped=true
    l.TextXAlignment=Enum.TextXAlignment.Left
    l.TextColor3=Color3.new(1,1,1)
    l.Font=Enum.Font.Gotham
    l.TextScaled=true
    l.Text=string.format("%s [%s] #%04d\n1/%s • MV %s",item.relicName,item.mutationName,item.serial,fmt(item.combinedOneIn),fmt(item.marketValue or item.baseValue))
    l.Parent=f

    local isEquipped=state.equippedUid==item.uid
    actionButton(f,isEquipped and "ON" or "EQUIP",0.79,0.19,function()
        EquipItem:FireServer(item.uid)
    end,false)

    actionButton(f,item.listed and "LISTED" or "SELL",1,0.19,function()
        listingItem=item
        priceTitle.Text=string.format("ANUNCIAR %s #%04d",item.relicName,item.serial)
        priceBox.Text=tostring(math.max(1,math.floor(item.marketValue or item.baseValue or 1)))
        priceModal.Visible=true
    end,item.listed==true)
end

local function marketRow(parent,listing)
    local f=Instance.new("Frame")
    f.Size=UDim2.new(1,-8,0,86)
    f.BackgroundColor3=Color3.fromRGB(39,39,46)
    f.Parent=parent
    corner(f,10)

    local l=Instance.new("TextLabel")
    l.BackgroundTransparency=1
    l.Position=UDim2.fromOffset(8,5)
    l.Size=UDim2.new(0.70,-10,1,-10)
    l.TextWrapped=true
    l.TextXAlignment=Enum.TextXAlignment.Left
    l.TextColor3=Color3.new(1,1,1)
    l.Font=Enum.Font.Gotham
    l.TextScaled=true
    l.Text=string.format("%s [%s] #%04d\n%s Coins • %s",listing.item.relicName,listing.item.mutationName,listing.item.serial,fmt(listing.price),listing.sellerName)
    l.Parent=f

    actionButton(f,"BUY",1,0.27,function()
        BuyListing:FireServer(listing.listingId)
    end,false)
end

local function rebuildEquippedVisual()
    if equippedModel then
        equippedModel:Destroy()
        equippedModel=nil
        equippedItem=nil
    end

    if not state.equippedUid then return end

    for _,item in ipairs(state.inventory) do
        if item.uid==state.equippedUid then
            equippedItem=item
            equippedModel=RelicModelBuilder.build(item)
            equippedModel.Name="LocalEquippedRelic"
            equippedModel.Parent=workspace
            break
        end
    end
end

local function refresh()
    top.Text=string.format(
        "Coins %s | Luck %d | Pity %d | %d/%d | %s",
        fmt(state.coins),state.luckLevel,state.pity,#state.inventory,state.inventoryCap,state.biome.name or "Normal"
    )

    autoBtn.Text=state.autoRoll and "AUTO ON" or "AUTO"
    quickBtn.Text=state.quickRoll and "QUICK ON" or "QUICK"

    clear(left)
    for _,item in ipairs(state.inventory) do
        inventoryRow(left,item)
    end

    clear(right)
    for _,listing in ipairs(state.market) do
        marketRow(right,listing)
    end

    rebuildEquippedVisual()
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
    reveal.Size=UDim2.fromOffset(220,120)
    revealText.Text=string.format("%s\n[%s]\n#%04d\n1/%s",item.relicName,item.mutationName,item.serial,fmt(item.combinedOneIn))
    TweenService:Create(reveal,TweenInfo.new(0.35,Enum.EasingStyle.Back),{Size=UDim2.fromOffset(460,240)}):Play()
    task.delay(state.quickRoll and 0.35 or 1.25,function()
        reveal.Visible=false
    end)
end)

RunService.RenderStepped:Connect(function()
    if not equippedModel or not equippedModel.Parent then return end
    local character=player.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local spin=os.clock()*1.4
    local hover=math.sin(os.clock()*2.2)*0.35
    equippedModel:PivotTo(root.CFrame*CFrame.new(3.5,2.2+hover,0)*CFrame.Angles(0,spin,0))
end)

player.CharacterAdded:Connect(function()
    task.wait(1)
    rebuildEquippedVisual()
end)

refresh()
