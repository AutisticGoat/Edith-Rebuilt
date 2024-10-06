local rng = RNG()

function edithMod:BrimStomp(player)
	if edithMod:IsKeyStompPressed(player) then return end
	
	local rng = edithMod.Enums.Utils.RNG
	
	if player:HasCollectible(CollectibleType.COLLECTIBLE_BLACK_POWDER) then
		-- local randomSpawn = edithMod.RandomNumber(rng, 1, 3)
		
		-- if randomSpawn ~= 1 then return end
	
		local distance = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and 90 or 70
		edithMod:SpawnBlackPowder(player, 2, player.Position, distance)
	end
end
edithMod:AddCallback(JumpLib.Callbacks.PLAYER_LAND, edithMod.BrimStomp, {
    tag = "edithMod_EdithJump",
})

function edithMod:Stuff(effect)
	local effectData = edithMod:GetData(effect)

	local Vec1 = Vector(236.606, 224.768)
	local Vec2 = Vector(236.606, 364.768)

	-- print(Vec1:Distance(Vec2))

	if effectData.CustomSpawn ~= true then
		effect.Visible = false
		effect:Remove()
	else
		-- print(effect.Position)
	end
	
end
edithMod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, edithMod.Stuff, EffectVariant.PLAYER_CREEP_BLACKPOWDER)