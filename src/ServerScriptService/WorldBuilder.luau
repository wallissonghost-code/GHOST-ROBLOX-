local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Shared=ReplicatedStorage:WaitForChild("RelicShared")
local RelicModelBuilder=require(Shared.RelicModelBuilder)

local WorldBuilder={}

local PLOT_POSITIONS={
    Vector3.new(-110,0,105), Vector3.new(0,0,118), Vector3.new(110,0,105),
    Vector3.new(-118,0,0), Vector3.new(118,0,0),
    Vector3.new(-110,0,-105), Vector3.new(0,0,-125), Vector3.new(110,0,-105),
}

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

local function surfaceText(part,text,face)
    local gui=Instance.new("SurfaceGui")
    gui.Face=face or Enum.NormalId.Front
    gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud=28
    gui.Parent=part
    local t=Instance.new("TextLabel")
    t.Size=UDim2.fromScale(1,1)
    t.BackgroundColor3=Color3.fromRGB(15,15,20)
    t.BackgroundTransparency=.12
    t.TextColor3=Color3.new(1,1,1)
    t.Font=Enum.Font.GothamBlack
    t.TextScaled=true
    t.TextWrapped=true
    t.Text=text
    t.Parent=gui
    return t
end

local function lamp(parent,pos)
    local pole=p(parent,"StreetLamp",Vector3.new(1,10,1),pos+Vector3.new(0,5,0),Color3.fromRGB(55,55,64),Enum.Material.Metal)
    local head=p(parent,"StreetLampHead",Vector3.new(2.8,.8,2.8),pos+Vector3.new(0,10,0),Color3.fromRGB(225,215,175),Enum.Material.Neon)
    local light=Instance.new("PointLight")
    light.Range=24
    light.Brightness=1.2
    light.Color=Color3.fromRGB(255,238,190)
    light.Parent=head
    return pole
end

local function tree(parent,pos)
    p(parent,"TreeTrunk",Vector3.new(2,7,2),pos+Vector3.new(0,3.5,0),Color3.fromRGB(88,63,42),Enum.Material.Wood)
    local crown=p(parent,"TreeCrown",Vector3.new(8,8,8),pos+Vector3.new(0,10,0),Color3.fromRGB(55,103,69),Enum.Material.Grass)
    crown.Shape=Enum.PartType.Ball
end

local function road(parent,name,size,pos)
    local r=p(parent,name,size,pos,Color3.fromRGB(38,40,45),Enum.Material.Asphalt)
    r.CanCollide=true
    return r
end

local function sidewalk(parent,name,size,pos)
    return p(parent,name,size,pos,Color3.fromRGB(94,95,101),Enum.Material.Concrete)
end

local function buildMuseumFrontage(world,index,center)
    -- Public sidewalk / NPC arrival zone in front of each museum.
    sidewalk(world,"MuseumSidewalk"..index,Vector3.new(72,.5,10),center+Vector3.new(0,.3,38))
    local marker=p(world,"MuseumGateMarker"..index,Vector3.new(16,.45,7),center+Vector3.new(0,.55,34),Color3.fromRGB(87,62,152),Enum.Material.Neon)
    marker.Transparency=.35
    marker.CanCollide=false
    marker:SetAttribute("MuseumIndex",index)
    marker:SetAttribute("NPCEntry",true)

    -- Reserved strip for the future personal crate conveyor.
    local conveyorBase=p(world,"ConveyorReserve"..index,Vector3.new(9,.55,42),center+Vector3.new(-31,.85,0),Color3.fromRGB(35,37,44),Enum.Material.Metal)
    conveyorBase:SetAttribute("MuseumIndex",index)
    conveyorBase:SetAttribute("FutureConveyor",true)

    local belt=p(world,"ConveyorBeltPreview"..index,Vector3.new(6,.3,38),center+Vector3.new(-31,1.3,0),Color3.fromRGB(67,70,80),Enum.Material.Metal)
    belt:SetAttribute("MuseumIndex",index)
    belt:SetAttribute("FutureConveyor",true)

    -- Three future crate-opening positions.
    for slot=1,3 do
        local z=-12+(slot-1)*12
        local pad=p(world,"CrateOpenPad_"..index.."_"..slot,Vector3.new(7,.35,7),center+Vector3.new(31,.75,z),Color3.fromRGB(71,55,105),Enum.Material.Marble)
        pad:SetAttribute("MuseumIndex",index)
        pad:SetAttribute("CrateOpenSlot",slot)
    end
end

