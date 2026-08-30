local function tier(name, color)
	return table.freeze({ Name = name, Color = color })
end

return table.freeze({
	[1] = tier("Common", Color3.fromRGB(195, 198, 205)),
	[2] = tier("Rare", Color3.fromRGB(87, 157, 255)),
	[3] = tier("Epic", Color3.fromRGB(201, 92, 255)),
	[4] = tier("Legendary", Color3.fromRGB(255, 201, 64)),
})
