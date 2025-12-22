local mod = EdithRebuilt
local enums = mod.Enums
local ModRNG = mod.Modules.RNG
local Callbacks = enums.Callbacks

-- Pendiente de rehacer

---@param player EntityPlayer
---@param params TEdithHopParryParams
mod:AddCallback(Callbacks.PERFECT_PARRY, function (_, player, _, params)
    local adders = {
        ---@param rng RNG
        [CollectibleType.COLLECTIBLE_APPLE] = function(rng)
            if not ModRNG.RandomBoolean(rng, 1 / math.max(15 - player.Luck, 1)) then return end
            params.ParryDamage = params.ParryDamage * 4
        end,
        ---@param rng RNG
        [CollectibleType.COLLECTIBLE_TOUGH_LOVE] = function(rng)
            if not ModRNG.RandomBoolean(rng, 1 / math.max(10 - player.Luck, 1)) then return end
            params.ParryDamage = params.ParryDamage * 3.2
        end,
        ---@param rng RNG
        [CollectibleType.COLLECTIBLE_STYE] = function(rng)
            if not ModRNG.RandomBoolean(rng) then return end
            params.ParryDamage = params.ParryDamage * 1.28
        end,
        ---@param rng RNG
        [CollectibleType.COLLECTIBLE_BLOOD_CLOT] = function(rng)
            if not ModRNG.RandomBoolean(rng) then return end
            params.ParryDamage = params.ParryDamage * 1.1
        end,
        [CollectibleType.COLLECTIBLE_CHEMICAL_PEEL] = function(rng)
            if not ModRNG.RandomBoolean(rng) then return end
            params.ParryDamage = params.ParryDamage + 2
        end
    }

    for item, funct in pairs(adders) do
        if not player:HasCollectible(item) then goto Continue end
        funct(player:GetCollectibleRNG(item))
        ::Continue::
    end
end)