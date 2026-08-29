local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Shared=ReplicatedStorage:WaitForChild("RelicShared")
local RelicModelBuilder=require(Shared.RelicModelBuilder)

local WorldBuilder={}

local function p(parent,name,size,pos,color,material)
    local x=Instance.new("Part")
    x.Name=name
    x.Size=size
    x.Position=pos
    x.Anchored=true
    x.Color=color
    x.Material=material or Enum.Material.SmoothPlastic
    x.TopSurface=Enum.SurfaceType.Smooth
    x.BottomSurface=Enum.SurfaceType.Smooth
    x.Parent=parent
    return x
end

local function sign(part,text,offset,width)
    local gui=Instance.new("BillboardGui")
    gui.Adornee=part
    gui.Size=UDim2.fromOffset(width or 260,64)
    gui.StudsOffset=offset or Vector3.new(0,4,0)
    gui.AlwaysOnTop=true
    gui.Parent=part

    local t=Instance.new("TextLabel")
    t.Size=UDim2.fromScale(1,1)
    t.BackgroundTransparency=.18
    t.BackgroundColor3=Color3.fromRGB(12,12,18)
    t.TextColor3=Color3.new(1,1,1)
    t.Font=Enum.Font.GothamBlack
    t.TextScaled=true
    t.TextWrapped=true
    t.Text=text
    t.Parent=gui

    local c=Instance.new("UICorner")
    c.CornerRadius=UDim.new(0,10)
    c.Parent=t
end

local function pillar(parent,pos,height,color)
    p(parent,"Pillar",Vector3.new(3,height,3),pos+Vector3.new(0,height/2,0),color,Enum.Material.Marble)
    p(parent,"PillarCap",Vector3.new(4,1,4),pos+Vector3.new(0,height+.5,0),color,Enum.Material.Marble)
end

local function zonePad(parent,name,pos,color,label)
    local pad=p(parent,name,Vector3.new(46,1,46),pos,color,Enum.Material.Slate)
    sign(pad,label,Vector3.new(0,5,0),300)
    for _,dx in ipairs({-20,20}) do
        for _,dz in ipairs({-20,20}) do
            pillar(parent,pos+Vector3.new(dx,0,dz),8,color)
        end
    end
    return pad
end

