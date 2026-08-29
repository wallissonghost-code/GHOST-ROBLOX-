local RelicModelBuilder = {}

local function part(parent, name, size, cframe, color, material, shape)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cframe
    p.Color = color
    p.Material = material or Enum.Material.Metal
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = true
    if shape then p.Shape = shape end
    p.Parent = parent
    return p
end

local function tierColor(tier)
    local map = {
        Common = Color3.fromRGB(170,170,170),
        Uncommon = Color3.fromRGB(75,200,110),
        Rare = Color3.fromRGB(70,120,235),
        Epic = Color3.fromRGB(170,80,230),
        Legendary = Color3.fromRGB(240,155,40),
        Mythic = Color3.fromRGB(235,65,110),
        Divine = Color3.fromRGB(255,235,120),
        Secret = Color3.fromRGB(45,45,60),
        Apex = Color3.fromRGB(235,235,255),
    }
    return map[tier] or Color3.new(1,1,1)
end

local function addMutationFx(model, anchor, item, color)
    if item.mutationName == "Normal" then return end
    local light = Instance.new("PointLight")
    light.Range = 14
    light.Brightness = math.min(4.5, 1 + math.log10(item.mutationOneIn or 1))
    light.Color = color
    light.Parent = anchor

    local particles = Instance.new("ParticleEmitter")
    particles.Rate = math.clamp(math.log10(item.mutationOneIn or 1) * 3, 4, 22)
    particles.Lifetime = NumberRange.new(0.6,1.2)
    particles.Speed = NumberRange.new(0.3,0.9)
    particles.SpreadAngle = Vector2.new(180,180)
    particles.Parent = anchor
end

