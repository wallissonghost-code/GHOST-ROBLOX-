local Lighting=game:GetService("Lighting")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Shared=ReplicatedStorage:WaitForChild("RelicShared")
local Config=require(Shared.Config)
local WeightedRNG=require(Shared.WeightedRNG)

local BiomeService={}
local current=Config.BIOMES[1]

local function choose()
    return WeightedRNG.chooseWeighted(Config.BIOMES,function(b)
        return Config.BIOME_WEIGHTS[b.id] or 0
    end)
end

local function apply(b)
    Lighting.ClockTime=b.clock
    Lighting.Brightness=b.brightness
end

function BiomeService.init(onChanged)
    task.spawn(function()
        while true do
            current=choose()
            apply(current)
            if onChanged then onChanged(current) end
            task.wait(current.duration)
        end
    end)
end

function BiomeService.get() return current end
return BiomeService
