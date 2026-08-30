import json, math

WORLD = 16384
HALF = WORLD // 2
TILE = 512
WATER_TILE = 1024
ISLAND_RADIUS = 7480
CENTER_ISLAND_RADIUS = 1350
INNER_LAKE_R1 = 1600
INNER_LAKE_R2 = 2750

TERRITORIES = [
    (1, -5200, 4300, "PLAINS"),
    (2, -5850, 900, "FOREST"),
    (3, -4400, -3300, "FOREST"),
    (4, -700, -5600, "SNOW"),
    (5, 2800, -4550, "FOREST"),
    (6, 5650, -2500, "DESERT"),
    (7, 5800, 1100, "PLAINS"),
    (8, 4700, 5000, "FOREST"),
    (9, 900, 6500, "COAST"),
    (10, 1700, 3850, "FOREST"),
    (11, -1900, 3900, "FOREST"),
    (12, -5000, -500, "PLAINS"),
]


def part(size, pos, material="Grass", color=(0.3,0.45,0.22), collide=True, transparency=0, shape=None, rotation=None):
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
    if rotation:
        props["Orientation"] = list(rotation)
    return {"$className":"Part", "$properties":props}


def island_edge(x,z):
    d = math.sqrt(x*x+z*z)
    noise = 330*math.sin(z/760.0) + 250*math.cos(x/920.0) + 180*math.sin((x-z)/580.0) + 120*math.cos((x+z)/430.0)
    return d <= ISLAND_RADIUS + noise


def biome_for(x,z):
    # Snow crown at the north.
    if z < -4300 and -2200 < x < 1600:
        return "Snow", (0.82,0.86,0.90), "SNOW"
    # Desert in the north-east.
    if x > 3400 and z < -900:
        return "Sand", (0.73,0.54,0.30), "DESERT"
    # Darker western/northern forests.
    if x < -2500 and z < 1500:
        return "Grass", (0.13,0.31,0.12), "FOREST"
    if x > 1000 and z < -2500:
        return "Grass", (0.18,0.38,0.15), "FOREST"
    # Southern coast/plains.
    if z > 4800:
        return "Grass", (0.31,0.48,0.23), "COAST"
    return "Grass", (0.27,0.45,0.21), "PLAINS"


def elevation(x,z):
    d = math.sqrt(x*x+z*z)
    base = 34 + 15*math.sin(x/950.0) + 11*math.cos(z/1120.0) + 7*math.sin((x+z)/720.0)
    # Mountain belt around snow region and NW highlands.
    if z < -3600 and -2800 < x < 1500:
        base += 80 + 45*math.sin(x/430.0) + 35*math.cos(z/510.0)
    elif x < -3000 and z < -1800:
        base += 28 + 18*math.sin((x-z)/600.0)
    elif x > 3600 and z < -1000:
        base += 16 + 14*math.sin(x/680.0)
    # flatten territory clearings
    for _,tx,tz,_ in TERRITORIES:
        td = math.sqrt((x-tx)**2 + (z-tz)**2)
        if td < 850:
            return 42
    if d < CENTER_ISLAND_RADIUS:
        return 46
    return max(18, base)


def road_between(workspace, name, x1,z1,x2,z2,width=72,y=52):
    dx, dz = x2-x1, z2-z1
    length = math.sqrt(dx*dx+dz*dz)
    if length < 1:
        return
    angle = math.degrees(math.atan2(dx,dz))
    cx, cz = (x1+x2)/2, (z1+z2)/2
    workspace[name] = part((width,4,length),(cx,y,cz),"Concrete",(0.095,0.10,0.105),True,0,None,(0,angle,0))


workspace = {"$properties":{"FallenPartsDestroyHeight":-700}}

