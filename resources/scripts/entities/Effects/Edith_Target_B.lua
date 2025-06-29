local mod = EdithRebuilt
local enums = mod.Enums
local utils = enums.Utils
local game = utils.Game
local effectVar = enums.EffectVariant
local tables = enums.Tables
local misc = enums.Misc
local saveManager = mod.SaveManager
local Hsx = mod.Hsx
local Arrow = {}

local arrowPath = "gfx/effects/TaintedEdithArrow/effect_000_tainted_edith"

local funcs = {
	IsEdith = mod.IsEdith,
	SetVector = mod.SetVector,
	GetData = mod.CustomDataWrapper.getData,
	MenuData = saveManager.GetSettingsSave,
	RGBCycle = mod.RGBCycle,
	Switch = mod.When,
	HSVToRGB = Hsx.hsv2rgb,
	RGBToHSV = Hsx.rgb2hsv,
}

local value = 0

local function RGBFunction(color, step)
	local newColor = color
	value = value + step

	newColor.R, newColor.B, newColor.G = funcs.RGBToHSV(newColor.R, newColor.B, newColor.G)
	newColor.R = newColor.R - step
	newColor.R, newColor.B, newColor.G = funcs.HSVToRGB(newColor.R, newColor.B, newColor.G)

	color = newColor
end

local HSVStartColor = Color(1, 0, 0)

function Arrow:RenderTaintedEdithArrow(effect)
	local room = game:GetRoom()
	local rendermode = room:GetRenderMode()
	
	if rendermode == RenderMode.RENDER_WATER_REFLECT then return false end
	local saveData = saveManager.GetSettingsSave()

	if not saveData then return end
	local player = effect.SpawnerEntity:ToPlayer()

	if not player then return end

	local effectSprite = effect:GetSprite()
	local tEdithdata = saveData.TEdithData
	local arrowColor = tEdithdata.ArrowColor
	local arrowDesign = tEdithdata.ArrowDesign
	local RGBmode = tEdithdata.RGBMode
	local RGBspeed = tEdithdata.RGBSpeed
	local playerData = funcs.GetData(player)
	local HopVec = playerData.HopVector
	local color = HSVStartColor

	effectSprite:SetFrame("Idle", 1)
	
	effect.Visible = effect.FrameCount > 1
	effectSprite.Rotation = arrowDesign ~= 7 and HopVec:GetAngleDegrees() or 0 

	if RGBmode then
		RGBFunction(color, RGBspeed)
		mod:ChangeColor(effect, color.R, color.G, color.B)
	else
		mod:ChangeColor(effect, arrowColor.Red, arrowColor.Green, arrowColor.Blue)
	end

	effectSprite:ReplaceSpritesheet(0, arrowPath .. tables.ArrowSuffix[arrowDesign] .. ".png", true)
end
mod:AddCallback(ModCallbacks.MC_PRE_EFFECT_RENDER, Arrow.RenderTaintedEdithArrow, effectVar.EFFECT_EDITH_B_TARGET)

function Arrow:taintedArrowUpdate(effect)
	local player = effect.SpawnerEntity:ToPlayer()

	if not player then return end
	mod:TargetDoorManager(effect, player, 20)
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, Arrow.taintedArrowUpdate, effectVar.EFFECT_EDITH_B_TARGET)

function Arrow:ReplaceArrowSprite(effect)
	local saveData = saveManager.GetSettingsSave()

	if not saveData then return end

	local effectSprite = effect:GetSprite()
	local tEdithdata = saveData.TEdithData
	local arrowDesign = tEdithdata.ArrowDesign

	effectSprite:ReplaceSpritesheet(0, arrowPath .. tables.ArrowSuffix[arrowDesign] .. ".png", true)
end
mod:AddCallback(enums.Callbacks.ARROW_SPRITE_CHANGE, Arrow.ReplaceArrowSprite)