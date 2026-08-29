local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Shared=ReplicatedStorage:WaitForChild("RelicShared")
local Config=require(Shared.Config)
local Util=require(Shared.Util)
local WeightedRNG=require(Shared.WeightedRNG)

local RNGService={}

local function luck(profile)
    local lvl=profile.luckLevel or 0
    if lvl<=0 then return 1 end
    local cfg=Config.LUCK_UPGRADES[lvl]
    return cfg and cfg.multiplier or 1
end

local function pity(profile)
    local p=profile.pity or 0
    if p<Config.PITY_START then return 1 end
    return math.min(Config.PITY_CAP,1+(p-Config.PITY_START+1)*Config.PITY_STEP)
end

function RNGService.roll(profile,biome,serialProvider,mvProvider)
    local mult=luck(profile)*pity(profile)*biome.luckMult
    local relic=Config.RELICS[1]
    for _,r in ipairs(Config.RELICS) do
        if WeightedRNG.oneIn(r.oneIn,mult) and r.oneIn>=relic.oneIn then relic=r end
    end

    local mutation=Config.MUTATIONS[1]
    for _,m in ipairs(Config.MUTATIONS) do
        if WeightedRNG.oneIn(m.oneIn,biome.mutationMult) and m.oneIn>=mutation.oneIn then mutation=m end
    end

    local item={
        uid=Util.guid(),
        relicId=relic.id,
        relicName=relic.name,
        tier=relic.tier,
        serial=serialProvider(relic.id),
        baseOneIn=relic.oneIn,
        mutationId=mutation.id,
        mutationName=mutation.name,
        mutationOneIn=mutation.oneIn,
        mutationValueMult=mutation.valueMult or 1,
        combinedOneIn=relic.oneIn*math.max(1,mutation.oneIn),
        baseValue=relic.baseValue,
        marketValue=mvProvider(relic.id,relic.baseValue),
        createdAt=os.time(),
        biomeFound=biome.id,
        listed=false,
    }

    profile.stats.rolls+=1
    if relic.oneIn>=900 then profile.pity=0 else profile.pity=(profile.pity or 0)+1 end
    profile.stats.bestOneIn=math.max(profile.stats.bestOneIn or 1,item.combinedOneIn)
    profile.index[relic.id]=true
    return item
end

return RNGService