# Ocean base.
idx = 0
for x in range(-HALF + WATER_TILE//2, HALF, WATER_TILE):
    for z in range(-HALF + WATER_TILE//2, HALF, WATER_TILE):
        idx += 1
        workspace[f"OCEAN_{idx}"] = part((WATER_TILE,18,WATER_TILE),(x,-9,z),"Glass",(0.035,0.29,0.50),False,0.12)

# Main island terrain. The circular inner lake is carved out here.
li = 0
for x in range(-HALF + TILE//2, HALF, TILE):
    for z in range(-HALF + TILE//2, HALF, TILE):
        if not island_edge(x,z):
            continue
        d = math.sqrt(x*x+z*z)
        if INNER_LAKE_R1 < d < INNER_LAKE_R2:
            continue
        mat,color,bname = biome_for(x,z)
        h = elevation(x,z)
        li += 1
        workspace[f"LAND_{li}_{bname}"] = part((TILE+10,h,TILE+10),(x,h/2,z),mat,color)

# Central neutral island is clean and circular-ish via layered pads.
workspace["CENTER_ISLAND_BASE"] = part((2400,44,2400),(0,22,0),"Grass",(0.25,0.46,0.22))
workspace["CENTER_ISLAND_INNER"] = part((1700,16,1700),(0,52,0),"Grass",(0.20,0.42,0.18))
workspace["CENTER_RING_ROAD"] = part((2050,4,2050),(0,62,0),"Concrete",(0.10,0.105,0.11),True,0,"Cylinder",(0,0,90))
workspace["CENTER_GREEN"] = part((1500,8,1500),(0,66,0),"Grass",(0.16,0.38,0.16),True,0,"Cylinder",(0,0,90))

# Inner lake water ring (four broad quadrants, underneath bridges).
for n,(x,z,sx,sz) in enumerate([
    (0,-2150,5200,1150),(0,2150,5200,1150),(-2150,0,1150,3000),(2150,0,1150,3000)
]):
    workspace[f"INNER_LAKE_{n}"] = part((sx,14,sz),(x,14,z),"Glass",(0.035,0.36,0.60),False,0.10)

# Territory clearings: natural flat pads, no buildings.
for tid,tx,tz,bio in TERRITORIES:
    mat = "Snow" if bio=="SNOW" else "Sand" if bio=="DESERT" else "Grass"
    col = (0.82,0.86,0.90) if bio=="SNOW" else (0.75,0.55,0.31) if bio=="DESERT" else (0.24,0.45,0.20)
    workspace[f"TERRITORY_{tid}_CLEARING"] = part((1500,10,1500),(tx,47,tz),mat,col,True,0,"Cylinder",(0,0,90))
    # subtle capture boundary ring using transparent neon disc under clearing edge
    workspace[f"TERRITORY_{tid}_MARKER"] = part((1580,3,1580),(tx,53,tz),"Neon",(0.16,0.62,0.95),False,0.72,"Cylinder",(0,0,90))
    workspace[f"TERRITORY_{tid}_INNER"] = part((1420,4,1420),(tx,55,tz),mat,col,True,0,"Cylinder",(0,0,90))

# Radial highways from every territory to the central lake edge.
for tid,tx,tz,_ in TERRITORIES:
    d = math.sqrt(tx*tx+tz*tz)
    ex, ez = tx*(INNER_LAKE_R2/d), tz*(INNER_LAKE_R2/d)
    road_between(workspace,f"ROAD_T{tid}",tx,tz,ex,ez,76,58)
    # bridge across inner lake to central island
    ix, iz = tx*(CENTER_ISLAND_RADIUS/d), tz*(CENTER_ISLAND_RADIUS/d)
    road_between(workspace,f"BRIDGE_T{tid}",ex,ez,ix,iz,86,62)

# Outer ring road joining all 12 territories.
ordered = TERRITORIES
for i in range(len(ordered)):
    a = ordered[i]
    b = ordered[(i+1)%len(ordered)]
    road_between(workspace,f"OUTER_LINK_{i}",a[1],a[2],b[1],b[2],60,56)

# Forest masses, concentrated away from roads and clearings.
for i in range(220):
    x = -6800 + (i*619) % 6200
    z = -6100 + (i*883) % 9000
    if not island_edge(x,z):
        continue
    if x > 3400 and z < -900:
        continue
    if z < -4300 and -2200 < x < 1600:
        continue
    if math.sqrt(x*x+z*z) < 3000:
        continue
    if any(math.sqrt((x-tx)**2+(z-tz)**2) < 1000 for _,tx,tz,_ in TERRITORIES):
        continue
    gy=elevation(x,z)
    trunk=65+(i%5)*10
    workspace[f"TREE_TRUNK_{i}"] = part((18,trunk,18),(x,gy+trunk/2,z),"Wood",(0.24,0.13,0.06))
    workspace[f"TREE_TOP_{i}"] = part((105,105,105),(x,gy+trunk+35,z),"Grass",(0.07,0.24,0.07),False,0,"Ball")

# Snow mountain range at north.
for i in range(52):
    x = -2100 + (i*733)%3600
    z = -6900 + (i*547)%2800
    if not island_edge(x,z):
        continue
    gy=elevation(x,z)
    h=180+(i%7)*90
    s=150+(i%4)*85
    workspace[f"SNOW_PEAK_{i}"] = part((s,h,s),(x,gy+h/2,z),"Slate",(0.30,0.32,0.34))
    workspace[f"SNOW_CAP_{i}"] = part((s*0.72,h*0.28,s*0.72),(x,gy+h*0.90,z),"Snow",(0.91,0.93,0.95),False)

# Desert mesas and boulders in territory 6 region.
for i in range(70):
    x=3600+(i*601)%3300
    z=-5000+(i*733)%4300
    if not island_edge(x,z):
        continue
    if math.sqrt((x-5650)**2+(z+2500)**2)<950:
        continue
    gy=elevation(x,z)
    s=90+(i%5)*45
    h=45+(i%4)*35
    workspace[f"DESERT_ROCK_{i}"] = part((s,h,s*0.8),(x,gy+h/2,z),"Sand",(0.58,0.34,0.18))

# Additional natural lakes like the reference map.
for n,(x,z,sx,sz) in enumerate([
    (-900,3200,1000,650),(2300,3300,750,520),(-3300,2300,720,500),(3200,-4100,900,650),(-3900,4700,850,600)
]):
    workspace[f"LAKE_{n}"] = part((sx,12,sz),(x,18,z),"Glass",(0.035,0.36,0.60),False,0.10)

# Spawn in neutral city zone, no structures around it.
workspace["STATIC_SPAWN"]={"$className":"SpawnLocation","$properties":{
    "Anchored":True,"Neutral":True,"CanCollide":True,
    "Size":[42,2,42],"Position":[0,72,0],"Material":"Neon","Color":[0.12,0.90,0.35]
}}

project={
    "name":"GhostTerritoryIsland12",
    "tree":{"$className":"DataModel","Workspace":workspace}
}

print(json.dumps(project,separators=(",",":")))
