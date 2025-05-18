local mod = EdithRebuilt
local Pepper = {}
local rng = mod.Enums.Utils.RNG

function Pepper:OnSpawningPepper(effect)
	if effect.SubType ~= mod.Enums.SubTypes.PEPPER_CREEP then return end
	
	local saltFrame = tostring(rng:RandomInt(1, 6))
	local saltSprite = effect:GetSprite()
	saltSprite:Play("SmallBlood0" .. saltFrame, true)	
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, Pepper.OnSpawningPepper, EffectVariant.PLAYER_CREEP_RED)