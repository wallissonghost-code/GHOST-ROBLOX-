import json

WORLD = 16384
TILE = 2048
HALF = WORLD // 2

REGIONS = [
    ("CapitalCity", (0, 0), (4096, 4096), "Concrete", (0.41, 0.43, 0.44)),
    ("Forest", (-4608, -4096), (5120, 5120), "Grass", (0.20, 0.40, 0.18)),
    ("Desert", (4864, -4096), (4864, 5120), "Sand", (0.74, 0.61, 0.36)),
    ("Mountains", (4864, 4352), (4864, 4608), "Slate", (0.35, 0.36, 0.35)),
    ("Airport", (0, -5632), (4096, 3072), "Concrete", (0.25, 0.26, 0.27)),
    ("Harbor", (-5632, 3072), (3072, 4096), "Concrete", (0.34, 0.40, 0.42)),
    ("Industrial", (0, 5632), (4096, 3072), "Concrete", (0.44, 0.39, 0.31)),
    ("PlayerBases", (-4608, 5376), (5120, 3072), "Grass", (0.27, 0.38, 0.23)),
]


def region_for(x, z):
    for name, (cx, cz), (sx, sz), material, color in REGIONS:
        if abs(x - cx) <= sx / 2 and abs(z - cz) <= sz / 2:
            return name, material, color
    return "Wilderness", "Grass", (0.36, 0.46, 0.29)


def part(size, pos, material, color, collide=True):
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
            "TopSurface": "Smooth",
            "BottomSurface": "Smooth",
        },
    }


workspace = {
    "$properties": {
        "FallenPartsDestroyHeight": -1000,
    }
}

# 8x8 static grid = 16,384 x 16,384 studs.
for xi, x in enumerate(range(-HALF + TILE // 2, HALF, TILE)):
    for zi, z in enumerate(range(-HALF + TILE // 2, HALF, TILE)):
        region, material, color = region_for(x, z)
        workspace[f"TILE_{xi}_{zi}_{region}"] = part(
            (TILE, 32, TILE),
            (x, -16, z),
            material,
            color,
        )

# Primary cross-continent highways.
for i, z in enumerate(range(-HALF + TILE // 2, HALF, TILE)):
    workspace[f"ROAD_NS_{i}"] = part(
        (120, 2, TILE), (0, 1, z), "Concrete", (0.08, 0.09, 0.10)
    )
for i, x in enumerate(range(-HALF + TILE // 2, HALF, TILE)):
    workspace[f"ROAD_EW_{i}"] = part(
        (TILE, 2, 120), (x, 1, 0), "Concrete", (0.08, 0.09, 0.10)
    )

# Region beacons: tall, bright physical markers that exist before any scripts run.
for name, (cx, cz), _size, _material, color in REGIONS:
    workspace[f"BEACON_{name}"] = part(
        (24, 240, 24), (cx, 120, cz), "Neon", color, collide=False
    )

workspace["STATIC_SPAWN"] = {
    "$className": "SpawnLocation",
    "$properties": {
        "Anchored": True,
        "Neutral": True,
        "CanCollide": True,
        "Size": [32, 2, 32],
        "Position": [0, 3, 0],
        "Material": "Neon",
        "Color": [0.1, 0.85, 0.3],
    },
}

project = {
    "name": "GhostMegaWorldStatic",
    "tree": {
        "$className": "DataModel",
        "Workspace": workspace,
    },
}

print(json.dumps(project, separators=(",", ":")))
