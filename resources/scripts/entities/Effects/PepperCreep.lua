local mod = edithMod

function mod:OnSpawningPepper(effect)
	if effect.SubType ~= mod.Enums.SubTypes.PEPPER_CREEP then return end
	
	local saltFrame = tostring(mod.RandomNumber(1, 6))
	local saltSprite = effect:GetSprite()
	saltSprite:Play("SmallBlood0" .. saltFrame, true)	
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, mod.OnSpawningPepper, EffectVariant.PLAYER_CREEP_RED)