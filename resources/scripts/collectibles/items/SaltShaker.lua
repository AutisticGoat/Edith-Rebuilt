local mod = edithMod
local enums = mod.Enums
local items = enums.CollectibleType
local misc = enums.Misc
local utils = enums.Utils
local sfx = utils.SFX
local SaltQuantity = 20
local ndegree = 360 / SaltQuantity

---comment
---@param player EntityPlayer
---@return boolean?
function mod:UseSaltShaker(_, _, player, _, _, _)	
	local SoundPitch = edithMod.RandomNumber(0.9, 1.1)
	for _, entity in ipairs(Isaac.FindByType(EntityType.ENTITY_EFFECT)) do
		local effectData = edithMod.GetData(entity)
		local effect = entity:ToEffect()
		if not effect then return end

		if effectData.SpawnType == "SaltShakerSpawn" then
			effect:SetTimeout(1)
		end
	end
	for i = 1, SaltQuantity do	
		edithMod:SpawnSaltCreep(player, player.Position + misc.SaltShakerDist:Rotated(ndegree*i), 0, 7, 1, "SaltShakerSpawn")
	end

	sfx:Play(edithMod.Enums.SoundEffect.SOUND_SALT_SHAKER, 2, 0, false, SoundPitch, 0)
	return true
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.UseSaltShaker, items.COLLECTIBLE_SALTSHAKER)