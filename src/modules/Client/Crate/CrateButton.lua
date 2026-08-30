local require=require(script.Parent.loader).load(script)
local BasicPane=require("BasicPane"); local BasicPaneUtils=require("BasicPaneUtils"); local Blend=require("Blend"); local Rx=require("Rx"); local SoundUtils=require("SoundUtils"); local TextServiceUtils=require("TextServiceUtils"); local WxTheme=require("WxTheme")
local CrateButton=setmetatable({},BasicPane); CrateButton.ClassName="CrateButton"; CrateButton.__index=CrateButton
function CrateButton.new(obj)
 local self=setmetatable(BasicPane.new(obj),CrateButton); self._maid:GiveTask(self:_render():Subscribe(function(gui) self.Gui=gui end)); self.Activated=self.Gui.Activated; local sound=SoundUtils.createSoundFromId(9113878560); self.Activated:Connect(function() sound:Play() end); sound.Parent=self.Gui; return self
end
function CrateButton:_render()
 local props={Text="UNBOX!",TextColor3=WxTheme.TEXT,TextSize=16,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,FontFace=Font.fromId(WxTheme.ID_SANS,Enum.FontWeight.SemiBold)}
 local desired=TextServiceUtils.observeSizeForLabelProps(props):Pipe({Rx.map(function(s)return Vector3.new(s.X+32,s.Y+16) end),Rx.defaultsTo(Vector3.new(0,32))})
 local anim=Blend.Computed(BasicPaneUtils.observeVisible(self),desired,function(vis,s)return vis and s or Vector3.new(0,s.Y) end)
 local spring=Blend.Spring(anim,25,.7):Pipe({Rx.map(function(s)return UDim2.fromOffset(math.round(s.X/2)*2,math.round(s.Y)) end)})
 return Blend.New("ImageButton")({ClipsDescendants=true,Image=WxTheme.PATTERN_STRIPE,BackgroundColor3=WxTheme.BG,ImageColor3=WxTheme.BG_MID,ScaleType=Enum.ScaleType.Tile,TileSize=UDim2.fromOffset(32,32),Visible=spring:Pipe({Rx.map(function(s)return s.X.Offset>8 end)}),Size=spring,Blend.New("UICorner")({CornerRadius=UDim.new(0,4)}),Blend.New("UIStroke")({Thickness=2,Color=WxTheme.TEXT}),Blend.New("TextLabel")(props)})
end
return CrateButton
