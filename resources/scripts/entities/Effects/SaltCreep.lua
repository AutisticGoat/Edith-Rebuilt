local mod = EdithRebuilt
local enums = mod.Enums
local subtype = enums.SubTypes
local utils = enums.Utils
local rng = utils.RNG
local data = mod.CustomDataWrapper.getData
local SaltCreep = {}

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

function SaltCreep:AddSaltEffects(effect)
    if not isSaltCreepEffect(effect) then return end
    
    local effectData = data(effect)
    local entities = mod.GetEnemies()
    local effectPos = effect.Position

    for _, entity in pairs(entities) do
		local distance = entity.Position:Distance(effectPos)

        if distance > 20 then goto Break end
        entity:AddFreeze(EntityRef(effect), 90)

        if effectData.SpawnType == "Sal" then
            local enemyData = data(entity)
            enemyData.SalFreeze = true
        end

        ::Break::
    end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, SaltCreep.AddSaltEffects, EffectVariant.PLAYER_CREEP_RED)
