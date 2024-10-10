local game = edithMod.Enums.Utils.Game

function edithMod:RenderTaintedEdithArrow(effect)
	local player = effect.SpawnerEntity:ToPlayer()
		
	effect.Visible = effect.FrameCount > 1
	
	local sprite = effect:GetSprite()
	
	if not player then return end
	
	local playerData = edithMod:GetData(player)
	local HopVec = playerData.HopVector
	
	local rotation = HopVec:GetAngleDegrees()
	
	sprite.Rotation = rotation

	local SaveManager = edithMod.saveManager
	local menuData = SaveManager.GetDeadSeaScrollsSave()

	if not menuData then return end


	local arrowColor = menuData.ArrowColor

	local newEffecColor = effect.Color
	
	newEffecColor.R = arrowColor.Red
	newEffecColor.G = arrowColor.Green
	newEffecColor.B = arrowColor.Blue

	effect.Color = newEffecColor

	print(newEffecColor)

end
edithMod:AddCallback(ModCallbacks.MC_PRE_EFFECT_RENDER, edithMod.RenderTaintedEdithArrow, edithMod.Enums.EffectVariant.EFFECT_EDITH_B_TARGET)

