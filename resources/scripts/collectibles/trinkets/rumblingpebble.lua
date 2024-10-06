function edithMod:DestroyRockWithPebble(rock)	

	local players = PlayerManager.GetPlayers() 

	for _, player in pairs(players) do
		
		if not player:HasTrinket(edithMod.Enums.TrinketType.TRINKET_RUMBLING_PEBBLE) then return end
		
		-- print(player:GetPlayerType())
		local rng = player:GetTrinketRNG(edithMod.Enums.TrinketType.TRINKET_RUMBLING_PEBBLE)
		local trinketMult = player:GetTrinketMultiplier(edithMod.Enums.TrinketType.TRINKET_RUMBLING_PEBBLE)
		
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
			
		local totalrocks = edithMod:RandomNumber(rng, minRocks, maxRocks)
		
		local shootDegree = 360 / totalrocks

		for i = 1, totalrocks do
			local range = edithMod:GetPlayerRange(player)
			-- print(edithMod:GetPlayerRange(player))
		
			local variation = edithMod:RandomNumber(rng, -10, 10)
			local rockTear = Isaac.Spawn(
				EntityType.ENTITY_TEAR,
				TearVariant.ROCK,
				0,
				rock.Position,
				Vector(1, 1):Rotated((shootDegree + variation) * i) * 10,
				nil
			):ToTear()
			
			local rockData = edithMod:GetData(rockTear)
			
			local baseHeight = -23.45
			local rangeMult = 
			
			rockTear:AddTearFlags(TearFlags.TEAR_ROCK | player.TearFlags)
			
			rockTear.FallingAcceleration = edithMod:RandomNumber(rng, 1.5, 2)			
			
			local FallSpeedVar = edithMod:RandomNumber(rng, 80, 120) / 100
			rockTear.FallingSpeed = (-10 * (range / 6.5)) * FallSpeedVar
			rockTear.Height = baseHeight * (range / 6.5)
			rockTear.Scale = edithMod:RandomNumber(rng, 80, 120) / 100
			rockTear.CollisionDamage = 5.25 * rockTear.Scale
			
			rockData.IsPebbleTear = true
			
			-- print(rockTear.Height)
		end
	end
end
edithMod:AddCallback(ModCallbacks.MC_POST_GRID_ROCK_DESTROY, edithMod.DestroyRockWithPebble)

function edithMod:ShootTear(tear, index, grid)
	local tearData = edithMod:GetData(tear)
	local player = edithMod:GetPlayerFromTear(tear)
	
	local rock = grid:ToRock()
	-- print(rock)
	
	if not rock then return end
	
	if not tearData.IsPebbleTear then return end
	
	
	print("Es lágrima del guijarro ese")
	
	grid:Destroy()
	
	-- for k, v in pairs(tearData) do
		-- print(k, v)
	-- end
	-- print(tearData)
	-- print("colliding with rock")
	-- if not player then return end
	
	
	
	-- if not rock then return end
	
	-- if not tearData.IsPebbleTear then return end
	
	-- print("adkjaslkdn")
	
	-- grid:Destroy()
end
edithMod:AddCallback(ModCallbacks.MC_PRE_TEAR_GRID_COLLISION, edithMod.ShootTear)