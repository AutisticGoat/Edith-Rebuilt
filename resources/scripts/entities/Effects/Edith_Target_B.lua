local game = edithMod.Enums.Utils.Game
local room = edithMod.Enums.Utils.Room
local tables = edithMod.Enums.Tables

local arrowPath = "gfx/effects/TaintedEdithArrow/effect_000_tainted_edith"

function edithMod:RenderTaintedEdithArrow(effect)
	local player = effect.SpawnerEntity:ToPlayer()
	local effectSprite = effect:GetSprite()
	
	local rendermode = room:GetRenderMode()
	
	if rendermode == 5 then return false end
		
	local sprite = effect:GetSprite()
	
	if not player then return end
	
	local SaveManager = edithMod.saveManager
	local menuData = SaveManager.GetDeadSeaScrollsSave()

	if not menuData then return end

	local arrowColor = menuData.ArrowColor
	local arrowDesign = menuData.ArrowDesign
	
	local playerData = edithMod:GetData(player)
	local HopVec = playerData.HopVector
	
	if arrowDesign ~= 7 then
		local rotation = HopVec:GetAngleDegrees()
		sprite.Rotation = rotation
	end
		
	edithMod:ChangeColor(effect, arrowColor.Red, arrowColor.Green, arrowColor.Blue)
	effectSprite:ReplaceSpritesheet(0, arrowPath .. tables.ArrowSuffix[arrowDesign] .. ".png", true)
end
edithMod:AddCallback(ModCallbacks.MC_PRE_EFFECT_RENDER, edithMod.RenderTaintedEdithArrow, edithMod.Enums.EffectVariant.EFFECT_EDITH_B_TARGET)

function edithMod:taintedArrowUpdate(effect)
	local roomSize = room:GetGridSize()
	local player = effect.SpawnerEntity:ToPlayer()

	if not player then return end

	edithMod:TargetDoorManager(effect, player, 20)
end
edithMod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, edithMod.taintedArrowUpdate, edithMod.Enums.EffectVariant.EFFECT_EDITH_B_TARGET)
