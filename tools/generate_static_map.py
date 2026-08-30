import json, math

WORLD = 16384
TILE = 1024
HALF = WORLD // 2

REGIONS = [
    ("CapitalCity", (0, 0), (4096, 4096), "Concrete", (0.34, 0.36, 0.38)),
    ("Airport", (0, -5632), (4096, 3072), "Concrete", (0.20, 0.21, 0.22)),
    ("Forest", (-4608, -4096), (5120, 5120), "Grass", (0.16, 0.36, 0.14)),
    ("Desert", (4864, -4096), (4864, 5120), "Sand", (0.72, 0.53, 0.28)),
    ("Mountains", (4864, 4352), (4864, 4608), "Slate", (0.28, 0.30, 0.31)),
    ("Harbor", (-5632, 3072), (3072, 4096), "Concrete", (0.27, 0.34, 0.37)),
    ("Industrial", (0, 5632), (4096, 3072), "Concrete", (0.35, 0.31, 0.24)),
    ("PlayerBases", (-4608, 5376), (5120, 3072), "Grass", (0.22, 0.34, 0.18)),
]


def region_for(x, z):
    for name, (cx, cz), (sx, sz), material, color in REGIONS:
        if abs(x - cx) <= sx / 2 and abs(z - cz) <= sz / 2:
            return name, material, color
    return "Wilderness", "Grass", (0.28, 0.44, 0.22)


def part(size, pos, material="Concrete", color=(0.5,0.5,0.5), collide=True, transparency=0):
    return {
        "$className": "Part",
        "$properties": {
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
        },
    }

workspace = {"$properties": {"FallenPartsDestroyHeight": -1000}}

