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
        Secret = Color3.fromRGB(40,40,55),
        Apex = Color3.fromRGB(235,235,255),
    }
    return map[tier] or Color3.new(1,1,1)
end

function RelicModelBuilder.build(item)
    local m = Instance.new("Model")
    m.Name = item.relicName

    local color = tierColor(item.tier)
    local base = part(m, "Core", Vector3.new(2.2,2.2,2.2), CFrame.new(), color, Enum.Material.Neon, Enum.PartType.Ball)

    if item.relicName:find("Crown") then
        base.Size = Vector3.new(2.8,1.1,2.8)
        for i=-1,1 do
            part(m, "Spike", Vector3.new(0.35,1.8,0.35), CFrame.new(i*0.8,1.2,0), color, Enum.Material.Neon)
        end
    elseif item.relicName:find("Halo") then
        base.Shape = Enum.PartType.Cylinder
        base.Size = Vector3.new(0.35,4,4)
        base.CFrame = CFrame.Angles(0,0,math.rad(90))
    elseif item.relicName:find("Key") then
        base.Size = Vector3.new(0.7,3.4,0.7)
        part(m, "Teeth", Vector3.new(1.6,0.4,0.7), CFrame.new(0,-1.3,0), color, Enum.Material.Neon)
    elseif item.relicName:find("Fragment") then
        base.Size = Vector3.new(1.4,3.6,1.2)
        base.Orientation = Vector3.new(20,15,35)
    end

    if item.mutationName ~= "Normal" then
        local light = Instance.new("PointLight")
        light.Range = 12
        light.Brightness = math.min(5, 1 + math.log10(item.mutationOneIn or 1))
        light.Color = color
        light.Parent = base

        local particles = Instance.new("ParticleEmitter")
        particles.Rate = math.clamp(math.log10(item.mutationOneIn or 1) * 4, 4, 30)
        particles.Lifetime = NumberRange.new(0.7,1.4)
        particles.Speed = NumberRange.new(0.4,1.2)
        particles.Parent = base
    end

    m.PrimaryPart = base
    return m
end

return RelicModelBuilder
