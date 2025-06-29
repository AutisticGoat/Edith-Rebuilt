local mod = EdithRebuilt
local enums = mod.Enums
local game = enums.Utils.Game
local tables = enums.Tables
local misc = enums.Misc
local saveManager = mod.SaveManager
local Hsx = mod.Hsx
local effect = enums.EffectVariant
local div = 155/255 
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
	room:GetCamera():SetFocusPosition(cameraPos)
	
	if room:GetType() == RoomType.ROOM_DUNGEON then
		for _, v in ipairs(teleportPoints) do
			local DungeonVector = Vector(v.X, v.Y)
			if (effectPos - DungeonVector):Length() > 20 then break end
			player.Position = effectPos + effect.Velocity:Normalized():Resized(25)
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

	if value > 1 then value = 0 end

	color.R, color.G, color.B = funcs.RGBToHSV(color.R, color.G, color.B)
	color.R = color.R + step
	color.R, color.G, color.B = funcs.HSVToRGB(color.R, color.G, color.B)
end

local currentDate = os.date("*t") -- converts the current date to a table
local isTDOV = (currentDate.month == 3 and currentDate.day == 31)

local HSVStartColor = Color(1, 0, 0)
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
	local targetLine = edithData.targetline
	local effectColor = effect.Color
	local effectSprite = effect:GetSprite()
	local targetDesign = edithData.targetdesign
	local color = effectColor

	if targetDesign == 1 then
		if RGBmode then
			RGBFunction(HSVStartColor, RGBspeed)
			effect:SetColor(HSVStartColor, -1, 100, false, false)
		else
			color:SetTint(targetColor.Red, targetColor.Green, targetColor.Blue, 1)
			effect:SetColor(color, -1, 100, false, false)
		end
	else
		color = Color.Default
		effect:SetColor(color, -1, 100, false, false)
	end

	if isTDOV then
		color = Color.Default
	end

	if not targetLine then return end
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

	funcs.DrawLine(player.Position, effect.Position, targetlineColor, isObscure) 
end
mod:AddCallback(ModCallbacks.MC_PRE_EFFECT_RENDER, Target.EdithTargetSprite, effect.EFFECT_EDITH_TARGET)

---@param effect EntityEffect
function mod:Mierda(effect)
	if not saveManager:IsLoaded() then return end
	local saveData = funcs.MenuData()

	if not saveData then return end
	local edithData = saveData.EdithData
	local effectSprite = effect:GetSprite()
	local targetDesign = edithData.targetdesign
	local suffix = funcs.Switch(targetDesign, tables.TargetSuffix, "")
	local path = misc.TargetPath .. suffix .. ".png"
	
	effectSprite:ReplaceSpritesheet(0, path, true)
end
mod:AddCallback(enums.Callbacks.TARGET_SPRITE_CHANGE, mod.Mierda)