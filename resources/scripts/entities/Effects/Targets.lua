local mod = EdithRebuilt
local enums = mod.Enums
local Vars = enums.EffectVariant 
local game = enums.Utils.Game
local misc = enums.Misc
local saveManager = mod.SaveManager
local tables = enums.Tables
local Hsx = mod.Hsx
local defColor = Color.Default
local RGBColors = { Target = Color(1, 0, 0), Arrow = Color(1, 0, 0) }

local funcs = {
	GetData = mod.CustomDataWrapper.getData,
	DrawLine = mod.drawLine,
	MenuData = saveManager.GetSettingsSave,
	Switch = mod.When,
	HSVToRGB = Hsx.hsv2rgb,
	RGBToHSV = Hsx.rgb2hsv,
}

local teleportPoints = {
	Vector(110, 135),
	Vector(595, 385),
	Vector(595, 272),
}

---@param effect EntityEffect
local function IsAnyEdithTarget(effect)
    local var = effect.Variant
    return var == Vars.EFFECT_EDITH_TARGET or var == Vars.EFFECT_EDITH_B_TARGET
end

local function interpolateVector2D(vectorA, vectorB, t)
	local minT = (1 - t)
    return Vector(minT * vectorA.X + t * vectorB.X, minT * vectorA.Y + t * vectorB.Y)
end

---@param color Color
---@param step number
local function RGBFunction(color, step, value)
	value = value + step

	if value > 1 then value = 0 end

	color.R, color.G, color.B = funcs.RGBToHSV(color.R, color.G, color.B)
	color.R = color.R + step
	color.R, color.G, color.B = funcs.HSVToRGB(color.R, color.G, color.B)
end

---@param effect EntityEffect
---@param player EntityPlayer
local function EdithTargetManagement(effect, player)
	if effect.Variant ~= Vars.EFFECT_EDITH_TARGET then return end

	local playerPos = player.Position
	local effectPos = effect.Position
	local playerData = funcs.GetData(player)
	local room = game:GetRoom()

	if mod.IsKeyStompPressed(player) or playerData.ExtraJumps > 0 and playerData.EdithJumpTimer == 0 then
		effect:GetSprite():Play("Blink")
	end

	room:GetCamera():SetFocusPosition(interpolateVector2D(playerPos, effectPos, 0.6))

	if room:GetType() == RoomType.ROOM_DUNGEON then
		for _, v in pairs(teleportPoints) do
			if (effectPos - v):Length() > 20 then break end
			player.Position = effectPos + effect.Velocity:Normalized():Resized(25)
		end
	end

	local markedTarget = player:GetMarkedTarget()
	if not markedTarget then return end

	markedTarget.Position = effect.Position
	markedTarget.Velocity = Vector.Zero
	markedTarget.Visible = false
end

local currentDate = os.date("*t") -- converts the current date to a table
local isTDOV = (currentDate.month == 3 and currentDate.day == 31)

---@param effect EntityEffect
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, function (_, effect)
	if not IsAnyEdithTarget(effect) then return end
	Isaac.RunCallback(mod.Enums.Callbacks.TARGET_SPRITE_CHANGE, effect)
end)

---@param effect EntityEffect
---@param player EntityPlayer
---@param saveData EdithData
local function EdithTargetRender(effect, player, saveData)
	local targetColor = saveData.TargetColor
	local targetDesign = saveData.TargetDesign
	local effectSprite = effect:GetSprite()
	local color = effect.Color
	local IsRGB = saveData.RGBMode
	local effectData = funcs.GetData(effect)

	effectData.RGBState = effectData.RGBState or 0

	if IsRGB then
		RGBFunction(RGBColors.Target, saveData.RGBSpeed, effectData.RGBState)
	else
		color:SetTint(targetColor.Red, targetColor.Green, targetColor.Blue, 1)
	end

	local newColor = not isTDOV and ((targetDesign == 1 and (IsRGB and RGBColors.Target or color) or defColor)) or defColor
	effect:SetColor(newColor, -1, 100, false, false)

	if not saveData.TargetLine then return end
	local targetlineColor = misc.TargetLineColor
	local isObscure = effectSprite:GetFrame() >= funcs.Switch(effectSprite:GetAnimation(), tables.FrameLimits, 0)	
	local lineColor = funcs.Switch(targetDesign, tables.TargetLineColorValues, color)
	targetlineColor:SetColorize(lineColor.R, lineColor.G, lineColor.B, 1)

	funcs.DrawLine(player.Position, effect.Position, targetlineColor, isObscure) 
end

---@param effect EntityEffect
---@param player EntityPlayer
---@param saveData TEdithData
local function TaintedEdithArrowRender(effect, player, saveData)
	local effectData = funcs.GetData(effect)
	effectData.RGBState = effectData.RGBState or 0
	effect.Visible = effect.FrameCount > 1

	if saveData.ArrowDesign ~= 7 then
		effect:GetSprite().Rotation = funcs.GetData(player).HopVector:GetAngleDegrees() 
	end

	if saveData.RGBMode then
		RGBFunction(RGBColors.Arrow, saveData.RGBSpeed, effectData.RGBState)
		mod:ChangeColor(effect, RGBColors.Arrow.R, RGBColors.Arrow.G, RGBColors.Arrow.B)
	else
		local color = saveData.ArrowColor
		mod:ChangeColor(effect, color.Red, color.Green, color.Blue)
	end
end

---@param effect EntityEffect
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, effect)
	if not IsAnyEdithTarget(effect) then return end
	local player = effect.SpawnerEntity:ToPlayer()

    if not player then return end
	mod:TargetDoorManager(effect, player, effect.Variant == Vars.EFFECT_EDITH_TARGET and 28 or 20)
    EdithTargetManagement(effect, player)
end)

---@param effect EntityEffect
mod:AddCallback(ModCallbacks.MC_PRE_EFFECT_RENDER, function(_, effect)
	if game:GetRoom():GetRenderMode() == RenderMode.RENDER_WATER_REFLECT then return false end
	if not IsAnyEdithTarget(effect) then return end
	if not saveManager:IsLoaded() then return end

	local saveData = funcs.MenuData()
	if not saveData then return end
	local player = effect.SpawnerEntity:ToPlayer()

    if not player then return end
	local isTarget = effect.Variant == Vars.EFFECT_EDITH_TARGET
	local data = isTarget and saveData.EdithData --[[@as EdithData]] or saveData.TEdithData --[[@as TEdithData]]
	local func = isTarget and EdithTargetRender or TaintedEdithArrowRender
	
	func(effect, player, data)
end)

---@param effect EntityEffect
function mod:Mierda(effect)
	local isTarget = effect.Variant == Vars.EFFECT_EDITH_TARGET
	local MenuSprite = isTarget and mod.GetConfigData("EdithData").TargetDesign or mod.GetConfigData("TEdithData").ArrowDesign
	local TargetTable = isTarget and tables.TargetSuffix or tables.ArrowSuffix
	local path = isTarget and misc.TargetPath or misc.ArrowPath

	effect:GetSprite():ReplaceSpritesheet(0, path .. mod.When(MenuSprite, TargetTable, "") .. ".png", true)
end
mod:AddCallback(enums.Callbacks.TARGET_SPRITE_CHANGE, mod.Mierda)