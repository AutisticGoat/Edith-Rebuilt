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

---@param entity EntityNPC
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, entity)
    if not Status.EntHasStatusEffect(entity, effects.PEPPERED) then return end

    data(entity).Hits = data(entity).Hits or 1
    local hits = data(entity).Hits

    data(entity).Hits = hits + 1

    if hits % 2 ~= 0 then return end

    local Puff = Status.SpawnSpicePuff(entity, rng)

    Puff:GetSprite().PlaybackSpeed = ModRNG.RandomFloat(rng, 0.9, 1.1)

    local X = ModRNG.RandomFloat(rng, 0.85, 1.15)
    local Y = ModRNG.RandomFloat(rng, 0.85, 1.15)

    Puff.Color = Color(0.5, 0.5, 0.5)
    Puff.SpriteScale = Vector(X, Y)

    sfx:Play(enums.SoundEffect.SOUND_PEPPER_SNEEZE, 1, 2, false, ModRNG.RandomFloat(rng, 0.95, 1.15))

    if damageFlag == true then return end

    damageFlag = true
    for _, ent in ipairs(Isaac.FindInRadius(entity.Position, 40, EntityPartition.ENEMY)) do
        if GetPtrHash(ent) ~= GetPtrHash(entity) then
            Helpers.TriggerPush(ent, entity, 30)
            ent:TakeDamage(15, 0, EntityRef(entity), 0)
        end
    end
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