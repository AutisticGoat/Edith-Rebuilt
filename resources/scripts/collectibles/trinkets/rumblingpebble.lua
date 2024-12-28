local mod = edithMod
local enums = mod.Enums
local trinket = enums.TrinketType


function edithMod:DestroyRockWithPebble(rock)	

	local players = PlayerManager.GetPlayers() 

	for _, player in pairs(players) do
		
		if not player:HasTrinket(trinket.TRINKET_RUMBLING_PEBBLE) then return end
		
		-- print(player:GetPlayerType())
		local rng = player:GetTrinketRNG(trinket.TRINKET_RUMBLING_PEBBLE)
		local trinketMult = player:GetTrinketMultiplier(trinket.TRINKET_RUMBLING_PEBBLE)
		
		local minRockMult = {
			[1] = 3,
			[2] = 3,
			[3] = 4,
			[4] = 4,
			[5] = 5,
		}
		local minRocks = edithMod.SwitchCase(trinketMult, minRockMult)
		
		local maxRockMult = {
			[1] = 5,
			[2] = 6,
			[3] = 7,
			[4] = 8,
			[5] = 9,
		}
		local maxRocks = edithMod.SwitchCase(trinketMult, maxRockMult)
			
		local totalrocks = edithMod:RandomNumber(minRocks, maxRocks)
		
		local shootDegree = 360 / totalrocks

		for i = 1, totalrocks do
			local range = edithMod:GetPlayerRange(player)
		
			local variation = edithMod:RandomNumber(-10, 10)
			local rockTear = Isaac.Spawn(
				EntityType.ENTITY_TEAR,
				TearVariant.ROCK,
				0,
				rock.Position,
				Vector(1, 1):Rotated((shootDegree + variation) * i) * 10,
				player
			):ToTear()
			
			if not rockTear then return end

			local rockData = edithMod:GetData(rockTear)
			
			local baseHeight = -23.45			
			rockTear:AddTearFlags(TearFlags.TEAR_ROCK | player.TearFlags)
			
			rockTear.FallingAcceleration = edithMod:RandomNumber(1.5, 2)			
			
			local FallSpeedVar = edithMod:RandomNumber(80, 120) / 100
			rockTear.FallingSpeed = (-10 * (range / 6.5)) * FallSpeedVar
			rockTear.Height = baseHeight * (range / 6.5)
			rockTear.Scale = edithMod:RandomNumber(80, 120) / 100
			rockTear.CollisionDamage = 5.25 * rockTear.Scale
			
			rockData.IsPebbleTear = true
		end
	end
end
edithMod:AddCallback(ModCallbacks.MC_POST_GRID_ROCK_DESTROY, edithMod.DestroyRockWithPebble)

---comment
---@param tear EntityTear
function mod:RandomRockTear(tear)
	local player = edithMod:GetPlayerFromTear(tear)

	if not player then return end 
	if not player:HasTrinket(trinket.TRINKET_RUMBLING_PEBBLE) then return end
	local rng = player:GetTrinketRNG(trinket.TRINKET_RUMBLING_PEBBLE)
	local randomRockTearChance = edithMod:RandomNumber(1, 100, rng)

	if randomRockTearChance <= 30 then
		local randomDamageVar = edithMod:RandomNumber(500, 2000) / 1000
		tear:AddTearFlags(TearFlags.TEAR_ROCK)
		tear:ChangeVariant(TearVariant.ROCK)
		tear.CollisionDamage = tear.CollisionDamage * randomDamageVar
	end
end
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, mod.RandomRockTear)

function edithMod:ShootTear(tear, index, grid)
	local tearData = edithMod:GetData(tear)
	local player = edithMod:GetPlayerFromTear(tear)

	local rock = grid:ToRock()	
	if not rock then return end
	if not tearData.IsPebbleTear then return end
	
	print("Es lágrima del guijarro ese")
	
	grid:Destroy()
end
edithMod:AddCallback(ModCallbacks.MC_PRE_TEAR_GRID_COLLISION, edithMod.ShootTear)