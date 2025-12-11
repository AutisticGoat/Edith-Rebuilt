local mod = EdithRebuilt
local enums = mod.Enums 
local modules = mod.Modules
local ModRNG = modules.RNG
local Helpers = modules.HELPERS
local trinket = enums.TrinketType
local Paprika = {}

---@param entity Entity
---@param source EntityRef
---@param amount number
function Paprika:OnKilling(entity, source, _, amount)
    if source.Type == 0 then return end

    local player = Helpers.GetPlayerFromRef(source)

    if not player then return end
    if not player:HasTrinket(trinket.TRINKET_PAPRIKA) then return end
    if not ModRNG.RandomBoolean(player:GetTrinketRNG(trinket.TRINKET_PAPRIKA)) then return end

    local entPos = entity.Position
    local paprikaMult = player:GetTrinketMultiplier(trinket.TRINKET_PAPRIKA)
    local Paprikacloud = Isaac.Spawn(
        EntityType.ENTITY_EFFECT,
        EffectVariant.POOF02,
        2,
        entPos,
        Vector.Zero,
        nil
    )
    Helpers.ChangeColor(Paprikacloud, 0.8, 0.2, 0, 1)

    for _, Ent in ipairs(Isaac.FindInCapsule(Capsule(entPos, Vector.One, 0, 40), EntityPartition.ENEMY)) do
        Ent:TakeDamage(amount * (0.25 * ((0.05 * paprikaMult) - 0.05)), 0, source, 0)
        Ent:AddBurn(source, 60, amount * 0.2)
        mod.TriggerPush(Ent, entity, 20, 3, false)
    end
end
mod:AddCallback(PRE_NPC_KILL.ID, Paprika.OnKilling)