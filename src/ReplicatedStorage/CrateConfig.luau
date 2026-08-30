local CrateConfig = {}

CrateConfig.SPAWN_MIN_SECONDS = 6
CrateConfig.SPAWN_MAX_SECONDS = 10
CrateConfig.TRAVEL_SECONDS = 15
CrateConfig.MAX_ACTIVE_ON_BELT = 3
CrateConfig.OPENING_SLOTS = 3

CrateConfig.TIERS = {
    { id="common", name="CAIXA COMUM", weight=55, openSeconds=5, minOneIn=1, maxOneIn=35, mutationBoost=1.0, color=Color3.fromRGB(145,145,155) },
    { id="uncommon", name="CAIXA INCOMUM", weight=25, openSeconds=10, minOneIn=5, maxOneIn=150, mutationBoost=1.1, color=Color3.fromRGB(70,185,105) },
    { id="rare", name="CAIXA RARA", weight=12, openSeconds=18, minOneIn=35, maxOneIn=900, mutationBoost=1.25, color=Color3.fromRGB(70,120,235) },
    { id="epic", name="CAIXA ÉPICA", weight=5, openSeconds=30, minOneIn=150, maxOneIn=5_500, mutationBoost=1.5, color=Color3.fromRGB(170,80,230) },
    { id="legendary", name="CAIXA LENDÁRIA", weight=2, openSeconds=60, minOneIn=900, maxOneIn=30_000, mutationBoost=2.0, color=Color3.fromRGB(240,155,40) },
    { id="mythic", name="CAIXA MÍTICA", weight=0.8, openSeconds=120, minOneIn=5_500, maxOneIn=1_500_000, mutationBoost=2.8, color=Color3.fromRGB(235,65,110) },
    { id="celestial", name="CAIXA CELESTIAL", weight=0.18, openSeconds=240, minOneIn=30_000, maxOneIn=10_000_000, mutationBoost=4.0, color=Color3.fromRGB(135,220,255) },
    { id="secret", name="CAIXA SECRETA", weight=0.02, openSeconds=480, minOneIn=200_000, maxOneIn=500_000_000, mutationBoost=7.0, color=Color3.fromRGB(50,40,75) },
}

function CrateConfig.get(id)
    for _,tier in ipairs(CrateConfig.TIERS) do
        if tier.id == id then return tier end
    end
end

return CrateConfig
