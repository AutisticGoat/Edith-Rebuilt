local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local sounds = enums.SoundEffect
local misc = enums.Misc
local utils = enums.Utils
local sfx = utils.SFX
local SaltQuantity = 14
local degree = 360 / SaltQuantity
local data = mod.CustomDataWrapper.getData
local SaltShaker = {}

local DespawnSaltTypes = {
	["SaltShakerSpawn"] = true,
	["SaltShakerSpawnJudas"] = true,
}

---@param rng RNG
---@param player EntityPlayer
---@param flag UseFlag
---@return boolean?
function SaltShaker:UseSaltShaker(_, rng, player, flag)	
	if flag & UseFlag.USE_CARBATTERY == UseFlag.USE_CARBATTERY then return end
    local hasCarBattery = player:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY) 
	local playerPos = player.Position
	local spawnType = mod.IsJudasWithBirthright(player) and "SaltShakerSpawnJudas" or "SaltShakerSpawn"
	local color = spawnType == "SaltShakerSpawnJudas" and Color(1, 0.4, 0.15) or nil

	for _, entity in ipairs(Isaac.FindByType(EntityType.ENTITY_EFFECT)) do
		if not mod.When(data(entity).SpawnType, DespawnSaltTypes, false) then goto continue end
		entity:ToEffect():SetTimeout(1)
	    ::continue::
	end
	
	for i = 1, SaltQuantity do	
		mod:SpawnSaltCreep(player, playerPos + misc.SaltShakerDist:Rotated(degree * i), 0, hasCarBattery and 14 or 7, 1, 4.5, spawnType, false, true, color)
	end
	
	sfx:Play(sounds.SOUND_SALT_SHAKER, 2, 0, false, mod.RandomFloat(rng, 0.9, 1.1), 0)
	return true
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, SaltShaker.UseSaltShaker, items.COLLECTIBLE_SALTSHAKER)