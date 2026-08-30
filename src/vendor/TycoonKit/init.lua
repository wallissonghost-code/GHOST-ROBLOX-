-- TycoonKit
-- Copyright (c) 2026 rumin
-- Licensed under the MIT License. See LICENSES/roblox-tycoon-kit-MIT.txt

local Players = game:GetService("Players")
local Plot = require(script:WaitForChild("Plot"))

local Signal = {}
Signal.__index = Signal
function Signal.new() return setmetatable({_handlers = {}}, Signal) end
function Signal:Connect(fn)
	table.insert(self._handlers, fn)
	return {Disconnect = function()
		for i, handler in ipairs(self._handlers) do
			if handler == fn then table.remove(self._handlers, i) return end
		end
	end}
end
function Signal:Fire(...)
	for _, handler in ipairs(self._handlers) do task.spawn(handler, ...) end
end

local TycoonKit = {}
TycoonKit.__index = TycoonKit
function TycoonKit.new(options)
	options = options or {}
	local plotsFolder = options.plotsFolder or workspace:WaitForChild("Plots")
	local self = setmetatable({
		_plotsFolder = plotsFolder,
		_plots = {},
		_ownedBy = {},
		PurchaseMade = Signal.new(),
		CoinCollected = Signal.new(),
		PlotAssigned = Signal.new(),
		PlotReleased = Signal.new(),
	}, TycoonKit)
	for _, model in ipairs(plotsFolder:GetChildren()) do
		if model:IsA("Model") then table.insert(self._plots, Plot.new(self, model)) end
	end
	for _, player in ipairs(Players:GetPlayers()) do task.spawn(function() self:_assignPlot(player) end) end
	Players.PlayerAdded:Connect(function(player) self:_assignPlot(player) end)
	Players.PlayerRemoving:Connect(function(player) self:_releasePlot(player) end)
	return self
end
function TycoonKit:_assignPlot(player)
	if self._ownedBy[player] then return end
	for _, plot in ipairs(self._plots) do
		if not plot.Owner then
			plot:Claim(player)
			self._ownedBy[player] = plot
			self.PlotAssigned:Fire(player, plot.Model)
			return
		end
	end
	warn(("[TycoonKit] No free plot for %s"):format(player.Name))
end
function TycoonKit:_releasePlot(player)
	local plot = self._ownedBy[player]
	if not plot then return end
	plot:Release()
	self._ownedBy[player] = nil
	self.PlotReleased:Fire(player, plot.Model)
end
function TycoonKit:GetPlot(player) return self._ownedBy[player] end
function TycoonKit:GetCash(player)
	local plot = self._ownedBy[player]
	return plot and plot:GetCash() or 0
end
function TycoonKit:AddCash(player, amount)
	local plot = self._ownedBy[player]
	if plot then plot:AddCash(amount) end
end
function TycoonKit:GetPurchases(player)
	local plot = self._ownedBy[player]
	return plot and plot:GetPurchases() or {}
end
function TycoonKit:RestorePurchases(player, buttonNames)
	local plot = self._ownedBy[player]
	if plot then plot:RestorePurchases(buttonNames) end
end
return TycoonKit
