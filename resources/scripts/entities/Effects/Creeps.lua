local mod = EdithRebuilt
local enums = mod.Enums
local subtype = enums.SubTypes
local utils = enums.Utils
local data = mod.CustomDataWrapper.getData

---@param effect EntityEffect
local function isModCreepEffect(effect)
    local subType = effect.SubType
    return subType == subtype.SALT_CREEP or subType == subtype.PEPPER_CREEP
end

---@param effect EntityEffect 
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, function(_, effect)
    if not isModCreepEffect(effect) then return end
    effect:GetSprite():Play("SmallBlood0" .. tostring(utils.RNG:RandomInt(1, 6)), true)    
end, EffectVariant.PLAYER_CREEP_RED)

mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, effect)
    if effect.SubType ~= subtype.SALT_CREEP then return end
    
    local effectData = data(effect)
    local effectPos = effect.Position

    for _, entity in pairs(mod.GetEnemies()) do
        if entity.Position:Distance(effectPos) > 20 then goto Break end
        entity:AddFreeze(EntityRef(effect), 90)
 
        if effectData.SpawnType == "Sal" then
            data(entity).SalFreeze = true
        end
        ::Break::
    end
end, EffectVariant.PLAYER_CREEP_RED)