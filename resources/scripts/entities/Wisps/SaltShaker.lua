local mod = EdithRebuilt
local enums = mod.Enums
local modules = mod.Modules
local helpers = modules.HELPERS
local Creeps = modules.CREEPS
local Player = modules.PLAYER
local saltTypes = enums.SaltTypes
local shakerID = enums.CollectibleType.COLLECTIBLE_SALTSHAKER

---@param ent Entity
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function (_, ent, amount)
    local wisp = ent:ToFamiliar()

    if not wisp then return end
    if not helpers.IsModItemWisp(wisp, shakerID) then return end
    if wisp.HitPoints > amount then return end
    
    local saltType = Player.IsJudasWithBirthright(wisp.Player) and saltTypes.SALT_SHAKER_JUDAS or saltTypes.SALT_SHAKER

    Creeps.SpawnSaltCreep(wisp, ent.Position, 0, 5, 2, 4, saltType)    
end)