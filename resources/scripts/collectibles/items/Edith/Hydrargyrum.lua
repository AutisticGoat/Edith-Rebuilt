local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local StatusEffects = mod.Modules.STATUS_EFFECTS
local Helpers = mod.Modules.HELPERS
local data = mod.DataHolder.GetEntityData
local Hydrargyrum = {}

---@param srcEnt Entity
---@return boolean
local function IsHydrargyrumTear(srcEnt)
    return srcEnt and srcEnt:ToTear() and data(srcEnt).IsHydrargyrumTear --[[@as boolean]]
end

---@param ent Entity
---@param source EntityRef
function Hydrargyrum:ApplyHydrargyrumCurse(ent, _, _, source)
    local srcEnt = source.Entity
    local player = Helpers.GetPlayerFromRef(source)

    if not player then return end
    if IsHydrargyrumTear(srcEnt) then return end
    if not player:HasCollectible(items.COLLECTIBLE_HYDRARGYRUM) then return end

    StatusEffects.SetStatusEffect(enums.EdithStatusEffects.HYDRARGYRUM_CURSE, ent, 120, player)
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, Hydrargyrum.ApplyHydrargyrumCurse)