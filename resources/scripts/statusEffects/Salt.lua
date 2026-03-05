local mod = EdithRebuilt
local modules = mod.Modules
local effects = mod.Enums.EdithStatusEffects
local Status = modules.STATUS_EFFECTS
local damageFlag = false

---@param entity Entity
---@param amount number
---@param flags DamageFlag
---@param source EntityRef
---@param Cooldown integer
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, entity, amount, flags, source, Cooldown)
    if not Status.EntHasStatusEffect(entity, effects.SALTED) then return end
    if not amount == (amount * 1.2) then return end
    if damageFlag == true then return end

    damageFlag = true
    entity:TakeDamage(amount * 1.2, flags, source, Cooldown)
    damageFlag = false
    return false
end)

mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, function (_, npc)
    if not Status.EntHasStatusEffect(npc, effects.SALTED) then return end
    if JumpLib:GetData(npc).Jumping then return end
    npc:MultiplyFriction(0.6)
end)
