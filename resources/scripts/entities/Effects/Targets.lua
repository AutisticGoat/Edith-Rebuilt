local mod = EdithRebuilt
local enums = mod.Enums
local Vars = enums.EffectVariant 
local game = enums.Utils.Game
local level = enums.Utils.Level
local misc = enums.Misc
local tables = enums.Tables
local Hsx = mod.Hsx
local defColor = Color.Default
local RGBColors = { Target = Color(1, 0, 0), Arrow = Color(1, 0, 0) }
local modules = mod.Modules
local Edith = modules.EDITH
local TEdith = modules.TEDITH
local Helpers = modules.HELPERS
local targetArrow = modules.TARGET_ARROW
local data = mod.DataHolder.GetEntityData

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

	color.R, color.G, color.B = Hsx.rgb2hsv(color.R, color.G, color.B)
	color.R = color.R + step
	color.R, color.G, color.B = Hsx.hsv2rgb(color.R, color.G, color.B)
end

local targetSprite = Sprite("gfx/edith rebuilt target.anm2", true)

---Draws a line between from `from` position to `to` position
---@param from Vector
---@param to Vector
---@param color Color
---@param isObscure? boolean
local function drawLine(from, to, color, isObscure)
	local diffVector = to - from
	local angle = diffVector:GetAngleDegrees()
	local sectionCount = math.floor(diffVector:Length() / 16) - 1
	local direction = Vector.FromAngle(angle)

	targetSprite:SetFrame("Line", isObscure and 1 or 0)
	targetSprite.Color = color
	targetSprite.Rotation = angle

	local currentPos
	for i = 0, sectionCount do
		currentPos = from + direction * (i * 16)
		targetSprite:Render(Isaac.WorldToScreen(currentPos))
	end
end

---@param effect EntityEffect
---@param player EntityPlayer
local function EdithTargetManagement(effect, player)
	if effect.Variant ~= Vars.EFFECT_EDITH_TARGET then return end

	local playerPos = player.Position
	local effectPos = effect.Position
	local room = game:GetRoom()
	local params = Edith.GetJumpStompParams(player)
	local RoomName = level:GetCurrentRoomDesc().Data.Name

	local anim = (Helpers.IsKeyStompPressed(player) or Edith.IsJumping(player) and params.Cooldown == 0) and "Blink" or "Idle" 
	effect:GetSprite():Play(anim)

	room:GetCamera():SetFocusPosition(interpolateVector2D(playerPos, effectPos, 0.6))

	if Helpers.IsVestigeChallenge() and JumpLib:GetData(player).Jumping then
		effect.Velocity = effect.Velocity * 0.6
	end

	if room:GetType() == RoomType.ROOM_DUNGEON then
		for _, v in pairs(teleportPoints) do
			if (effectPos - v):Length() > 20 then goto continue end
			if RoomName == "Beast Room" then goto continue end
			if RoomName == "Rotgut Maggot" and (v.X ~= 595 and v.Y ~= 385) then goto continue end
			player.Position = effectPos + effect.Velocity:Normalized():Resized(25)
		    ::continue::
		end
	end

	local markedTarget = player:GetMarkedTarget()
	if not markedTarget then return end

	markedTarget.Position = effect.Position
	markedTarget.Velocity = Vector.Zero
	markedTarget.Visible = false
end

mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, function (_, npc)
	if npc.Variant ~= 1 then return end
	local capsule = npc:GetCollisionCapsule()

	for _, ent in ipairs(Isaac.FindInCapsule(capsule, EntityPartition.EFFECT)) do
		if ent.Variant ~= Vars.EFFECT_EDITH_TARGET then goto continue end		
		local player = ent.SpawnerEntity:ToPlayer()
		if not player then goto continue end
		ent.Velocity = (player.Position - npc.Position):Resized(20)
		::continue::
	end
end, EntityType.ENTITY_ROTGUT)

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
	local effectData = data(effect)

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
	local isObscure = effectSprite:GetFrame() >= Helpers.When(effectSprite:GetAnimation(), tables.FrameLimits, 0)	
	local lineColor = Helpers.When(targetDesign, tables.TargetLineColorValues, color)
	targetlineColor:SetColorize(lineColor.R, lineColor.G, lineColor.B, 1)

	drawLine(player.Position, effect.Position, targetlineColor, isObscure) 
end

---@param effect EntityEffect
---@param player EntityPlayer
---@param saveData TEdithData
local function TaintedEdithArrowRender(effect, player, saveData)
	local effectData = data(effect)
	effectData.RGBState = effectData.RGBState or 0
	effect.Visible = effect.FrameCount > 1

	if saveData.ArrowDesign ~= 2 or Helpers.IsGrudgeChallenge() then
		effect:GetSprite().Rotation = TEdith.GetHopParryParams(player).HopDirection:GetAngleDegrees() 
	end

	if saveData.RGBMode then
		RGBFunction(RGBColors.Arrow, saveData.RGBSpeed, effectData.RGBState)
		Helpers.ChangeColor(effect, RGBColors.Arrow.R, RGBColors.Arrow.G, RGBColors.Arrow.B)
	else
		local color = saveData.ArrowColor
		Helpers.ChangeColor(effect, color.Red, color.Green, color.Blue)
	end
end

---@param effect EntityEffect
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, effect)
	if not IsAnyEdithTarget(effect) then return end
	local player = effect.SpawnerEntity:ToPlayer()
	local radius = effect.Variant == Vars.EFFECT_EDITH_TARGET and 28 or 20

    if not player then return end
	targetArrow.TargetDoorManager(effect, player, radius)
    EdithTargetManagement(effect, player)
end)

---@param effect EntityEffect
mod:AddCallback(ModCallbacks.MC_PRE_EFFECT_RENDER, function(_, effect)
	if game:GetRoom():GetRenderMode() == RenderMode.RENDER_WATER_REFLECT then return false end
	if not IsAnyEdithTarget(effect) then return end

	local player = effect.SpawnerEntity:ToPlayer()

    if not player then return end
	local isTarget = effect.Variant == Vars.EFFECT_EDITH_TARGET
	local dataType = isTarget and enums.ConfigDataTypes.EDITH or enums.ConfigDataTypes.TEDITH
	local data = Helpers.GetConfigData(dataType) ---@cast data EdithData|TEdithData	
	local func = isTarget and EdithTargetRender or TaintedEdithArrowRender
	
	func(effect, player, data)
end)

---@param effect EntityEffect
function mod:Mierda(effect)
	local isTarget = effect.Variant == Vars.EFFECT_EDITH_TARGET
	local MenuSprite = isTarget and Helpers.GetConfigData("EdithData").TargetDesign or Helpers.GetConfigData("TEdithData").ArrowDesign
	local TargetTable = isTarget and tables.TargetSuffix or tables.ArrowSuffix
	local path = isTarget and misc.TargetPath or misc.ArrowPath
	effect:GetSprite():ReplaceSpritesheet(0, path .. Helpers.When(MenuSprite, TargetTable, "") .. ".png", true)
end
mod:AddCallback(enums.Callbacks.TARGET_SPRITE_CHANGE, mod.Mierda)