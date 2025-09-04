local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local Hydrargyrum = {}
local data = mod.CustomDataWrapper.getData

---@param entity Entity
---@param amount number
---@param flags DamageFlag
---@param source EntityRef
function Hydrargyrum:GettingDamage(entity, amount, flags, source)
    if source.Type == 0 then return end
    local player = mod.GetPlayerFromRef(source)
    
    if not (player and player:HasCollectible(items.COLLECTIBLE_HYDRARGYRUM)) then return end
    if not mod.IsEnemy(entity) then return end

    local entData = data(entity)

    if entData.MercuryTimer and entity.HitPoints <= amount then
        Isaac.Spawn(
            EntityType.ENTITY_EFFECT,
            EffectVariant.FIRE_JET,
            0,
            entity.Position,
            Vector.Zero,
            nil
        )
    end

    if not (entData.MercuryTimer == 0 or entData.MercuryTimer == nil) then return end
    entData.MercuryTimer = 120
    entData.Player = player
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, Hydrargyrum.GettingDamage)