import json, math

WORLD = 16384
HALF = WORLD // 2
TILE = 512
WATER_TILE = 1024
ISLAND_RADIUS = 7350
CENTER_RADIUS = 1250
LAKE_INNER = 1500
LAKE_OUTER = 2600

# Clockwise layout inspired by the approved reference image.
TERRITORIES = [
    (1, -5400,  4200, "PLAINS"),
    (2, -5900,  1100, "FOREST"),
    (3, -4500, -3300, "FOREST"),
    (4,  -900, -5650, "SNOW"),
    (5,  2700, -4700, "FOREST"),
    (6,  5650, -2500, "DESERT"),
    (7,  5900,  1000, "PLAINS"),
    (8,  4700,  4850, "FOREST"),
    (9,   900,  6500, "COAST"),
    (10, 2200,  3900, "PLAINS"),
    (11,-1900,  4100, "FOREST"),
    (12,-5000,  -300, "PLAINS"),
]


def part(size, pos, material="Grass", color=(0.28,0.45,0.22), collide=True, transparency=0, orientation=None):
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
    if orientation:
        props["Orientation"] = list(orientation)
    return {"$className":"Part", "$properties":props}


def distance(x, z, cx=0, cz=0):
    return math.sqrt((x-cx)**2 + (z-cz)**2)


def coast_limit(x, z):
    return ISLAND_RADIUS + (
        260*math.sin(z/820.0)
        + 210*math.cos(x/940.0)
        + 140*math.sin((x-z)/670.0)
        + 90*math.cos((x+z)/510.0)
    )


def biome(x, z):
    # North snow range.
    if z < -4300 and -2500 < x < 1500:
        return "Snow", (0.86,0.89,0.92), "SNOW"
    # North-east desert.
    if x > 3400 and z < -800:
        return "Sand", (0.74,0.56,0.32), "DESERT"
    # West / north-west forest.
    if x < -2500 and z < 1800:
        return "Grass", (0.13,0.31,0.13), "FOREST"
    # North-east forest pocket.
    if x > 800 and z < -2800:
        return "Grass", (0.17,0.37,0.15), "FOREST"
    # South coastal plain.
    if z > 5000:
        return "Grass", (0.32,0.50,0.25), "COAST"
    return "Grass", (0.28,0.46,0.22), "PLAINS"


def height_at(x, z):
    # Deliberately low-relief terrain. Nothing here can become a giant wall.
    h = 22 + 6*math.sin(x/1000.0) + 5*math.cos(z/1150.0) + 3*math.sin((x+z)/900.0)
    if z < -4300 and -2500 < x < 1500:
        h += 18 + 7*math.sin(x/700.0)
    elif x > 3400 and z < -800:
        h += 5
    # Flatten territory footprints and central island.
    for _, tx, tz, _ in TERRITORIES:
        if distance(x,z,tx,tz) < 950:
            return 28
    if distance(x,z) < CENTER_RADIUS + 300:
        return 30
    return max(12, min(55, h))


def road_between(ws, name, x1,z1,x2,z2,width=70,y=34, material="Concrete", color=(0.08,0.085,0.09)):
    dx, dz = x2-x1, z2-z1
    length = math.sqrt(dx*dx + dz*dz)
    if length < 1:
        return
    cx, cz = (x1+x2)/2, (z1+z2)/2
    angle = math.degrees(math.atan2(dx, dz))
    ws[name] = part((width, 3, length), (cx,y,cz), material, color, True, 0, (0,angle,0))


def ring(ws, prefix, cx, cz, radius, width, y, color, segments=36, transparency=0.35):
    for i in range(segments):
        a1 = 2*math.pi*i/segments
        a2 = 2*math.pi*(i+1)/segments
        x1, z1 = cx + radius*math.cos(a1), cz + radius*math.sin(a1)
        x2, z2 = cx + radius*math.cos(a2), cz + radius*math.sin(a2)
        dx, dz = x2-x1, z2-z1
        length = math.sqrt(dx*dx+dz*dz) + 3
        mx, mz = (x1+x2)/2, (z1+z2)/2
        angle = math.degrees(math.atan2(dx,dz))
        ws[f"{prefix}_{i}"] = part((width,3,length),(mx,y,mz),"Neon",color,False,transparency,(0,angle,0))


workspace = {"$properties":{"FallenPartsDestroyHeight":-600}}

