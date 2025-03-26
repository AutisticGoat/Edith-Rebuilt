local mod = edithMod
local enums = mod.Enums
local utils = enums.Utils
local game = utils.Game
local effectVar = enums.EffectVariant
local tables = enums.Tables
local misc = enums.Misc
local saveManager = mod.SaveManager
local Hsx = edithMod.Hsx

local arrowPath = "gfx/effects/TaintedEdithArrow/effect_000_tainted_edith"

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


local value = 0

local function RGBFunction(color, step)
	local newColor = color

	value = value + step

	newColor.R, newColor.B, newColor.G = funcs.RGBToHSV(newColor.R, newColor.B, newColor.G)
	newColor.R = newColor.R - step
	newColor.R, newColor.B, newColor.G = funcs.HSVToRGB(newColor.R, newColor.B, newColor.G)

	color = newColor
end

function edithMod:RenderTaintedEdithArrow(effect)
	local room = game:GetRoom()
	local player = effect.SpawnerEntity:ToPlayer()
	local effectSprite = effect:GetSprite()
	
	local rendermode = room:GetRenderMode()
	
	if rendermode == RenderMode.RENDER_WATER_REFLECT then return false end
	local saveData = saveManager.GetDeadSeaScrollsSave()

	if not saveData then return end
	if not player then return end

	local tEdithdata = saveData.TEdithData
	local arrowColor = tEdithdata.ArrowColor
	local arrowDesign = tEdithdata.ArrowDesign
	local RGBmode = tEdithdata.RGBMode
	local RGBspeed = tEdithdata.RGBSpeed

	local playerData = edithMod.GetData(player)
	local HopVec = playerData.HopVector
	
	effectSprite.Rotation = arrowDesign ~= 7 and HopVec:GetAngleDegrees() or 0 

	local color = Color.Default

	-- print(RGBspeed, RGBmode)

	if RGBmode then
		color = misc.HSVStartColor
		RGBFunction(color, RGBspeed)
	else
		color = Color(arrowColor.Red, arrowColor.Green, arrowColor.Blue)
	end

	-- for i = 1, 40 do
		
	-- end

	effect:SetColor(color, -1, 100, false, false)
	effectSprite:ReplaceSpritesheet(0, arrowPath .. tables.ArrowSuffix[arrowDesign] .. ".png", true)
end
edithMod:AddCallback(ModCallbacks.MC_PRE_EFFECT_RENDER, edithMod.RenderTaintedEdithArrow, effectVar.EFFECT_EDITH_B_TARGET)

function edithMod:taintedArrowUpdate(effect)
	local player = effect.SpawnerEntity:ToPlayer()

	if not player then return end
	edithMod:TargetDoorManager(effect, player, 20)
end
edithMod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, edithMod.taintedArrowUpdate, effectVar.EFFECT_EDITH_B_TARGET)