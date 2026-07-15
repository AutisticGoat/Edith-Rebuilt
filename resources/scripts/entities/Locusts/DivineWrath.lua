local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local modules = mod.Modules
local Helpers = modules.HELPERS
local ModRNG = modules.RNG

---@param entity Entity
---@param amount number
---@param flags DamageFlag
---@param source EntityRef
---@param countdown integer
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function (_, entity, amount, flags, source, countdown)
    local ent = source.Entity

    if not ent then return end
    if not Helpers.IsModItemLocust(ent, items.COLLECTIBLE_DIVINE_WRATH) then return end

    local mult = ModRNG.RandomFloat(ent:GetDropRNG(), 1.5, 2)

    return {Damage = amount * mult, DamageFlags = flags, DamageCountdown = countdown}
end)
