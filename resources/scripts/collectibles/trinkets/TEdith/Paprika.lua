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

    local rng = player:GetTrinketRNG(TrinketType.TRINKET_PAPER_CLIP)
    local explodeRoll = rng:RandomInt(1, 100)

    if explodeRoll > 50 then return end

    local Paprikacloud = Isaac.Spawn(
        EntityType.ENTITY_EFFECT,
        EffectVariant.POOF02,
        2,
        entity.Position,
        Vector.Zero,
        nil
    )

    local color = Paprikacloud.Color
    color:SetTint(0.8, 0.2, 0, 1)
    Paprikacloud.Color = color

    local capsule = Capsule(entity.Position, Vector.One, 0, 40)

    for _, CapsuleEnt in ipairs(Isaac.FindInCapsule(capsule, EntityPartition.ENEMY)) do
        CapsuleEnt:TakeDamage(amount * 0.25, 0, source, 0)
        CapsuleEnt:AddBurn(source, 60, amount * 0.2)
        mod.TriggerPush(CapsuleEnt, player, 20, 3, false)
    end
end
mod:AddCallback(PRE_NPC_KILL.ID, Paprika.OnKilling)