# 16x16 grid = 16,384 x 16,384. Smaller tiles make region boundaries obvious.
for xi, x in enumerate(range(-HALF + TILE // 2, HALF, TILE)):
    for zi, z in enumerate(range(-HALF + TILE // 2, HALF, TILE)):
        region, material, color = region_for(x, z)
        workspace[f"TILE_{xi}_{zi}_{region}"] = part((TILE, 32, TILE), (x, -16, z), material, color)

# Cross-continent highways.
for i, z in enumerate(range(-HALF + TILE // 2, HALF, TILE)):
    workspace[f"HIGHWAY_NS_{i}"] = part((140, 3, TILE), (0, 1.5, z), "Asphalt", (0.06, 0.065, 0.07))
for i, x in enumerate(range(-HALF + TILE // 2, HALF, TILE)):
    workspace[f"HIGHWAY_EW_{i}"] = part((TILE, 3, 140), (x, 1.5, 0), "Asphalt", (0.06, 0.065, 0.07))

# Capital: street grid + skyline blocks around a clear central plaza.
for n, x in enumerate(range(-1600, 1601, 400)):
    workspace[f"CAP_ROAD_X_{n}"] = part((90, 3, 3600), (x, 1.6, 0), "Asphalt", (0.055,0.06,0.065))
for n, z in enumerate(range(-1600, 1601, 400)):
    workspace[f"CAP_ROAD_Z_{n}"] = part((3600, 3, 90), (0, 1.7, z), "Asphalt", (0.055,0.06,0.065))

building_index = 0
for x in (-1400,-1000,-600,600,1000,1400):
    for z in (-1400,-1000,-600,600,1000,1400):
        h = 100 + ((abs(x)+abs(z)) // 200) % 6 * 45
        building_index += 1
        workspace[f"CAP_BUILDING_{building_index}"] = part((250,h,250),(x,h/2,z),"Concrete",(0.40,0.43,0.46))
        workspace[f"CAP_ROOF_{building_index}"] = part((270,8,270),(x,h+4,z),"Metal",(0.12,0.14,0.16))

workspace["CAPITAL_PLAZA"] = part((700,4,700),(0,2,0),"Marble",(0.65,0.67,0.68))
workspace["CAPITAL_TOWER"] = part((120,420,120),(0,210,0),"Metal",(0.18,0.40,0.55))

# Airport: runway, taxiways and hangars.
workspace["AIRPORT_RUNWAY"] = part((340,4,3000),(0,2,-5600),"Asphalt",(0.04,0.045,0.05))
for i,z in enumerate(range(-6900,-4299,400)):
    workspace[f"RUNWAY_MARK_{i}"] = part((24,5,180),(0,4,z),"Neon",(0.9,0.9,0.82),False)
for i,x in enumerate((-1300,-900,900,1300)):
    workspace[f"HANGAR_{i}"] = part((500,180,350),(x,90,-5200),"Metal",(0.30,0.33,0.35))

# Forest: clusters of trunks/canopies.
for i in range(70):
    x = -6800 + (i * 733) % 4200
    z = -6500 + (i * 977) % 4300
    workspace[f"TREE_TRUNK_{i}"] = part((28,110,28),(x,55,z),"Wood",(0.26,0.14,0.07))
    workspace[f"TREE_TOP_{i}"] = part((130,130,130),(x,150,z),"Grass",(0.08,0.28,0.08),False)

# Desert: mesas and rocky outcrops.
for i in range(30):
    x = 2800 + (i * 811) % 4200
    z = -6500 + (i * 617) % 4300
    h = 70 + (i % 5) * 35
    workspace[f"DESERT_ROCK_{i}"] = part((180+(i%3)*90,h,160+(i%4)*70),(x,h/2,z),"Sandstone",(0.56,0.30,0.16))

# Mountains: tall stepped rock masses.
for i in range(32):
    x = 2900 + (i * 683) % 4100
    z = 2600 + (i * 911) % 3900
    h = 180 + (i % 7) * 110
    s = 220 + (i % 4) * 100
    workspace[f"MOUNTAIN_{i}"] = part((s,h,s),(x,h/2,z),"Slate",(0.22,0.24,0.25))

# Harbor: water basin, piers, warehouses.
workspace["HARBOR_WATER"] = part((2200,20,2500),(-6000,-6,3200),"Glass",(0.05,0.38,0.62),False,0.18)
for i,z in enumerate((2200,2700,3200,3700,4200)):
    workspace[f"PIER_{i}"] = part((1200,20,120),(-5300,8,z),"Wood",(0.28,0.18,0.10))
for i,z in enumerate((2300,3100,3900)):
    workspace[f"PORT_WAREHOUSE_{i}"] = part((650,180,420),(-6800,90,z),"Metal",(0.30,0.33,0.34))

# Industrial: factory halls, stacks and yards.
for i,x in enumerate((-1500,-700,700,1500)):
    workspace[f"FACTORY_{i}"] = part((550,220,700),(x,110,5600),"Metal",(0.31,0.30,0.28))
    workspace[f"STACK_{i}"] = part((80,420,80),(x+180,210,5200),"Brick",(0.24,0.23,0.22))

# Player bases: 12 clearly separated plots.
plot = 0
for row,z in enumerate((4700,5500,6300)):
    for col,x in enumerate((-6700,-5700,-4700,-3700)):
        plot += 1
        workspace[f"BASE_PLOT_{plot}"] = part((820,6,620),(x,3,z),"Concrete",(0.26,0.29,0.27))
        workspace[f"BASE_PAD_{plot}"] = part((90,5,90),(x,7,z),"Neon",(0.10,0.80,0.32),False)

# Physical region towers; distinctive shape/color per region.
for idx,(name,(cx,cz),_size,_material,color) in enumerate(REGIONS):
    workspace[f"REGION_TOWER_{name}"] = part((36,300,36),(cx,150,cz),"Neon",color,False)
    workspace[f"REGION_TOP_{name}"] = part((160,28,160),(cx,314,cz),"Neon",color,False)

# Fixed spawn in Capital City plaza.
workspace["STATIC_SPAWN"] = {
    "$className": "SpawnLocation",
    "$properties": {
        "Anchored": True,
        "Neutral": True,
        "CanCollide": True,
        "Size": [40, 2, 40],
        "Position": [220, 6, 220],
        "Material": "Neon",
        "Color": [0.1, 0.85, 0.3],
    },
}

project = {"name":"GhostMegaWorldStatic","tree":{"$className":"DataModel","Workspace":workspace}}
print(json.dumps(project,separators=(",",":")))
