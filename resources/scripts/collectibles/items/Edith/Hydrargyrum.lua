local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local StatusEffects = mod.Modules.STATUS_EFFECTS
local Hydrargyrum = {}
local data = mod.CustomDataWrapper.getData

---@param ent Entity
---@param source EntityRef
function Hydrargyrum:ApplyHydrargyrumCurse(ent, _, _, source)
    local player = mod.GetPlayerFromRef(source)

    if not player then return end
    if not player:HasCollectible(items.COLLECTIBLE_HYDRARGYRUM) then return end

    mod.SetIsHydrargyrumCurse(ent, 120, player)
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, Hydrargyrum.ApplyHydrargyrumCurse)

---@param npc EntityNPC
---@param source EntityRef
function Hydrargyrum:KillingHydrargyrumCursedEnemy(npc, source)
    if not StatusEffects.EntHasStatusEffect(npc, enums.EdithStatusEffects.HYDRARGYRUM_CURSE) then return end
    Isaac.Spawn(
        EntityType.ENTITY_EFFECT,
        EffectVariant.FIRE_JET,
        0,
        npc.Position,
        Vector.Zero,
        nil
    )
end
mod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, Hydrargyrum.KillingHydrargyrumCursedEnemy)