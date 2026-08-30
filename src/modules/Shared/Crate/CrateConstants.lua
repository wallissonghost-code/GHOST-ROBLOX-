local function relic(name, color, tier, weight)
	return table.freeze({
		Name = name,
		Color = color,
		Tier = tier,
		Weight = weight,
	})
end

return table.freeze({
	relic("Rusty Compass", Color3.fromRGB(145, 108, 74), 1, 240),
	relic("Old Coin", Color3.fromRGB(170, 145, 76), 1, 220),
	relic("Broken Idol", Color3.fromRGB(112, 108, 101), 1, 185),
	relic("Ancient Key", Color3.fromRGB(160, 130, 77), 1, 150),
	relic("Moon Stone", Color3.fromRGB(163, 173, 195), 1, 120),

	relic("Amber Mask", Color3.fromRGB(230, 139, 54), 2, 65),
	relic("Silver Eye", Color3.fromRGB(145, 181, 212), 2, 48),
	relic("Runic Skull", Color3.fromRGB(93, 139, 179), 2, 35),
	relic("Frozen Sigil", Color3.fromRGB(85, 203, 240), 2, 25),
	relic("Blood Charm", Color3.fromRGB(190, 50, 69), 2, 18),

	relic("Void Crown", Color3.fromRGB(120, 65, 202), 3, 8),
	relic("Angel Core", Color3.fromRGB(242, 224, 151), 3, 5),
	relic("Glitched Cube", Color3.fromRGB(223, 67, 242), 3, 3),
	relic("Celestial Orb", Color3.fromRGB(94, 226, 255), 3, 2),

	relic("Reality Key", Color3.fromRGB(255, 190, 50), 4, 0.8),
	relic("Black Halo", Color3.fromRGB(80, 50, 110), 4, 0.35),
	relic("Origin Fragment", Color3.fromRGB(255, 236, 138), 4, 0.12),
	relic("Zero Relic", Color3.fromRGB(235, 245, 255), 4, 0.04),
})
