local mod = EdithRebuilt
local modules = mod.Modules
local effects = mod.Enums.EdithStatusEffects
local Status = modules.STATUS_EFFECTS
local Creeps = modules.CREEPS
local Helpers = modules.HELPERS

---@param npc EntityNPC
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, function (_, npc)
    if not Status.EntHasStatusEffect(npc, effects.OREGANO) then return end

    npc:MultiplyFriction(0.9)

    local player = Helpers.GetPlayerFromRef(Status.GetStatusEffectData(npc, effects.OREGANO).Source)

    if not player then return end
    if Status.GetStatusEffectCountdown(npc, effects.OREGANO) % 15 ~= 0 then return end
    Creeps.SpawnOreganoCreep(player, npc.Position, 5)
    npc:TakeDamage(2, 0, EntityRef(nil), 5)
end)