local WeightedRNG = {}
local rng = Random.new()

function WeightedRNG.chooseWeighted(entries, weightFn)
    local total = 0
    local weights = table.create(#entries)
    for i, entry in ipairs(entries) do
        local w = math.max(0, weightFn(entry))
        weights[i] = w
        total += w
    end
    if total <= 0 then return entries[1] end

    local pick = rng:NextNumber() * total
    local acc = 0
    for i, entry in ipairs(entries) do
        acc += weights[i]
        if pick <= acc then return entry end
    end
    return entries[#entries]
end

function WeightedRNG.oneIn(oneIn, multiplier)
    multiplier = multiplier or 1
    oneIn = math.max(1, oneIn / math.max(multiplier, 0.0001))
    return rng:NextNumber() <= 1 / oneIn
end

return WeightedRNG
