local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local sounds = enums.SoundEffect
local misc = enums.Misc
local utils = enums.Utils
local sfx = utils.SFX
local SaltQuantity = 20
local ndegree = 360 / SaltQuantity
local data = mod.CustomDataWrapper.getData
local SaltShaker = {}

---@param rng RNG
---@param player EntityPlayer
---@param flag UseFlag
---@return boolean?
function SaltShaker:UseSaltShaker(_, rng, player, flag)	
	if flag & UseFlag.USE_CARBATTERY == UseFlag.USE_CARBATTERY then return end
    local Hascarbattery = player:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY) 
	local playerPos = player.Position
	local SaltTime = Hascarbattery and 14 or 7
	local SoundPitch = rng:RandomInt(90, 110) / 100

	for _, entity in ipairs(Isaac.FindByType(EntityType.ENTITY_EFFECT)) do
		local effectData = data(entity)
		local effect = entity:ToEffect()
		if not effect then return end

		if effectData.SpawnType == "SaltShakerSpawn" then
			effect:SetTimeout(1)
		end
	end

	for i = 1, SaltQuantity do	
		mod:SpawnSaltCreep(player, playerPos + misc.SaltShakerDist:Rotated(ndegree*i), 0, SaltTime, 1, "SaltShakerSpawn")
	end
	
	sfx:Play(sounds.SOUND_SALT_SHAKER, 2, 0, false, SoundPitch, 0)
	return true
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, SaltShaker.UseSaltShaker, items.COLLECTIBLE_SALTSHAKER)