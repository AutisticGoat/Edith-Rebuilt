local mod = EdithRebuilt
local modules = mod.Modules
local effects = mod.Enums.EdithStatusEffects
local Status = modules.STATUS_EFFECTS
local Helpers = modules.HELPERS
local ModRNG = modules.RNG
local damageFlag = false

---@param entity Entity
---@param rng RNG
local function SpawnTurmericCloud(entity, rng)
    local Puff = Status.SpawnSpicePuff(entity, rng)
    Puff:GetSprite().PlaybackSpeed = ModRNG.RandomFloat(rng, 0.9, 1.1)
    Puff.Color = Color(1, 1, 1, 1, 250/255, 198/255, 49/255)
end

---@param entity Entity
local function SetTurmeric(entity)
    local rng = RNG(math.max(Random(), 1))

    for _, enemy in ipairs(Isaac.FindInRadius(entity.Position, 60, EntityPartition.ENEMY)) do
        if not Helpers.IsEnemy(enemy) then goto continue end
        if not ModRNG.RandomBoolean(rng, 0.35) then goto continue end

        SpawnTurmericCloud(entity, rng)
        Status.SetStatusEffect(effects.TURMERIC, enemy, 90, entity)
        ::continue::
    end
end

---@param entity Entity
---@param amount number
---@param flags DamageFlag
---@param source EntityRef
---@param Cooldown integer
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, entity, amount, flags, source, Cooldown)
    if not Status.EntHasStatusEffect(entity, effects.TURMERIC) then return end
    if not amount == (amount * 1.25) then return end
    if damageFlag == true then return end

    damageFlag = true
    entity:TakeDamage(amount * 1.25, flags, source, Cooldown)
    SetTurmeric(entity)
    damageFlag = false

    return false
end)