function edithMod:OnSpawningSalt(effect)
	if effect.SubType ~= edithMod.Enums.SubTypes.PEPPER_CREEP then 
		return 
	end
	
	local rng = edithMod.Enums.Utils.RNG
	local saltFrame = tostring(edithMod:RandomNumber(rng, 1, 6))
		
	local saltSprite = effect:GetSprite()
	saltSprite:Play("SmallBlood0" .. saltFrame, true)	
end
edithMod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, edithMod.OnSpawningSalt, EffectVariant.PLAYER_CREEP_RED)