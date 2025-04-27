local mod = edithMod
local enums = mod.Enums
local trinket = enums.TrinketType
local BurnedSalt = {}

---@param tear EntityTear
function BurnedSalt:SaltTearShoot(tear)
    local player = mod:GetPlayerFromTear(tear) 

    if not player then return end
    if not player:HasTrinket(trinket.TRINKET_BURNED_SALT) then return end

    local rng = player:GetTrinketRNG(trinket.TRINKET_BURNED_SALT)

    if rng:RandomFloat() > 0.5 then return end
    local tearData = mod.GetData(tear)
    mod.ForceSaltTear(tear, true)
    tear.CollisionDamage = tear.CollisionDamage * 1.2
    tearData.BurnedSaltTear = true
end
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, BurnedSalt.SaltTearShoot)

---@param entity Entity
---@param amount number
---@param source EntityRef
function BurnedSalt:OnKill(entity, amount, _, source)
    local ent = source.Entity

    if not ent then return end
    local tear = ent:ToTear()

    if not tear then return end
    local player = mod:GetPlayerFromTear(tear)

    if not player then return end
    if entity.HitPoints > amount then return end
    local tearData = mod.GetData(tear)

    if not tearData.BurnedSaltTear then return end 
    local rng = player:GetTrinketRNG(trinket.TRINKET_BURNED_SALT)

    if rng:RandomFloat() > 0.5 then return end
    local randomTears = rng:RandomInt(4, 7)

    for _ = 1, randomTears do
        local burnedSaltTear = Isaac.Spawn(
            EntityType.ENTITY_TEAR,
            0,
            0,
            ent.Position,
            RandomVector():Resized(player.ShotSpeed * 10),
            player
        ):ToTear() 

        if not burnedSaltTear then return end
        mod.ForceSaltTear(burnedSaltTear, true)
    end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, BurnedSalt.OnKill)