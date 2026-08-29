local ProgressionService = {}

local DAILY_COOLDOWN = 20 * 60 * 60

local QUESTS = {
    { id="roll_25", name="Faça 25 rolls", kind="rolls", target=25, reward=750 },
    { id="roll_100", name="Faça 100 rolls", kind="rolls", target=100, reward=3500 },
    { id="rare_3", name="Encontre 3 itens Rare+", kind="rare", target=3, reward=5000 },
    { id="sell_1", name="Venda 1 item no mercado", kind="sales", target=1, reward=2500 },
}

local function ensure(profile)
    profile.daily = profile.daily or { lastClaim=0, streak=0 }
    profile.questProgress = profile.questProgress or {}
    profile.claimedQuests = profile.claimedQuests or {}
    profile.unlockedZones = profile.unlockedZones or { starter=true }
end

function ProgressionService.questSnapshot(profile)
    ensure(profile)
    local out = {}
    for _,q in ipairs(QUESTS) do
        table.insert(out, {
            id=q.id,
            name=q.name,
            target=q.target,
            progress=math.min(q.target, profile.questProgress[q.id] or 0),
            reward=q.reward,
            claimed=profile.claimedQuests[q.id] == true,
        })
    end
    return out
end

function ProgressionService.addProgress(profile, kind, amount)
    ensure(profile)
    for _,q in ipairs(QUESTS) do
        if q.kind == kind and not profile.claimedQuests[q.id] then
            profile.questProgress[q.id] = math.min(q.target, (profile.questProgress[q.id] or 0) + (amount or 1))
        end
    end
end

function ProgressionService.claimQuest(profile, questId)
    ensure(profile)
    for _,q in ipairs(QUESTS) do
        if q.id == questId then
            if profile.claimedQuests[questId] then return false, "already claimed" end
            if (profile.questProgress[questId] or 0) < q.target then return false, "not complete" end
            profile.claimedQuests[questId] = true
            profile.coins += q.reward
            return true, q.reward
        end
    end
    return false, "unknown quest"
end

function ProgressionService.claimDaily(profile)
    ensure(profile)
    local now = os.time()
    local elapsed = now - (profile.daily.lastClaim or 0)
    if elapsed < DAILY_COOLDOWN then
        return false, DAILY_COOLDOWN - elapsed
    end

    if elapsed <= 48 * 60 * 60 then
        profile.daily.streak = math.min(7, (profile.daily.streak or 0) + 1)
    else
        profile.daily.streak = 1
    end

    profile.daily.lastClaim = now
    local reward = 1000 + (profile.daily.streak - 1) * 750
    profile.coins += reward
    return true, reward
end

function ProgressionService.dailyRemaining(profile)
    ensure(profile)
    return math.max(0, DAILY_COOLDOWN - (os.time() - (profile.daily.lastClaim or 0)))
end

function ProgressionService.recycle(profile, uid)
    ensure(profile)
    local item = profile.inventory[uid]
    if not item then return false, "item missing" end
    if item.listed then return false, "item listed" end
    if profile.equippedUid == uid then profile.equippedUid = nil end

    local base = item.marketValue or item.baseValue or 1
    local mutation = item.mutationValueMult or 1
    local payout = math.max(1, math.floor(base * 0.35 * math.max(1, mutation)))
    profile.inventory[uid] = nil
    profile.coins += payout
    return true, payout
end

function ProgressionService.collectionCount(profile)
    ensure(profile)
    local n = 0
    for _,found in pairs(profile.index or {}) do if found then n += 1 end end
    return n
end

function ProgressionService.unlockZone(profile, zoneId, cost)
    ensure(profile)
    if profile.unlockedZones[zoneId] then return true, "already" end
    if profile.coins < cost then return false, "coins" end
    profile.coins -= cost
    profile.unlockedZones[zoneId] = true
    return true, cost
end

return ProgressionService
