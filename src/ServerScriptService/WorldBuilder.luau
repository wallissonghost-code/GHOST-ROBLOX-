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
    x.Parent=parent
    return x
end

local function sign(part,text)
    local gui=Instance.new("BillboardGui")
    gui.Adornee=part
    gui.Size=UDim2.fromOffset(240,60)
    gui.StudsOffset=Vector3.new(0,4,0)
    gui.AlwaysOnTop=true
    gui.Parent=part

    local t=Instance.new("TextLabel")
    t.Size=UDim2.fromScale(1,1)
    t.BackgroundTransparency=0.25
    t.BackgroundColor3=Color3.fromRGB(15,15,20)
    t.TextColor3=Color3.new(1,1,1)
    t.Font=Enum.Font.GothamBlack
    t.TextScaled=true
    t.Text=text
    t.Parent=gui
end

function WorldBuilder.build()
    local old=workspace:FindFirstChild("RelicWorld")
    if old then old:Destroy() end

    local world=Instance.new("Folder")
    world.Name="RelicWorld"
    world.Parent=workspace

    p(world,"Ground",Vector3.new(360,2,360),Vector3.new(0,-1,0),Color3.fromRGB(35,38,42),Enum.Material.Slate)

    local altar=p(world,"RollAltar",Vector3.new(18,3,18),Vector3.new(0,1.5,0),Color3.fromRGB(80,60,130),Enum.Material.Neon)
    sign(altar,"RELIC ALTAR")

    local prompt=Instance.new("ProximityPrompt")
    prompt.Name="RollPrompt"
    prompt.ActionText="ROLL"
    prompt.ObjectText="Relic Altar"
    prompt.HoldDuration=0
    prompt.MaxActivationDistance=14
    prompt.Parent=altar

    for i=1,8 do
        local angle=math.rad((i-1)*45)
        local pedestal=p(world,"Pedestal"..i,Vector3.new(7,2,7),Vector3.new(math.cos(angle)*42,1,math.sin(angle)*42),Color3.fromRGB(55,58,65),Enum.Material.Marble)
        pedestal:SetAttribute("PedestalIndex",i)
    end

    local hall=p(world,"MarketHall",Vector3.new(90,2,50),Vector3.new(0,1,-95),Color3.fromRGB(48,48,55),Enum.Material.Concrete)
    sign(hall,"PLAYER MARKET")

    for i=1,10 do
        local x=-36+((i-1)%5)*18
        local z=-88-math.floor((i-1)/5)*18
        local booth=p(world,"MarketBooth"..i,Vector3.new(12,4,10),Vector3.new(x,2,z),Color3.fromRGB(70,72,82),Enum.Material.Metal)
        booth:SetAttribute("MarketBooth",i)
    end

    local spawn=Instance.new("SpawnLocation")
    spawn.Name="Spawn"
    spawn.Size=Vector3.new(10,1,10)
    spawn.Position=Vector3.new(0,1,70)
    spawn.Anchored=true
    spawn.Neutral=true
    spawn.Parent=world

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
    model:PivotTo(CFrame.new(0,8,0))

    task.delay(4,function()
        if holder.Parent then holder:Destroy() end
    end)
end

return WorldBuilder
