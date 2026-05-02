local mod = EdithRebuilt
local enums = mod.Enums
local trinket = enums.TrinketType
local modules = mod.Modules
local ModRNG = modules.RNG
local Helpers = modules.HELPERS

---@param entity Entity
local function SpawnPaprikaCloud(entity)
    local cloud = Isaac.Spawn(
        EntityType.ENTITY_EFFECT,
        EffectVariant.POOF02,
        2,
        entity.Position,
        Vector.Zero,
        nil
    )
    Helpers.ChangeColor(cloud, 0.8, 0.2, 0, 1)
end

---@param player EntityPlayer
---@param entity Entity
---@param amount number
---@param source EntityRef
local function DamageEnemies(player, entity, amount, source)
    local paprikaMult = player:GetTrinketMultiplier(trinket.TRINKET_PAPRIKA)
    local scaledDamage = amount * (0.0125 * (paprikaMult - 1))
    local enemies = Isaac.FindInCapsule(Capsule(entity.Position, Vector.One, 0, 40), EntityPartition.ENEMY)

    for _, ent in ipairs(enemies) do
        ent:TakeDamage(scaledDamage, 0, source, 0)
        ent:AddBurn(source, 60, amount * 0.2)
        Helpers.TriggerPush(ent, entity, 20)
    end
end

---@param entity Entity
---@param source EntityRef
---@param amount number
mod:AddCallback(PRE_NPC_KILL.ID, function(_, entity, source, _, amount)
    if source.Type == 0 then return end

    local player = Helpers.GetPlayerFromRef(source)

    if not player then return end
    if not player:HasTrinket(trinket.TRINKET_PAPRIKA) then return end
    if not ModRNG.RandomBoolean(player:GetTrinketRNG(trinket.TRINKET_PAPRIKA)) then return end

    SpawnPaprikaCloud(entity)
    DamageEnemies(player, entity, amount, source)
end)