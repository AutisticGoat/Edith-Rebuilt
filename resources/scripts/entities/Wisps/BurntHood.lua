local mod = EdithRebuilt
local enums = mod.Enums
local modules = mod.Modules
local Helpers = modules.HELPERS
local BurntHoodID = enums.CollectibleType.COLLECTIBLE_BURNT_HOOD
local data = mod.DataHolder.GetEntityData
local callbacks = enums.Callbacks
local TEdithMod = modules.TEDITH
local Jump = modules.JUMP

---@param fam EntityFamiliar
mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, function (_, fam)
    if not Helpers.IsModItemWisp(fam, BurntHoodID) then return end

    data(fam).JustSpawned = true
end)

mod:AddCallback(callbacks.POST_PARRY_LAND, function (_, player)
    local hpMult = TEdithMod.GetParryType(TEdithMod.GetHopParryParams(player)) / 2

    for _, ent in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, FamiliarVariant.WISP, BurntHoodID)) do
        local famData = data(ent)

        if not famData.JustSpawned then goto continue end

        ent.HitPoints = ent.HitPoints * hpMult

        if hpMult == 0 then
            ent:Die()
        end

        famData.JustSpawned = false
        ::continue::
    end
end)

---@param ent Entity
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, ent)
    if not Helpers.IsModItemWisp(ent, BurntHoodID) then return end
    if ent:ToFamiliar().Player:GetDamageCooldown() == 0 then return end
    if (not data(ent).JustSpawned) or (not Jump.IsJumping(ent)) then return end

    return false
end, EntityType.ENTITY_FAMILIAR)