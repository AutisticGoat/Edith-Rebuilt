local mod = EdithRebuilt
local enums = mod.Enums
local trinket = enums.TrinketType
local data = mod.CustomDataWrapper.getData
local BurntSalt = {}

---@param tear EntityTear
function BurntSalt:SaltTearShoot(tear)
    local player = mod:GetPlayerFromTear(tear) 

    if not player then return end
    if not player:HasTrinket(trinket.TRINKET_BURNT_SALT) then return end
    if not mod.RandomBoolean(player:GetTrinketRNG(trinket.TRINKET_BURNT_SALT)) then return end 
    mod.ForceSaltTear(tear, true)
    data(tear).BurntSaltTear = true
    tear.CollisionDamage = tear.CollisionDamage * 1.2
end
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, BurntSalt.SaltTearShoot)

---@param npc EntityNPC
---@param source EntityRef
function BurntSalt:OnKill(npc, source)
    if source.Type == 0 then return end

    local player = mod.GetPlayerFromRef(source)
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
        mod.ForceSaltTear(burntSaltTear, true)
    end
end
mod:AddCallback(PRE_NPC_KILL.ID, BurntSalt.OnKill)