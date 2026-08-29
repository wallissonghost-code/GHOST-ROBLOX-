local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local player=Players.LocalPlayer
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
    inventory={},inventoryCap=50,market={},biome={name="Normal"}
}

local function fmt(n)
    n=tonumber(n) or 0
    if n>=1e12 then return string.format("%.2fT",n/1e12) end
    if n>=1e9 then return string.format("%.2fB",n/1e9) end
    if n>=1e6 then return string.format("%.2fM",n/1e6) end
    if n>=1e3 then return string.format("%.1fK",n/1e3) end
    return tostring(math.floor(n))
end

local gui=Instance.new("ScreenGui")
gui.Name="RelicMarketRNGV3"
gui.ResetOnSpawn=false
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
    b.Parent=controls
    return b
end

local rollBtn=button("ROLL",0)
local autoBtn=button("AUTO",155)
local quickBtn=button("QUICK",310)
local luckBtn=button("LUCK+",465)

local left=Instance.new("ScrollingFrame")
left.Position=UDim2.fromOffset(10,80)
left.Size=UDim2.new(0.49,-15,1,-168)
left.BackgroundColor3=Color3.fromRGB(27,27,33)
left.AutomaticCanvasSize=Enum.AutomaticSize.Y
left.CanvasSize=UDim2.new()
left.Parent=gui

local right=left:Clone()
right.AnchorPoint=Vector2.new(1,0)
right.Position=UDim2.new(1,-10,0,80)
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
notice.Parent=gui

local reveal=Instance.new("Frame")
reveal.AnchorPoint=Vector2.new(0.5,0.5)
reveal.Position=UDim2.fromScale(0.5,0.5)
reveal.Size=UDim2.fromOffset(420,220)
reveal.BackgroundColor3=Color3.fromRGB(20,20,28)
reveal.Visible=false
reveal.Parent=gui

local revealText=Instance.new("TextLabel")
revealText.BackgroundTransparency=1
revealText.Size=UDim2.fromScale(1,1)
revealText.TextColor3=Color3.new(1,1,1)
revealText.Font=Enum.Font.GothamBlack
revealText.TextScaled=true
revealText.TextWrapped=true
revealText.Parent=reveal

local function clear(frame)
    for _,c in frame:GetChildren() do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end
end

local function row(parent,text,btnText,cb)
    local f=Instance.new("Frame")
    f.Size=UDim2.new(1,-8,0,78)
    f.BackgroundColor3=Color3.fromRGB(39,39,46)
    f.Parent=parent

    local l=Instance.new("TextLabel")
    l.BackgroundTransparency=1
    l.Position=UDim2.fromOffset(8,5)
    l.Size=UDim2.new(0.67,-10,1,-10)
    l.TextWrapped=true
    l.TextXAlignment=Enum.TextXAlignment.Left
    l.TextColor3=Color3.new(1,1,1)
    l.Font=Enum.Font.Gotham
    l.TextScaled=true
    l.Text=text
    l.Parent=f

    local b=Instance.new("TextButton")
    b.AnchorPoint=Vector2.new(1,0.5)
    b.Position=UDim2.new(1,-8,0.5,0)
    b.Size=UDim2.new(0.30,0,0,48)
    b.Text=btnText
    b.Font=Enum.Font.GothamBold
    b.TextScaled=true
    b.Parent=f
    b.MouseButton1Click:Connect(cb)
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
        row(
            left,
            string.format("%s [%s] #%04d\n1/%s • MV %s",item.relicName,item.mutationName,item.serial,fmt(item.combinedOneIn),fmt(item.marketValue or item.baseValue)),
            "EQUIP",
            function() EquipItem:FireServer(item.uid) end
        )
    end

    clear(right)
    for _,listing in ipairs(state.market) do
        row(
            right,
            string.format("%s [%s] #%04d\n%s Coins • %s",listing.item.relicName,listing.item.mutationName,listing.item.serial,fmt(listing.price),listing.sellerName),
            "BUY",
            function() BuyListing:FireServer(listing.listingId) end
        )
    end
end

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

refresh()
