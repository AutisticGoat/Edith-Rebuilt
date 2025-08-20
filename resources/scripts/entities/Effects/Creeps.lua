local mod = EdithRebuilt
local enums = mod.Enums
local subtype = enums.SubTypes
local game = enums.Utils.Game
local data = mod.CustomDataWrapper.getData

---@param effect EntityEffect
local function isModCreepEffect(effect)
    local subType = effect.SubType
    return subType == subtype.SALT_CREEP or subType == subtype.PEPPER_CREEP
end

---@param effect EntityEffect 
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, function(_, effect)
    if not isModCreepEffect(effect) then return end
    effect:GetSprite():Play("SmallBlood0" .. tostring(effect:GetDropRNG():RandomInt(1, 6)), true)
end, EffectVariant.PLAYER_CREEP_RED)

---@param effect EntityEffect
local function SaltCreepUpdate(effect)
    if effect.SubType ~= subtype.SALT_CREEP then return end
    
    local effectData = data(effect)
    local effectPos = effect.Position
    local spawnType = effectData.SpawnType
    local player = effect.SpawnerEntity:ToPlayer()

    if not player then return end

    for _, entity in pairs(mod.GetEnemies()) do
        local entPos = entity.Position

        if entPos:Distance(effectPos) > 20 then goto continue end
        entity:AddFreeze(EntityRef(effect), 90)
 
        if spawnType == "Sal" then
            data(entity).SalFreeze = true
        end

        if spawnType == "SaltShakerSpawnJudas" and game:GetFrameCount() % 15 == 0 then
            mod.SpawnFireJet(player, entPos, 2, true, 1)
        end
        ::continue::
    end
end

---@param effect EntityEffect
local function PepperCreepUpdate(effect)
    if effect.SubType ~= subtype.PEPPER_CREEP then return end    
    if not effect.SpawnerEntity then return end
    local player = effect.SpawnerEntity:ToPlayer()

    if not player then return end
    local effectPos = effect.Position

    for _, entity in pairs(mod.GetEnemies()) do
        if entity.Position:Distance(effectPos) > 20 then goto continue end
        mod.PepperEnemy(entity, player, 60)
        ::continue::
    end
end

mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, effect)
    SaltCreepUpdate(effect)
    PepperCreepUpdate(effect)
end, EffectVariant.PLAYER_CREEP_RED)