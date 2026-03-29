local mod = EdithRebuilt
local modules = mod.Modules
local ModRNG = modules.RNG
local StompUtils = modules.STOMP_UTILS
local Callbacks = mod.Enums.Callbacks

---@param player EntityPlayer
---@param params TEdithHopParryParams|EdithJumpStompParams
local function ApplyDamageAdders(player, params)
    local damage = StompUtils.GetDamage(params)
    local adders = {
        ---@param rng RNG
        [CollectibleType.COLLECTIBLE_APPLE] = function(rng)
            if not ModRNG.RandomBoolean(rng, 1 / math.max(15 - player.Luck, 1)) then return end
            StompUtils.SetDamage(params, damage * 4)
        end,
        ---@param rng RNG
        [CollectibleType.COLLECTIBLE_TOUGH_LOVE] = function(rng)
            if not ModRNG.RandomBoolean(rng, 1 / math.max(10 - player.Luck, 1)) then return end
            StompUtils.SetDamage(params, damage * 3.2)
        end,
        ---@param rng RNG
        [CollectibleType.COLLECTIBLE_STYE] = function(rng)
            if not ModRNG.RandomBoolean(rng) then return end
            StompUtils.SetDamage(params, damage * 1.28)
        end,
        ---@param rng RNG
        [CollectibleType.COLLECTIBLE_BLOOD_CLOT] = function(rng)
            if not ModRNG.RandomBoolean(rng) then return end
            StompUtils.SetDamage(params, damage * 1.1)
        end,
        [CollectibleType.COLLECTIBLE_CHEMICAL_PEEL] = function(rng)
            if not ModRNG.RandomBoolean(rng) then return end
            StompUtils.SetDamage(params, damage + 2)
        end,
    }

    for item, funct in pairs(adders) do
        if not player:HasCollectible(item) then goto Continue end
        funct(player:GetCollectibleRNG(item))
        ::Continue::
    end
end

---@param params TEdithHopParryParams
mod:AddCallback(Callbacks.PERFECT_PARRY, function(_, player, _, params)
    ApplyDamageAdders(player, params)
end)

---@param params EdithJumpStompParams
mod:AddCallback(Callbacks.OFFENSIVE_STOMP, function(_, player, params)
    ApplyDamageAdders(player, params)
end)
