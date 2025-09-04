local mod = EdithRebuilt
local funcs = require("resources.scripts.stompSynergies.Funcs")
local EdithJump = require("resources.scripts.stompSynergies.JumpData")

---@param player EntityPlayer
function mod:TechnologyLand(player)
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_TECHNOLOGY) then return end    
    if funcs.DefensiveStomp(player) then return end

    local hasBirthright = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)
    local damageMult = hasBirthright and 1.25 or 1
    local distDiv = hasBirthright and 4 or 5
    local playerPos = player.Position
    local entPos, laser, dir, dist

    for _, ent in ipairs(mod.GetStompedEnemies(player)) do
        entPos = ent.Position
        dir = (entPos - playerPos):Normalized()
        dist = playerPos:Distance(entPos)

        laser =  player:FireTechLaser(playerPos, LaserOffset.LASER_TECH1_OFFSET, dir, false, true, player, damageMult)

        laser:SetMaxDistance(dist + (player.TearRange / distDiv))
    end
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, mod.TechnologyLand, EdithJump)