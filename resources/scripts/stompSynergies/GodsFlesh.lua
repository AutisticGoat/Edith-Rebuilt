local mod = EdithRebuilt
local enums = mod.Enums
local ModRNG = mod.Modules.RNG
local Helpers = mod.Modules.HELPERS
local Callbacks = enums.Callbacks

---@param player EntityPlayer
---@param ent Entity
function mod:StompDamageAdders(player, ent)
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_GODS_FLESH) then return end
    if not Helpers.IsEnemy(ent) then return end

    local rng = player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_GODS_FLESH)

    if not ModRNG.RandomBoolean(rng, 0.2) then return end

    ent:AddShrink(EntityRef(player), 150)
end
mod:AddCallback(Callbacks.OFFENSIVE_STOMP_HIT, mod.StompDamageAdders)