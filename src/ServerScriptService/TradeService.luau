local HttpService = game:GetService("HttpService")

local TradeService = {}
local deps
local offers = {}

function TradeService.init(d)
    deps = d
end

local function getPlayer(userId)
    return deps.findPlayer(userId)
end

local function validItem(profile, uid)
    local item = profile and profile.inventory[uid]
    if not item then return nil end
    if item.listed then return nil end
    return item
end

function TradeService.createOffer(fromPlayer, targetUserId, myUid, wantedUid)
    local target = getPlayer(targetUserId)
    if not target or target == fromPlayer then return false, "target unavailable" end

    local fromProfile = deps.data.get(fromPlayer)
    local targetProfile = deps.data.get(target)

    if wantedUid == "__equipped__" then
        wantedUid = targetProfile and targetProfile.equippedUid or nil
    end

    local myItem = validItem(fromProfile, myUid)
    local wantedItem = validItem(targetProfile, wantedUid)
    if not myItem or not wantedItem then return false, "invalid item" end

    local id = HttpService:GenerateGUID(false)
    offers[id] = {
        id=id,
        fromUserId=fromPlayer.UserId,
        fromName=fromPlayer.DisplayName,
        targetUserId=target.UserId,
        targetName=target.DisplayName,
        myUid=myUid,
        wantedUid=wantedUid,
        myItemName=myItem.relicName,
        mySerial=myItem.serial,
        wantedItemName=wantedItem.relicName,
        wantedSerial=wantedItem.serial,
        createdAt=os.time(),
    }
    return true, offers[id]
end

function TradeService.respond(targetPlayer, offerId, accept)
    local offer = offers[offerId]
    if not offer then return false, "missing offer" end
    if offer.targetUserId ~= targetPlayer.UserId then return false, "not target" end

    offers[offerId] = nil
    if not accept then return true, "declined" end

    local fromPlayer = getPlayer(offer.fromUserId)
    if not fromPlayer then return false, "sender offline" end

    local fromProfile = deps.data.get(fromPlayer)
    local targetProfile = deps.data.get(targetPlayer)
    local myItem = validItem(fromProfile, offer.myUid)
    local wantedItem = validItem(targetProfile, offer.wantedUid)
    if not myItem or not wantedItem then return false, "item changed" end

    fromProfile.inventory[offer.myUid] = nil
    targetProfile.inventory[offer.wantedUid] = nil

    myItem.lastTradeAt = os.time()
    wantedItem.lastTradeAt = os.time()
    myItem.lastOwnerUserId = targetPlayer.UserId
    wantedItem.lastOwnerUserId = fromPlayer.UserId

    targetProfile.inventory[offer.myUid] = myItem
    fromProfile.inventory[offer.wantedUid] = wantedItem

    if fromProfile.equippedUid == offer.myUid then fromProfile.equippedUid = nil end
    if targetProfile.equippedUid == offer.wantedUid then targetProfile.equippedUid = nil end

    fromProfile.stats.trades = (fromProfile.stats.trades or 0) + 1
    targetProfile.stats.trades = (targetProfile.stats.trades or 0) + 1

    return true, {
        fromPlayer=fromPlayer,
        targetPlayer=targetPlayer,
        receivedByFrom=wantedItem,
        receivedByTarget=myItem,
    }
end

function TradeService.clearPlayer(userId)
    for id,offer in pairs(offers) do
        if offer.fromUserId == userId or offer.targetUserId == userId then
            offers[id] = nil
        end
    end
end

return TradeService
