local game = edithMod.Enums.Utils.Game

local baseDestroyChance = 0.25
local spawnChance = 0.025

local spawnedRune = false

function edithMod:SpawnOnKill(entity, damage, flag, source, cooldown)
	if source.Type == 0 then return end
	
	local playerEntity = source.Entity:ToPlayer()
	local familiarEntity = source.Entity:ToFamiliar()
	local tearEntity = source.Entity:ToTear()
	
	local player = (
		playerEntity or
		familiarEntity and familiarEntity.Player or
		tearEntity and edithMod:GetPlayerFromTear(tearEntity) 
	)
		
	if not player then return end
	
	if not player:HasTrinket(edithMod.Enums.TrinketType.TRINKET_GEODE) then return end
	
	local trinketMult = player:GetTrinketMultiplier(edithMod.Enums.TrinketType.TRINKET_GEODE)
	local rng = player:GetTrinketRNG(edithMod.Enums.TrinketType.TRINKET_GEODE)
	local spawnRuneRoll = edithMod:RandomNumber()
		
	if entity:IsActiveEnemy() and entity:IsVulnerableEnemy() and spawnedRune == false then
		print(entity:IsDead())
		if entity.HitPoints < damage then
			if spawnRuneRoll <= spawnChance then					
				 
				local vec = Vector.One
				
					
				Isaac.Spawn(
					EntityType.ENTITY_PICKUP,
					PickupVariant.PICKUP_TAROTCARD,
					randomRune,
					entity.Position,
					Vector.Zero + vec:Rotated(90),
					player
				)
		
				spawnedRune = true
			end
		end
		print(cooldown)
	end
end
-- edithMod:AddCallback(ModCallbacks.MC_POST_ENTITY_TAKE_DMG, edithMod.SpawnOnKill)


function edithMod:SpawnRuneOnKill(entity)
	local players = PlayerManager.GetPlayers()
	
	for _, player in ipairs(players) do
		if not player:HasTrinket(edithMod.Enums.TrinketType.TRINKET_GEODE) then return end
		
		local trinketMult = player:GetTrinketMultiplier(edithMod.Enums.TrinketType.TRINKET_GEODE)
		local rng = player:GetTrinketRNG(edithMod.Enums.TrinketType.TRINKET_GEODE)
		local spawnRuneRoll = edithMod:RandomNumber(rng)
		
		local effectMult = {
			[2] = 1.25,
			[3] = 1.5,
			[4] = 1.75,
			[5] = 2
		}
			
		local multiplier = edithMod.SwitchCase(trinketMult, effectMult) or 1
		
		print(spawnRuneRoll)
		
		if spawnRuneRoll < spawnChance then
			local randomRune = edithMod:GetRandomRune(rng)
		
			
			
			spawnChance = math.min((spawnChance + 0.025) * multiplier, 0.125 * multiplier)
			baseDestroyChance = math.min((baseDestroyChance + 0.0625) * multiplier, 0.5 * multiplier)
		
			Isaac.Spawn(
				EntityType.ENTITY_PICKUP,
				PickupVariant.PICKUP_TAROTCARD,
				randomRune,
				entity.Position,
				Vector.Zero,
				player
			)
		
		end
		
	print(spawnChance, baseDestroyChance, multiplier)
	end
end
edithMod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, edithMod.SpawnRuneOnKill)

function edithMod:DestroyGeode(player, damage, flag, source, cooldown)
	if not player:HasTrinket(edithMod.Enums.TrinketType.TRINKET_GEODE) then return end
	
	local rng = player:GetTrinketRNG(edithMod.Enums.TrinketType.TRINKET_GEODE)
	local trinketMult = player:GetTrinketMultiplier(edithMod.Enums.TrinketType.TRINKET_GEODE)
	
	local breakGeodeRoll = edithMod:RandomNumber(rng)
	local baseRunes = 3
	
	local totalRune = baseRunes + (trinketMult - 1)
		
	local spawnDegree = 360 / totalRune
				
	for i = 1, totalRune do
		local randomRune = edithMod:GetRandomRune(rng)		
		Isaac.Spawn(
			EntityType.ENTITY_PICKUP,
			PickupVariant.PICKUP_TAROTCARD,
			randomRune,
			player.Position,
			Vector(1, 1):Rotated(spawnDegree * i) * 1.3,
			player
		)
	end
	
	player:TryRemoveTrinket(edithMod.Enums.TrinketType.TRINKET_GEODE)
end
edithMod:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, edithMod.DestroyGeode)
