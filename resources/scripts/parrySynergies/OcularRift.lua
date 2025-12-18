
local mod = EdithRebuilt
local callbacks = mod.Enums.Callbacks
local ModRNG = mod.Modules.RNG

---@param player EntityPlayer
---@param entity Entity
mod:AddCallback(callbacks.PERFECT_PARRY, function(_, player, entity)
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_OCULAR_RIFT) then return end

    local rng = player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_OCULAR_RIFT)
    local formula = 1 / math.max((20 - player.Luck), 5)

    if not ModRNG.RandomBoolean(rng, formula) then return end

    local rift = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.RIFT, 0, entity.Position, Vector.Zero,
    player):ToEffect() ---@cast rift EntityEffect

    rift.CollisionDamage = player.Damage / 2
    rift:SetTimeout(60)
end)
