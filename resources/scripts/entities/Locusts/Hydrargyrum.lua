local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local modules = mod.Modules
local Helpers = modules.HELPERS
local statusEffects = modules.STATUS_EFFECTS

---@param fam EntityFamiliar
---@param col Entity
mod:AddCallback(ModCallbacks.MC_PRE_FAMILIAR_COLLISION, function(_, fam, col)
    if not Helpers.IsModItemLocust(fam, items.COLLECTIBLE_HYDRARGYRUM) then return end
    if not Helpers.IsEnemy(col) then return end

    statusEffects.SetStatusEffect(enums.EdithStatusEffects.HYDRARGYRUM_CURSE, col, 120, fam.Player)
end)