local Builder = {}

local function part(model, name, size, color, cframe, shape, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.CFrame = cframe or CFrame.new()
	p.Shape = shape or Enum.PartType.Block
	p.Material = material or Enum.Material.Metal
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = true
	p.Parent = model
	return p
end

local function wedge(model, name, size, color, cframe, material)
	local p = Instance.new("WedgePart")
	p.Name = name
	p.Size = size
	p.Color = color
	p.CFrame = cframe or CFrame.new()
	p.Material = material or Enum.Material.Metal
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Parent = model
	return p
end

local function darken(c, f)
	return Color3.new(c.R * f, c.G * f, c.B * f)
end

local function ring(model, color, radius, count)
	for i = 1, count do
		local a = (i / count) * math.pi * 2
		part(model, "Ring", Vector3.new(0.34, 0.34, 0.34), color, CFrame.new(math.cos(a) * radius, math.sin(a) * radius, 0), Enum.PartType.Ball, Enum.Material.Metal)
	end
end

function Builder.Build(entry, parent)
	local model = Instance.new("Model")
	model.Name = entry.Name
	model.Parent = parent
	local c = entry.Color
	local d = darken(c, 0.42)
	local visual = entry.Visual or "orb"
	local root

	if visual == "compass" then
		ring(model, c, 1.25, 14)
		root = part(model, "Center", Vector3.new(0.6,0.6,0.35), d, CFrame.new(), Enum.PartType.Cylinder)
		wedge(model, "NeedleA", Vector3.new(0.32,1.55,0.22), Color3.fromRGB(235,75,75), CFrame.new(0,0.45,-0.28))
		wedge(model, "NeedleB", Vector3.new(0.32,1.35,0.22), Color3.fromRGB(220,220,220), CFrame.new(0,-0.4,-0.28) * CFrame.Angles(0,0,math.pi))
	elseif visual == "coin" then
		root = part(model, "Coin", Vector3.new(0.42,2.55,2.55), c, CFrame.Angles(0,0,math.rad(90)), Enum.PartType.Cylinder, Enum.Material.Metal)
		part(model, "Stamp", Vector3.new(0.16,1.1,1.1), d, CFrame.new(-0.28,0,0) * CFrame.Angles(0,0,math.rad(90)), Enum.PartType.Cylinder)
	elseif visual == "idol" then
		root = part(model, "Body", Vector3.new(1.45,1.9,0.85), c, CFrame.new(0,-0.35,0))
		part(model, "Head", Vector3.new(1.15,1.15,1.0), c, CFrame.new(0,1.15,0), Enum.PartType.Ball)
		part(model, "Base", Vector3.new(2.1,0.35,1.35), d, CFrame.new(0,-1.45,0))
	elseif visual == "key" then
		root = part(model, "Shaft", Vector3.new(0.45,2.7,0.45), c, CFrame.new(0,-0.1,0))
		ring(model, c, 0.72, 10)
		for _, p in model:GetChildren() do if p.Name == "Ring" then p.CFrame = p.CFrame + Vector3.new(0,1.75,0) end end
		part(model, "ToothA", Vector3.new(0.9,0.35,0.45), d, CFrame.new(0.42,-1.35,0))
		part(model, "ToothB", Vector3.new(0.65,0.35,0.45), d, CFrame.new(0.3,-0.9,0))
	elseif visual == "stone" then
		root = part(model, "Stone", Vector3.new(2.25,2.25,2.25), c, CFrame.new(), Enum.PartType.Ball, Enum.Material.Slate)
		part(model, "Glow", Vector3.new(0.8,0.8,0.8), Color3.new(1,1,1), CFrame.new(0.6,0.5,-0.8), Enum.PartType.Ball, Enum.Material.Neon)
	elseif visual == "mask" then
		root = part(model, "Mask", Vector3.new(2.05,2.55,0.48), c, CFrame.new(), Enum.PartType.Block, Enum.Material.SmoothPlastic)
		part(model, "EyeL", Vector3.new(0.5,0.28,0.2), Color3.new(0,0,0), CFrame.new(-0.55,0.4,-0.35))
		part(model, "EyeR", Vector3.new(0.5,0.28,0.2), Color3.new(0,0,0), CFrame.new(0.55,0.4,-0.35))
		wedge(model, "HornL", Vector3.new(0.5,1.3,0.5), d, CFrame.new(-0.8,1.7,0) * CFrame.Angles(0,0,math.rad(-18)))
		wedge(model, "HornR", Vector3.new(0.5,1.3,0.5), d, CFrame.new(0.8,1.7,0) * CFrame.Angles(0,math.pi,math.rad(18)))
	elseif visual == "eye" then
		root = part(model, "Eye", Vector3.new(2.55,1.65,1.2), c, CFrame.new(), Enum.PartType.Ball, Enum.Material.SmoothPlastic)
		part(model, "Iris", Vector3.new(0.85,0.85,0.35), Color3.fromRGB(70,130,255), CFrame.new(0,0,-0.7), Enum.PartType.Ball, Enum.Material.Neon)
		part(model, "Pupil", Vector3.new(0.36,0.36,0.22), Color3.new(0,0,0), CFrame.new(0,0,-0.92), Enum.PartType.Ball)
	elseif visual == "skull" then
		root = part(model, "Skull", Vector3.new(2.0,2.0,1.65), c, CFrame.new(0,0.45,0), Enum.PartType.Ball, Enum.Material.Slate)
		part(model, "Jaw", Vector3.new(1.35,0.8,1.1), c, CFrame.new(0,-0.75,0))
		part(model, "EyeL", Vector3.new(0.48,0.55,0.25), Color3.new(0,0,0), CFrame.new(-0.48,0.6,-0.8), Enum.PartType.Ball)
		part(model, "EyeR", Vector3.new(0.48,0.55,0.25), Color3.new(0,0,0), CFrame.new(0.48,0.6,-0.8), Enum.PartType.Ball)
	elseif visual == "sigil" then
		root = part(model, "Core", Vector3.new(1.0,1.0,1.0), c, CFrame.new(), Enum.PartType.Ball, Enum.Material.Neon)
		for i=1,6 do local a=i*math.pi/3; part(model,"Rune",Vector3.new(0.34,1.4,0.34),c,CFrame.new(math.cos(a)*1.1,math.sin(a)*1.1,0)*CFrame.Angles(0,0,a),Enum.PartType.Block,Enum.Material.Neon) end
	elseif visual == "charm" then
		root = part(model, "Gem", Vector3.new(1.7,2.1,0.8), c, CFrame.new(), Enum.PartType.Ball, Enum.Material.Neon)
		ring(model, d, 0.48, 9)
		for _, p in model:GetChildren() do if p.Name == "Ring" then p.CFrame = p.CFrame + Vector3.new(0,1.5,0) end end
	elseif visual == "crown" then
		root = part(model, "Band", Vector3.new(2.8,0.7,1.4), c, CFrame.new(0,-0.7,0))
		for x=-1,1 do wedge(model,"Spike",Vector3.new(0.7,2.0,0.8),c,CFrame.new(x*0.9,0.55,0)) end
	elseif visual == "core" then
		root = part(model, "Core", Vector3.new(2.15,2.15,2.15), c, CFrame.new(), Enum.PartType.Ball, Enum.Material.Neon)
		ring(model, d, 1.55, 14)
	elseif visual == "cube" then
		root = part(model, "Cube", Vector3.new(2.4,2.4,2.4), c, CFrame.Angles(math.rad(22),math.rad(34),math.rad(12)), Enum.PartType.Block, Enum.Material.Neon)
		part(model,"Glitch",Vector3.new(2.9,0.25,0.35),Color3.fromRGB(0,255,200),CFrame.new(0,0.35,-1.25),Enum.PartType.Block,Enum.Material.Neon)
	elseif visual == "orb" then
		root = part(model, "Orb", Vector3.new(2.45,2.45,2.45), c, CFrame.new(), Enum.PartType.Ball, Enum.Material.Neon)
		ring(model, Color3.new(1,1,1), 1.55, 12)
	elseif visual == "halo" then
		ring(model, c, 1.55, 18)
		root = part(model, "Core", Vector3.new(0.3,0.3,0.3), d, CFrame.new(), Enum.PartType.Ball, Enum.Material.Neon)
	elseif visual == "fragment" then
		root = wedge(model, "Fragment", Vector3.new(2.0,3.2,1.15), c, CFrame.Angles(math.rad(12),math.rad(25),math.rad(-8)), Enum.Material.Neon)
		wedge(model, "Shard", Vector3.new(0.8,1.9,0.7), d, CFrame.new(1.0,-0.4,0.2) * CFrame.Angles(0,math.rad(20),0), Enum.Material.Neon)
	else
		root = part(model, "Relic", Vector3.new(2.2,2.2,2.2), c, CFrame.new(), Enum.PartType.Ball, Enum.Material.Neon)
	end

	model.PrimaryPart = root or model:FindFirstChildWhichIsA("BasePart")
	if model.PrimaryPart then model:PivotTo(CFrame.new()) end
	return model
end

function Builder.CreateViewport(parent, entry)
	local viewport = Instance.new("ViewportFrame")
	viewport.BackgroundTransparency = 1
	viewport.Ambient = Color3.fromRGB(180,180,190)
	viewport.LightColor = Color3.fromRGB(255,255,255)
	viewport.LightDirection = Vector3.new(-1,-1,-1)
	viewport.Parent = parent
	local world = Instance.new("WorldModel")
	world.Parent = viewport
	local model = Builder.Build(entry, world)
	local camera = Instance.new("Camera")
	camera.FieldOfView = 34
	camera.CFrame = CFrame.lookAt(Vector3.new(0,0,8.2), Vector3.new())
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	return viewport, model, camera
end

return Builder
