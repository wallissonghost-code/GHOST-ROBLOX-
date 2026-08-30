local require=require(script.Parent.loader).load(script)
local BasicPane=require("BasicPane")
local BasicPaneUtils=require("BasicPaneUtils")
local Blend=require("Blend")
local CrateConstants=require("CrateConstants")
local RelicVisualBuilder=require("RelicVisualBuilder")
local Rx=require("Rx")
local RxBrioUtils=require("RxBrioUtils")
local Signal=require("Signal")
local TierConstants=require("TierConstants")
local WxPane=require("WxPane")
local WxTheme=require("WxTheme")

local V=setmetatable({},BasicPane)
V.ClassName="CrateInventoryView"
V.__index=V

local P=8
local ACROSS=4
local W=126
local H=174
local VIEW_H=104
local GRID=ACROSS*W+(ACROSS-1)*P

function V.new(model)
	local self=setmetatable(BasicPane.new(),V)
	self._model=model
	self.OnClose=self._maid:Add(Signal.new())
	self._maid:GiveTask(self:_render():Subscribe(function(g)self.Gui=g end))
	return self
end

local function label(parent,text,pos,size,textSize,color,fontWeight)
	local l=Instance.new("TextLabel")
	l.BackgroundTransparency=1
	l.Position=pos
	l.Size=size
	l.Text=text
	l.TextColor3=color
	l.TextSize=textSize
	l.TextWrapped=true
	l.TextXAlignment=Enum.TextXAlignment.Center
	l.FontFace=Font.fromId(WxTheme.ID_SANS,fontWeight or Enum.FontWeight.Medium)
	l.Parent=parent
	return l
end

local function renderRelic(index,count)
	index=tonumber(index)
	local data=CrateConstants[index]
	if not data then return Instance.new("Frame") end
	local tier=TierConstants[data.Tier]

	local card=Instance.new("Frame")
	card.Name=tostring(index)
	card.LayoutOrder=-data.OneIn
	card.BackgroundColor3=WxTheme.BG
	local corner=Instance.new("UICorner")
	corner.CornerRadius=UDim.new(0,9)
	corner.Parent=card
	local stroke=Instance.new("UIStroke")
	stroke.Color=tier.Color
	stroke.Thickness=2
	stroke.Transparency=0.15
	stroke.Parent=card

	local preview=Instance.new("Frame")
	preview.Size=UDim2.new(1,-10,0,VIEW_H)
	preview.Position=UDim2.fromOffset(5,5)
	preview.BackgroundColor3=Color3.fromRGB(11,12,18)
	preview.ClipsDescendants=true
	preview.Parent=card
	local pc=Instance.new("UICorner")
	pc.CornerRadius=UDim.new(0,7)
	pc.Parent=preview

	local viewport,model=RelicVisualBuilder.CreateViewport(preview,data)
	viewport.Size=UDim2.fromScale(1,1)
	viewport.Position=UDim2.fromScale(0,0)
	model:PivotTo(CFrame.Angles(math.rad(-8),math.rad(18),0))

	label(card,data.Name,UDim2.fromOffset(5,112),UDim2.new(1,-10,0,28),12,WxTheme.TEXT,Enum.FontWeight.Bold)
	label(card,tier.Name.." • 1/"..tostring(data.OneIn),UDim2.fromOffset(5,140),UDim2.new(1,-10,0,16),10,tier.Color,Enum.FontWeight.SemiBold)
	label(card,"x"..tostring(count),UDim2.new(1,-40,0,8),UDim2.fromOffset(32,18),11,Color3.new(1,1,1),Enum.FontWeight.Bold)

	return card
end

function V:_render()
	return WxPane.render({
		Title="RELIC COLLECTION",
		ClipsDescendants=true,
		Size=UDim2.fromOffset(GRID,430),
		OnClose=self.OnClose,
		Visible=BasicPaneUtils.observeVisible(self),
		Blend.New("ScrollingFrame")({
			Size=UDim2.new(1,24,1,0),
			BackgroundTransparency=1,
			ScrollingDirection=Enum.ScrollingDirection.Y,
			ScrollBarThickness=10,
			BorderSizePixel=0,
			ScrollBarImageColor3=WxTheme.PRIMARY_B,
			CanvasSize=self._model:ObserveCount():Pipe({Rx.map(function(count)
				local rows=(count+ACROSS-1)//ACROSS
				return UDim2.fromOffset(GRID,math.max(H,rows*H+(rows-1)*P))
			end)}),
			Blend.New("UIGridLayout")({CellSize=UDim2.fromOffset(W,H),CellPadding=UDim2.fromOffset(P,P),SortOrder=Enum.SortOrder.LayoutOrder}),
			self._model:ObservePairsBrio():Pipe({RxBrioUtils.map(renderRelic)})
		})
	})
end

return V
