local mod = EdithRebuilt
local enums = mod.Enums
local modules = mod.Modules
local Helpers = modules.HELPERS
local item = enums.CollectibleType

---@param ent Entity
---@param amount number
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, ent, amount)
    if not Helpers.IsModItemWisp(ent, item.COLLECTIBLE_SULFURIC_FIRE) then return end
    if ent.HitPoints > amount then return end

    local fam = ent:ToFamiliar() ---@cast fam EntityFamiliar
    local player = fam.Player
    local hitEnemies = Isaac.FindInRadius(fam.Position, 70, EntityPartition.ENEMY)

    Helpers.TriggerSulfuricFireDamage(player, 1, 1, EntityRef(player), hitEnemies)
end, EntityType.ENTITY_FAMILIAR)

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function ()
    for _, fam in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, FamiliarVariant.WISP, item.COLLECTIBLE_SULFURIC_FIRE)) do
        fam:Kill()
    end
end)