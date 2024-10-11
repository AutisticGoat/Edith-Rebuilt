local game = edithMod.Enums.Utils.Game

local arrowPath = "gfx/effects/TaintedEdithArrow/effect_000_tainted_edith"

local arrowSuffix = {
	[1] = "_arrow",
	[2] = "_arrow_pointy",
	[3] = "_triangle_line",
	[4] = "_triangle_full",
	[5] = "_chevron_line",
	[6] = "_chevron_full",
	[7] = "_grudge",
}		

function edithMod:RenderTaintedEdithArrow(effect)
	local player = effect.SpawnerEntity:ToPlayer()
	local effectSprite = effect:GetSprite()
	
	
	effect.Visible = effect.FrameCount > 1
	
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
	
	

	local newEffecColor = effect.Color
	
	newEffecColor.R = arrowColor.Red
	newEffecColor.G = arrowColor.Green
	newEffecColor.B = arrowColor.Blue

	effect.Color = newEffecColor
	
	effectSprite:ReplaceSpritesheet(0, arrowPath .. arrowSuffix[arrowDesign] .. ".png", true)
	
	-- local SelectedArrowDesign = arrowSuffix[]
end
edithMod:AddCallback(ModCallbacks.MC_PRE_EFFECT_RENDER, edithMod.RenderTaintedEdithArrow, edithMod.Enums.EffectVariant.EFFECT_EDITH_B_TARGET)