# Ocean floor/water grid.
water_i = 0
for x in range(-HALF + WATER_TILE//2, HALF, WATER_TILE):
    for z in range(-HALF + WATER_TILE//2, HALF, WATER_TILE):
        water_i += 1
        workspace[f"OCEAN_{water_i}"] = part(
            (WATER_TILE, 12, WATER_TILE), (x,-6,z), "Glass", (0.035,0.30,0.53), False, 0.12
        )

# Single island. The annular lake is carved from the land itself.
land_i = 0
for x in range(-HALF + TILE//2, HALF, TILE):
    for z in range(-HALF + TILE//2, HALF, TILE):
        d = distance(x,z)
        if d > coast_limit(x,z):
            continue
        if LAKE_INNER < d < LAKE_OUTER:
            continue
        mat, color, bname = biome(x,z)
        h = height_at(x,z)
        land_i += 1
        workspace[f"LAND_{land_i}_{bname}"] = part((TILE+6,h,TILE+6),(x,h/2,z),mat,color)

# Central neutral island only: flat terrain, no structures.
workspace["NEUTRAL_CENTER"] = part((2200, 10, 2200),(0,35,0),"Grass",(0.24,0.45,0.21))
ring(workspace,"CENTER_ROAD",0,0,920,92,42,(0.70,0.72,0.74),40,0.0)

# Water around the central island, using flat water sheets only.
for n,(x,z,sx,sz) in enumerate([
    (0,-2050,5000,1000),
    (0,2050,5000,1000),
    (-2050,0,1000,3100),
    (2050,0,1000,3100),
]):
    workspace[f"CENTER_LAKE_{n}"] = part((sx,8,sz),(x,8,z),"Glass",(0.035,0.36,0.62),False,0.08)

# Twelve territory zones: only low flat pads and thin boundary markers.
for tid, tx, tz, bio_name in TERRITORIES:
    mat = "Snow" if bio_name == "SNOW" else "Sand" if bio_name == "DESERT" else "Grass"
    col = (0.86,0.89,0.92) if bio_name == "SNOW" else (0.74,0.56,0.32) if bio_name == "DESERT" else (0.25,0.46,0.21)
    workspace[f"TERRITORY_{tid}_GROUND"] = part((1450,8,1450),(tx,32,tz),mat,col)
    ring(workspace,f"TERRITORY_{tid}_BORDER",tx,tz,690,28,37,(0.18,0.64,0.95),30,0.48)

# Roads: territory -> inner lake -> central neutral island.
for tid, tx, tz, _ in TERRITORIES:
    d = distance(tx,tz)
    lake_x, lake_z = tx*(LAKE_OUTER/d), tz*(LAKE_OUTER/d)
    center_x, center_z = tx*(CENTER_RADIUS/d), tz*(CENTER_RADIUS/d)
    road_between(workspace,f"ROAD_{tid}_OUTER",tx,tz,lake_x,lake_z,72,35)
    road_between(workspace,f"BRIDGE_{tid}",lake_x,lake_z,center_x,center_z,82,39,"Concrete",(0.14,0.15,0.16))

# Outer road network linking neighboring territories.
for i in range(len(TERRITORIES)):
    a = TERRITORIES[i]
    b = TERRITORIES[(i+1)%len(TERRITORIES)]
    road_between(workspace,f"OUTER_ROUTE_{i}",a[1],a[2],b[1],b[2],56,34)

# A few low natural relief plates only; no trees, buildings, towers or tall props.
# Snow ridges.
for i in range(18):
    x = -2100 + (i*377)%3400
    z = -6750 + (i*463)%2100
    if distance(x,z) < coast_limit(x,z):
        h = 24 + (i%4)*8
        workspace[f"SNOW_RIDGE_{i}"] = part((380, h, 300),(x,28+h/2,z),"Snow",(0.82,0.85,0.88))

# Desert mesas kept low and wide.
for i in range(16):
    x = 3900 + (i*421)%2700
    z = -4700 + (i*353)%3200
    h = 18 + (i%3)*7
    workspace[f"DESERT_MESA_{i}"] = part((420, h, 330),(x,28+h/2,z),"Sand",(0.66,0.45,0.24))

# Small lakes like the reference.
for n,(x,z,sx,sz) in enumerate([
    (-3100,2300,650,420),
    (2550,3300,720,480),
    (2950,-3900,780,520),
    (-3900,4500,720,470),
]):
    workspace[f"LAKE_{n}"] = part((sx,7,sz),(x,9,z),"Glass",(0.035,0.36,0.62),False,0.08)

# Spawn in the neutral center.
workspace["STATIC_SPAWN"] = {"$className":"SpawnLocation","$properties":{
    "Anchored":True,
    "Neutral":True,
    "CanCollide":True,
    "Size":[40,2,40],
    "Position":[0,43,0],
    "Material":"Grass",
    "Color":[0.24,0.45,0.21],
    "Transparency":0.15
}}

project = {
    "name":"GhostCleanTerritoryIsland12",
    "tree":{"$className":"DataModel","Workspace":workspace}
}

print(json.dumps(project,separators=(",",":")))
