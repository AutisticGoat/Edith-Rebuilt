local mod = EdithRebuilt
local helpers = mod.Modules.HELPERS
local Creeps = mod.Modules.CREEPS
local shakerID = mod.Enums.CollectibleType.COLLECTIBLE_SALTSHAKER

---@param familiar EntityFamiliar
mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(_, familiar)
end)

---@param ent Entity
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function (_, ent, amount)
    local wisp = ent:ToFamiliar()

    if not wisp then return end
    if not helpers.IsModItemWisp(wisp, shakerID) then return end
    if wisp.HitPoints > amount then return end

    print(wisp.HitPoints, amount)


    -- if not helpers.IsModItemWisp(ent, shakerID) then return end
    -- print("aaaaaaaaaaaaa")
    
    Creeps.SpawnSaltCreep(wisp, ent.Position, 0, 5, 2, 4, "SaltShaker")
    -- Creeps.SpawnSaltCreep()
    
end)