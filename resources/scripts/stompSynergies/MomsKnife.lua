function edithMod:BrimStomp(player)
	if edithMod:IsKeyStompPressed(player) then return end
	if player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_KNIFE) then		
		local knifeEntities = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and 8 or 4
		local degrees = 360/knifeEntities
			
		for i = 1, knifeEntities do
			
			knife = player:FireKnife(player, degrees * i, true, 0, 0)
			
			local knifeData = edithMod:GetData(knife)
			
			knifeData.StompKnife = true			
			knife:Shoot(1, player.TearRange / 3)
		end
	end
end
edithMod:AddCallback(JumpLib.Callbacks.PLAYER_LAND, edithMod.BrimStomp, {
    tag = "edithMod_EdithJump",
})

function edithMod:RemoveKnife(knife)
	local knifeData = edithMod:GetData(knife)		
	if knifeData.StompKnife == true then
		if not knife:IsFlying() then 
			knife:Remove()
		end
	end
end
edithMod:AddCallback(ModCallbacks.MC_POST_KNIFE_UPDATE, edithMod.RemoveKnife)