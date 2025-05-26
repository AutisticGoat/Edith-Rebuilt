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

    local rng = player:GetTrinketRNG(trinket.TRINKET_BURNT_SALT)

    if rng:RandomFloat() > 0.5 then return end
    local tearData = data(tear)
    tearData.BurntSaltTear = true
    mod.ForceSaltTear(tear, true)
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

    local tearData = data(tear)

    if not tearData.BurntSaltTear then return end 
    local rng = player:GetTrinketRNG(trinket.TRINKET_BURNT_SALT)

    if rng:RandomFloat() > 0.5 then return end
    local randomTears = rng:RandomInt(4, 7)

    for _ = 1, randomTears do
        local burntSaltTear = Isaac.Spawn(
            EntityType.ENTITY_TEAR,
            0,
            0,
            npc.Position,
            RandomVector():Resized(player.ShotSpeed * 10),
            player
        ):ToTear() 

        if not burntSaltTear then return end
        mod.ForceSaltTear(burntSaltTear, true)
    end
end
mod:AddCallback(PRE_NPC_KILL.ID, BurntSalt.OnKill)