local mod = EdithRebuilt
local funcs = require("resources.scripts.stompSynergies.Funcs")
local EdithJump = require("resources.scripts.stompSynergies.JumpData")

---@param player EntityPlayer
function mod:BrimStomp(player)
	if funcs.DefensiveStomp(player) then return end
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE) then return end

	local totalRays = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and 6 or 4
	local shootDegrees = 360 / totalRays
	local laser
	
	for	i = 1, totalRays do
		laser = player:FireDelayedBrimstone(shootDegrees * i, player)
		laser:SetMaxDistance(player.TearRange / 5)
		laser:AddTearFlags(player.TearFlags)
		funcs.GetData(laser).StompBrimstone = true
	end
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, mod.BrimStomp, EdithJump)

function mod:LaserSpin(laser)
	if funcs.GetData(laser).StompBrimstone ~= true then return end	
	laser.Angle = laser.Angle + 10
end
mod:AddCallback(ModCallbacks.MC_POST_LASER_UPDATE, mod.LaserSpin)