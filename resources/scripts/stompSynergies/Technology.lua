local mod = EdithRebuilt
local Helpers = mod.Modules.HELPERS
local callbacks = mod.Enums.Callbacks

---@param player EntityPlayer
---@param ent Entity
mod:AddCallback(callbacks.OFFENSIVE_STOMP_HIT, function(_, player, ent)
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_TECHNOLOGY) then return end    
    if not Helpers.IsEnemy(ent) then return end 

    local hasBirthright = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)
    local damageMult = hasBirthright and 1.25 or 1
    local distDiv = hasBirthright and 4 or 5
    local playerPos = player.Position
    local entPos = ent.Position
    local dir = (entPos - playerPos):Normalized()
    local dist = playerPos:Distance(entPos)
    local laser = player:FireTechLaser(playerPos, LaserOffset.LASER_TECH1_OFFSET, dir, false, true, player, damageMult)

    laser:SetMaxDistance(dist + (player.TearRange / distDiv))
end)