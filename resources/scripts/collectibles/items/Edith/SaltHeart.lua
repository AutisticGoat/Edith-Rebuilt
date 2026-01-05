local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local data = mod.DataHolder.GetEntityData
local saltTypes = enums.SaltTypes
local invalidDamageFlags = DamageFlag.DAMAGE_SPIKES | DamageFlag.DAMAGE_INVINCIBLE | DamageFlag.DAMAGE_NO_MODIFIERS | DamageFlag.DAMAGE_NO_PENALTIES
local modules = mod.Modules
local ModRNG = modules.RNG
local StsEffects = modules.STATUS_EFFECTS
local Helpers = modules.HELPERS
local Creeps = modules.CREEPS
local Maths = modules.MATHS
local effects = enums.EdithStatusEffects
local SaltHeart = {}

---@param entity Entity
---@param amount number
---@param flags DamageFlag
---@param source EntityRef
function SaltHeart:GettingDamage(entity, amount, flags, source)
    local player = entity:ToPlayer()
    if not (player and player:HasCollectible(items.COLLECTIBLE_SALT_HEART)) then return end
    if Maths.HasBitFlags(flags, invalidDamageFlags) then return end

    local playerData = data(player)

    playerData.SaltHeartDDFlag = playerData.SaltHeartDDFlag or false
    StsEffects.SetStatusEffect(enums.EdithStatusEffects.SALTED, player, 90, player)

    if not playerData.SaltHeartDDFlag then 
        playerData.SaltHeartDDFlag = true
        player:TakeDamage(amount * 2, flags, source, 0)
        playerData.SaltHeartDDFlag = false
        return false
    end

    for _ = 1, player:GetCollectibleRNG(items.COLLECTIBLE_SALT_HEART):RandomInt(4, 6) do
        local tears = player:FireTear(entity.Position, RandomVector() * (player.ShotSpeed * 10), false, false, false, player, 1)
		
        tears.CollisionDamage = tears.CollisionDamage / 2
		Helpers.ForceSaltTear(tears, false)
		tears:AddTearFlags(TearFlags.TEAR_PIERCING)
    end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, SaltHeart.GettingDamage)

---@param player EntityPlayer
function SaltHeart:SpawnSaltCreep(player)
    if not player:HasCollectible(items.COLLECTIBLE_SALT_HEART) then return end
    if not StsEffects.EntHasStatusEffect(player, effects.SALTED) then return end
    if StsEffects.GetStatusEffectCountdown(player, effects.SALTED) % 5 ~= 0 then return end
    
    Creeps.SpawnSaltCreep(player, player.Position, 0, 5, 2, 3, saltTypes.SALT_HEART, true, true)
end
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, SaltHeart.SpawnSaltCreep)

---@param player EntityPlayer
function SaltHeart:Stats(player)
    if not player:HasCollectible(items.COLLECTIBLE_SALT_HEART) then return end
    player.Damage = (player.Damage + ((0.5 * player:GetCollectibleNum(items.COLLECTIBLE_SALT_HEART)) - 1)) * 1.75
end
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, SaltHeart.Stats, CacheFlag.CACHE_DAMAGE)

---@param npc EntityNPC
---@param source EntityRef
function SaltHeart:OnSaltedDeath(npc, source)
    local saltedType = data(npc).SaltType ---@cast saltedType SaltTypes
    local player = Helpers.GetPlayerFromRef(source)

    if not player then return end
    if not StsEffects.EntHasStatusEffect(player, effects.SALTED) then return end
    if saltedType ~= saltTypes.SALT_HEART then return end
    if not ModRNG.RandomBoolean(player:GetCollectibleRNG(items.COLLECTIBLE_SALT_HEART), 0.25) then return end

    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, 0, npc.Position, Vector.Zero, nil)
end 
mod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, SaltHeart.OnSaltedDeath)