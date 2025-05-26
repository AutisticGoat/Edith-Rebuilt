local mod = EdithRebuilt
local enums = mod.Enums
local trinket = enums.TrinketType
local plyMan = PlayerManager
local data = mod.CustomDataWrapper.getData
local RumblingPebble = {}

function RumblingPebble:DestroyRockWithPebble(rock)	
	local players = plyMan.GetPlayers() 
	for _, player in pairs(players) do
		if not player:HasTrinket(trinket.TRINKET_RUMBLING_PEBBLE) then return end
		local rng = player:GetTrinketRNG(trinket.TRINKET_RUMBLING_PEBBLE)
		local trinketMult = player:GetTrinketMultiplier(trinket.TRINKET_RUMBLING_PEBBLE)
		local minRocks = 2 + trinketMult
		local maxRocks = 4 + trinketMult
		local totalrocks = rng:RandomInt(minRocks, maxRocks)
		local shootDegree = 360 / totalrocks
		local range = mod.GetPlayerRange(player)

		for i = 1, totalrocks do
			local variation = rng:RandomInt(-10, 10)
			local rockTear = Isaac.Spawn(
				EntityType.ENTITY_TEAR,
				TearVariant.ROCK,
				0,
				rock.Position,
				Vector.One:Rotated((shootDegree + variation) * i) * 10,
				player
			):ToTear()
			
			if not rockTear then return end
			local rockData = data(rockTear)
			
			local baseHeight = -23.45			
			rockTear:AddTearFlags(TearFlags.TEAR_ROCK | player.TearFlags)
			
			rockTear.FallingAcceleration = rng:RandomInt(15, 20) / 10			
			
			local FallSpeedVar = rng:RandomInt(80, 120) / 100
			rockTear.FallingSpeed = (-10 * (range / 6.5)) * FallSpeedVar
			rockTear.Height = baseHeight * (range / 6.5)
			rockTear.Scale = rng:RandomInt(80, 120) / 100
			rockTear.CollisionDamage = 5.25 * rockTear.Scale
			
			rockData.IsPebbleTear = true
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_GRID_ROCK_DESTROY, RumblingPebble.DestroyRockWithPebble)

---comment
---@param tear EntityTear
function mod:RandomRockTear(tear)
	local player = mod:GetPlayerFromTear(tear)

	if not player then return end 
	if not player:HasTrinket(trinket.TRINKET_RUMBLING_PEBBLE) then return end
	local rng = player:GetTrinketRNG(trinket.TRINKET_RUMBLING_PEBBLE)
	local randomRockTearChance = rng:RandomInt(1, 100)

	if randomRockTearChance > 30 then return end
	local data = data(tear)
	local randomDamageVar = rng:RandomInt(500, 2000) / 1000
	tear:AddTearFlags(TearFlags.TEAR_ROCK)
	tear:ChangeVariant(TearVariant.ROCK)
	tear.CollisionDamage = tear.CollisionDamage * randomDamageVar
	data.IsPebbleTear = true
end
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, mod.RandomRockTear)

function RumblingPebble:ShootTear(tear, _, grid)
	local tearData = data(tear)

	if not grid:ToRock() then return end
	if not tearData.IsPebbleTear then return end
		
	grid:Destroy()
end
mod:AddCallback(ModCallbacks.MC_PRE_TEAR_GRID_COLLISION, RumblingPebble.ShootTear)