function WorldBuilder.build()
    local old=workspace:FindFirstChild("RelicWorld")
    if old then old:Destroy() end

    local world=Instance.new("Folder")
    world.Name="RelicWorld"
    world.Parent=workspace

    p(world,"Ground",Vector3.new(440,2,440),Vector3.new(0,-1,0),Color3.fromRGB(30,33,38),Enum.Material.Slate)

    -- central plaza
    p(world,"CentralPlaza",Vector3.new(130,1,130),Vector3.new(0,.5,0),Color3.fromRGB(45,46,54),Enum.Material.Marble)
    for i=1,4 do
        local angle=math.rad((i-1)*90+45)
        pillar(world,Vector3.new(math.cos(angle)*55,1,math.sin(angle)*55),12,Color3.fromRGB(77,71,95))
    end

    local altarBase=p(world,"AltarBase",Vector3.new(28,2,28),Vector3.new(0,1.5,0),Color3.fromRGB(45,35,70),Enum.Material.Marble)
    local altar=p(world,"RollAltar",Vector3.new(14,5,14),Vector3.new(0,4,0),Color3.fromRGB(105,70,205),Enum.Material.Neon)
    sign(altar,"⚡ RELIC ALTAR ⚡\nROLL AQUI",Vector3.new(0,7,0),300)

    local prompt=Instance.new("ProximityPrompt")
    prompt.Name="RollPrompt"
    prompt.ActionText="ROLL"
    prompt.ObjectText="Relic Altar"
    prompt.HoldDuration=0
    prompt.MaxActivationDistance=16
    prompt.KeyboardKeyCode=Enum.KeyCode.E
    prompt.Parent=altar

    local altarLight=Instance.new("PointLight")
    altarLight.Range=35
    altarLight.Brightness=3
    altarLight.Color=Color3.fromRGB(160,110,255)
    altarLight.Parent=altar

    -- showcase circle
    for i=1,8 do
        local angle=math.rad((i-1)*45)
        local pedestal=p(world,"ShowcasePedestal"..i,Vector3.new(7,2,7),Vector3.new(math.cos(angle)*43,1.5,math.sin(angle)*43),Color3.fromRGB(65,67,76),Enum.Material.Marble)
        pedestal:SetAttribute("PedestalIndex",i)
    end

    -- Market district
    local marketFloor=p(world,"MarketFloor",Vector3.new(108,1,62),Vector3.new(0,.5,-112),Color3.fromRGB(50,52,60),Enum.Material.Concrete)
    sign(marketFloor,"🏪 PLAYER MARKET",Vector3.new(0,6,0),330)
    for i=1,10 do
        local x=-40+((i-1)%5)*20
        local z=-102-math.floor((i-1)/5)*20
        local booth=p(world,"MarketBooth"..i,Vector3.new(14,5,12),Vector3.new(x,3,z),Color3.fromRGB(72,74,86),Enum.Material.Metal)
        booth:SetAttribute("MarketBooth",i)
        p(world,"BoothCounter"..i,Vector3.new(14,3,3),Vector3.new(x,4,z+5),Color3.fromRGB(95,78,117),Enum.Material.WoodPlanks)
    end

    -- Trade plaza
    local tradeFloor=zonePad(world,"TradePlaza",Vector3.new(120,.5,20),Color3.fromRGB(44,70,72),"🔄 TRADE PLAZA")
    p(world,"TradeTable",Vector3.new(18,3,8),Vector3.new(120,2.5,20),Color3.fromRGB(66,112,112),Enum.Material.WoodPlanks)

    -- Daily / Quests area
    local dailyFloor=zonePad(world,"DailyZone",Vector3.new(-120,.5,20),Color3.fromRGB(89,68,38),"🎁 DAILY + MISSÕES")
    local chest=p(world,"DailyChest",Vector3.new(10,7,7),Vector3.new(-120,4,20),Color3.fromRGB(199,145,42),Enum.Material.Metal)
    sign(chest,"DAILY REWARD\nUse o botão na tela",Vector3.new(0,6,0),260)
    local questBoard=p(world,"QuestBoard",Vector3.new(18,11,2),Vector3.new(-120,6,38),Color3.fromRGB(79,59,36),Enum.Material.WoodPlanks)
    sign(questBoard,"✅ MISSÕES\nRoll • Rare • Market",Vector3.new(0,0,0),270)

    -- Leaderboard area
    local rankFloor=zonePad(world,"RankingZone",Vector3.new(0,.5,120),Color3.fromRGB(70,56,30),"🏆 HALL DOS COLECIONADORES")
    local board=p(world,"LeaderboardBoard",Vector3.new(30,16,2),Vector3.new(0,9,132),Color3.fromRGB(25,25,30),Enum.Material.SmoothPlastic)
    sign(board,"🏆 TOP COINS\nAbra RANKING no menu",Vector3.new(0,0,0),360)

    -- Collection vault
    local collectionFloor=zonePad(world,"CollectionVault",Vector3.new(0,.5,190),Color3.fromRGB(46,49,74),"📚 COLLECTION VAULT")
    for i=1,6 do
        local x=-25+(i-1)*10
        p(world,"VaultStand"..i,Vector3.new(6,2,6),Vector3.new(x,2,190),Color3.fromRGB(75,78,105),Enum.Material.Marble)
    end

    -- Future progression islands / biome visual landmarks
    zonePad(world,"VoidZone",Vector3.new(155,.5,-125),Color3.fromRGB(46,31,62),"🌌 VOID DISTRICT")
    zonePad(world,"CelestialZone",Vector3.new(-155,.5,-125),Color3.fromRGB(105,96,58),"✨ CELESTIAL DISTRICT")

    -- paths connecting hub
    p(world,"PathNorth",Vector3.new(16,1,150),Vector3.new(0,.55,105),Color3.fromRGB(61,62,68),Enum.Material.Concrete)
    p(world,"PathSouth",Vector3.new(16,1,95),Vector3.new(0,.55,-66),Color3.fromRGB(61,62,68),Enum.Material.Concrete)
    p(world,"PathEast",Vector3.new(120,1,16),Vector3.new(80,.55,20),Color3.fromRGB(61,62,68),Enum.Material.Concrete)
    p(world,"PathWest",Vector3.new(120,1,16),Vector3.new(-80,.55,20),Color3.fromRGB(61,62,68),Enum.Material.Concrete)

    local spawn=Instance.new("SpawnLocation")
    spawn.Name="Spawn"
    spawn.Size=Vector3.new(12,1,12)
    spawn.Position=Vector3.new(0,2,62)
    spawn.Anchored=true
    spawn.Neutral=true
    spawn.Material=Enum.Material.Neon
    spawn.Color=Color3.fromRGB(96,76,170)
    spawn.Parent=world
    sign(spawn,"WELCOME TO RELIC MARKET RNG",Vector3.new(0,5,0),360)

    return {folder=world,altar=altar,prompt=prompt}
end

function WorldBuilder.showDrop(item)
    local folder=workspace:FindFirstChild("RelicWorld")
    if not folder then return end

    local old=folder:FindFirstChild("DropDisplay")
    if old then old:Destroy() end

    local holder=Instance.new("Model")
    holder.Name="DropDisplay"
    holder.Parent=folder

    local model=RelicModelBuilder.build(item)
    model.Parent=holder
    model:PivotTo(CFrame.new(0,11,0))

    if model.PrimaryPart then
        local light=Instance.new("PointLight")
        light.Range=25
        light.Brightness=3
        light.Parent=model.PrimaryPart
    end

    task.delay(3.5,function()
        if holder.Parent then holder:Destroy() end
    end)
end

return WorldBuilder
