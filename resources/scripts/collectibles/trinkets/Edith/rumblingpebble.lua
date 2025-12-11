local mod = EdithRebuilt
local enums = mod.Enums
local trinket = enums.TrinketType
local data = mod.CustomDataWrapper.getData
local baseHeight = -23.45
local modules = mod.Modules
local ModRNG = modules.RNG
local Helpers = modules.HELPERS
local Player = modules.PLAYER
local RumblingPebble = {}

function RumblingPebble:DestroyRockWithPebble(rock)	
	for _, player in pairs(PlayerManager.GetPlayers()) do
		if not player:HasTrinket(trinket.TRINKET_RUMBLING_PEBBLE) then goto continue end
		local rng = player:GetTrinketRNG(trinket.TRINKET_RUMBLING_PEBBLE)
		local trinketMult = player:GetTrinketMultiplier(trinket.TRINKET_RUMBLING_PEBBLE)
		local totalrocks = rng:RandomInt(2 + trinketMult, 4 + trinketMult)
		local shootDegree = 360 / totalrocks
		local rangemult = Player.GetPlayerRange(player) / 6.5
		local FallSpeedVar

		for i = 1, totalrocks do
			local rockTear = Isaac.Spawn(
				EntityType.ENTITY_TEAR,
				TearVariant.ROCK,
				0,
				rock.Position,
				Vector.One:Rotated((shootDegree + rng:RandomInt(-10, 10)) * i):Resized(10),
				player
			):ToTear()
			
			if not rockTear then return end
			
			FallSpeedVar = ModRNG.RandomFloat(rng, 0.8, 1.2)

			rockTear:AddTearFlags(player.TearFlags | TearFlags.TEAR_ROCK)
			rockTear.FallingAcceleration = ModRNG.RandomFloat(rng, 1.5, 2)
			rockTear.FallingSpeed = (-10 * rangemult) * FallSpeedVar
			rockTear.Height = baseHeight * rangemult
			rockTear.Scale = FallSpeedVar
			rockTear.CollisionDamage = 5.25 * rockTear.Scale
			
			data(rockTear).IsPebbleTear = true
		end
		::continue::
	end
end
mod:AddCallback(ModCallbacks.MC_POST_GRID_ROCK_DESTROY, RumblingPebble.DestroyRockWithPebble)

---@param tear EntityTear
function RumblingPebble:RandomRockTear(tear)
	local player = Helpers.GetPlayerFromTear(tear)

	if not player then return end 
	if not player:HasTrinket(trinket.TRINKET_RUMBLING_PEBBLE) then return end
	local rng = player:GetTrinketRNG(trinket.TRINKET_RUMBLING_PEBBLE)

	if not ModRNG.RandomBoolean(rng, 0.3) then return end
	tear.CollisionDamage = tear.CollisionDamage * ModRNG.RandomFloat(rng, 0.5, 2)
	tear:AddTearFlags(TearFlags.TEAR_ROCK)
	tear:ChangeVariant(TearVariant.ROCK)
	data(tear).IsPebbleTear = true
end
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, RumblingPebble.RandomRockTear)

function RumblingPebble:ShootTear(tear, _, grid)
	if not grid:ToRock() then return end
	if not data(tear).IsPebbleTear then return end
		
	grid:Destroy()
end
mod:AddCallback(ModCallbacks.MC_PRE_TEAR_GRID_COLLISION, RumblingPebble.ShootTear)