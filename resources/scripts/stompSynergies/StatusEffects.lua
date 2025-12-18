local mod = EdithRebuilt
local enums = mod.Enums
local Callbacks = enums.Callbacks

---@param player EntityPlayer
---@param entity Entity
mod:AddCallback(Callbacks.OFFENSIVE_STOMP_HIT, function(_, player, entity)
    if not entity:IsEnemy() then return end

    local ent = entity:ToNPC() ---@cast ent EntityNPC    
    ent:ApplyTearflagEffects(ent.Position, player.TearFlags, player, player.Damage)
end)