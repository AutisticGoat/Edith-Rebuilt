local mod = EdithRebuilt
local enums = mod.Enums
local modules = mod.Modules
local Helpers = modules.HELPERS
local Status = modules.STATUS_EFFECTS
local creeps = modules.CREEPS
local effects = enums.EdithStatusEffects
local trinket = enums.TrinketType
local data = mod.DataHolder.GetEntityData

---@param tear EntityTear
local function ShootBurntSaltTear(tear)
    Helpers.ForceSaltTear(tear, true)
    data(tear).BurntSaltTear = true
    tear.CollisionDamage = tear.CollisionDamage * 1.5
end

---@param tear EntityTear
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, function(_, tear)
    local player = Helpers.GetPlayerFromTear(tear)

    if not player then return end
    if not player:HasTrinket(trinket.TRINKET_BURNT_SALT) then return end
    if tear.TearIndex == 0 or tear.TearIndex % 3 ~= 0 then return end

    ShootBurntSaltTear(tear)
end)

---@param ent Entity
---@param source EntityRef
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, ent, _, _, source, countdown)
    if source.Type == 0 then return end

    local player = Helpers.GetPlayerFromRef(source)
    local tear = source.Entity:ToTear()

    if not player or not tear then return end
    if not player:HasTrinket(trinket.TRINKET_BURNT_SALT) then return end
    if not data(tear).BurntSaltTear then return end 

    Status.SetStatusEffect(effects.CINDER, ent, 150, player)
end)

local totalCreeps = 10
local degrees = 360/totalCreeps

---@param npc EntityNPC
---@param source EntityRef
mod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, function (_, npc, source)
    if source.Type == 0 then return end

    local player = Helpers.GetPlayerFromRef(source)

    if not player then return end 
    if not player:HasTrinket(trinket.TRINKET_BURNT_SALT) then return end
    if not Status.EntHasStatusEffect(npc, effects.CINDER) then return end

    for i = 1, totalCreeps do
        creeps.SpawnCinderCreep(player, npc.Position + Vector(0, 40):Rotated(degrees * i), 3, 5)
    end
end)