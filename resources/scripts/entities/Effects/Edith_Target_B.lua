local game = edithMod.Enums.Utils.Game
-- local sfx = SFXManager()

function edithMod:RenderTaintedEdithArrow(effect)
	local player = effect.SpawnerEntity:ToPlayer()
	
	-- print(effect.FrameCount > 1)
	
	effect.Visible = effect.FrameCount > 1
	
	local sprite = effect:GetSprite()
	
	if not player then return end
	
	local playerData = edithMod:GetData(player)
	local HopVec = playerData.HopVector
	
	local rotation = HopVec:GetAngleDegrees()
	
	sprite.Rotation = rotation
	
end
edithMod:AddCallback(ModCallbacks.MC_PRE_EFFECT_RENDER, edithMod.RenderTaintedEdithArrow, edithMod.Enums.EffectVariant.EFFECT_EDITH_B_TARGET)

