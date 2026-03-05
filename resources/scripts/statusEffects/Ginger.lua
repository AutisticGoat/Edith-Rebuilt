local mod = EdithRebuilt
local modules = mod.Modules
local effects = mod.Enums.EdithStatusEffects
local Status = modules.STATUS_EFFECTS
local Helpers = modules.HELPERS

---@param entity Entity
---@param source EntityRef
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, entity , _, _, source)
    local entSource = source.Entity

    if not source.Entity then return end
    if not Status.EntHasStatusEffect(entity, effects.GINGER) then return end

    Helpers.TriggerPush(entity, entSource, 20)
end)