local mod = EdithRebuilt
local enums = mod.Enums
local Callbacks = enums.Callbacks
local Maths = mod.Modules.MATHS

---@param player EntityPlayer
---@param entity Entity
---@param params EdithJumpStompParams
mod:AddCallback(Callbacks.OFFENSIVE_STOMP_HIT, function(_, player, entity, params)
    if not params.IsDefensiveStomp then return end
    if not entity:IsEnemy() then return end
    ---@cast entity EntityNPC

    -- Man how tf can this be so fucking easier I LOVE REPENTOGON
    entity:ApplyTearflagEffects(entity.Position, player.TearFlags, player, player.Damage)
end)