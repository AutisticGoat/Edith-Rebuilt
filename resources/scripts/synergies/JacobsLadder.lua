local mod = EdithRebuilt
local game = mod.Enums.Utils.Game
local Helpers = mod.Modules.HELPERS
local Player = mod.Modules.PLAYER
local Callbacks = mod.Enums.Callbacks

---@param player EntityPlayer
---@param ent Entity
---@param isStomp boolean
local function ChainLightning(player, ent, isStomp)
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_JACOBS_LADDER) then return end
    if not Helpers.IsEnemy(ent) then return end

    local damage = (isStomp and Player.PlayerHasBirthright(player)) and player.Damage or player.Damage / 2

    game:ChainLightning(ent.Position, damage, player.TearFlags, player)
end

mod:AddCallback(Callbacks.PERFECT_PARRY, function(_, player, ent) ChainLightning(player, ent, false) end)
mod:AddCallback(Callbacks.OFFENSIVE_STOMP_HIT, function(_, player, ent) ChainLightning(player, ent, true)  end)
