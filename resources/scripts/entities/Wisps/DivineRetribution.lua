local mod = EdithRebuilt
local enums = mod.Enums
local item = enums.CollectibleType

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function ()
    for _, fam in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, FamiliarVariant.WISP, item.COLLECTIBLE_DIVINE_RETRIBUTION)) do
        fam:Kill()
    end
end)