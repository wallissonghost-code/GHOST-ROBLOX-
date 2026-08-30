local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local TycoonKit = require(ServerStorage:WaitForChild("TycoonKit"))
local STORE = DataStoreService:GetDataStore("LicensedOpenWorld_v1")

local BASE_POSITIONS = {
	Vector3.new(-6900,0,-6500), Vector3.new(-2600,0,-6900),
	Vector3.new(2600,0,-6900), Vector3.new(6900,0,-5600),
	Vector3.new(6900,0,5600), Vector3.new(2600,0,6900),
	Vector3.new(-2600,0,6900), Vector3.new(-6900,0,5600),
}

local function makePart(parent,name,size,pos,color,material)
	local p=Instance.new("Part")
	p.Name=name; p.Anchored=true; p.CanCollide=true
	p.Size=size; p.Position=pos; p.Color=color or Color3.fromRGB(70,70,70)
	p.Material=material or Enum.Material.Concrete; p.TopSurface=Enum.SurfaceType.Smooth
	p.Parent=parent; return p
end

local function label(part,text)
	local gui=Instance.new("BillboardGui")
	gui.AlwaysOnTop=true; gui.MaxDistance=220; gui.Size=UDim2.fromOffset(260,70); gui.StudsOffset=Vector3.new(0,3.5,0); gui.Parent=part
	local t=Instance.new("TextLabel")
	t.BackgroundColor3=Color3.fromRGB(12,14,18); t.BackgroundTransparency=.08; t.Size=UDim2.fromScale(1,1)
	t.Text=text; t.TextScaled=true; t.TextColor3=Color3.new(1,1,1); t.Font=Enum.Font.GothamBold; t.Parent=gui
end

local function groundModelAt(model,center)
	local cf,size=model:GetBoundingBox()
	local bottom=cf.Position.Y-size.Y/2
	model:PivotTo(model:GetPivot()+Vector3.new(center.X-cf.Position.X,center.Y-bottom,center.Z-cf.Position.Z))
end

local templates=ServerStorage:WaitForChild("PremiumTemplates",30)
local plotsFolder=Workspace:FindFirstChild("Plots") or Instance.new("Folder")
plotsFolder.Name="Plots"; plotsFolder.Parent=Workspace
plotsFolder:ClearAllChildren()

local stages={
	{name="Barracks",price=1000,requires="",template="Barracks",offset=Vector3.new(-85,0,-35),dropValue=25},
	{name="MotorPool",price=3500,requires="Barracks",template="ArmyJeep",offset=Vector3.new(80,0,-25),dropValue=60},
	{name="Helipad",price=9000,requires="MotorPool",template="Helicopter",offset=Vector3.new(75,0,65),dropValue=140},
	{name="Headquarters",price=22000,requires="Helipad",template="MilitaryBase",offset=Vector3.new(0,0,15),dropValue=350},
}

for i,pos in ipairs(BASE_POSITIONS) do
	local plot=Instance.new("Model"); plot.Name="Plot"..i; plot.Parent=plotsFolder; plot:SetAttribute("BaseIndex",i)
	local spawn=Instance.new("SpawnLocation"); spawn.Name="Spawn"; spawn.Anchored=true; spawn.Neutral=true; spawn.Size=Vector3.new(18,2,18); spawn.Position=pos+Vector3.new(0,2,0); spawn.Transparency=1; spawn.Parent=plot
	local collector=makePart(plot,"Collector",Vector3.new(16,1,16),pos+Vector3.new(-25,1,65),Color3.fromRGB(30,220,90),Enum.Material.Neon); label(collector,"COLETAR")
	local buttons=Instance.new("Folder"); buttons.Name="Buttons"; buttons.Parent=plot
	local items=Instance.new("Folder"); items.Name="Items"; items.Parent=plot
	local droppers=Instance.new("Folder"); droppers.Name="Droppers"; droppers.Parent=plot
	for s,stage in ipairs(stages) do
		local button=makePart(buttons,stage.name,Vector3.new(18,1,18),pos+Vector3.new(-55+(s-1)*35,1,70),Color3.fromRGB(35,230,90),Enum.Material.Neon)
		button:SetAttribute("Price",stage.price); button:SetAttribute("Requires",stage.requires); label(button,stage.name.."\n$"..stage.price)
		local item=Instance.new("Model"); item.Name=stage.name; item.Parent=items
		local template=templates and templates:FindFirstChild(stage.template)
		if template then
			local visual=template:Clone(); visual.Name="LicensedVisual"; visual.Parent=item; groundModelAt(visual,pos+stage.offset)
		else
			local marker=makePart(item,"AssetUnavailable",Vector3.new(18,6,18),pos+stage.offset+Vector3.new(0,3,0),Color3.fromRGB(80,80,80)); label(marker,stage.name)
		end
		local dropper=Instance.new("Model"); dropper.Name=stage.name.."Income"; dropper:SetAttribute("Button",stage.name); dropper:SetAttribute("DropRate",.5); dropper:SetAttribute("DropValue",stage.dropValue); dropper.Parent=droppers
		local ds=makePart(dropper,"DropSpawn",Vector3.new(2,2,2),pos+Vector3.new(-25,6,40+s*4),Color3.fromRGB(255,210,0),Enum.Material.Neon); ds.CanCollide=false
	end
end

local tycoon=TycoonKit.new({plotsFolder=plotsFolder})
local profiles={}
local function key(player) return "p_"..player.UserId end
local function loadProfile(player)
	local data={cash=2500,purchases={}}
	local ok,result=pcall(function() return STORE:GetAsync(key(player)) end)
	if ok and type(result)=="table" then data.cash=tonumber(result.cash) or 2500; data.purchases=type(result.purchases)=="table" and result.purchases or {} end
	profiles[player]=data; return data
end
local function saveProfile(player)
	local data=profiles[player]; if not data then return end
	pcall(function() STORE:SetAsync(key(player),data) end)
end

local function syncPlayer(player)
	local plot=tycoon:GetPlot(player); if not plot then return end
	player:SetAttribute("Cash",tycoon:GetCash(player)); player:SetAttribute("BaseIndex",plot.Model:GetAttribute("BaseIndex") or 0)
	player:SetAttribute("Purchases",#tycoon:GetPurchases(player))
end

tycoon.PlotAssigned:Connect(function(player)
	local data=loadProfile(player)
	tycoon:RestorePurchases(player,data.purchases)
	local current=tycoon:GetCash(player); tycoon:AddCash(player,data.cash-current)
	syncPlayer(player)
end)
tycoon.PurchaseMade:Connect(function(player)
	local data=profiles[player] or loadProfile(player); data.cash=tycoon:GetCash(player); data.purchases=tycoon:GetPurchases(player); syncPlayer(player); saveProfile(player)
end)
tycoon.CoinCollected:Connect(function(player)
	local data=profiles[player]; if data then data.cash=tycoon:GetCash(player) end; syncPlayer(player)
end)
Players.PlayerRemoving:Connect(function(player) saveProfile(player); profiles[player]=nil end)
game:BindToClose(function() for _,p in ipairs(Players:GetPlayers()) do saveProfile(p) end end)

task.spawn(function()
	while true do task.wait(1); for _,p in ipairs(Players:GetPlayers()) do syncPlayer(p) end end
end)
