local require=require(script.Parent.loader).load(script)

local CrateConstants=require("CrateConstants")
local GetRemoteFunction=require("GetRemoteFunction")
local Maid=require("Maid")
local PlayerDataStoreService=require("PlayerDataStoreService")
local RelicVisualBuilder=require("RelicVisualBuilder")
local RxPlayerUtils=require("RxPlayerUtils")

local Service={ServiceName="CrateService"}
local COOLDOWN=2.5
local ATTR="CrateService_CrateCooldown"
local SUBSTORE="RelicsV1"

local function weightedRelicIndex()
	local total=0
	for _,entry in CrateConstants do total+=entry.Weight or 1 end
	local roll=math.random()*total
	local cursor=0
	for index,entry in CrateConstants do
		cursor+=entry.Weight or 1
		if roll<=cursor then return index end
	end
	return 1
end

local function ensureShowcase()
	local hub=workspace:FindFirstChild("GhostRNGHub")
	if not hub then
		hub=Instance.new("Folder")
		hub.Name="GhostRNGHub"
		hub.Parent=workspace
	end
	local stand=hub:FindFirstChild("LatestRelicStand")
	if not stand then
		stand=Instance.new("Model")
		stand.Name="LatestRelicStand"
		stand.Parent=hub
		local base=Instance.new("Part")
		base.Name="Base"
		base.Size=Vector3.new(8,1,8)
		base.Position=Vector3.new(0,1,-10)
		base.Anchored=true
		base.Material=Enum.Material.Slate
		base.Color=Color3.fromRGB(28,30,42)
		base.Parent=stand
		local top=Instance.new("Part")
		top.Name="Top"
		top.Size=Vector3.new(5.5,0.35,5.5)
		top.Position=Vector3.new(0,1.68,-10)
		top.Anchored=true
		top.Material=Enum.Material.Neon
		top.Color=Color3.fromRGB(126,75,220)
		top.Parent=stand
		local anchor=Instance.new("Part")
		anchor.Name="DisplayAnchor"
		anchor.Size=Vector3.new(1,1,1)
		anchor.Position=Vector3.new(0,5,-10)
		anchor.Transparency=1
		anchor.Anchored=true
		anchor.CanCollide=false
		anchor.Parent=stand
		local gui=Instance.new("BillboardGui")
		gui.Name="Info"
		gui.Size=UDim2.fromOffset(420,100)
		gui.StudsOffset=Vector3.new(0,3.2,0)
		gui.AlwaysOnTop=true
		gui.Parent=anchor
		local label=Instance.new("TextLabel")
		label.Name="Label"
		label.Size=UDim2.fromScale(1,1)
		label.BackgroundColor3=Color3.fromRGB(10,11,17)
		label.BackgroundTransparency=0.12
		label.TextColor3=Color3.new(1,1,1)
		label.TextStrokeTransparency=0.4
		label.TextScaled=true
		label.Font=Enum.Font.GothamBold
		label.Text="LAST RELIC"
		label.Parent=gui
		local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,12);corner.Parent=label
	end
	return stand
end

function Service:Init(serviceBag)
	self._maid=Maid.new()
	self._playerDataStoreService=serviceBag:GetService(PlayerDataStoreService)
end

function Service:Start()
	self._maid:GiveTask(RxPlayerUtils.observePlayersBrio():Subscribe(function(brio)
		self:_handlePlayer(brio:ToMaidAndValue())
	end))

	local remote=GetRemoteFunction("CrateServiceRemoteFunction")
	remote.OnServerInvoke=function(player,msg)
		if msg~="Unbox" then return end
		local previous=player:GetAttribute(ATTR)
		local now=workspace:GetServerTimeNow()
		if previous and now-previous<COOLDOWN then return end
		player:SetAttribute(ATTR,now)

		local index=weightedRelicIndex()
		local data=CrateConstants[index]
		player:SetAttribute("RNG_Rolls",(player:GetAttribute("RNG_Rolls") or 0)+1)
		player:SetAttribute("RNG_LastRelic",data.Name)
		player:SetAttribute("RNG_BestOneIn",math.max(player:GetAttribute("RNG_BestOneIn") or 0,data.OneIn or 1))
		self:_awardRelic(player,index)
		self:_updateShowcase(player,index)
		return index
	end
	self._maid:GiveTask(function()remote.OnServerInvoke=nil end)
end

local function setKey(parent,key,value)
	local current=parent:FindFirstChild(key)
	if value==nil then if current then current:Destroy() end return end
	if current then current.Value=value return end
	current=Instance.new("IntValue")
	current.Name=key
	current.Archivable=false
	current.Value=value
	current.Parent=parent
end

function Service:_handlePlayer(maid,player)
	player:SetAttribute("RNG_Rolls",player:GetAttribute("RNG_Rolls") or 0)
	player:SetAttribute("RNG_BestOneIn",player:GetAttribute("RNG_BestOneIn") or 0)
	maid:GivePromise(self._playerDataStoreService:PromiseDataStore(player)):Then(function(root)
		local old=player:FindFirstChild("RelicInventory")
		if old then old:Destroy() end
		local inventory=Instance.new("Folder")
		inventory.Archivable=false
		inventory.Name="RelicInventory"
		inventory.Parent=player
		local store=root:GetSubStore(SUBSTORE)
		local lastSnapshot=nil
		maid:GiveTask(store:Observe():Subscribe(function(snapshot)
			local delta=store._computeChangedKeys(nil,lastSnapshot,snapshot)
			for key in delta do setKey(inventory,key,snapshot[key]) end
			lastSnapshot=snapshot
		end))
	end)
end

function Service:_awardRelic(player,index)
	return self._playerDataStoreService:PromiseDataStore(player):Then(function(root)
		local store=root:GetSubStore(SUBSTORE)
		return store:Load(tostring(index),0):Then(function(count)
			store:Store(tostring(index),count+1)
		end)
	end)
end

function Service:_updateShowcase(player,index)
	local stand=ensureShowcase()
	local old=stand:FindFirstChild("CurrentRelic")
	if old then old:Destroy() end
	local data=CrateConstants[index]
	local model=RelicVisualBuilder.Build(data,stand)
	model.Name="CurrentRelic"
	model:PivotTo(CFrame.new(0,5,-10)*CFrame.Angles(0,math.rad(20),0))
	local anchor=stand:FindFirstChild("DisplayAnchor")
	local gui=anchor and anchor:FindFirstChild("Info")
	local label=gui and gui:FindFirstChild("Label")
	if label then
		label.Text=string.upper(player.DisplayName).." ROLLED\n"..string.upper(data.Name).."  •  1/"..tostring(data.OneIn)
		label.TextColor3=data.Color:Lerp(Color3.new(1,1,1),0.35)
	end
end

function Service:Destroy()self._maid:DoCleaning()end
return Service
