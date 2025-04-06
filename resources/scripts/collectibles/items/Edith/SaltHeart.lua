local mod = edithMod
local enums = mod.Enums
local items = enums.CollectibleType
local SaltHeart = {}

---@param entity Entity
---@param amount number
---@param flags DamageFlag
---@param source EntityRef
function SaltHeart:GettingDamage(entity, amount, flags, source)
    local player = entity:ToPlayer()
    if not player then return end
    if not player:HasCollectible(items.COLLECTIBLE_SALT_HEART) then return end
    if TSIL.Players.IsDamageToPlayerFatal(player, amount, source) then return end

    local playerData = mod.GetData(player)
    local rng = player:GetCollectibleRNG(items.COLLECTIBLE_SALT_HEART)

    playerData.SaltHeartDDFlag = playerData.SaltHeartDDFlag or false
    playerData.SaltHeartSpawnSaltTimer = 90

    if playerData.SaltHeartDDFlag == false then 
        playerData.SaltHeartDDFlag = true
        player:TakeDamage(amount * 2, flags, source, 0)
        return false
    end

    Isaac.CreateTimer(function()
        playerData.SaltHeartDDFlag = false
    end, 1, 1, false)

    local randSaltTears = rng:RandomInt(4, 6)

    for _ = 1, randSaltTears do
        local tears = player:FireTear(entity.Position, RandomVector() * (player.ShotSpeed * 10), false, false, false, player, 1)
		
		mod.ForceSaltTear(tears)
		tears:AddTearFlags(TearFlags.TEAR_PIERCING)
    end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, SaltHeart.GettingDamage)

---comment
---@param player EntityPlayer
function SaltHeart:SpawnSaltCreep(player)
    if not player:HasCollectible(items.COLLECTIBLE_SALT_HEART) then return end

    local playerData = mod.GetData(player)
    
    if playerData.SaltHeartSpawnSaltTimer == nil or playerData.SaltHeartSpawnSaltTimer <= 0 then return end
    playerData.SaltHeartSpawnSaltTimer = math.max(playerData.SaltHeartSpawnSaltTimer - 1, 0) 
    if playerData.SaltHeartSpawnSaltTimer % 5 ~= 0 then return end
    
    mod:SpawnSaltCreep(player, player.Position, 2, 5, 2, "SaltHeart")
end
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, SaltHeart.SpawnSaltCreep)

---comment
---@param player EntityPlayer
function SaltHeart:Stats(player)
    if not player:HasCollectible(items.COLLECTIBLE_SALT_HEART) then return end
    local SHAmount = player:GetCollectibleNum(items.COLLECTIBLE_SALT_HEART)
    player.Damage = (player.Damage + ((0.5 * SHAmount) - 1)) * 1.75
end
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, SaltHeart.Stats, CacheFlag.CACHE_DAMAGE)