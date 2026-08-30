local function relic(name, color, tier, weight, oneIn, visual)
	return table.freeze({
		Name = name,
		Color = color,
		Tier = tier,
		Weight = weight,
		OneIn = oneIn,
		Visual = visual,
	})
end

return table.freeze({
	relic("Rusty Compass", Color3.fromRGB(145,108,74), 1, 240, 5, "compass"),
	relic("Old Coin", Color3.fromRGB(190,157,67), 1, 220, 5, "coin"),
	relic("Broken Idol", Color3.fromRGB(112,108,101), 1, 185, 6, "idol"),
	relic("Ancient Key", Color3.fromRGB(160,130,77), 1, 150, 8, "key"),
	relic("Moon Stone", Color3.fromRGB(163,173,195), 1, 120, 9, "stone"),

	relic("Amber Mask", Color3.fromRGB(230,139,54), 2, 65, 17, "mask"),
	relic("Silver Eye", Color3.fromRGB(145,181,212), 2, 48, 23, "eye"),
	relic("Runic Skull", Color3.fromRGB(93,139,179), 2, 35, 32, "skull"),
	relic("Frozen Sigil", Color3.fromRGB(85,203,240), 2, 25, 45, "sigil"),
	relic("Blood Charm", Color3.fromRGB(190,50,69), 2, 18, 63, "charm"),

	relic("Void Crown", Color3.fromRGB(120,65,202), 3, 8, 141, "crown"),
	relic("Angel Core", Color3.fromRGB(242,224,151), 3, 5, 225, "core"),
	relic("Glitched Cube", Color3.fromRGB(223,67,242), 3, 3, 375, "cube"),
	relic("Celestial Orb", Color3.fromRGB(94,226,255), 3, 2, 563, "orb"),

	relic("Reality Key", Color3.fromRGB(255,190,50), 4, 0.8, 1407, "key"),
	relic("Black Halo", Color3.fromRGB(80,50,110), 4, 0.35, 3215, "halo"),
	relic("Origin Fragment", Color3.fromRGB(255,236,138), 4, 0.12, 9378, "fragment"),
	relic("Zero Relic", Color3.fromRGB(235,245,255), 4, 0.04, 28133, "orb"),
})
