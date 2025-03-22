function edithMod:KnifeStomp(player)
	if edithMod.IsKeyStompPressed(player) then return end
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_KNIFE) then return end		
	
	local knifeEntities = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and 8 or 4
	local degrees = 360/knifeEntities
			
	for i = 1, knifeEntities do
		local knife = player:FireKnife(player, degrees * i, true, 0, 0)
		local knifeData = edithMod.GetData(knife)
		
		knifeData.StompKnife = true			
		knife:Shoot(1, player.TearRange / 3)
	end
end
edithMod:AddCallback(JumpLib.Callbacks.PLAYER_LAND, edithMod.KnifeStomp, {
    tag = "edithMod_EdithJump",
})

function edithMod:RemoveKnife(knife)
	local knifeData = edithMod.GetData(knife)		
	
	if knifeData.StompKnife ~= true then return end
	if knife:IsFlying() then return end 
	knife:Remove()
end
edithMod:AddCallback(ModCallbacks.MC_POST_KNIFE_UPDATE, edithMod.RemoveKnife)