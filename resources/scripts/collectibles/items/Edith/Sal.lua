local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local data = mod.CustomDataWrapper.getData
local saltTypes = enums.SaltTypes
local Sal = {}

local baseRange = 6.5
local baseHeight = -23.45
local baseMultiplier = -70 / baseRange

local function ShootSalTear(player, position, rng, minTears, maxTears)
	local tear
	local fallSpeedVar

    for _ = 1, rng:RandomInt(minTears, maxTears) do
        tear = Isaac.Spawn(EntityType.ENTITY_TEAR, 0, 0, position, rng:RandomVector():Resized(20), player):ToTear()

        if not tear then return end

        fallSpeedVar = mod.RandomFloat(rng, 1.8, 2.2)

		mod.ForceSaltTear(tear)
		tear.Height = baseHeight * 3
        tear.Velocity = tear.Velocity * mod.RandomFloat(rng, 0.2, 0.6)
        tear.FallingAcceleration = (mod.RandomFloat(rng, 0.7, 1.6)) * 3
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
	if player.FrameCount % 15 ~= 0 then return end

	local rng = player:GetCollectibleRNG(items.COLLECTIBLE_SAL)
	local randomGib = {
		amount = rng:RandomInt(2, 5),
		speed = mod.RandomFloat(rng, 1, 2.5) 
	}
	mod:SpawnSaltCreep(player, player.Position, 0, 3, randomGib.amount, randomGib.speed, saltTypes.SAL, true, true)
end
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, Sal.SalSpawnSaltCreep)

---@param entity Entity
---@param source EntityRef
function Sal:KillingSalEnemy(entity, source)
	if not mod.IsSalted(entity) then return end

	local Ent = source.Entity
	local player = mod.GetPlayerFromRef(source)
	local tear = Ent and Ent:ToTear()
	
	if not player then return end
	if not player:HasCollectible(items.COLLECTIBLE_SAL) then return end
	if tear and data(tear).IsSalTear then return end

	ShootSalTear(player, entity.Position, player:GetCollectibleRNG(items.COLLECTIBLE_SAL), 6, 12)
end
mod:AddCallback(PRE_NPC_KILL.ID, Sal.KillingSalEnemy)