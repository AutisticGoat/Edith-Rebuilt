local mod = edithMod
local enums = mod.Enums
local subtype = enums.SubTypes
local utils = enums.Utils
local rng = utils.RNG

local function isSaltCreepEffect(effect)
    return effect.SubType == subtype.SALT_CREEP
end

function mod:OnSpawningSalt(effect)
    if not isSaltCreepEffect(effect) then return end
    local saltFrame = tostring(rng:RandomInt(1, 6))
    local saltSprite = effect:GetSprite()
    saltSprite:Play("SmallBlood0" .. saltFrame, true)    
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, mod.OnSpawningSalt, EffectVariant.PLAYER_CREEP_RED)

function edithMod:AddSaltEffects(effect)
    if not isSaltCreepEffect(effect) then return end
    
    local effectData = edithMod.GetData(effect)
    local entities = Isaac.GetRoomEntities()
    local effectPos = effect.Position

    for _, entity in pairs(entities) do
        if not (entity:IsVulnerableEnemy() and entity:IsActiveEnemy()) then goto Break end
		local distance = entity.Position:Distance(effectPos)

        if distance > 20 then goto Break end
        entity:AddFreeze(EntityRef(effect), 90)

        if effectData.SpawnType == "Sal" then
            local enemyData = edithMod.GetData(entity)
            enemyData.SalFreeze = true
        end

        ::Break::
    end
end
edithMod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, edithMod.AddSaltEffects, EffectVariant.PLAYER_CREEP_RED)
