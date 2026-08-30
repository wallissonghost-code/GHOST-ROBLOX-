local require = require(script.Parent.loader).load(script)

local CrateConstants = require("CrateConstants")
local GetRemoteFunction = require("GetRemoteFunction")
local Maid = require("Maid")
local PlayerDataStoreService = require("PlayerDataStoreService")
local RxPlayerUtils = require("RxPlayerUtils")

local Service = { ServiceName = "CrateService" }
local COOLDOWN = 2.5
local ATTR = "CrateService_CrateCooldown"
local SUBSTORE = "RelicsV1"

local function weightedRelicIndex()
	local total = 0
	for _, entry in CrateConstants do
		total += entry.Weight or 1
	end

	local roll = math.random() * total
	local cursor = 0
	for index, entry in CrateConstants do
		cursor += entry.Weight or 1
		if roll <= cursor then
			return index
		end
	end
	return 1
end

function Service:Init(serviceBag)
	self._maid = Maid.new()
	self._playerDataStoreService = serviceBag:GetService(PlayerDataStoreService)
end

function Service:Start()
	self._maid:GiveTask(RxPlayerUtils.observePlayersBrio():Subscribe(function(brio)
		self:_handlePlayer(brio:ToMaidAndValue())
	end))

	local remote = GetRemoteFunction("CrateServiceRemoteFunction")
	remote.OnServerInvoke = function(player, msg)
		if msg ~= "Unbox" then
			return
		end

		local previous = player:GetAttribute(ATTR)
		local now = workspace:GetServerTimeNow()
		if previous and now - previous < COOLDOWN then
			return
		end
		player:SetAttribute(ATTR, now)

		local index = weightedRelicIndex()
		self:_awardRelic(player, index)
		return index
	end

	self._maid:GiveTask(function()
		remote.OnServerInvoke = nil
	end)
end

local function setKey(parent, key, value)
	local current = parent:FindFirstChild(key)
	if value == nil then
		if current then current:Destroy() end
		return
	end
	if current then
		current.Value = value
	else
		current = Instance.new("IntValue")
		current.Name = key
		current.Archivable = false
		current.Value = value
		current.Parent = parent
	end
end

function Service:_handlePlayer(maid, player)
	maid:GivePromise(self._playerDataStoreService:PromiseDataStore(player)):Then(function(root)
		local inventory = Instance.new("Folder")
		inventory.Archivable = false
		inventory.Name = "ColorInventory"
		inventory.Parent = player

		local store = root:GetSubStore(SUBSTORE)
		local lastSnapshot = nil
		maid:GiveTask(store:Observe():Subscribe(function(snapshot)
			local delta = store._computeChangedKeys(nil, lastSnapshot, snapshot)
			for key in delta do
				setKey(inventory, key, snapshot[key])
			end
			lastSnapshot = snapshot
		end))
	end)
end

function Service:_awardRelic(player, index)
	return self._playerDataStoreService:PromiseDataStore(player):Then(function(root)
		local store = root:GetSubStore(SUBSTORE)
		return store:Load(tostring(index), 0):Then(function(count)
			store:Store(tostring(index), count + 1)
		end)
	end)
end

function Service:Destroy()
	self._maid:DoCleaning()
end

return Service
