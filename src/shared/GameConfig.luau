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

    VEHICLES = {
        Jeep = {cost = 0, maxSpeed = 75, color = Color3.fromRGB(55, 76, 52)},
        Pursuit = {cost = 7000, maxSpeed = 105, color = Color3.fromRGB(32, 34, 38)},
        Armored = {cost = 25000, maxSpeed = 62, color = Color3.fromRGB(65, 72, 61)},
        Helicopter = {cost = 50000, maxSpeed = 85, color = Color3.fromRGB(62, 70, 67)},
    },

    BASE_POSITIONS = {
        Vector3.new(-175, 0, -125),
        Vector3.new(175, 0, -125),
        Vector3.new(-175, 0, 125),
        Vector3.new(175, 0, 125),
    },
}
