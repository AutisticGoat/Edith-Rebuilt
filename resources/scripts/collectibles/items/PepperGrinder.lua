local sfx = edithMod.Enums.Utils.SFX

function edithMod:UsePepperGrinder(Id, RNG, player, flags, slot, data)
	local SoundPitch = edithMod:RandomNumber(RNG, 0.9, 1.1)

	for _, enemy in ipairs(Isaac.FindInRadius(player.Position, 100, EntityPartition.ENEMY)) do
		local enemyData = edithMod:GetData(enemy)
		enemy.Velocity = (enemy.Position - player.Position):Resized(20)
		enemyData.PepperFrames = 60
	end
	
	
	print(flags)
	sfx:Play(edithMod.Enums.SoundEffect.SOUND_PEPPER_GRINDER, 10, 0, false, SoundPitch, 0)
		
	return true
end
edithMod:AddCallback(ModCallbacks.MC_USE_ITEM, edithMod.UsePepperGrinder, edithMod.Enums.CollectibleType.COLLECTIBLE_PEPPERGRINDER)

function edithMod:myFunction2(entity) 
	local enemyData = edithMod:GetData(entity)
	
	if not enemyData.PepperFrames then return end
	
	if enemyData.PepperFrames < 1 then return end
	
	enemyData.PepperFrames = enemyData.PepperFrames - 1
	
	if enemyData.PepperFrames % 10 == 0 then
		-- entity:TakeDamage(2, Flags, Source, DamageCountdown)
		
		edithMod:SpawnPepperCreep(entity, entity.Position, 1, 0.6)
	end
end
edithMod:AddCallback(ModCallbacks.MC_NPC_UPDATE, edithMod.myFunction2)
