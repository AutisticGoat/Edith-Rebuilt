local mod = EdithRebuilt
local enums = mod.Enums
local modules = mod.Modules
local Helpers = modules.HELPERS
local StatusEffects = modules.STATUS_EFFECTS
local spicesMixID = enums.CollectibleType.COLLECTIBLE_SPICES_MIX 

---@param fam EntityFamiliar
mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, function (_, fam)
    if not Helpers.IsModItemWisp(fam, spicesMixID) then return end

    local player = fam.Player
    local slot = player:GetActiveItemSlot(spicesMixID)

    if slot == -1 then return end

    local current = player:GetActiveItemDesc(slot).VarData
    local spiceData = StatusEffects.GetSpiceEffect(current)
    local color = spiceData.Color

    fam.Color = Color(color.RO, color.GO, color.BO)
end)

---@param ent Entity
---@param amount number
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, ent, amount)
    if not Helpers.IsModItemWisp(ent, spicesMixID) then return end
    if ent.HitPoints > amount then return end

    local fam = ent:ToFamiliar() ---@cast fam EntityFamiliar
    local player = fam.Player
    local slot = player:GetActiveItemSlot(spicesMixID)

    if slot == -1 then return end

    local current = player:GetActiveItemDesc(slot).VarData
    local spiceData = StatusEffects.GetSpiceEffect(current)

    StatusEffects.TriggerSpiceEffect(player, spiceData, 30, 20)
end, EntityType.ENTITY_FAMILIAR)

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function ()
    for _, fam in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, FamiliarVariant.WISP, spicesMixID)) do
        fam:Kill()
    end
end)