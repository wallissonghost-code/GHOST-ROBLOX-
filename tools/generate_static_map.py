import json, math

WORLD = 16384
HALF = WORLD // 2
LAND_TILE = 512
WATER_TILE = 1024
LAND_RADIUS = 7600


def part(size, pos, material="Grass", color=(0.3, 0.45, 0.22), collide=True, transparency=0, cls="Part", shape=None):
    props = {
        "Anchored": True,
        "CanCollide": collide,
        "CanTouch": collide,
        "CanQuery": True,
        "Size": list(size),
        "Position": list(pos),
        "Material": material,
        "Color": list(color),
        "Transparency": transparency,
        "TopSurface": "Smooth",
        "BottomSurface": "Smooth",
    }
    if shape:
        props["Shape"] = shape
    return {"$className": cls, "$properties": props}


def land_profile(x, z):
    d = math.sqrt(x*x + z*z)
    edge = max(0.0, min(1.0, (LAND_RADIUS - d) / 1400.0))
    wave = math.sin(x / 930.0) * 13 + math.cos(z / 1170.0) * 10 + math.sin((x+z)/1550.0) * 7
    base = 24 + edge * 34 + wave

    # Regional shaping.
    if x > 2500 and z > 1800:  # mountains
        base += 55 + 35 * math.sin(x/420.0) + 25 * math.cos(z/510.0)
    elif x > 2600 and z < -1800:  # desert mesas
        base += 12 + 12 * math.sin(x/700.0)
    elif x < -2600 and z < -1600:  # forest hills
        base += 25 + 18 * math.sin(z/650.0)
    elif x < -3000 and z > 1800:  # harbor coast lowlands
        base -= 8
    elif abs(x) < 2300 and abs(z) < 2300:  # city basin
        base = 34
    elif abs(x) < 2200 and z < -4300:  # airport plateau
        base = 30
    elif abs(x) < 2300 and z > 4300:  # industrial plateau
        base = 36
    return max(8, base)


def biome(x, z):
    if abs(x) < 2300 and abs(z) < 2300:
        return "Concrete", (0.34, 0.36, 0.37), "CAPITAL"
    if abs(x) < 2200 and z < -4200:
        return "Concrete", (0.25, 0.27, 0.29), "AIRPORT"
    if x < -2500 and z < -1300:
        return "Grass", (0.13, 0.31, 0.12), "FOREST"
    if x > 2500 and z < -1300:
        return "Sand", (0.72, 0.53, 0.29), "DESERT"
    if x > 2500 and z > 1300:
        return "Slate", (0.28, 0.30, 0.31), "MOUNTAINS"
    if x < -3300 and z > 1400:
        return "Grass", (0.24, 0.39, 0.20), "HARBOR"
    if abs(x) < 2300 and z > 4200:
        return "Concrete", (0.34, 0.31, 0.27), "INDUSTRIAL"
    if x < -2600 and z > 4300:
        return "Grass", (0.22, 0.38, 0.18), "PLAYER_BASES"
    return "Grass", (0.28, 0.45, 0.22), "WILDERNESS"


workspace = {"$properties": {"FallenPartsDestroyHeight": -600}}

