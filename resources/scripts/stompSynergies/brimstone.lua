function edithMod:BrimStomp(player)
	if edithMod:IsKeyStompPressed(player) then return end
	
	if player:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE) then
		local totalRays = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and 6 or 4
	
		local shootDegrees = 360 / totalRays
		
		for	i = 1, totalRays do
			local laser = player:FireDelayedBrimstone(shootDegrees * i, player):ToLaser()
			laser:SetMaxDistance(player.TearRange / 5)
			laser:AddTearFlags(player.TearFlags)
			
			local brimData = edithMod:GetData(laser)
			
			brimData.StompBrimstone = true
		end
	end
end
edithMod:AddCallback(JumpLib.Callbacks.PLAYER_LAND, edithMod.BrimStomp, {
    tag = "edithMod_EdithJump",
})

function edithMod:LaserSpin(laser)
	local laserData = edithMod:GetData(laser)

	if laserData.StompBrimstone == true then	
		laser.Angle = laser.Angle + 10
	end
end
edithMod:AddCallback(ModCallbacks.MC_POST_LASER_UPDATE, edithMod.LaserSpin)