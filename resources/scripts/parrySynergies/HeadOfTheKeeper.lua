local mod = EdithRebuilt
local enums = mod.Enums
local ModRNG = mod.Modules.RNG
local Callbacks = enums.Callbacks

---@param player EntityPlayer
---@param ent Entity
mod:AddCallback(Callbacks.PERFECT_PARRY, function(_, player, ent)
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_HEAD_OF_THE_KEEPER) then return end
    local rng = player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_HEAD_OF_THE_KEEPER)

    if not ModRNG.RandomBoolean(rng, 0.05) then return end
    local RandomVel = ModRNG.RandomFloat(rng, 1.5, 3.5)

    Isaac.Spawn(
        EntityType.ENTITY_PICKUP,
        PickupVariant.PICKUP_COIN,
        CoinSubType.COIN_PENNY,
        ent.Position,
        rng:RandomVector() * RandomVel,
        player
    )
end)