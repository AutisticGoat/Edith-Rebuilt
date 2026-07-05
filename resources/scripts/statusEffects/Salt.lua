local mod = EdithRebuilt
local modules = mod.Modules
local effects = mod.Enums.EdithStatusEffects
local Status = modules.STATUS_EFFECTS

---@param entity Entity
---@param amount number
---@param flags DamageFlag
---@param source EntityRef
---@param Cooldown integer
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, entity, amount, flags, source, Cooldown)
    if not Status.EntHasStatusEffect(entity, effects.SALTED) then return end
    return {Damage = amount * 1.2, DamageFlags = flags, DamageCountdown = Cooldown}
end)

mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, function (_, npc)
    if not Status.EntHasStatusEffect(npc, effects.SALTED) then return end
    if JumpLib:GetData(npc).Jumping then return end
    npc:MultiplyFriction(0.6)
end)
