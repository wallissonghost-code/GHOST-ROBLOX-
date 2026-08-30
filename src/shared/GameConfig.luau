return {
    START_CASH = 5000,
    PASSIVE_INTERVAL = 5,
    BASE_INCOME = 125,
    UPGRADE_COSTS = {3000, 9000, 25000, 70000},
    UPGRADE_INCOME = {250, 500, 1000, 2200},

    HEIST_REWARD = 5500,
    HEIST_COOLDOWN = 120,
    MISSION_REWARD = 2200,
    DELIVERY_REWARD = 3000,
    CONVOY_REWARD = 4500,
    SHOP_MEDKIT_COST = 500,
    WANTED_MAX = 5,
    WANTED_DECAY_SECONDS = 40,

    WORLD_SIZE = 2400,
    VEHICLES = {
        Jeep = {cost = 0, maxSpeed = 92, color = Color3.fromRGB(55, 76, 52)},
        Pursuit = {cost = 7000, maxSpeed = 128, color = Color3.fromRGB(32, 34, 38)},
        Armored = {cost = 25000, maxSpeed = 76, color = Color3.fromRGB(65, 72, 61)},
        Helicopter = {cost = 50000, maxSpeed = 110, color = Color3.fromRGB(62, 70, 67)},
    },

    BASE_POSITIONS = {
        Vector3.new(-900, 0, -760),
        Vector3.new(-300, 0, -960),
        Vector3.new(300, 0, -960),
        Vector3.new(900, 0, -760),
        Vector3.new(-940, 0, 520),
        Vector3.new(-360, 0, 930),
        Vector3.new(360, 0, 930),
        Vector3.new(940, 0, 520),
    },
}
