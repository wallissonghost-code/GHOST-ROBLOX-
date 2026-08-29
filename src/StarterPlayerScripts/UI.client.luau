local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local RunService=game:GetService("RunService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local player=Players.LocalPlayer
local Shared=ReplicatedStorage:WaitForChild("RelicShared")
local Config=require(Shared:WaitForChild("Config"))
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
local RecycleItem=remotes.RecycleItem
local ClaimDaily=remotes.ClaimDaily
local ClaimQuest=remotes.ClaimQuest
local TradeOffer=remotes.TradeOffer
local TradeIncoming=remotes.TradeIncoming
local TradeRespond=remotes.TradeRespond
local LeaderboardChanged=remotes.LeaderboardChanged
local RequestLeaderboard=remotes.RequestLeaderboard

local state={
    coins=0,luckLevel=0,autoRoll=false,quickRoll=false,pity=0,
    inventory={},inventoryCap=50,market={},biome={name="Normal"},equippedUid=nil,
    quests={},dailyRemaining=0,dailyStreak=0,players={},leaderboard={},
    collectionCount=0,collectionTotal=#Config.RELICS,index={}
}

local equippedModel=nil
local listingItem=nil
local selectedTradeTarget=nil
local selectedTradeItem=nil
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

local function timeFmt(sec)
    sec=math.max(0,math.floor(tonumber(sec) or 0))
    local h=math.floor(sec/3600)
    local m=math.floor((sec%3600)/60)
    return string.format("%02dh %02dm",h,m)
end

local function corner(obj,r)
    local c=Instance.new("UICorner")
    c.CornerRadius=UDim.new(0,r or 10)
    c.Parent=obj
end

local function stroke(obj)
    local s=Instance.new("UIStroke")
    s.Thickness=1
    s.Transparency=.5
    s.Parent=obj
end

local gui=Instance.new("ScreenGui")
gui.Name="RelicMarketRNGFullUI"
gui.ResetOnSpawn=false
gui.Parent=player:WaitForChild("PlayerGui")

local stats=Instance.new("TextLabel")
stats.AnchorPoint=Vector2.new(1,0)
stats.Position=UDim2.new(1,-14,0,12)
stats.Size=UDim2.fromOffset(520,40)
stats.BackgroundColor3=Color3.fromRGB(16,16,22)
stats.BackgroundTransparency=.12
stats.TextColor3=Color3.new(1,1,1)
stats.Font=Enum.Font.GothamBold
stats.TextSize=17
stats.Parent=gui
corner(stats,11)
stroke(stats)

local biomeBadge=Instance.new("TextLabel")
biomeBadge.AnchorPoint=Vector2.new(.5,0)
biomeBadge.Position=UDim2.new(.5,0,0,12)
biomeBadge.Size=UDim2.fromOffset(220,40)
biomeBadge.BackgroundColor3=Color3.fromRGB(45,36,75)
biomeBadge.BackgroundTransparency=.12
biomeBadge.TextColor3=Color3.new(1,1,1)
biomeBadge.Font=Enum.Font.GothamBlack
biomeBadge.TextSize=16
biomeBadge.Parent=gui
corner(biomeBadge,11)

local menu=Instance.new("Frame")
menu.Position=UDim2.fromOffset(14,82)
menu.Size=UDim2.fromOffset(150,330)
menu.BackgroundTransparency=1
menu.Parent=gui

local menuButtons={}
local function menuButton(id,text,y)
    local b=Instance.new("TextButton")
    b.Position=UDim2.fromOffset(0,y)
    b.Size=UDim2.fromOffset(150,44)
    b.BackgroundColor3=Color3.fromRGB(34,33,44)
    b.TextColor3=Color3.new(1,1,1)
    b.Font=Enum.Font.GothamBold
    b.TextSize=14
    b.Text=text
    b.Parent=menu
    corner(b,9)
    stroke(b)
    menuButtons[id]=b
    return b
end

menuButton("inventory","🎒 INVENTÁRIO",0)
menuButton("market","🏪 MERCADO",50)
menuButton("quests","✅ MISSÕES",100)
menuButton("collection","📚 COLEÇÃO",150)
menuButton("trade","🔄 TRADE",200)
menuButton("ranking","🏆 RANKING",250)

local daily=Instance.new("TextButton")
daily.AnchorPoint=Vector2.new(0,1)
daily.Position=UDim2.new(0,14,1,-18)
daily.Size=UDim2.fromOffset(150,48)
daily.BackgroundColor3=Color3.fromRGB(176,121,37)
daily.TextColor3=Color3.new(1,1,1)
daily.Font=Enum.Font.GothamBlack
daily.TextSize=14
daily.Text="🎁 DAILY"
daily.Parent=gui
corner(daily,10)

local controls=Instance.new("Frame")
controls.AnchorPoint=Vector2.new(.5,1)
controls.Position=UDim2.new(.5,0,1,-18)
controls.Size=UDim2.fromOffset(476,54)
controls.BackgroundTransparency=1
controls.Parent=gui

local function control(text,x,w)
    local b=Instance.new("TextButton")
    b.Position=UDim2.fromOffset(x,0)
    b.Size=UDim2.fromOffset(w,50)
    b.BackgroundColor3=Color3.fromRGB(84,58,160)
    b.TextColor3=Color3.new(1,1,1)
    b.Font=Enum.Font.GothamBlack
    b.TextSize=18
    b.Text=text
    b.Parent=controls
    corner(b,11)
    return b
end

local rollBtn=control("ROLL",0,120)
local autoBtn=control("AUTO",128,104)
local quickBtn=control("QUICK",240,104)
local luckBtn=control("LUCK+",352,120)

local function makePanel(title)
    local p=Instance.new("Frame")
    p.AnchorPoint=Vector2.new(.5,.5)
    p.Position=UDim2.fromScale(.53,.5)
    p.Size=UDim2.fromOffset(590,540)
    p.BackgroundColor3=Color3.fromRGB(19,19,25)
    p.BackgroundTransparency=.03
    p.Visible=false
    p.ZIndex=10
    p.Parent=gui
    corner(p,16)
    stroke(p)

    local head=Instance.new("TextLabel")
    head.Position=UDim2.fromOffset(18,10)
    head.Size=UDim2.new(1,-80,0,42)
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
    close.BackgroundColor3=Color3.fromRGB(73,53,78)
    close.Text="✕"
    close.TextColor3=Color3.new(1,1,1)
    close.Font=Enum.Font.GothamBold
    close.TextSize=20
    close.ZIndex=12
    close.Parent=p
    corner(close,9)

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

    return p,scroll,head
end

local panels={}
for id,title in pairs({inventory="INVENTÁRIO",market="MERCADO GLOBAL",quests="MISSÕES",collection="COLEÇÃO",trade="TRADE",ranking="RANKING DE COINS"}) do
    local p,s,h=makePanel(title)
    panels[id]={frame=p,scroll=s,head=h}
end

local function showPanel(id)
    local target=panels[id]
    if not target then return end
    if activePanel and activePanel~=target.frame then activePanel.Visible=false end
    target.frame.Visible=not target.frame.Visible
    activePanel=target.frame.Visible and target.frame or nil
    if id=="ranking" and target.frame.Visible then RequestLeaderboard:FireServer() end
end

for id,b in pairs(menuButtons) do
    b.MouseButton1Click:Connect(function() showPanel(id) end)
end

local notice=Instance.new("TextLabel")
notice.AnchorPoint=Vector2.new(.5,0)
notice.Position=UDim2.new(.5,0,0,62)
notice.Size=UDim2.fromOffset(620,44)
notice.BackgroundColor3=Color3.fromRGB(12,12,16)
notice.BackgroundTransparency=.06
notice.TextColor3=Color3.new(1,1,1)
notice.Font=Enum.Font.GothamBold
notice.TextSize=17
notice.Visible=false
notice.ZIndex=40
notice.Parent=gui
corner(notice,10)

local reveal=Instance.new("Frame")
reveal.AnchorPoint=Vector2.new(.5,.5)
reveal.Position=UDim2.fromScale(.5,.43)
reveal.Size=UDim2.fromOffset(380,190)
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
priceModal.ZIndex=50
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
priceTitle.ZIndex=51
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
priceBox.ZIndex=51
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
confirmList.ZIndex=51
confirmList.Parent=priceModal
corner(confirmList,10)

local cancelList=confirmList:Clone()
cancelList.AnchorPoint=Vector2.new(1,0)
cancelList.Position=UDim2.new(1,-24,0,154)
cancelList.Size=UDim2.fromOffset(120,52)
cancelList.BackgroundColor3=Color3.fromRGB(145,64,70)
cancelList.Text="CANCELAR"
cancelList.Parent=priceModal

local tradeModal=Instance.new("Frame")
tradeModal.AnchorPoint=Vector2.new(.5,.5)
tradeModal.Position=UDim2.fromScale(.5,.5)
tradeModal.Size=UDim2.fromOffset(430,250)
tradeModal.BackgroundColor3=Color3.fromRGB(21,21,28)
tradeModal.Visible=false
tradeModal.ZIndex=55
tradeModal.Parent=gui
corner(tradeModal,16)

local tradeText=Instance.new("TextLabel")
tradeText.Position=UDim2.fromOffset(18,18)
tradeText.Size=UDim2.new(1,-36,0,150)
tradeText.BackgroundTransparency=1
tradeText.TextColor3=Color3.new(1,1,1)
tradeText.Font=Enum.Font.GothamBold
tradeText.TextSize=18
tradeText.TextWrapped=true
tradeText.ZIndex=56
tradeText.Parent=tradeModal

local acceptTrade=Instance.new("TextButton")
acceptTrade.Position=UDim2.fromOffset(24,182)
acceptTrade.Size=UDim2.fromOffset(225,48)
acceptTrade.BackgroundColor3=Color3.fromRGB(65,145,90)
acceptTrade.Text="ACEITAR"
acceptTrade.TextColor3=Color3.new(1,1,1)
acceptTrade.Font=Enum.Font.GothamBlack
acceptTrade.TextSize=18
acceptTrade.ZIndex=56
acceptTrade.Parent=tradeModal
corner(acceptTrade,10)

local declineTrade=acceptTrade:Clone()
declineTrade.AnchorPoint=Vector2.new(1,0)
declineTrade.Position=UDim2.new(1,-24,0,182)
declineTrade.Size=UDim2.fromOffset(135,48)
declineTrade.BackgroundColor3=Color3.fromRGB(145,64,70)
declineTrade.Text="RECUSAR"
declineTrade.Parent=tradeModal

local incomingOfferId=nil

local function clear(scroll)
    for _,c in scroll:GetChildren() do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end
end

local function row(scroll,text,actions,height)
    local f=Instance.new("Frame")
    f.Size=UDim2.new(1,-6,0,height or 80)
    f.BackgroundColor3=Color3.fromRGB(37,37,45)
    f.ZIndex=12
    f.Parent=scroll
    corner(f,10)

    local label=Instance.new("TextLabel")
    label.Position=UDim2.fromOffset(10,6)
    label.Size=UDim2.new(1,-210,1,-12)
    label.BackgroundTransparency=1
    label.Text=text
    label.TextColor3=Color3.new(1,1,1)
    label.TextXAlignment=Enum.TextXAlignment.Left
    label.TextWrapped=true
    label.Font=Enum.Font.Gotham
    label.TextSize=16
    label.ZIndex=13
    label.Parent=f

    local right=10
    for i=#actions,1,-1 do
        local a=actions[i]
        local w=a.w or 72
        local b=Instance.new("TextButton")
        b.AnchorPoint=Vector2.new(1,.5)
        b.Position=UDim2.new(1,-right,.5,0)
        b.Size=UDim2.fromOffset(w,42)
        b.BackgroundColor3=a.disabled and Color3.fromRGB(65,65,72) or (a.color or Color3.fromRGB(86,60,160))
        b.Text=a.text
        b.TextColor3=Color3.new(1,1,1)
        b.Font=Enum.Font.GothamBold
        b.TextSize=13
        b.ZIndex=13
        b.AutoButtonColor=not a.disabled
        b.Parent=f
        corner(b,8)
        if not a.disabled then b.MouseButton1Click:Connect(a.cb) end
        right+=w+8
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

local function rebuildInventory()
    clear(panels.inventory.scroll)
    for _,item in ipairs(state.inventory) do
        local equipped=state.equippedUid==item.uid
        row(panels.inventory.scroll,string.format("%s [%s] #%04d\n1/%s • MV %s",item.relicName,item.mutationName,item.serial,fmt(item.combinedOneIn),fmt(item.marketValue or item.baseValue)),{
            {text=equipped and "ON" or "EQUIP",w=66,cb=function() EquipItem:FireServer(item.uid) end},
            {text=item.listed and "LISTED" or "SELL",w=64,disabled=item.listed==true,cb=function()
                listingItem=item
                priceTitle.Text=string.format("ANUNCIAR %s #%04d",item.relicName,item.serial)
                priceBox.Text=tostring(math.max(1,math.floor(item.marketValue or item.baseValue or 1)))
                priceModal.Visible=true
            end},
            {text="RECYCLE",w=72,color=Color3.fromRGB(116,83,46),disabled=item.listed==true,cb=function() RecycleItem:FireServer(item.uid) end},
        })
    end
end

local function rebuildMarket()
    clear(panels.market.scroll)
    for _,listing in ipairs(state.market) do
        local own=listing.sellerUserId==player.UserId
        row(panels.market.scroll,string.format("%s [%s] #%04d\n%s Coins • %s",listing.item.relicName,listing.item.mutationName,listing.item.serial,fmt(listing.price),listing.sellerName),{
            {text=own and "CANCEL" or "BUY",w=88,color=own and Color3.fromRGB(145,64,70) or Color3.fromRGB(65,145,90),cb=function()
                if own then CancelListing:FireServer(listing.listingId) else BuyListing:FireServer(listing.listingId) end
            end}
        })
    end
    if #state.market==0 then row(panels.market.scroll,"Nenhum item anunciado agora.",{}) end
end

local function rebuildQuests()
    clear(panels.quests.scroll)
    for _,q in ipairs(state.quests or {}) do
        local complete=(q.progress or 0)>=(q.target or 1)
        row(panels.quests.scroll,string.format("%s\n%d/%d • Recompensa %s Coins",q.name,q.progress,q.target,fmt(q.reward)),{
            {text=q.claimed and "OK" or "CLAIM",w=82,disabled=q.claimed or not complete,color=Color3.fromRGB(65,145,90),cb=function() ClaimQuest:FireServer(q.id) end}
        })
    end
end

local function rebuildCollection()
    clear(panels.collection.scroll)
    panels.collection.head.Text=string.format("COLEÇÃO • %d/%d",state.collectionCount or 0,state.collectionTotal or #Config.RELICS)
    for _,r in ipairs(Config.RELICS) do
        local found=state.index and state.index[r.id]
        row(panels.collection.scroll,string.format("%s  •  %s  •  1/%s\n%s",found and "✅" or "❔",r.name,fmt(r.oneIn),found and "DESCOBERTO" or "NÃO DESCOBERTO"),{})
    end
end

local function rebuildTrade()
    clear(panels.trade.scroll)
    row(panels.trade.scroll,"PASSO 1: escolha um player. A oferta pede a RELÍQUIA EQUIPADA dele.",{})
    for _,p in ipairs(state.players or {}) do
        if p.userId~=player.UserId then
            local selected=selectedTradeTarget and selectedTradeTarget.userId==p.userId
            row(panels.trade.scroll,(selected and "✅ " or "👤 ")..p.name,{
                {text=selected and "SELECTED" or "SELECT",w=92,cb=function() selectedTradeTarget=p rebuildTrade() end}
            })
        end
    end
    if selectedTradeTarget then
        row(panels.trade.scroll,"PASSO 2: escolha qual relíquia SUA oferecer por "..selectedTradeTarget.name..".",{})
        for _,item in ipairs(state.inventory) do
            if not item.listed then
                local selected=selectedTradeItem and selectedTradeItem.uid==item.uid
                row(panels.trade.scroll,string.format("%s%s [%s] #%04d",selected and "✅ " or "",item.relicName,item.mutationName,item.serial),{
                    {text=selected and "SELECTED" or "OFFER",w=82,cb=function() selectedTradeItem=item rebuildTrade() end}
                })
            end
        end
        if selectedTradeItem then
            row(panels.trade.scroll,"Oferta pronta: sua "..selectedTradeItem.relicName.." pela relíquia equipada de "..selectedTradeTarget.name..".",{
                {text="ENVIAR TRADE",w=125,color=Color3.fromRGB(65,145,90),cb=function()
                    TradeOffer:FireServer(selectedTradeTarget.userId,selectedTradeItem.uid,"__equipped__")
                    selectedTradeItem=nil
                end}
            },88)
        end
    end
end

local function rebuildRanking()
    clear(panels.ranking.scroll)
    for i,entry in ipairs(state.leaderboard or {}) do
        row(panels.ranking.scroll,string.format("#%d   %s\n💰 %s Coins",i,entry.name or tostring(entry.userId),fmt(entry.coins)),{})
    end
    if #(state.leaderboard or {})==0 then row(panels.ranking.scroll,"Carregando ranking...",{}) end
end

local function refresh()
    stats.Text=string.format("💰 %s   Luck %d   Pity %d   🎒 %d/%d   📚 %d/%d",fmt(state.coins),state.luckLevel,state.pity,#state.inventory,state.inventoryCap,state.collectionCount or 0,state.collectionTotal or #Config.RELICS)
    biomeBadge.Text="🌌 "..(state.biome.name or "Normal").."  x"..tostring(state.biome.luckMult or 1)
    autoBtn.Text=state.autoRoll and "AUTO ON" or "AUTO"
    quickBtn.Text=state.quickRoll and "QUICK ON" or "QUICK"
    daily.Text=state.dailyRemaining and state.dailyRemaining>0 and ("🎁 "..timeFmt(state.dailyRemaining)) or ("🎁 DAILY x"..tostring((state.dailyStreak or 0)+1))

    rebuildInventory()
    rebuildMarket()
    rebuildQuests()
    rebuildCollection()
    rebuildTrade()
    rebuildRanking()
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

daily.MouseButton1Click:Connect(function() ClaimDaily:FireServer() end)
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
    rebuildMarket()
end)

BiomeChanged.OnClientEvent:Connect(function(b)
    state.biome=b
    biomeBadge.Text="🌌 "..(b.name or "Normal").."  x"..tostring(b.luckMult or 1)
end)

LeaderboardChanged.OnClientEvent:Connect(function(data)
    state.leaderboard=data or {}
    rebuildRanking()
end)

Notify.OnClientEvent:Connect(function(text)
    notice.Text=tostring(text)
    notice.Visible=true
    task.delay(2.8,function() notice.Visible=false end)
end)

RollResult.OnClientEvent:Connect(function(item)
    reveal.Visible=true
    reveal.Size=UDim2.fromOffset(220,110)
    revealText.Text=string.format("%s\n[%s] #%04d\n1/%s",item.relicName,item.mutationName,item.serial,fmt(item.combinedOneIn))
    TweenService:Create(reveal,TweenInfo.new(.3,Enum.EasingStyle.Back),{Size=UDim2.fromOffset(390,190)}):Play()
    task.delay(state.quickRoll and .35 or 1.15,function() reveal.Visible=false end)
end)

TradeIncoming.OnClientEvent:Connect(function(offer)
    incomingOfferId=offer.id
    tradeText.Text=string.format("%s quer trocar:\n%s #%04d\nPOR SUA\n%s #%04d",offer.fromName,offer.myItemName,offer.mySerial,offer.wantedItemName,offer.wantedSerial)
    tradeModal.Visible=true
end)

acceptTrade.MouseButton1Click:Connect(function()
    if incomingOfferId then TradeRespond:FireServer(incomingOfferId,true) end
    incomingOfferId=nil
    tradeModal.Visible=false
end)

declineTrade.MouseButton1Click:Connect(function()
    if incomingOfferId then TradeRespond:FireServer(incomingOfferId,false) end
    incomingOfferId=nil
    tradeModal.Visible=false
end)

RunService.RenderStepped:Connect(function()
    if equippedModel and equippedModel.Parent then
        local character=player.Character
        local root=character and character:FindFirstChild("HumanoidRootPart")
        if root then
            local spin=os.clock()*1.3
            local hover=math.sin(os.clock()*2.2)*.28
            equippedModel:PivotTo(root.CFrame*CFrame.new(3.1,2.1+hover,0)*CFrame.Angles(0,spin,0))
        end
    end
end)

player.CharacterAdded:Connect(function()
    task.wait(1)
    rebuildEquipped()
end)

task.spawn(function()
    while gui.Parent do
        task.wait(60)
        if state.dailyRemaining and state.dailyRemaining>0 then
            state.dailyRemaining=math.max(0,state.dailyRemaining-60)
            daily.Text=state.dailyRemaining>0 and ("🎁 "..timeFmt(state.dailyRemaining)) or "🎁 DAILY"
        end
    end
end)

refresh()
