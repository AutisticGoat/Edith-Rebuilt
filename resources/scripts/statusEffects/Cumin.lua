local mod = EdithRebuilt
local modules = mod.Modules
local effects = mod.Enums.EdithStatusEffects
local Status = modules.STATUS_EFFECTS
local data = mod.DataHolder.GetEntityData
local damageFlag = false

---@param npc EntityNPC
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if not Status.EntHasStatusEffect(npc, effects.CUMIN) then return end
    data(npc).CuminStopCountdown = data(npc).CuminStopCountdown or 0

    local cuminCountdown = data(npc).CuminStopCountdown

    if cuminCountdown > 0 then
        npc.Velocity = Vector.Zero
        data(npc).CuminStopCountdown = cuminCountdown - 1
    end
end)

mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, entity)
    if not Status.EntHasStatusEffect(entity, effects.CUMIN) then return end
    if damageFlag == true then return end

    damageFlag = true
    data(entity).CuminStopCountdown = 5
    damageFlag = false
end)
