local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local data = mod.DataHolder.GetEntityData
local saltTypes = enums.SaltTypes
local modules = mod.Modules
local ModRNG = modules.RNG
local Helpers = modules.HELPERS
local Creeps = modules.CREEPS
local StatusEffects = modules.STATUS_EFFECTS

---@param player EntityPlayer
local function SpawnSalCreep(player)
    local rng = player:GetCollectibleRNG(items.COLLECTIBLE_SAL)
    local gibAmount = rng:RandomInt(2, 5)
    local gibSpeed = ModRNG.RandomFloat(rng, 1, 2.5)
    Creeps.SpawnSaltCreep(player, player.Position, 0.5, 2, gibAmount, gibSpeed, saltTypes.SAL, true, true)
end

---@param source EntityRef
---@return boolean
local function IsSourceSalTear(source)
    local ent = source.Entity
    local tear = ent and ent:ToTear()
    return tear ~= nil and data(tear).IsSalTear == true
end

---@param player EntityPlayer
---@param entity Entity
local function ShootSalTear(player, entity)
    local rng = player:GetCollectibleRNG(items.COLLECTIBLE_SAL)
    Helpers.ShootArchedTear(player, rng, 8, 12, {
        variant  = 0,
        position = entity.Position,
        velocity = rng:RandomVector():Resized(20),
        apply    = function(tear)
            Helpers.ForceSaltTear(tear, false)
            tear:AddTearFlags(TearFlags.TEAR_PIERCING)
            data(tear).IsSalTear = true
        end,
    })
end

mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
    if not player:HasCollectible(items.COLLECTIBLE_SAL) then return end
    if player.FrameCount % 10 ~= 0 then return end
    SpawnSalCreep(player)
end)

mod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, function(_, entity, source)
    if not StatusEffects.EntHasStatusEffect(entity, enums.EdithStatusEffects.SALTED) then return end
    local player = Helpers.GetPlayerFromRef(source)
    if not player then return end
    if not player:HasCollectible(items.COLLECTIBLE_SAL) then return end
    if IsSourceSalTear(source) then return end
    ShootSalTear(player, entity)
end)