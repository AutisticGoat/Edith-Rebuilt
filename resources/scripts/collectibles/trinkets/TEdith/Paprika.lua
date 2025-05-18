local mod = EdithRebuilt
local enums = mod.Enums 
local trinket = enums.TrinketType
local Paprika = {}

---@param entity Entity
---@param amount number
---@param source EntityRef
function Paprika:OnKilling(entity, amount, _, source)
    local ent = source.Entity

    if not ent or ent.Type == EntityType.ENTITY_NULL then return end
    local player = ent:ToPlayer() or mod:GetPlayerFromTear(ent)

    if not player then return end
    if not player:HasTrinket(trinket.TRINKET_PAPRIKA) then return end
    if entity.HitPoints > amount then return end

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
    DebugRenderer.Get(1, true):Capsule(capsule)

    for _, CapsuleEnt in ipairs(Isaac.FindInCapsule(capsule, EntityPartition.ENEMY)) do
        CapsuleEnt:TakeDamage(amount * 0.25, 0, source, 0)
        mod.TriggerPush(CapsuleEnt, ent, 20, 3, false)
        CapsuleEnt:AddBurn(source, 60, amount * 0.2)
    end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, Paprika.OnKilling)