function WorldBuilder.build()
    local old=workspace:FindFirstChild("RelicWorld")
    if old then old:Destroy() end

    local world=Instance.new("Folder")
    world.Name="RelicWorld"
    world.Parent=workspace

    -- Large neighborhood base.
    p(world,"Ground",Vector3.new(520,2,520),Vector3.new(0,-1,0),Color3.fromRGB(48,73,52),Enum.Material.Grass)

    -- Main cross avenues connecting every museum to the hub.
    road(world,"MainAvenueNS",Vector3.new(30,1,420),Vector3.new(0,.05,0))
    road(world,"MainAvenueEW",Vector3.new(420,1,30),Vector3.new(0,.06,0))

    -- Secondary north/south streets serving the corner museums.
    road(world,"WestMuseumStreet",Vector3.new(24,1,300),Vector3.new(-110,.07,0))
    road(world,"EastMuseumStreet",Vector3.new(24,1,300),Vector3.new(110,.07,0))
    road(world,"NorthMuseumStreet",Vector3.new(300,1,24),Vector3.new(0,.08,105))
    road(world,"SouthMuseumStreet",Vector3.new(300,1,24),Vector3.new(0,.08,-105))

    -- Central social plaza.
    local plaza=sidewalk(world,"MuseumDistrictPlaza",Vector3.new(86,1,86),Vector3.new(0,.55,0))
    local plazaCore=p(world,"PlazaCore",Vector3.new(38,1.2,38),Vector3.new(0,1.1,0),Color3.fromRGB(66,58,91),Enum.Material.Marble)
    plazaCore:SetAttribute("SocialHub",true)

    -- Central station / future crate-event terminal.
    local station=p(world,"CentralStation",Vector3.new(24,8,12),Vector3.new(0,4,-10),Color3.fromRGB(45,43,57),Enum.Material.Metal)
    surfaceText(station,"MUSEUM DISTRICT\nCENTRAL STATION",Enum.NormalId.Front)
    local stationRoof=p(world,"StationRoof",Vector3.new(30,1.3,17),Vector3.new(0,8.6,-10),Color3.fromRGB(91,62,170),Enum.Material.Metal)
    stationRoof.CanCollide=true

    local marketBoard=p(world,"MarketBoard",Vector3.new(19,7,1),Vector3.new(-28,4,17),Color3.fromRGB(30,30,37),Enum.Material.SmoothPlastic)
    surfaceText(marketBoard,"PLAYER\nMARKET",Enum.NormalId.Front)
    local rankingBoard=p(world,"RankingBoard",Vector3.new(19,7,1),Vector3.new(28,4,17),Color3.fromRGB(30,30,37),Enum.Material.SmoothPlastic)
    surfaceText(rankingBoard,"MUSEUM\nRANKING",Enum.NormalId.Front)

    -- Decorative fountain / meeting landmark.
    local fountain=p(world,"FountainBase",Vector3.new(15,2,15),Vector3.new(0,1.6,19),Color3.fromRGB(103,105,115),Enum.Material.Marble)
    local water=p(world,"FountainWater",Vector3.new(12,.4,12),Vector3.new(0,2.75,19),Color3.fromRGB(75,155,210),Enum.Material.Glass)
    water.Transparency=.2
    p(world,"FountainCenter",Vector3.new(3,8,3),Vector3.new(0,6,19),Color3.fromRGB(122,124,135),Enum.Material.Marble)

    -- Street furniture and greenery around the hub.
    for _,pos in ipairs({
        Vector3.new(-46,0,-46),Vector3.new(46,0,-46),Vector3.new(-46,0,46),Vector3.new(46,0,46),
        Vector3.new(-75,0,-20),Vector3.new(75,0,-20),Vector3.new(-75,0,20),Vector3.new(75,0,20),
        Vector3.new(-20,0,-75),Vector3.new(20,0,-75),Vector3.new(-20,0,75),Vector3.new(20,0,75),
    }) do lamp(world,pos) end

    for _,pos in ipairs({
        Vector3.new(-55,0,-55),Vector3.new(55,0,-55),Vector3.new(-55,0,55),Vector3.new(55,0,55),
        Vector3.new(-155,0,45),Vector3.new(155,0,45),Vector3.new(-155,0,-45),Vector3.new(155,0,-45),
    }) do tree(world,pos) end

    -- Every museum gets an exterior sidewalk, NPC entry marker and reserved crate machinery footprint.
    for i,center in ipairs(PLOT_POSITIONS) do
        buildMuseumFrontage(world,i,center)
    end

    -- Neighborhood border and four gateways.
    sidewalk(world,"NorthPromenade",Vector3.new(380,1,16),Vector3.new(0,.25,180))
    sidewalk(world,"SouthPromenade",Vector3.new(380,1,16),Vector3.new(0,.25,-180))
    sidewalk(world,"EastPromenade",Vector3.new(16,1,380),Vector3.new(180,.25,0))
    sidewalk(world,"WestPromenade",Vector3.new(16,1,380),Vector3.new(-180,.25,0))

    for i,data in ipairs({
        {Vector3.new(0,7,188),"MUSEUM DISTRICT"},
        {Vector3.new(0,7,-188),"MUSEUM DISTRICT"},
        {Vector3.new(188,7,0),"MUSEUM DISTRICT"},
        {Vector3.new(-188,7,0),"MUSEUM DISTRICT"},
    }) do
        local gate=p(world,"DistrictGate"..i,Vector3.new(30,12,2),data[1],Color3.fromRGB(50,47,62),Enum.Material.Metal)
        surfaceText(gate,data[2],Enum.NormalId.Front)
    end

    -- Neutral emergency spawn. MuseumBootstrap immediately moves players to their assigned museum.
    local spawn=Instance.new("SpawnLocation")
    spawn.Name="EmergencySpawn"
    spawn.Size=Vector3.new(10,1,10)
    spawn.Position=Vector3.new(0,2,0)
    spawn.Anchored=true
    spawn.Neutral=true
    spawn.Transparency=1
    spawn.CanCollide=false
    spawn.Parent=world

    -- Legacy roll trigger kept only so existing server code remains compatible while crate mechanics replace Roll.
    local legacy=p(world,"LegacyRollTrigger",Vector3.new(2,2,2),Vector3.new(0,-20,0),Color3.new(0,0,0),Enum.Material.SmoothPlastic)
    legacy.Transparency=1
    legacy.CanCollide=false
    local prompt=Instance.new("ProximityPrompt")
    prompt.Name="RollPrompt"
    prompt.ActionText="ROLL"
    prompt.ObjectText="Legacy"
    prompt.Enabled=false
    prompt.Parent=legacy

    return {folder=world,altar=legacy,prompt=prompt,plaza=plaza,plotPositions=PLOT_POSITIONS}
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