# Ocean baked beneath and around the island.
wi = 0
for x in range(-HALF + WATER_TILE//2, HALF, WATER_TILE):
    for z in range(-HALF + WATER_TILE//2, HALF, WATER_TILE):
        wi += 1
        workspace[f"OCEAN_{wi}"] = part(
            (WATER_TILE, 20, WATER_TILE), (x, -10, z), "Glass", (0.05, 0.35, 0.58), False, 0.18
        )

# Organic continent made from many medium tiles at varying height.
li = 0
for x in range(-HALF + LAND_TILE//2, HALF, LAND_TILE):
    for z in range(-HALF + LAND_TILE//2, HALF, LAND_TILE):
        d = math.sqrt(x*x + z*z)
        coast_noise = 260*math.sin(z/700.0) + 180*math.cos(x/930.0) + 120*math.sin((x-z)/510.0)
        if d > LAND_RADIUS + coast_noise:
            continue
        h = land_profile(x, z)
        material, color, name = biome(x, z)
        li += 1
        workspace[f"LAND_{li}_{name}"] = part((LAND_TILE+4, h, LAND_TILE+4), (x, h/2, z), material, color)

# Central city plaza and radial safe spawn district.
workspace["CAPITAL_PLAZA"] = part((1100, 10, 1100), (0, 40, 0), "Concrete", (0.50, 0.52, 0.54))
workspace["CAPITAL_GREEN"] = part((420, 12, 420), (0, 46, 0), "Grass", (0.18, 0.42, 0.18))

# Main cross-country highways.
for i, z in enumerate(range(-6656, 6657, 512)):
    if abs(z) < 7600:
        y = land_profile(0, z) + 2
        workspace[f"HW_NS_{i}"] = part((120, 4, 520), (0, y, z), "Concrete", (0.07,0.075,0.08))
for i, x in enumerate(range(-6656, 6657, 512)):
    if abs(x) < 7600:
        y = land_profile(x, 0) + 2
        workspace[f"HW_EW_{i}"] = part((520, 4, 120), (x, y, 0), "Concrete", (0.07,0.075,0.08))

# City street grid with blocks kept away from spawn.
city_roads = (-1800,-1350,-900,-450,450,900,1350,1800)
for i, x in enumerate(city_roads):
    workspace[f"CITY_V_{i}"] = part((80,4,4000),(x,38,0),"Concrete",(0.065,0.07,0.075))
for i, z in enumerate(city_roads):
    workspace[f"CITY_H_{i}"] = part((4000,4,80),(0,38,z),"Concrete",(0.065,0.07,0.075))

# Skyline: varied towers, deliberately outside safe central square.
bi = 0
for x in (-1650,-1200,-750,750,1200,1650):
    for z in (-1650,-1200,-750,750,1200,1650):
        bi += 1
        h = 120 + ((bi*73) % 260)
        w = 210 + ((bi*31) % 120)
        base_y = 34
        workspace[f"CITY_BUILDING_{bi}"] = part((w,h,w),(x,base_y+h/2,z),"Concrete",(0.38+0.02*(bi%3),0.41,0.44))
        workspace[f"CITY_ROOF_{bi}"] = part((w+14,8,w+14),(x,base_y+h+4,z),"Metal",(0.13,0.15,0.17))
        # window strips
        for f in range(1, max(2,int(h//70))):
            wy = base_y + f*65
            workspace[f"CITY_WIN_{bi}_{f}"] = part((w+4,8,w+4),(x,wy,z),"Neon",(0.10,0.32,0.48),False,0.15)

# Airport plateau: long runway, taxiways and terminals.
air_y = 34
workspace["AIRPORT_RUNWAY"] = part((300,5,3300),(0,air_y,-5600),"Concrete",(0.045,0.05,0.055))
workspace["AIRPORT_TAXI_W"] = part((140,4,2800),(-650,air_y,-5600),"Concrete",(0.11,0.115,0.12))
workspace["AIRPORT_TAXI_E"] = part((140,4,2800),(650,air_y,-5600),"Concrete",(0.11,0.115,0.12))
for i,z in enumerate(range(-7000,-4199,300)):
    workspace[f"RUNWAY_MARK_{i}"] = part((18,6,120),(0,air_y+4,z),"Neon",(0.95,0.95,0.86),False)
for i,x in enumerate((-1500,-1050,1050,1500)):
    workspace[f"AIR_HANGAR_{i}"] = part((360,170,480),(x,air_y+85,-5200),"Metal",(0.29,0.32,0.34))
workspace["AIR_TERMINAL"] = part((900,160,360),(0,air_y+80,-4100),"Concrete",(0.42,0.45,0.47))

# Forest: denser trees and small clearings.
for i in range(150):
    x = -6900 + (i*619) % 4300
    z = -6600 + (i*883) % 4900
    if math.sqrt(x*x+z*z) > 7450 or abs(x) < 2700:
        continue
    gy = land_profile(x,z)
    trunk_h = 70 + (i%5)*12
    workspace[f"TREE_TRUNK_{i}"] = part((22,trunk_h,22),(x,gy+trunk_h/2,z),"Wood",(0.24,0.13,0.06))
    workspace[f"TREE_TOP_{i}"] = part((115,115,115),(x,gy+trunk_h+40,z),"Grass",(0.07,0.25,0.07),False,0,"Part","Ball")

# Desert: mesas, boulders, dry route.
for i in range(55):
    x = 2850 + (i*743) % 4300
    z = -6700 + (i*577) % 5000
    if math.sqrt(x*x+z*z) > 7450:
        continue
    gy = land_profile(x,z)
    s = 90 + (i%5)*45
    h = 45 + (i%4)*35
    workspace[f"DESERT_ROCK_{i}"] = part((s,h,s*0.85),(x,gy+h/2,z),"Sand",(0.58,0.34,0.18))

# Mountain region: layered rocky peaks.
for i in range(48):
    x = 2850 + (i*641) % 4300
    z = 1900 + (i*829) % 5000
    if math.sqrt(x*x+z*z) > 7450:
        continue
    gy = land_profile(x,z)
    h = 180 + (i%7)*95
    s = 170 + (i%4)*90
    workspace[f"PEAK_{i}"] = part((s,h,s),(x,gy+h/2,z),"Slate",(0.20,0.22,0.23))
    workspace[f"PEAK_CAP_{i}"] = part((s*0.7,h*0.22,s*0.7),(x,gy+h*0.93,z),"Concrete",(0.66,0.67,0.67),False)

# Harbor: water inlet, piers, warehouses and container yard.
harbor_y = 18
workspace["HARBOR_BASIN"] = part((2600,24,2600),(-5850,6,3350),"Glass",(0.03,0.32,0.56),False,0.12)
for i,z in enumerate((2400,2900,3400,3900,4400)):
    workspace[f"PIER_{i}"] = part((1250,18,110),(-5200,harbor_y,z),"Wood",(0.27,0.17,0.09))
for i,z in enumerate((2450,3350,4250)):
    workspace[f"PORT_WH_{i}"] = part((620,160,420),(-6900,harbor_y+80,z),"Metal",(0.28,0.31,0.32))
for i in range(24):
    x = -6400 + (i%6)*150
    z = 4800 + (i//6)*120
    workspace[f"CONTAINER_{i}"] = part((120,90,70),(x,65,z),"Metal",(0.25+0.08*(i%3),0.20+0.05*((i+1)%3),0.18+0.07*((i+2)%3)))

# Industrial district.
for i,x in enumerate((-1650,-850,0,850,1650)):
    workspace[f"FACTORY_{i}"] = part((560,210,650),(x,36+105,5650),"Metal",(0.30,0.30,0.28))
    workspace[f"STACK_{i}"] = part((70,380,70),(x+190,36+190,5250),"Brick",(0.26,0.24,0.22))

# Player base territory: 12 large flat lots separated from the city.
plot = 0
for z in (5000,5800,6600):
    for x in (-6750,-5750,-4750,-3750):
        if math.sqrt(x*x+z*z) > 7450:
            continue
        plot += 1
        gy = land_profile(x,z)
        workspace[f"BASE_PLOT_{plot}"] = part((820,8,620),(x,gy+4,z),"Concrete",(0.27,0.29,0.28))
        workspace[f"BASE_MARK_{plot}"] = part((70,5,70),(x,gy+10,z),"Neon",(0.08,0.78,0.30),False)

# Spawn is baked into the safe central park.
workspace["STATIC_SPAWN"] = {"$className":"SpawnLocation","$properties":{
    "Anchored":True,
    "Neutral":True,
    "CanCollide":True,
    "Size":[44,2,44],
    "Position":[0,55,0],
    "Material":"Neon",
    "Color":[0.12,0.90,0.35]
}}

project = {
    "name":"GhostOpenWorldOrganic16K",
    "tree":{
        "$className":"DataModel",
        "Workspace":workspace
    }
}

print(json.dumps(project,separators=(",",":")))
