local Config = {}

-- CI deploy marker: gameplay values below are unchanged.
Config.START_COINS = 1000
Config.BASE_INVENTORY_SLOTS = 50
Config.MARKET_FEE = 0.08
Config.BASE_ROLL_COOLDOWN = 0.90
Config.QUICK_ROLL_COOLDOWN = 0.30
Config.PITY_START = 25
Config.PITY_STEP = 0.035
Config.PITY_CAP = 2.5
Config.MAX_MARKET_LISTINGS_PER_PLAYER = 10

Config.LUCK_UPGRADES = {
    { level = 1, cost = 5_000, multiplier = 1.25 },
    { level = 2, cost = 25_000, multiplier = 1.60 },
    { level = 3, cost = 125_000, multiplier = 2.10 },
    { level = 4, cost = 600_000, multiplier = 2.90 },
    { level = 5, cost = 2_500_000, multiplier = 4.00 },
    { level = 6, cost = 12_000_000, multiplier = 5.50 },
}

Config.RELICS = {
    { id="rust_ring", name="Rust Ring", oneIn=2, baseValue=25, tier="Common", shape="Ring" },
    { id="old_coin", name="Old Coin", oneIn=5, baseValue=50, tier="Common", shape="Coin" },
    { id="broken_idol", name="Broken Idol", oneIn=12, baseValue=90, tier="Uncommon", shape="Idol" },
    { id="silver_eye", name="Silver Eye", oneIn=35, baseValue=220, tier="Uncommon", shape="Eye" },
    { id="amber_mask", name="Amber Mask", oneIn=150, baseValue=900, tier="Rare", shape="Mask" },
    { id="moon_charm", name="Moon Charm", oneIn=900, baseValue=4_000, tier="Epic", shape="Charm" },
    { id="blood_idol", name="Blood Idol", oneIn=5_500, baseValue=18_000, tier="Epic", shape="Idol" },
    { id="void_crown", name="Void Crown", oneIn=30_000, baseValue=110_000, tier="Legendary", shape="Crown" },
    { id="angel_core", name="Angel Core", oneIn=200_000, baseValue=650_000, tier="Mythic", shape="Core" },
    { id="black_halo", name="Black Halo", oneIn=1_500_000, baseValue=3_500_000, tier="Mythic", shape="Halo" },
    { id="reality_key", name="Reality Key", oneIn=10_000_000, baseValue=25_000_000, tier="Divine", shape="Key" },
    { id="zero_relic", name="Zero Relic", oneIn=75_000_000, baseValue=250_000_000, tier="Secret", shape="Core" },
    { id="origin_fragment", name="Origin Fragment", oneIn=500_000_000, baseValue=1_500_000_000, tier="Apex", shape="Shard" },
}

Config.MUTATIONS = {
    { id="none", name="Normal", oneIn=1, valueMult=1.0 },
    { id="shiny", name="Shiny", oneIn=30, valueMult=2.0 },
    { id="corrupted", name="Corrupted", oneIn=150, valueMult=5.0 },
    { id="glitched", name="Glitched", oneIn=900, valueMult=12.0 },
    { id="celestial", name="Celestial", oneIn=7_500, valueMult=40.0 },
    { id="singularity", name="Singularity", oneIn=60_000, valueMult=180.0 },
}

Config.BIOMES = {
    { id="normal", name="Normal", duration=180, luckMult=1.0, mutationMult=1.0, clock=14, brightness=2.0 },
    { id="blood_moon", name="Blood Moon", duration=90, luckMult=1.35, mutationMult=1.25, clock=0, brightness=0.8 },
    { id="void_storm", name="Void Storm", duration=75, luckMult=1.80, mutationMult=1.50, clock=22, brightness=0.55 },
    { id="celestial_rift", name="Celestial Rift", duration=60, luckMult=2.50, mutationMult=2.00, clock=6, brightness=2.6 },
}

Config.BIOME_WEIGHTS = { normal = 70, blood_moon = 20, void_storm = 8, celestial_rift = 2 }

return Config
