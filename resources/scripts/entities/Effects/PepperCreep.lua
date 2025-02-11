function edithMod:OnSpawningPepper(effect)
	if effect.SubType ~= edithMod.Enums.SubTypes.PEPPER_CREEP then 
		return 
	end
	
	local saltFrame = tostring(edithMod:RandomNumber(1, 6))
		
	local saltSprite = effect:GetSprite()
	saltSprite:Play("SmallBlood0" .. saltFrame, true)	
end
edithMod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, edithMod.OnSpawningPepper, EffectVariant.PLAYER_CREEP_RED)