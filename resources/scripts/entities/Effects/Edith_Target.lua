local mod = edithMod
local enums = mod.Enums
local utils = enums.Utils
local tables = enums.Tables
local game = utils.Game
local misc = enums.Misc
local saveManager = mod.SaveManager
local Hsx = edithMod.Hsx

local funcs = {
	IsEdith = mod.IsEdith,
	SetVector = mod.SetVector,
	GetData = mod.GetData,
	DrawLine = mod.drawLine,
	MenuData = saveManager.GetDeadSeaScrollsSave,
	RGBCycle = mod.RGBCycle,
	Switch = mod.When,
	HSVToRGB = Hsx.hsv2rgb,
	RGBToHSV = Hsx.rgb2hsv,
}

local function interpolateVector2D(vectorA, vectorB, t)
    local Interpolated = {
        X = (1 - t) * vectorA.X + t * vectorB.X,
        Y = (1 - t) * vectorA.Y + t * vectorB.Y,
    }
    return Vector(Interpolated.X, Interpolated.Y)
end

local DungeonVector = Vector.Zero

local teleportPoints = {
	{X = 110, Y = 135},
	{X = 595, Y = 385},
	{X = 595, Y = 272},
}

function mod:EdithTargetLogic(effect)	
	local player = effect.SpawnerEntity:ToPlayer()
	if player.ControlsEnabled == false then return end
		
	effect.Velocity = effect.Velocity * 0.6
	effect.DepthOffset = -100
	effect.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
	
	local playerPos = player.Position
	local effectPos = effect.Position
	local playerData = funcs.GetData(player)
	local targetSprite = effect:GetSprite()
	local room = game:GetRoom()

	if edithMod.IsKeyStompPressed(player) or playerData.ExtraJumps > 0 and playerData.EdithJumpTimer == 0 then
		targetSprite:Play("Blink")
	end
	
	if targetSprite:GetAnimation() == "Blink" then
		effect.Velocity = effect.Velocity * 0.3
	end

	local cameraPos = interpolateVector2D(playerPos, effectPos, 0.6)
	local Camera = room:GetCamera()
	Camera:SetFocusPosition(cameraPos)
	
	local markedTarget = player:GetMarkedTarget()
	if markedTarget then
		markedTarget.Position = effect.Position
		markedTarget.Velocity = Vector.Zero
		markedTarget.Visible = false
	end
	
	if room:GetType() == RoomType.ROOM_DUNGEON then
		for _, v in ipairs(teleportPoints) do
			edithMod.SetVector(DungeonVector, v.X, v.Y)
			
			if (effectPos - DungeonVector):Length() <= 20 then
				player.Position = effectPos + effect.Velocity:Normalized():Resized(25)
				break
			end
		end
	end
	
	edithMod:TargetDoorManager(effect, player, 25)
end 
edithMod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.EdithTargetLogic, edithMod.Enums.EffectVariant.EFFECT_EDITH_TARGET)

local value = 0

local function RGBFunction(color, step)
	local newColor = color

	value = value + step

	newColor.R, newColor.B, newColor.G = funcs.RGBToHSV(newColor.R, newColor.B, newColor.G)
	newColor.R = newColor.R - step
	newColor.R, newColor.B, newColor.G = funcs.HSVToRGB(newColor.R, newColor.B, newColor.G)

	color = newColor
end

function mod:EdithTargetSprite(effect)
	local room = game:GetRoom()	
	if room:GetRenderMode() == RenderMode.RENDER_WATER_REFLECT then return false end
	
    local player = effect.SpawnerEntity:ToPlayer()
    if not player then return end
	if not funcs.IsEdith(player, false) then return end
	if not saveManager:IsLoaded() then return end
	local saveData = funcs.MenuData()

	if not saveData then return end
	local edithData = saveData.EdithData
	local targetColor = edithData.TargetColor
	local RGBmode = edithData.RGBMode
	local RGBspeed = edithData.RGBSpeed
	local targetSpace = edithData.linespace
	local targetDesign = edithData.targetdesign
	local targetLine = edithData.targetline
	local effectColor = effect.Color
	local effectSprite = effect:GetSprite()

	local color = Color.Default

	if targetDesign == 1 then
		if RGBmode then
			color = misc.HSVStartColor
			RGBFunction(color, RGBspeed)
		else
			color = Color(targetColor.Red, targetColor.Green, targetColor.Blue)
		end
	end

	print(RGBspeed)

	-- effect.Color = Color(1, 0, 0)

	-- local color = effect.Color 

	-- RGBFunction(color, 0.0)
	

	-- print(color)

	-- local color = (targetDesign == 1 and 
	-- 	(RGBmode and funcs.RGBCycle(RGBspeed) or Color(targetColor.Red, targetColor.Green, targetColor.Blue)) 
	-- ) or Color.Default

	effect:SetColor(color, -1, 100, false, false)
	effectSprite:ReplaceSpritesheet(0, misc.TargetPath .. tables.TargetSuffix[targetDesign] .. ".png", true)
		
	if targetLine ~= true then return end
	local targetlineColor = misc.TargetLineColor
	local animation = effectSprite:GetAnimation()
	local frame = effectSprite:GetFrame()
	local isObscure = frame >= funcs.Switch(animation, tables.FrameLimits, 0)	
	
	if targetDesign == 1 then
		targetlineColor = effectColor
	else
		targetlineColor.R = tables.ColorValues[targetDesign].R
		targetlineColor.G = tables.ColorValues[targetDesign].G
		targetlineColor.B = tables.ColorValues[targetDesign].B
	end

	if isObscure then
		local newObcureColor = targetlineColor
		newObcureColor.R = newObcureColor.R * misc.ObscureDiv
		newObcureColor.G = newObcureColor.G * misc.ObscureDiv
		newObcureColor.B = newObcureColor.B * misc.ObscureDiv
		
		targetlineColor = newObcureColor
	end
	funcs.DrawLine(player.Position, effect.Position, targetlineColor, targetSpace) 
end
edithMod:AddCallback(ModCallbacks.MC_PRE_EFFECT_RENDER, mod.EdithTargetSprite,edithMod.Enums.EffectVariant.EFFECT_EDITH_TARGET)
