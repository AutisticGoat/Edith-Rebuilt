function edithMod:OnSpawningSalt(effect)
	if effect.SubType ~= edithMod.Enums.SubTypes.SALT_CREEP then 
		return 
	end
	
	local rng = edithMod.Enums.Utils.RNG
	local saltFrame = tostring(edithMod:RandomNumber(rng, 1, 6))
		
	local saltSprite = effect:GetSprite()
	saltSprite:Play("SmallBlood0" .. saltFrame, true)	
end
edithMod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, edithMod.OnSpawningSalt, EffectVariant.PLAYER_CREEP_RED)

function edithMod:AddSaltEffects(effect)
	if effect.SubType ~= edithMod.Enums.SubTypes.SALT_CREEP then 
		return 
	end
	
	local effectData = edithMod:GetData(effect)
	-- local player = effect.SpawnetEntity:ToPlayer()
	
	-- print()
	
	-- for k, v in pairs(effectData) do
		-- print(k, v)
	-- end
	
	for i, entity in pairs(Isaac.GetRoomEntities()) do
		if entity:IsVulnerableEnemy() and entity:IsActiveEnemy() then
			if entity.Position:Distance(effect.Position) <= 20 then
				entity:AddFreeze(EntityRef(effect), 90)
				
				-- print(effectData.SpawnType == "Sal" )
				if effectData.SpawnType == "Sal" then
					local enemyData = edithMod:GetData(entity)
					
					enemyData.SalFreeze = true
				end
			end
		end
	end
end
edithMod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, edithMod.AddSaltEffects, EffectVariant.PLAYER_CREEP_RED)