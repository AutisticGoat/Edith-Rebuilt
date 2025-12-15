local mod = EdithRebuilt
local enums = mod.Enums
local subtype = enums.SubTypes
local game = enums.Utils.Game
local saltTypes = enums.SaltTypes
local modules = mod.Modules
local StatusEffects = modules.STATUS_EFFECTS
local Helpers = modules.HELPERS
local Player = modules.PLAYER
local data = mod.CustomDataWrapper.getData

local ModCreeps = {
    [subtype.CINDER_CREEP] = true,
    [subtype.SALT_CREEP] = true,
    [subtype.PEPPER_CREEP] = true
}

---@param effect EntityEffect
local function isModCreepEffect(effect)
    return Helpers.When(effect.SubType, ModCreeps, false)
end

local SaltShakerSalts = {
    [saltTypes.SALT_SHAKER] = true,
    [saltTypes.SALT_SHAKER_JUDAS] = true
}

local SaltedTimes = {
    [saltTypes.SAL] = 150,
    [saltTypes.SALT_HEART] = 120,
    [saltTypes.EDITHS_HOOD] = 120,
    [saltTypes.SALT_SHAKER] = 90,
    [saltTypes.SALT_SHAKER_JUDAS] = 90,
}

---@param effect EntityEffect 
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, function(_, effect)
    if not isModCreepEffect(effect) then return end
    effect:GetSprite():Play("SmallBlood0" .. tostring(effect:GetDropRNG():RandomInt(1, 6)), true)
end, EffectVariant.PLAYER_CREEP_RED)

---@param effect EntityEffect
local function SaltCreepUpdate(effect)
    if effect.SubType ~= subtype.SALT_CREEP then return end
    
    local effectData = data(effect)
    local spawnType = effectData.SpawnType ---@cast spawnType SaltTypes
    local player = effect.SpawnerEntity:ToPlayer() 
    local isSaltShakerSalt = Helpers.When(spawnType, SaltShakerSalts, false)

    if not player then return end

    if isSaltShakerSalt then
        effectData.SaltShakerCentralPos = data(player).SpawnCentralPosition --[[@as Vector]]
        local pos = effectData.SaltShakerCentralPos
        local capsule = Capsule(pos, Vector.One, 0, 70)

        for _, entity in pairs(Isaac.FindInCapsule(capsule, EntityPartition.ENEMY)) do
            if not Helpers.IsEnemy(entity) then goto continue end
            Helpers.TriggerPushPos(effect, entity, entity.Position, pos, 6, 15, false)
            ::continue::
        end
    else
        effectData.SaltShakerCentralPos = nil
    end

    for _, entity in pairs(Isaac.FindInRadius(effect.Position, 20 * effect.SpriteScale.X, EntityPartition.ENEMY)) do

        if Helpers.IsVestigeChallenge() then
            entity:AddFear(EntityRef(player), 120)
        else
            StatusEffects.SetStatusEffect(enums.EdithStatusEffects.SALTED, entity, SaltedTimes[spawnType], player)
        end

        data(entity).SaltType = spawnType

        if spawnType == saltTypes.SALT_SHAKER_JUDAS and game:GetFrameCount() % 15 == 0 then
            mod.SpawnFireJet(player, entity.Position, 2, true, 1)
        end
    end
end

---@param effect EntityEffect
local function PepperCreepUpdate(effect)
    if effect.SubType ~= subtype.PEPPER_CREEP then return end
    if not effect.SpawnerEntity then return end
    local player = effect.SpawnerEntity:ToPlayer()

    if not player then return end

    for _, entity in pairs(Isaac.FindInRadius(effect.Position, 20 * effect.SpriteScale.X, EntityPartition.ENEMY)) do
        StatusEffects.SetStatusEffect(enums.EdithStatusEffects.PEPPERED, entity, 150, player)
    end
end

-- ---@param effect EntityEffect
local function CinderCreepUpdate(effect)
    if effect.SubType ~= subtype.CINDER_CREEP then return end    

    local player = effect.SpawnerEntity:ToPlayer()

    if not player then return end
    if not Player.PlayerHasBirthright(player) then return end

    for _, entity in pairs(Isaac.FindInRadius(effect.Position, 20 * effect.SpriteScale.X, EntityPartition.ENEMY)) do
        data(entity).IsInCinderCreep = true
    end
end

---@param npc EntityNPC
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
	local npcData = data(npc)

	if not npcData.IsInCinderCreep then 
		npcData.CindeerCount = 0 
		return
	end

	npcData.CindeerCount = npcData.CindeerCount or 0
	npcData.CindeerCount = npcData.CindeerCount + 1
    
    if npcData.CindeerCount % 15 == 0 then
        Helpers.SpawnFireJet(npc.Position, 5, 1, 0.7)
    end

	npcData.IsInCinderCreep = false
end)

mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, effect)
    SaltCreepUpdate(effect)
    PepperCreepUpdate(effect)
    CinderCreepUpdate(effect)
end, EffectVariant.PLAYER_CREEP_RED)