function edithMod:TechXStomp(player)
	if edithMod:IsKeyStompPressed(player) then return end
	
	if player:HasCollectible(CollectibleType.COLLECTIBLE_TECH_X) then	
		local techXDistance = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and 65 or 50
		local LaserDamage = (techXDistance/100) + 0.25


		local techX = player:FireTechXLaser(player.Position, Vector(0,0), techXDistance, player, LaserDamage)
		techX.DisableFollowParent = true
		techX:SetTimeout(17) 
	end
end
edithMod:AddCallback(JumpLib.Callbacks.PLAYER_LAND, edithMod.TechXStomp, {
    tag = "edithMod_EdithJump",
})