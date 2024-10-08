local game = edithMod.Enums.Utils.Game

function edithMod:SalSpawnSaltCreep(player)
	local shouldSpawnSalt = game:GetFrameCount() % 15 == 0

	if not player:HasCollectible(edithMod.Enums.CollectibleType.COLLECTIBLE_SAL) then return end
	
	if not shouldSpawnSalt then return end
	
	edithMod:SpawnSaltCreep(player, player.Position, 1, 3, 2, "Sal")
end
edithMod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, edithMod.SalSpawnSaltCreep)

function edithMod:KillingSalEnemy(entity, amount, flags, source, countdown)
	local entityData = edithMod:GetData(entity)

	if entityData.SalFreeze ~= true then return end

	if entity.HitPoints >= amount then return end

	local Ent = source.Entity
	local player = Ent:ToPlayer() or edithMod:GetPlayerFromTear(Ent)
	local tear = Ent:ToTear()

	if tear then
		local entTearData = edithMod:GetData(tear)
		if entTearData.IsSalTear == true then return end
	end

	if not player then return end
	
	local rng = player:GetCollectibleRNG(edithMod.Enums.CollectibleType.COLLECTIBLE_SAL)
	
	local randomTears = rng:RandomInt(4, 6)
	
	for i = 1, randomTears do
		local tears = player:FireTear(entity.Position, RandomVector() * (player.ShotSpeed * 10), false, false, false, player, 1):ToTear()
		
		local tearData = edithMod:GetData(tears)
		
		tears:AddTearFlags(TearFlags.TEAR_PIERCING)
		
		tearData.IsSalTear = true
	end
end
edithMod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, edithMod.KillingSalEnemy)