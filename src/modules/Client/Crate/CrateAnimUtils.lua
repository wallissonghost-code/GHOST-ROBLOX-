local require=require(script.Parent.loader).load(script)

local ContentProviderUtils=require("ContentProviderUtils")
local CrateConstants=require("CrateConstants")
local Promise=require("Promise")
local RelicVisualBuilder=require("RelicVisualBuilder")
local SoundUtils=require("SoundUtils")
local TierConstants=require("TierConstants")
local WxTheme=require("WxTheme")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")

local SOUND_PLINK="rbxassetid://3199239518"
local SOUND_FINAL="rbxassetid://2752040675"
local SOUND_TIERS={[1]="",[2]="rbxassetid://3199299018",[3]="rbxassetid://3199299018",[4]="rbxassetid://8068122001"}

local A={}
A.ESTIMATED_TIME_REVEAL=2.25

function A.promisePreload()
	return ContentProviderUtils.promisePreload({
		SoundUtils.createSoundFromId(SOUND_PLINK),
		SoundUtils.createSoundFromId(SOUND_FINAL),
		SoundUtils.createSoundFromId(SOUND_TIERS[2]),
		SoundUtils.createSoundFromId(SOUND_TIERS[4]),
	})
end

local function text(parent,text,size,pos,textSize,color,weight)
	local l=Instance.new("TextLabel")
	l.BackgroundTransparency=1
	l.Size=size
	l.Position=pos
	l.Text=text
	l.TextColor3=color
	l.TextSize=textSize
	l.TextWrapped=true
	l.TextXAlignment=Enum.TextXAlignment.Center
	l.FontFace=Font.fromId(WxTheme.ID_SANS,weight or Enum.FontWeight.Bold)
	l.Parent=parent
	return l
end

function A.animate(parent,targetIndex)
	local promise=Promise.new()
	local data=CrateConstants[targetIndex]
	local tier=TierConstants[data.Tier]

	local overlay=Instance.new("Frame")
	overlay.Name="RelicReveal"
	overlay.AnchorPoint=Vector2.new(0.5,0.5)
	overlay.Position=UDim2.fromScale(0.5,0.5)
	overlay.Size=UDim2.fromScale(1,1)
	overlay.BackgroundColor3=Color3.new(0,0,0)
	overlay.BackgroundTransparency=1
	overlay.Parent=parent

	local card=Instance.new("Frame")
	card.AnchorPoint=Vector2.new(0.5,0.5)
	card.Position=UDim2.fromScale(0.5,0.5)
	card.Size=UDim2.fromOffset(320,390)
	card.BackgroundColor3=Color3.fromRGB(14,16,24)
	card.BackgroundTransparency=1
	card.Parent=overlay
	local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,18);corner.Parent=card
	local stroke=Instance.new("UIStroke");stroke.Color=tier.Color;stroke.Thickness=3;stroke.Transparency=1;stroke.Parent=card
	local scale=Instance.new("UIScale");scale.Scale=0.35;scale.Parent=card

	local glow=Instance.new("Frame")
	glow.AnchorPoint=Vector2.new(0.5,0.5)
	glow.Position=UDim2.fromScale(0.5,0.42)
	glow.Size=UDim2.fromOffset(260,260)
	glow.BackgroundColor3=data.Color
	glow.BackgroundTransparency=0.78
	glow.Parent=card
	local gc=Instance.new("UICorner");gc.CornerRadius=UDim.new(1,0);gc.Parent=glow

	local viewport,model=RelicVisualBuilder.CreateViewport(card,data)
	viewport.AnchorPoint=Vector2.new(0.5,0.5)
	viewport.Position=UDim2.fromScale(0.5,0.42)
	viewport.Size=UDim2.fromOffset(260,260)
	viewport.ZIndex=3

	local title=text(card,data.Name,UDim2.new(1,-20,0,38),UDim2.new(0,10,0,275),25,Color3.new(1,1,1),Enum.FontWeight.Bold)
	title.TextTransparency=1
	local rarity=text(card,tier.Name.."  •  1/"..tostring(data.OneIn),UDim2.new(1,-20,0,28),UDim2.new(0,10,0,317),16,tier.Color,Enum.FontWeight.Bold)
	rarity.TextTransparency=1
	local hint=text(card,"NEW RELIC ACQUIRED",UDim2.new(1,-20,0,22),UDim2.new(0,10,0,350),12,Color3.fromRGB(180,185,205),Enum.FontWeight.SemiBold)
	hint.TextTransparency=1

	local spin=0
	local connection=RunService.RenderStepped:Connect(function(dt)
		spin+=dt*0.95
		if model and model.Parent then model:PivotTo(CFrame.Angles(math.rad(-8),spin,0)) end
	end)

	task.defer(function()
		TweenService:Create(overlay,TweenInfo.new(0.18),{BackgroundTransparency=0.28}):Play()
		TweenService:Create(card,TweenInfo.new(0.38,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{BackgroundTransparency=0.04}):Play()
		TweenService:Create(scale,TweenInfo.new(0.42,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
		TweenService:Create(stroke,TweenInfo.new(0.3),{Transparency=0}):Play()
		local plink=SoundUtils.createSoundFromId(SOUND_PLINK);plink.Parent=card;plink:Play()
		task.wait(0.45)
		TweenService:Create(title,TweenInfo.new(0.2),{TextTransparency=0}):Play()
		TweenService:Create(rarity,TweenInfo.new(0.2),{TextTransparency=0}):Play()
		TweenService:Create(hint,TweenInfo.new(0.2),{TextTransparency=0}):Play()
		SoundUtils.playFromIdInParent({SoundId=SOUND_FINAL,Volume=0.65},card)
		if SOUND_TIERS[data.Tier]~="" then SoundUtils.playFromIdInParent({SoundId=SOUND_TIERS[data.Tier],Volume=0.25},card) end
		task.wait(1.45)
		TweenService:Create(scale,TweenInfo.new(0.22,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Scale=0.1}):Play()
		TweenService:Create(overlay,TweenInfo.new(0.22),{BackgroundTransparency=1}):Play()
		task.wait(0.24)
		connection:Disconnect()
		overlay:Destroy()
		promise:Resolve()
	end)

	return promise
end

return A
