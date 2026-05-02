local mod = EdithRebuilt
local enums = mod.Enums
local modules = mod.Modules
local effects = enums.EdithStatusEffects
local Status = modules.STATUS_EFFECTS
local Creeps = modules.CREEPS
local Helpers = modules.HELPERS
local utils = enums.Utils
local sfx = utils.SFX
local game = utils.Game
local ModRNG = modules.RNG
local data = mod.DataHolder.GetEntityData
local Peppers = 10
local degree = 360/Peppers
local rng = RNG()
local damageFlag = false

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function ()
    rng:SetSeed(game:GetSeeds():GetStartSeed(), 35)
end)

local function SpawnPepperCloud(entity, RNG)
    local Puff = Status.SpawnSpicePuff(entity, RNG)

    Puff:GetSprite().PlaybackSpeed = ModRNG.RandomFloat(RNG, 0.9, 1.1)

    local X = ModRNG.RandomFloat(RNG, 0.85, 1.15)
    local Y = ModRNG.RandomFloat(RNG, 0.85, 1.15)

    Puff.Color = Color(0.5, 0.5, 0.5)
    Puff.SpriteScale = Vector(X, Y)
end

local function TriggerPepperEffects(entity, RNG)
    SpawnPepperCloud(entity, RNG)
    sfx:Play(enums.SoundEffect.SOUND_PEPPER_SNEEZE, 1, 2, false, ModRNG.RandomFloat(RNG, 0.95, 1.15))
end

local function TriggerPepperDamage(entity)
    for _, ent in ipairs(Isaac.FindInRadius(entity.Position, 40, EntityPartition.ENEMY)) do
        if GetPtrHash(ent) ~= GetPtrHash(entity) then
            Helpers.TriggerPush(ent, entity, 30)
            ent:TakeDamage(ent.MaxHitPoints * 0.2, 0, EntityRef(entity), 0)
        end
    end
end

local function PepperHitsManager(entData)
    entData.PepperHits = entData.PepperHits or 1
    entData.PepperHits = entData + 1
end

---@param entity EntityNPC
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, entity)
    if not Status.EntHasStatusEffect(entity, effects.PEPPERED) then return end

    local entData = data(entity)
    PepperHitsManager(entData)
 
    if entData.PepperHits % 2 ~= 0 then return end

    TriggerPepperEffects(entity, RNG)

    if damageFlag then return end

    damageFlag = true
    TriggerPepperDamage(entity)
    damageFlag = false

    return true
end)

---@param entity EntityNPC
mod:AddCallback(PRE_NPC_KILL.ID, function(_, entity)
    if not Status.EntHasStatusEffect(entity, effects.PEPPERED) then return end

    for i = 1, Peppers do
        Creeps.SpawnPepperCreep(entity, entity.Position + Vector(0, 40):Rotated(i * degree), 4, 8)
    end
end)