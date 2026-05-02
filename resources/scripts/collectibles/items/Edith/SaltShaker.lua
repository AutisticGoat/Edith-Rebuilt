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
local Player = modules.PLAYER
local BitMask = modules.BIT_MASK
local StsEffects = modules.STATUS_EFFECTS 
local Helpers = modules.HELPERS
local Creeps = modules.CREEPS
local degree = 360 / SaltQuantity
local data = mod.DataHolder.GetEntityData
local SaltShaker = {}

local DespawnSaltTypes = {
	[saltTypes.SALT_SHAKER] = true,
	[saltTypes.SALT_SHAKER_JUDAS] = true,
}

local JudasSaltColor = Color(1, 0.4, 0.15)

-- DRY: lógica compartida entre UseSaltShaker y OnSaltedDeath
---@param player EntityPlayer
---@return SaltTypes, Color?
local function GetSaltShakerParams(player)
    local spawnType = Player.IsJudasWithBirthright(player)
        and saltTypes.SALT_SHAKER_JUDAS
        or saltTypes.SALT_SHAKER
    local color = spawnType == saltTypes.SALT_SHAKER_JUDAS and JudasSaltColor or nil
    return spawnType, color
end

---@param player EntityPlayer
local function DespawnExistingSaltCreeps(player)
    for _, entity in ipairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_RED, enums.SubTypes.SALT_CREEP)) do
		if GetPtrHash(entity.SpawnerEntity) ~= GetPtrHash(player) then goto continue end
        -- if not Helpers.When(data(entity).SpawnType, DespawnSaltTypes, false) then goto continue end
        entity:ToEffect():SetTimeout(1)
        ::continue::
    end
end

---@param player EntityPlayer
---@param spawnType SaltTypes
---@param color Color?
---@param hasCarBattery boolean
local function SpawnSaltCircle(player, spawnType, color, hasCarBattery)
    local playerPos = player.Position
    for i = 1, SaltQuantity do
        Creeps.SpawnSaltCreep(
            player,
            playerPos + misc.SaltShakerDist:Rotated(degree * i),
            0, hasCarBattery and 12 or 6, 1, 4.5,
            spawnType, false, true, color
        )
    end
end

---@param player EntityPlayer
---@param rng RNG
local function SpawnSaltCloud(player, rng)
    local cloud = StsEffects.SpawnSpicePuff(player, rng)

    local X = ModRNG.RandomFloat(rng, 0.8, 1.15)
    local Y = ModRNG.RandomFloat(rng, 0.8, 1.15)

    cloud.Color = StsEffects.GetSpiceEffectData(enums.EdithStatusEffects.SALTED).Color
    cloud.SpriteScale = Vector.One * Vector(X, Y)
    cloud:GetSprite().PlaybackSpeed = ModRNG.RandomFloat(rng, 1.4, 1.8)
end 

---@param rng RNG
---@param player EntityPlayer
---@param flag UseFlag
---@return boolean?
mod:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, _, rng, player, flag)
    if BitMask.HasBitFlags(flag, UseFlag.USE_CARBATTERY --[[@as BitSet128]]) then return end

    local hasCarBattery = player:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY)
    local spawnType, color = GetSaltShakerParams(player)

    DespawnExistingSaltCreeps(player)
    SpawnSaltCloud(player, rng)
    SpawnSaltCircle(player, spawnType, color, hasCarBattery)

    data(player).SpawnCentralPosition = player.Position
    sfx:Play(sounds.SOUND_SALT_SHAKER, 2, 0, false, ModRNG.RandomFloat(rng, 0.9, 1.1), 0)
    return true
end, items.COLLECTIBLE_SALTSHAKER)

---@param npc EntityNPC
---@param source EntityRef
function SaltShaker:OnSaltedDeath(npc, source)
    if not StsEffects.EntHasStatusEffect(npc, enums.EdithStatusEffects.SALTED) then return end

    local player = Helpers.GetPlayerFromRef(source)
    if not player then return end

    local saltedType = data(npc).SaltType ---@cast saltedType SaltTypes
    if not Helpers.When(saltedType, DespawnSaltTypes, false) then return end

    local spawnType, color = GetSaltShakerParams(player)
    Creeps.SpawnSaltCreep(player, npc.Position, 0, 5, 1, 4.5, spawnType, false, true, color)
end
mod:AddCallback(PRE_NPC_KILL.ID, SaltShaker.OnSaltedDeath)