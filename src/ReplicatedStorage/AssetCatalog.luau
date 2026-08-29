local AssetCatalog = {}

-- Curated Creator Store assets used only as VISUAL museum pieces.
-- MuseumService sanitizes inserted assets and removes scripts/tools/prompts.
-- If an asset cannot load, the game falls back to the procedural RelicModelBuilder.
AssetCatalog.RELIC_ASSETS = {
    rust_ring = {
        assetId = 70897902492927,
        sourceName = "Meshes/InnerRing",
        creatorStore = true,
        scale = 0.8,
    },
    old_coin = {
        assetId = 10737243803,
        sourceName = "Coin Model",
        creatorStore = true,
        scale = 0.9,
    },
    broken_idol = {
        assetId = 5510027184,
        sourceName = "Trophy",
        creatorStore = true,
        scale = 0.85,
    },
    silver_eye = {
        assetId = 9653613382,
        sourceName = "Eye",
        creatorStore = true,
        scale = 0.75,
    },
    amber_mask = {
        assetId = 74212734353781,
        sourceName = "Mask",
        creatorStore = true,
        scale = 0.8,
    },
    moon_charm = {
        assetId = 1622659316,
        sourceName = "Crystal",
        creatorStore = true,
        scale = 0.75,
    },
    blood_idol = {
        assetId = 200480044,
        sourceName = "Crystal",
        creatorStore = true,
        scale = 0.8,
    },
    void_crown = {
        assetId = 96651343126365,
        sourceName = "Crown",
        creatorStore = true,
        scale = 0.85,
    },
    angel_core = {
        assetId = 6768917255,
        sourceName = "Treasure Chest Mesh",
        creatorStore = true,
        scale = 0.7,
    },
    black_halo = {
        assetId = 0,
        sourceName = "Procedural Halo",
        creatorStore = false,
        scale = 1,
    },
    reality_key = {
        assetId = 61251941,
        sourceName = "Key by Roblox",
        creatorStore = true,
        scale = 0.8,
    },
    zero_relic = {
        assetId = 6768917255,
        sourceName = "Treasure Chest Mesh",
        creatorStore = true,
        scale = 0.65,
    },
    origin_fragment = {
        assetId = 1622659316,
        sourceName = "Crystal",
        creatorStore = true,
        scale = 0.9,
    },
}

function AssetCatalog.get(relicId)
    return AssetCatalog.RELIC_ASSETS[relicId]
end

return AssetCatalog
