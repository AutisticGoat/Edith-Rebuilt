local mod = EdithRebuilt
local enums = mod.Enums
local Callbacks = enums.Callbacks
local Maths = mod.Modules.MATHS

---@param player EntityPlayer
---@param entity Entity
---@param params EdithJumpStompParams
mod:AddCallback(Callbacks.OFFENSIVE_STOMP_HIT, function(_, player, entity, params)
    if params.IsDefensiveStomp then return end
    if not entity:IsEnemy() then return end

    local ent = entity:ToNPC()
    ---@cast ent EntityNPC

    -- Man how tf can this be so fucking easier I LOVE REPENTOGON
    ent:ApplyTearflagEffects(ent.Position, player.TearFlags, player, player.Damage)
end)