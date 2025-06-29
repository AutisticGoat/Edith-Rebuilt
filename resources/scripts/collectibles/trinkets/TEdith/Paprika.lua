local mod = EdithRebuilt
local enums = mod.Enums 
local trinket = enums.TrinketType
local Paprika = {}

---@param entity Entity
---@param source EntityRef
---@param amount number
function Paprika:OnKilling(entity, source, _, amount)
    if source.Type == 0 then return end

    local player = mod.GetPlayerFromRef(source)

    if not player then return end
    if not player:HasTrinket(trinket.TRINKET_PAPRIKA) then return end
    if not mod.RandomBoolean(player:GetTrinketRNG(trinket.TRINKET_PAPRIKA)) then return end

    local Paprikacloud = Isaac.Spawn(
        EntityType.ENTITY_EFFECT,
        EffectVariant.POOF02,
        2,
        entity.Position,
        Vector.Zero,
        nil
    )

    local paprikaMult = player:GetTrinketMultiplier(trinket.TRINKET_PAPRIKA)
    local DamageAdder = (0.05 * paprikaMult) - 0.05

    mod:ChangeColor(Paprikacloud, 0.8, 0.2, 0, 1)

    for _, CapsuleEnt in ipairs(Isaac.FindInCapsule(Capsule(entity.Position, Vector.One, 0, 40), EntityPartition.ENEMY)) do
        CapsuleEnt:TakeDamage(amount * (0.25 * DamageAdder), 0, source, 0)
        CapsuleEnt:AddBurn(source, 60, amount * 0.2)
        mod.TriggerPush(CapsuleEnt, entity, 20, 3, false)
    end
end
mod:AddCallback(PRE_NPC_KILL.ID, Paprika.OnKilling)