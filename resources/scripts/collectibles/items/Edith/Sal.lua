local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local data = mod.DataHolder.GetEntityData
local saltTypes = enums.SaltTypes
local modules = mod.Modules
local ModRNG = modules.RNG
local Helpers = modules.HELPERS
local Creeps = modules.CREEPS
local StatusEffects = modules.STATUS_EFFECTS
local Sal = {}

local baseRange = 6.5
local baseHeight = -23.45
local baseMultiplier = -70 / baseRange

---@param player EntityPlayer
---@param position Vector
---@param rng RNG
---@param minTears integer
---@param maxTears integer
local function ShootSalTear(player, position, rng, minTears, maxTears)
	local tear
	local fallSpeedVar

    for _ = 1, rng:RandomInt(minTears, maxTears) do
        tear = Isaac.Spawn(EntityType.ENTITY_TEAR, 0, 0, position, rng:RandomVector():Resized(20), player):ToTear() ---@cast tear EntityTear

        fallSpeedVar = ModRNG.RandomFloat(rng, 1.8, 2.2)

		Helpers.ForceSaltTear(tear, false)
		tear.Height = baseHeight * 3
        tear.Velocity = tear.Velocity * ModRNG.RandomFloat(rng, 0.2, 0.6)
        tear.FallingAcceleration = (ModRNG.RandomFloat(rng, 0.7, 1.6)) * 3
        tear.FallingSpeed = (baseMultiplier * (fallSpeedVar)) 
        tear.CollisionDamage = tear.CollisionDamage * rng:RandomInt(8, 12) / 10
		tear.Scale = tear.CollisionDamage/3.5
		tear:AddTearFlags(TearFlags.TEAR_PIERCING)

		data(tear).IsSalTear = true
    end
end

---@param player EntityPlayer
function Sal:SalSpawnSaltCreep(player)
	if not player:HasCollectible(items.COLLECTIBLE_SAL) then return end
	if player.FrameCount % 10 ~= 0 then return end

	local rng = player:GetCollectibleRNG(items.COLLECTIBLE_SAL)
	local gibAmount = rng:RandomInt(2, 5)
	local gibSpeed = ModRNG.RandomFloat(rng, 1, 2.5)

	Creeps.SpawnSaltCreep(player, player.Position, 0.5, 2, gibAmount, gibSpeed, saltTypes.SAL, true, true)
end
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, Sal.SalSpawnSaltCreep)

---@param entity Entity
---@param source EntityRef
function Sal:KillingSalEnemy(entity, source)
	if not StatusEffects.EntHasStatusEffect(entity, enums.EdithStatusEffects.SALTED) then return end
	local player = Helpers.GetPlayerFromRef(source)

	if not player then return end
	if not player:HasCollectible(items.COLLECTIBLE_SAL) then return end

	local Ent = source.Entity
	local tear = Ent and Ent:ToTear()
	if tear and data(tear).IsSalTear then return end

	ShootSalTear(player, entity.Position, player:GetCollectibleRNG(items.COLLECTIBLE_SAL), 8, 12)
end
mod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, Sal.KillingSalEnemy)