local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local modules = mod.Modules
local ModRNG = modules.RNG
local Helpers = modules.HELPERS
local DivineWrath = {}

local baseRange = 6.5
local baseHeight = -23.45
local baseMultiplier = -70 / baseRange

---comment
---@param player EntityPlayer
---@param rng RNG
---@param minTears integer
---@param maxTears integer
local function ShootFireRockTear(player, rng, minTears, maxTears)
	local tear
	local fallSpeedVar

    for _ = 1, rng:RandomInt(minTears, maxTears) do
        tear = Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.ROCK, 0, player.Position, rng:RandomVector():Resized(20) + player.Velocity, player):ToTear()

        if not tear then return end

        fallSpeedVar = ModRNG.RandomFloat(rng, 1.8, 2.2)

		tear.Visible = false
		tear.Height = baseHeight * 3
        tear.Velocity = tear.Velocity * ModRNG.RandomFloat(rng, 0.2, 0.6)
        tear.FallingAcceleration = (ModRNG.RandomFloat(rng, 0.7, 1.6)) * 3
        tear.FallingSpeed = (baseMultiplier * (fallSpeedVar)) 
        tear.CollisionDamage = tear.CollisionDamage * rng:RandomInt(8, 12) / 10
		tear.Scale = tear.CollisionDamage/3.5
        tear:AddTearFlags(TearFlags.TEAR_BURN)
        Helpers.ChangeColor(tear, 1, 0.2, 0)

		tear.Visible = true
    end
end

---@param rng RNG
---@param player EntityPlayer
function DivineWrath:OnUse(_, rng, player)
    ShootFireRockTear(player, rng, 8, 12)

    for ring = 1, 2 do
		local dist = ring == 1 and 40 or 20
		for rocks = 1, 6 do
			CustomShockwaveAPI:SpawnCustomCrackwave(
				player.Position, -- Position
				player, -- Spawner
				dist, -- Steps
				rocks * (360 / 6), -- Angle
				1, -- Delay
				ring, -- Limit
				player.Damage / 2 -- Damage
			)
		end
	end

	return true
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, DivineWrath.OnUse, items.COLLECTIBLE_DIVINE_WRATH)