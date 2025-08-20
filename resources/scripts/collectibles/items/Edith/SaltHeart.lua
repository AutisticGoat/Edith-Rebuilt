local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local data = mod.CustomDataWrapper.getData
local invalidDamageFlags = DamageFlag.DAMAGE_SPIKES | DamageFlag.DAMAGE_INVINCIBLE | DamageFlag.DAMAGE_NO_MODIFIERS | DamageFlag.DAMAGE_NO_PENALTIES
local SaltHeart = {}


---@param entity Entity
---@param amount number
---@param flags DamageFlag
---@param source EntityRef
function SaltHeart:GettingDamage(entity, amount, flags, source)
    local player = entity:ToPlayer()
    if not (player and player:HasCollectible(items.COLLECTIBLE_SALT_HEART)) then return end
    if mod.HasBitFlags(flags, invalidDamageFlags) then return end
    
    -- if TSIL.Players.IsDamageToPlayerFatal(player, amount, source) then return end

    print(mod.HasBitFlags)

    print(flags)

    local playerData = data(player)

    playerData.SaltHeartDDFlag = playerData.SaltHeartDDFlag or false
    playerData.SaltHeartSpawnSaltTimer = 90

    if not playerData.SaltHeartDDFlag then 
        playerData.SaltHeartDDFlag = true
        player:TakeDamage(amount * 2, flags, source, 0)
        playerData.SaltHeartDDFlag = false
        return false
    end

    for _ = 1, player:GetCollectibleRNG(items.COLLECTIBLE_SALT_HEART):RandomInt(4, 6) do
        local tears = player:FireTear(entity.Position, RandomVector() * (player.ShotSpeed * 10), false, false, false, player, 1)
		
		mod.ForceSaltTear(tears)
		tears:AddTearFlags(TearFlags.TEAR_PIERCING)
    end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, SaltHeart.GettingDamage)

---@param player EntityPlayer
function SaltHeart:SpawnSaltCreep(player)
    if not player:HasCollectible(items.COLLECTIBLE_SALT_HEART) then return end

    local playerData = data(player)
    
    if not playerData.SaltHeartSpawnSaltTimer or playerData.SaltHeartSpawnSaltTimer <= 0 then return end
    playerData.SaltHeartSpawnSaltTimer = math.max(playerData.SaltHeartSpawnSaltTimer - 1, 0) 
    if playerData.SaltHeartSpawnSaltTimer % 5 ~= 0 then return end
    
    mod:SpawnSaltCreep(player, player.Position, 2, 5, 2, 3, "SaltHeart", false, true)
end
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, SaltHeart.SpawnSaltCreep)

---@param player EntityPlayer
function SaltHeart:Stats(player)
    if not player:HasCollectible(items.COLLECTIBLE_SALT_HEART) then return end
    player.Damage = (player.Damage + ((0.5 * player:GetCollectibleNum(items.COLLECTIBLE_SALT_HEART)) - 1)) * 1.75
end
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, SaltHeart.Stats, CacheFlag.CACHE_DAMAGE)