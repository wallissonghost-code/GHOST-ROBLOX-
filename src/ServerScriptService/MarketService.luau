local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Shared=ReplicatedStorage:WaitForChild("RelicShared")
local Config=require(Shared.Config)
local Util=require(Shared.Util)

local MarketService={}
local deps
local market={}

function MarketService.init(d)
    deps=d
    market=deps.data.loadMarket()
end

function MarketService.snapshot()
    local out={}
    for id,l in pairs(market) do
        local c=Util.deepCopy(l)
        c.listingId=id
        table.insert(out,c)
    end
    table.sort(out,function(a,b) return (a.createdAt or 0)>(b.createdAt or 0) end)
    return out
end

function MarketService.listItem(player,uid,price)
    price=math.floor(tonumber(price) or 0)
    if price<=0 then return false,"invalid price" end

    local profile=deps.data.get(player)
    local item=profile and profile.inventory[uid]
    if not item or item.listed then return false,"invalid item" end

    local count=0
    for _,listing in pairs(market) do
        if listing.sellerUserId==player.UserId then count+=1 end
    end
    if count>=Config.MAX_MARKET_LISTINGS_PER_PLAYER then return false,"listing limit" end

    local id=Util.guid()
    item.listed=true
    item.listingId=id
    market[id]={
        sellerUserId=player.UserId,
        sellerName=player.DisplayName,
        price=price,
        createdAt=os.time(),
        item=Util.deepCopy(item),
    }
    deps.data.saveMarket(market)
    return true
end

function MarketService.buy(player,listingId)
    local l=market[listingId]
    if not l then return false,"missing" end
    if l.sellerUserId==player.UserId then return false,"own listing" end

    local buyer=deps.data.get(player)
    if not buyer or buyer.coins<l.price then return false,"coins" end
    if Util.count(buyer.inventory)>=Config.BASE_INVENTORY_SLOTS then return false,"inventory full" end

    local sellerPlayer=deps.findPlayer(l.sellerUserId)
    if not sellerPlayer then return false,"seller offline" end
    local seller=deps.data.get(sellerPlayer)
    local item=seller and seller.inventory[l.item.uid]
    if not item or item.listingId~=listingId then return false,"stale" end

    buyer.coins-=l.price
    seller.coins+=math.floor(l.price*(1-Config.MARKET_FEE))
    seller.inventory[item.uid]=nil

    local transfer=Util.deepCopy(item)
    transfer.listed=false
    transfer.listingId=nil
    transfer.lastPurchasePrice=l.price
    buyer.inventory[transfer.uid]=transfer

    seller.stats.totalSales+=l.price
    buyer.stats.totalPurchases+=l.price
    deps.data.recordSale(transfer.relicId,l.price)

    market[listingId]=nil
    deps.data.saveMarket(market)
    return true,transfer
end

return MarketService
