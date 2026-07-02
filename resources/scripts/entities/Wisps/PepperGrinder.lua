local mod = EdithRebuilt
local enums = mod.Enums
local modules = mod.Modules
local Helpers = modules.HELPERS
local StatusEffects = modules.STATUS_EFFECTS
local PepperGrinderID = enums.CollectibleType.COLLECTIBLE_PEPPERGRINDER

---@param ent Entity
---@param amount number
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, ent, amount)
    if not Helpers.IsModItemWisp(ent, PepperGrinderID) then return end
    if ent.HitPoints > amount then return end

    local fam = ent:ToFamiliar() ---@cast fam EntityFamiliar
    local player = fam.Player
    local spiceData = StatusEffects.GetSpiceEffect(2)

    StatusEffects.TriggerSpiceEffect(player, spiceData, 30, 20)
end, EntityType.ENTITY_FAMILIAR)