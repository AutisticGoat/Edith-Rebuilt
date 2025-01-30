local function isSaltCreepEffect(effect)
    return effect.SubType == edithMod.Enums.SubTypes.SALT_CREEP
end

function edithMod:OnSpawningSalt(effect)
    if not isSaltCreepEffect(effect) then 
        return 
    end
    
    local saltFrame = tostring(edithMod:RandomNumber(1, 6))
    local saltSprite = effect:GetSprite()
    saltSprite:Play("SmallBlood0" .. saltFrame, true)    
end
edithMod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, edithMod.OnSpawningSalt, EffectVariant.PLAYER_CREEP_RED)

function edithMod:AddSaltEffects(effect)
    if not isSaltCreepEffect(effect) then 
        return 
    end
    
    local effectData = edithMod:GetData(effect)
    local entities = Isaac.GetRoomEntities()
    
    for _, entity in pairs(entities) do
        if entity:IsVulnerableEnemy() and entity:IsActiveEnemy() then
			local distance = entity.Position:Distance(effect.Position)

            if distance <= 20 then
                entity:AddFreeze(EntityRef(effect), 90)
                if effectData.SpawnType == "Sal" then
                    local enemyData = edithMod:GetData(entity)
                    enemyData.SalFreeze = true
                end
            end
        end
    end
end
edithMod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, edithMod.AddSaltEffects, EffectVariant.PLAYER_CREEP_RED)
