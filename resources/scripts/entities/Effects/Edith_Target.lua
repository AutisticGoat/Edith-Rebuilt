local mod = EdithRebuilt
local enums = mod.Enums
local utils = enums.Utils
local tables = enums.Tables
local game = utils.Game
local misc = enums.Misc
local saveManager = mod.SaveManager
local Hsx = mod.Hsx
local effect = enums.EffectVariant
local callbacks = enums.Callbacks
local Target = {}

local funcs = {
	IsEdith = mod.IsEdith,
	SetVector = mod.SetVector,
	GetData = mod.CustomDataWrapper.getData,
	DrawLine = mod.drawLine,
	MenuData = saveManager.GetSettingsSave,
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

local teleportPoints = {
	{X = 110, Y = 135},
	{X = 595, Y = 385},
	{X = 595, Y = 272},
}

---@param effect EntityEffect
function Target:EdithTargetLogic(effect)	
	local player = effect.SpawnerEntity:ToPlayer()
	if not player then return end

	if player.ControlsEnabled == false then return end
		
	local playerPos = player.Position
	local effectPos = effect.Position
	local playerData = funcs.GetData(player)
	local targetSprite = effect:GetSprite()
	local room = game:GetRoom()

	if mod.IsKeyStompPressed(player) or playerData.ExtraJumps > 0 and playerData.EdithJumpTimer == 0 then
		targetSprite:Play("Blink")
	end
	
	local cameraPos = interpolateVector2D(playerPos, effectPos, 0.6)
	local Camera = room:GetCamera()
	Camera:SetFocusPosition(cameraPos)
	
	if room:GetType() == RoomType.ROOM_DUNGEON then
		for _, v in ipairs(teleportPoints) do
			local DungeonVector = Vector(v.X, v.Y)
			if (effectPos - DungeonVector):Length() > 20 then goto Break end
			player.Position = effectPos + effect.Velocity:Normalized():Resized(25)
			break
			::Break::
		end
	end

	mod:TargetDoorManager(effect, player, 25)
	
	local markedTarget = player:GetMarkedTarget()
	if not markedTarget then return end

	markedTarget.Position = effect.Position
	markedTarget.Velocity = Vector.Zero
	markedTarget.Visible = false
end 
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, Target.EdithTargetLogic, effect.EFFECT_EDITH_TARGET)

local value = 0

---@param color Color
---@param step number
local function RGBFunction(color, step)
	value = value + step

	color.R, color.G, color.B = funcs.RGBToHSV(color.R, color.G, color.B)
	color.R = color.R + step
	color.R, color.G, color.B = funcs.HSVToRGB(color.R, color.G, color.B)
end

local currentDate = os.date("*t") -- converts the current date to a table
local isTDOV = (currentDate.month == 3 and currentDate.day == 31)

---@param effect EntityEffect
---@return boolean?
function Target:EdithTargetSprite(effect)
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
	local targetDesign = edithData.targetdesign
	local targetLine = edithData.targetline
	local effectColor = effect.Color
	local effectSprite = effect:GetSprite()

	local color = misc.HSVStartColor

	if targetDesign == 1 then
		if RGBmode then
			RGBFunction(color, RGBspeed)
		else
			color:SetTint(targetColor.Red, targetColor.Green, targetColor.Blue, 1)
		end
	else
		color = Color.Default
	end

	-- print(color)

	effect:SetColor(color, -1, 100, false, false)
	effectSprite:ReplaceSpritesheet(0, misc.TargetPath .. tables.TargetSuffix[targetDesign] .. ".png", true)
		
	if isTDOV then
		effectSprite:ReplaceSpritesheet(0, misc.TargetPath .. tables.TargetSuffix[2] .. ".png", true)
		effect.Color = Color.Default
	end

	if targetLine ~= true then return end
	local targetlineColor = misc.TargetLineColor
	local animation = effectSprite:GetAnimation()
	local frame = effectSprite:GetFrame()
	local isObscure = frame >= funcs.Switch(animation, tables.FrameLimits, 0)	

	if targetDesign == 1 then
		targetlineColor = effectColor
	else
		local lineColor = funcs.Switch(targetDesign, tables.ColorValues, 1)
		targetlineColor:SetColorize(lineColor.R, lineColor.G, lineColor.B, 1)
	end

	if isTDOV then
		local tableColor = tables.ColorValues[2]
		targetlineColor:SetColorize(tableColor.R, tableColor.G, tableColor.B, 1)
	end

	if isObscure then
		targetlineColor = targetlineColor * misc.Obscurecolor
	end
	funcs.DrawLine(player.Position, effect.Position, targetlineColor) 
end
mod:AddCallback(ModCallbacks.MC_PRE_EFFECT_RENDER, Target.EdithTargetSprite, effect.EFFECT_EDITH_TARGET)