local mod = EdithRebuilt
local modules = mod.Modules
local effects = mod.Enums.EdithStatusEffects
local Status = modules.STATUS_EFFECTS
local Helpers = modules.HELPERS
local ModRNG = modules.RNG
local baseRange = 6.5
local baseHeight = -23.45
local baseMultiplier = -70 / baseRange
local data = mod.DataHolder.GetEntityData
local function ShootMercuryTear(player, position, rng)
	local tear
	local fallSpeedVar

    tear = Isaac.Spawn(EntityType.ENTITY_TEAR, 0, 0, position, rng:RandomVector():Resized(20), player):ToTear()

    if not tear then return end

    fallSpeedVar = ModRNG.RandomFloat(rng, 1.8, 2.2)

    Helpers.ForceSaltTear(tear, false)
    tear.Height = baseHeight * 3
    tear.Velocity = tear.Velocity * ModRNG.RandomFloat(rng, 0.2, 0.6)
    tear.FallingAcceleration = (ModRNG.RandomFloat(rng, 0.7, 1.6)) * 3
    tear.FallingSpeed = (baseMultiplier * (fallSpeedVar)) 
    tear.CollisionDamage = tear.CollisionDamage * rng:RandomInt(8, 12) / 10
    tear.Scale = tear.CollisionDamage/3.5
    tear:ChangeVariant(TearVariant.METALLIC)
    tear:AddTearFlags(TearFlags.TEAR_PIERCING)

    data(tear).IsHydrargyrumTear = true
end

---@param npc EntityNPC
local function OnHydrargyrumCurseUpdate(npc)
    if not Status.EntHasStatusEffect(npc, effects.HYDRARGYRUM_CURSE) then return end

    local data = Status.GetStatusEffectData(npc, effects.HYDRARGYRUM_CURSE)
    if data.Countdown % 15 ~= 0 then return end

    local player = Helpers.GetPlayerFromRef(data.Source) 
    if not player then return end

    ShootMercuryTear(player, npc.Position, mod.Enums.Utils.RNG)
end

---@param tear EntityTear
local function OnMercuryTearDeath(_, tear)
    if not data(tear).IsHydrargyrumTear then return end

    local player = Helpers.GetPlayerFromTear(tear)
    if not player then return end
    local weapon = player:GetWeapon(1)
    if not weapon then return end

    local tearHits = player:GetTearHitParams(weapon:GetWeaponType())
    tearHits.TearFlags = TearFlags.TEAR_NORMAL | TearFlags.TEAR_BURN

    local Creep = player:SpawnAquariusCreep(tearHits)
    Creep.Position = tear.Position
    Creep.Color = Color(0, 0, 0, 1, 0.6, 0.6, 0.6)
end
mod:AddCallback(ModCallbacks.MC_POST_TEAR_DEATH, OnMercuryTearDeath)

---@param npc EntityNPC
local function OnNpcUpdate(_, npc)
    OnHydrargyrumCurseUpdate(npc)
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, OnNpcUpdate)