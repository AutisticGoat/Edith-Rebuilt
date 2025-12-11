local mod = EdithRebuilt
local enums = mod.Enums
local modules = mod.Modules
local ModRNG = modules.RNG
local Helpers = modules.HELPERS
local trinket = enums.TrinketType
local data = mod.CustomDataWrapper.getData
local BurntSalt = {}

---@param tear EntityTear
function BurntSalt:SaltTearShoot(tear)
    local player = Helpers.GetPlayerFromTear(tear) 

    if not player then return end
    if not player:HasTrinket(trinket.TRINKET_BURNT_SALT) then return end
    if not ModRNG.RandomBoolean(player:GetTrinketRNG(trinket.TRINKET_BURNT_SALT)) then return end 
    Helpers.ForceSaltTear(tear, true)
    data(tear).BurntSaltTear = true
    tear.CollisionDamage = tear.CollisionDamage * 1.25
end
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, BurntSalt.SaltTearShoot)

---@param npc EntityNPC
---@param source EntityRef
function BurntSalt:OnKill(npc, source)
    if source.Type == 0 then return end

    local player = Helpers.GetPlayerFromRef(source)
    local tear = source.Entity:ToTear()

    if not player or not tear then return end 
    if not player:HasTrinket(trinket.TRINKET_BURNT_SALT) then return end
    if not data(tear).BurntSaltTear then return end 

    local rng = player:GetTrinketRNG(trinket.TRINKET_BURNT_SALT)

    if mod.RandomBoolean(rng) then return end

    local burntSaltTear
    for _ = 1, rng:RandomInt(4, 7) do
        burntSaltTear = Isaac.Spawn(
            EntityType.ENTITY_TEAR,
            0,
            0,
            npc.Position,
            rng:RandomVector():Resized(player.ShotSpeed * 10),
            player
        ):ToTear()  
        
        if not burntSaltTear then return end
        Helpers.ForceSaltTear(burntSaltTear, true)
    end
end
mod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, BurntSalt.OnKill)