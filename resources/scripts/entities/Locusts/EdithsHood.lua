local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local modules = mod.Modules
local Helpers = modules.HELPERS
local statusEffects = modules.STATUS_EFFECTS

---@param fam EntityFamiliar
---@param col Entity
mod:AddCallback(ModCallbacks.MC_PRE_FAMILIAR_COLLISION, function(_, fam, col)
    if not Helpers.IsModItemLocust(fam, items.COLLECTIBLE_EDITHS_HOOD) then return end
    if not Helpers.IsEnemy(col) then return end

    statusEffects.SetStatusEffect(enums.EdithStatusEffects.SALTED, col, 120, fam.Player)
end)

---@param npc EntityNPC
---@param source EntityRef  
mod:AddCallback(PRE_NPC_KILL.ID, function (_, npc, source)
    local ent = source.Entity

    if not ent then return end
    if not Helpers.IsModItemLocust(ent, items.COLLECTIBLE_EDITHS_HOOD) then return end

    Helpers.SpawnSaltTears(ent:ToFamiliar().Player, npc, ent:GetDropRNG(), 3, 6)
end)