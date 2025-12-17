local mod = EdithRebuilt
local enums = mod.Enums
local game = enums.Utils.Game
local Helpers = mod.Modules.HELPERS
local Callbacks = enums.Callbacks

---@param player EntityPlayer
---@param ent Entity
---@param params EdithJumpStompParams
function mod:StompDamageAdders(player, ent, params)
    if params.IsDefensiveStomp then return end
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_JACOBS_LADDER) then return end
    if not Helpers.IsEnemy(ent) then return end
    game:ChainLightning(ent.Position, player.Damage / 2, player.TearFlags, player)
end
mod:AddCallback(Callbacks.OFFENSIVE_STOMP_HIT, mod.StompDamageAdders)