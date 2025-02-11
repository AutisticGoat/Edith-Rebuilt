function edithMod:ShootSaltTears(tear)
	local player = edithMod:GetPlayerFromTear(tear)
	
	if not player then return end
	
	if not player:HasCollectible(edithMod.Enums.CollectibleType.COLLECTIBLE_EDITHS_HOOD) then return end
	
	edithMod:ForceSaltTear(tear)
	
	local rng = player:GetCollectibleRNG(edithMod.Enums.CollectibleType.COLLECTIBLE_EDITHS_HOOD)
	local randomSpawnChance = edithMod:RandomNumber(6)
end
edithMod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, edithMod.ShootSaltTears)

function edithMod:HoodStats(player, flags)
	if not player:HasCollectible(edithMod.Enums.CollectibleType.COLLECTIBLE_EDITHS_HOOD) then return end

	if flags == CacheFlag.CACHE_DAMAGE then
		player.Damage = player.Damage * 1.35
	elseif flags == CacheFlag.CACHE_FIREDELAY then
		player.MaxFireDelay = edithMod.tearsUp(player.MaxFireDelay, 0.8, true)
	end	
end
edithMod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, edithMod.HoodStats)

function edithMod:onKillWithTear(tear, collider)
	local player = edithMod:GetPlayerFromTear(tear)
	
	if not player then return end 
	if not player:HasCollectible(edithMod.Enums.CollectibleType.COLLECTIBLE_EDITHS_HOOD) then return end
	if not (collider:IsActiveEnemy() and collider:IsVulnerableEnemy()) then return end
	
	if collider.HitPoints <= tear.CollisionDamage then
		local rng = player:GetCollectibleRNG(edithMod.Enums.CollectibleType.COLLECTIBLE_EDITHS_HOOD)	
		local randomSpawnChance = edithMod:RandomNumber(5)
		
		if randomSpawnChance ~= 1 then return end
		
		local maxCreep = 5	
		local saltDegrees = 360 / maxCreep
		
		for i = 1, maxCreep do
			edithMod:SpawnSaltCreep(player, collider.Position + Vector(0, 18):Rotated(saltDegrees*i), 1, 5, 1, "SaltShakerSpawn")
		end
	end
end
edithMod:AddCallback(ModCallbacks.MC_PRE_TEAR_COLLISION, edithMod.onKillWithTear)