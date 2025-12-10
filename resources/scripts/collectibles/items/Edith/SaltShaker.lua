local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local sounds = enums.SoundEffect
local misc = enums.Misc
local utils = enums.Utils
local saltTypes = enums.SaltTypes
local sfx = utils.SFX
local SaltQuantity = 14
local modules = mod.Modules
local ModRNG = modules.RNG
local StsEffects = modules.STATUS_EFFECTS 
local degree = 360 / SaltQuantity
local data = mod.CustomDataWrapper.getData
local SaltShaker = {}

local DespawnSaltTypes = {
	[saltTypes.SALT_SHAKER] = true,
	[saltTypes.SALT_SHAKER_JUDAS] = true,
}

---@param rng RNG
---@param player EntityPlayer
---@param flag UseFlag
---@return boolean?
function SaltShaker:UseSaltShaker(_, rng, player, flag)	
	if mod.HasBitFlags(flag, UseFlag.USE_CARBATTERY) then return end
    local hasCarBattery = player:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY) 
	local playerPos = player.Position
	local spawnType = mod.IsJudasWithBirthright(player) and saltTypes.SALT_SHAKER_JUDAS or saltTypes.SALT_SHAKER
	local color = spawnType == saltTypes.SALT_SHAKER_JUDAS and Color(1, 0.4, 0.15) or nil

	for _, entity in ipairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_RED, enums.SubTypes.SALT_CREEP)) do
		if not mod.When(data(entity).SpawnType, DespawnSaltTypes, false) then goto continue end
		entity:ToEffect():SetTimeout(1)
	    ::continue::
	end

	for i = 1, SaltQuantity do	
		mod:SpawnSaltCreep(player, playerPos + misc.SaltShakerDist:Rotated(degree * i), 0, hasCarBattery and 12 or 6, 1, 4.5, spawnType, false, true, color)
	end

	data(player).SpawnCentralPosition = player.Position

	sfx:Play(sounds.SOUND_SALT_SHAKER, 2, 0, false, ModRNG.RandomFloat(rng, 0.9, 1.1), 0)
	return true
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, SaltShaker.UseSaltShaker, items.COLLECTIBLE_SALTSHAKER)

---@param npc EntityNPC
---@param source EntityRef
function SaltShaker:OnSaltedDeath(npc, source)
	if not StsEffects.EntHasStatusEffect(npc, enums.EdithStatusEffects.SALTED) then return end
    local player = mod.GetPlayerFromRef(source)

	if not player then return end
	local saltedType = data(npc).SaltType ---@cast saltedType SaltTypes
	local color = saltedType == saltTypes.SALT_SHAKER_JUDAS and Color(1, 0.4, 0.15) or nil
	local spawnType = mod.IsJudasWithBirthright(player) and saltTypes.SALT_SHAKER_JUDAS or saltTypes.SALT_SHAKER

    if not mod.When(saltedType, DespawnSaltTypes, false) then return end

	mod:SpawnSaltCreep(player, npc.Position, 0, 5, 1, 4.5, spawnType, false, true, color)
end 
mod:AddCallback(PRE_NPC_KILL.ID, SaltShaker.OnSaltedDeath)