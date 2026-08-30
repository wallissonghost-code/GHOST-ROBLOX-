-- Plot — TycoonKit per-plot state
-- Copyright (c) 2026 rumin
-- Licensed under the MIT License. See LICENSES/roblox-tycoon-kit-MIT.txt

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local COIN_LIFETIME = 30
local PURCHASE_DEBOUNCE = 0.25

local function getHiddenStorage()
	local folder = ServerStorage:FindFirstChild("_TycoonHidden")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "_TycoonHidden"
		folder.Parent = ServerStorage
	end
	return folder
end

local Plot = {}
Plot.__index = Plot

function Plot.new(tycoon, model)
	local self = setmetatable({Tycoon=tycoon, Model=model, Owner=nil, _cash=0, _purchased={}, _dropperRunning={}, _coins={}, _released=true}, Plot)
	self._buttonsFolder = model:WaitForChild("Buttons")
	self._itemsFolder = model:WaitForChild("Items")
	self._droppersFolder = model:WaitForChild("Droppers")
	self._collector = model:WaitForChild("Collector")
	self._spawnLocation = model:WaitForChild("Spawn")
	local hidden = getHiddenStorage()
	self._hiddenItemsFolder = Instance.new("Folder")
	self._hiddenItemsFolder.Name = "Items_" .. model.Name
	self._hiddenItemsFolder.Parent = hidden
	self._hiddenButtonsFolder = Instance.new("Folder")
	self._hiddenButtonsFolder.Name = "Buttons_" .. model.Name
	self._hiddenButtonsFolder.Parent = hidden
	for _, item in ipairs(self._itemsFolder:GetChildren()) do item.Parent = self._hiddenItemsFolder end
	for _, button in ipairs(self._buttonsFolder:GetChildren()) do button.Parent = self._hiddenButtonsFolder end
	self._collector.Touched:Connect(function(hit) self:_handleCoinTouch(hit) end)
	return self
end

function Plot:Claim(player)
	self.Owner = player
	self._cash = 2500
	self._purchased = {}
	self._released = false
	self.Model:SetAttribute("OwnerUserId", player.UserId)
	self.Model:SetAttribute("Cash", self._cash)
	player.RespawnLocation = self._spawnLocation
	local character = player.Character
	if character then character:PivotTo(self._spawnLocation.CFrame * CFrame.new(0, 5, 0)) end
	self:_evaluateButtons()
end

function Plot:Release()
	self._released = true
	self.Owner = nil
	self._purchased = {}
	self._cash = 0
	self.Model:SetAttribute("OwnerUserId", 0)
	self.Model:SetAttribute("Cash", 0)
	self._dropperRunning = {}
	for coin in pairs(self._coins) do coin:Destroy() end
	self._coins = {}
	for _, item in ipairs(self._itemsFolder:GetChildren()) do item.Parent = self._hiddenItemsFolder end
	for _, button in ipairs(self._buttonsFolder:GetChildren()) do button.Parent = self._hiddenButtonsFolder end
end
function Plot:AddCash(amount)
	self._cash = math.max(0, self._cash + amount)
	self.Model:SetAttribute("Cash", self._cash)
end
function Plot:GetCash() return self._cash end
function Plot:_evaluateButtons()
	local allButtons = {}
	for _, b in ipairs(self._buttonsFolder:GetChildren()) do allButtons[b.Name]=b end
	for _, b in ipairs(self._hiddenButtonsFolder:GetChildren()) do allButtons[b.Name]=b end
	for name, button in pairs(allButtons) do
		local requires = button:GetAttribute("Requires")
		local satisfied = (not requires or requires == "" or self._purchased[requires])
		local shouldShow = satisfied and not self._purchased[name]
		button.Parent = shouldShow and self._buttonsFolder or self._hiddenButtonsFolder
		if shouldShow then self:_wireButton(button) end
	end
end
function Plot:_wireButton(button)
	if button:GetAttribute("_TouchWired") then return end
	button:SetAttribute("_TouchWired", true)
	local touchPart = button:IsA("BasePart") and button or button:FindFirstChildWhichIsA("BasePart")
	if not touchPart then return end
	local debounce=false
	touchPart.Touched:Connect(function(hit)
		if debounce or self._released or not self.Owner then return end
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player ~= self.Owner or button.Parent ~= self._buttonsFolder then return end
		debounce=true
		local price = button:GetAttribute("Price") or 0
		if self._cash >= price then
			self:AddCash(-price)
			self._purchased[button.Name]=true
			self:_unlockItem(button.Name)
			self:_startDroppersFor(button.Name)
			self.Tycoon.PurchaseMade:Fire(self.Owner, button.Name, self._cash)
			self:_evaluateButtons()
		end
		task.wait(PURCHASE_DEBOUNCE)
		debounce=false
	end)
end
function Plot:_unlockItem(name)
	local item=self._hiddenItemsFolder:FindFirstChild(name)
	if item then item.Parent=self._itemsFolder end
end
function Plot:GetPurchases()
	local list={}
	for name in pairs(self._purchased) do table.insert(list,name) end
	return list
end
function Plot:RestorePurchases(buttonNames)
	for _,name in ipairs(buttonNames) do
		self._purchased[name]=true
		self:_unlockItem(name)
		self:_startDroppersFor(name)
	end
	self:_evaluateButtons()
end
function Plot:_startDroppersFor(buttonName)
	for _,dropper in ipairs(self._droppersFolder:GetChildren()) do
		if dropper:GetAttribute("Button")==buttonName then self:_startDropper(dropper) end
	end
end
function Plot:_startDropper(dropper)
	if self._dropperRunning[dropper] then return end
	local spawnPart=dropper:FindFirstChild("DropSpawn")
	if not spawnPart or not spawnPart:IsA("BasePart") then return end
	local rate=math.max(0.05,dropper:GetAttribute("DropRate") or 1)
	local value=dropper:GetAttribute("DropValue") or 1
	self._dropperRunning[dropper]=true
	task.spawn(function()
		while self._dropperRunning[dropper] and not self._released do
			task.wait(1/rate)
			if not self._dropperRunning[dropper] or self._released then break end
			self:_spawnCoin(spawnPart.CFrame,value)
		end
	end)
end
function Plot:_spawnCoin(cframe,value)
	local coin=Instance.new("Part")
	coin.Name="TycoonCoin"
	coin.Shape=Enum.PartType.Ball
	coin.Size=Vector3.new(1,1,1)
	coin.Material=Enum.Material.Neon
	coin.Color=Color3.fromRGB(255,211,0)
	coin.CFrame=cframe
	coin:SetAttribute("Value",value)
	coin:SetAttribute("PlotName",self.Model.Name)
	coin.Parent=workspace
	self._coins[coin]=true
	task.delay(COIN_LIFETIME,function() if coin.Parent then coin:Destroy() end end)
end
function Plot:_handleCoinTouch(hit)
	if self._released or not self.Owner then return end
	if not hit:IsA("BasePart") or hit:GetAttribute("PlotName")~=self.Model.Name then return end
	local value=hit:GetAttribute("Value")
	if not value then return end
	self._coins[hit]=nil
	hit:Destroy()
	self:AddCash(value)
	self.Tycoon.CoinCollected:Fire(self.Owner,value)
end
return Plot
