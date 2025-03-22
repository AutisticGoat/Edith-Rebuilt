local enums = edithMod.Enums
local utils = enums.Utils
local game = utils.Game
local effectVar = enums.EffectVariant
local tables = enums.Tables

local arrowPath = "gfx/effects/TaintedEdithArrow/effect_000_tainted_edith"

function edithMod:RenderTaintedEdithArrow(effect)
	local room = game:GetRoom()
	local player = effect.SpawnerEntity:ToPlayer()
	local effectSprite = effect:GetSprite()
	
	local rendermode = room:GetRenderMode()
	
	if rendermode == RenderMode.RENDER_WATER_REFLECT then return false end
	local saveData = edithMod.SaveManager.GetDeadSeaScrollsSave()
	local tEdithdata = saveData.TEdithData
	
	if not player then return end
	local arrowColor = tEdithdata.ArrowColor
	local arrowDesign = tEdithdata.ArrowDesign
	
	local playerData = edithMod.GetData(player)
	local HopVec = playerData.HopVector
	
	effectSprite.Rotation = arrowDesign ~= 7 and HopVec:GetAngleDegrees() or 0 

	local color = tEdithdata.RGBMode and edithMod.RGBCycle(tEdithdata.RGBSpeed) or Color(arrowColor.Red, arrowColor.Green, arrowColor.Blue)

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