function RelicModelBuilder.build(item)
    local m = Instance.new("Model")
    m.Name = item.relicName
    local color = tierColor(item.tier)
    local id = item.relicId or ""
    local anchor

    if id == "rust_ring" then
        anchor = part(m,"Ring",Vector3.new(0.55,4.8,4.8),CFrame.Angles(0,0,math.rad(90)),Color3.fromRGB(128,78,42),Enum.Material.Metal,Enum.PartType.Cylinder)
        part(m,"Inset",Vector3.new(0.65,2.6,2.6),CFrame.new(0,0,0)*CFrame.Angles(0,0,math.rad(90)),Color3.fromRGB(55,55,60),Enum.Material.SmoothPlastic,Enum.PartType.Cylinder)
    elseif id == "old_coin" then
        anchor = part(m,"Coin",Vector3.new(0.65,5.2,5.2),CFrame.Angles(0,0,math.rad(90)),Color3.fromRGB(185,145,65),Enum.Material.Metal,Enum.PartType.Cylinder)
        part(m,"Center",Vector3.new(0.72,2.3,2.3),CFrame.Angles(0,0,math.rad(90)),Color3.fromRGB(220,185,90),Enum.Material.Metal,Enum.PartType.Cylinder)
    elseif id == "broken_idol" or id == "blood_idol" then
        local idolColor = id == "blood_idol" and Color3.fromRGB(130,20,30) or color
        anchor = part(m,"Body",Vector3.new(2.7,4.7,2.2),CFrame.new(),idolColor,Enum.Material.Slate)
        part(m,"Head",Vector3.new(2.1,2.1,2.1),CFrame.new(0,3.2,0),idolColor,Enum.Material.Slate,Enum.PartType.Ball)
        part(m,"Base",Vector3.new(4.3,0.7,3.4),CFrame.new(0,-2.7,0),idolColor,Enum.Material.Rock)
        part(m,"HornL",Vector3.new(0.45,2.2,0.45),CFrame.new(-1.1,4.4,0)*CFrame.Angles(0,0,math.rad(-25)),idolColor,Enum.Material.Slate)
        part(m,"HornR",Vector3.new(0.45,2.2,0.45),CFrame.new(1.1,4.4,0)*CFrame.Angles(0,0,math.rad(25)),idolColor,Enum.Material.Slate)
    elseif id == "silver_eye" then
        anchor = part(m,"Eye",Vector3.new(5.3,2.8,1.15),CFrame.new(),Color3.fromRGB(205,215,225),Enum.Material.Metal)
        part(m,"Iris",Vector3.new(1.5,1.5,1.3),CFrame.new(0,0,-0.45),Color3.fromRGB(70,170,255),Enum.Material.Neon,Enum.PartType.Ball)
        part(m,"Pupil",Vector3.new(0.55,0.55,1.45),CFrame.new(0,0,-0.7),Color3.fromRGB(15,15,20),Enum.Material.SmoothPlastic,Enum.PartType.Ball)
    elseif id == "amber_mask" then
        anchor = part(m,"Mask",Vector3.new(4.5,5.7,0.75),CFrame.new(),Color3.fromRGB(214,140,45),Enum.Material.Metal)
        part(m,"Forehead",Vector3.new(3.2,1.4,0.9),CFrame.new(0,2.1,-0.15),Color3.fromRGB(245,176,68),Enum.Material.Neon)
        part(m,"EyeL",Vector3.new(0.95,0.65,1.05),CFrame.new(-1.1,0.8,-0.25),Color3.fromRGB(30,20,15),Enum.Material.SmoothPlastic)
        part(m,"EyeR",Vector3.new(0.95,0.65,1.05),CFrame.new(1.1,0.8,-0.25),Color3.fromRGB(30,20,15),Enum.Material.SmoothPlastic)
        part(m,"Jaw",Vector3.new(2.6,1.3,0.95),CFrame.new(0,-2.1,-0.1),Color3.fromRGB(180,105,30),Enum.Material.Metal)
    elseif id == "moon_charm" then
        anchor = part(m,"Moon",Vector3.new(0.7,4.9,4.9),CFrame.Angles(0,0,math.rad(90)),Color3.fromRGB(175,195,255),Enum.Material.Neon,Enum.PartType.Cylinder)
        part(m,"Cutout",Vector3.new(0.8,3.5,3.5),CFrame.new(0,0.9,0)*CFrame.Angles(0,0,math.rad(90)),Color3.fromRGB(45,45,65),Enum.Material.SmoothPlastic,Enum.PartType.Cylinder)
        part(m,"Chain",Vector3.new(0.45,2.2,0.45),CFrame.new(0,3.3,0),Color3.fromRGB(210,210,220),Enum.Material.Metal)
    elseif id == "void_crown" then
        anchor = part(m,"Band",Vector3.new(5.8,1.35,5.2),CFrame.new(),Color3.fromRGB(35,25,55),Enum.Material.Metal)
        for i=-2,2 do
            local h = 2.4 + (2-math.abs(i))*0.65
            part(m,"Spike"..i,Vector3.new(0.65,h,0.65),CFrame.new(i*1.05,1.55+h/2,0),Color3.fromRGB(120,55,220),Enum.Material.Neon)
        end
    elseif id == "angel_core" then
        anchor = part(m,"Core",Vector3.new(3.8,3.8,3.8),CFrame.new(),Color3.fromRGB(235,245,255),Enum.Material.Neon,Enum.PartType.Ball)
        part(m,"WingL",Vector3.new(3.7,1.0,2.4),CFrame.new(-3.1,0.5,0)*CFrame.Angles(0,0,math.rad(25)),Color3.fromRGB(245,245,255),Enum.Material.SmoothPlastic)
        part(m,"WingR",Vector3.new(3.7,1.0,2.4),CFrame.new(3.1,0.5,0)*CFrame.Angles(0,0,math.rad(-25)),Color3.fromRGB(245,245,255),Enum.Material.SmoothPlastic)
    elseif id == "black_halo" then
        anchor = part(m,"Halo",Vector3.new(0.55,6.0,6.0),CFrame.Angles(0,0,math.rad(90)),Color3.fromRGB(35,20,55),Enum.Material.Neon,Enum.PartType.Cylinder)
        part(m,"Inner",Vector3.new(0.7,3.5,3.5),CFrame.Angles(0,0,math.rad(90)),Color3.fromRGB(18,18,22),Enum.Material.SmoothPlastic,Enum.PartType.Cylinder)
    elseif id == "reality_key" then
        anchor = part(m,"Shaft",Vector3.new(0.8,5.8,0.8),CFrame.new(),Color3.fromRGB(245,225,120),Enum.Material.Metal)
        part(m,"Bow",Vector3.new(0.8,3.2,3.2),CFrame.new(0,3.5,0)*CFrame.Angles(0,0,math.rad(90)),Color3.fromRGB(245,225,120),Enum.Material.Neon,Enum.PartType.Cylinder)
        part(m,"Teeth",Vector3.new(3.1,0.8,0.8),CFrame.new(1.1,-2.3,0),Color3.fromRGB(245,225,120),Enum.Material.Metal)
    elseif id == "zero_relic" then
        anchor = part(m,"ZeroCore",Vector3.new(4.8,4.8,4.8),CFrame.Angles(math.rad(25),math.rad(35),0),Color3.fromRGB(15,15,20),Enum.Material.Glass)
        part(m,"InnerCore",Vector3.new(2.7,2.7,2.7),CFrame.new(),Color3.fromRGB(120,20,180),Enum.Material.Neon,Enum.PartType.Ball)
    elseif id == "origin_fragment" then
        anchor = part(m,"Shard",Vector3.new(2.3,6.2,2.1),CFrame.Angles(math.rad(18),math.rad(25),math.rad(16)),Color3.fromRGB(225,235,255),Enum.Material.Glass)
        part(m,"Shard2",Vector3.new(1.2,4.0,1.2),CFrame.new(2.0,-0.8,0.6)*CFrame.Angles(math.rad(-10),0,math.rad(-18)),Color3.fromRGB(150,210,255),Enum.Material.Neon)
    else
        anchor = part(m,"Core",Vector3.new(4,4,4),CFrame.new(),color,Enum.Material.Neon,Enum.PartType.Ball)
    end

    m.PrimaryPart = anchor
    addMutationFx(m, anchor, item, color)
    return m
end

return RelicModelBuilder
