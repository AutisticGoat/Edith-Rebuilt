local mod = EdithRebuilt
local enums = mod.Enums
local utils = enums.Utils
local ModRNG = mod.Modules.RNG
local Callbacks = enums.Callbacks

---@param player EntityPlayer
---@param ent Entity
---@param params EdithJumpStompParams
mod:AddCallback(Callbacks.OFFENSIVE_STOMP_HIT, function(_, player, ent, params)
    if params.IsDefensiveStomp then return end
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_HEAD_OF_THE_KEEPER) then return end

    local rng = player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_HEAD_OF_THE_KEEPER)

    if not ModRNG(rng, 0.05) then return end

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