local sfx = SFXManager()

function edithMod:UseSaltShaker(Id, RNG, player, flags, slot, data)
	local SoundPitch = edithMod:RandomNumber(RNG, 0.9, 1.1)

	for i, entity in pairs(Isaac.FindByType(EntityType.ENTITY_EFFECT)) do
		local effectData = edithMod:GetData(entity)
		
		if effectData.SpawnType == "SaltShakerSpawn" then
			entity:Remove()
		end
	
	end

	sfx:Play(edithMod.Enums.SoundEffect.SOUND_SALT_SHAKER, 2, 0, false, SoundPitch, 0)
	local SaltQuantity = 17
	local ndegree = 360/SaltQuantity
	for i = 1, SaltQuantity do	
		edithMod:SpawnSaltCreep(player, player.Position + Vector(0, 60):Rotated(ndegree*i), 0, 7, 1, "SaltShakerSpawn")
	end
		
	return true
end
edithMod:AddCallback(ModCallbacks.MC_USE_ITEM, edithMod.UseSaltShaker, edithMod.Enums.CollectibleType.COLLECTIBLE_SALTSHAKER)
