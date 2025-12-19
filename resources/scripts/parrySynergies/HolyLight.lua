local mod = EdithRebuilt
local enums = mod.Enums
local ModRNG = mod.Modules.RNG
local Callbacks = enums.Callbacks

---@param player EntityPlayer
---@param ent Entity
---@param params TEdithHopParryParams
mod:AddCallback(Callbacks.PERFECT_PARRY, function(_, player, ent, params)
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_HOLY_LIGHT) then return end

    local rng = player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_HOLY_LIGHT)
    local formula = 1 / math.max((10 - (player.Luck * 0.9)), 2)

    if not ModRNG.RandomBoolean(rng, formula) then return end

    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 10, ent.Position, Vector.Zero, player)
    ent:TakeDamage(params.ParryDamage * 3, DamageFlag.DAMAGE_LASER, EntityRef(player), 0)
end)