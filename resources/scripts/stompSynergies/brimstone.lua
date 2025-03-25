local mod = edithMod
local funcs = require("resources.scripts.stompSynergies.Funcs")
local EdithJump = require("resources.scripts.stompSynergies.JumpData")

---@param player EntityPlayer
function mod:BrimStomp(player)
	if funcs.KeyStompPressed(player) then return end
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE) then return end

	local totalRays = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and 6 or 4
	local shootDegrees = 360 / totalRays
	
	for	i = 1, totalRays do
		local laser = player:FireDelayedBrimstone(shootDegrees * i, player)
		local brimData = funcs.GetData(laser)
		laser:SetMaxDistance(player.TearRange / 5)
		laser:AddTearFlags(player.TearFlags)
		brimData.StompBrimstone = true
	end
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, mod.BrimStomp, EdithJump)

function mod:LaserSpin(laser)
	local laserData = funcs.GetData(laser)

	if laserData.StompBrimstone ~= true then return end	
	laser.Angle = laser.Angle + 10
end
mod:AddCallback(ModCallbacks.MC_POST_LASER_UPDATE, mod.LaserSpin)