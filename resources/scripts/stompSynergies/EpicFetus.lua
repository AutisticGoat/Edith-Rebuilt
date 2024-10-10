local game = edithMod.Enums.Utils.Game

-- function edithMod:TechXStomp(player)
	-- if edithMod:IsKeyStompPressed(player) then return end

	-- if player:HasCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS) then	
		-- local explosionParams = {
			-- Position = player.Position,
			-- Damage = 10,
			-- flags = player.TearFlags,
			-- Color = Color.Default,
			-- Source = player,
			-- radius = 50,
			-- LineCheck = false,
			-- damageSource = false ,
			-- damageFlags = DamageFlag.DAMAGE_EXPLOSION, 
		-- }
	
		-- game:BombExplosionEffects(
			-- explosionParams.Position,
			-- explosionParams.Damage,
			-- explosionParams.flags,
			-- explosionParams.Color,
			-- explosionParams.Source,
			-- explosionParams.Radius,
			-- false,
			-- false,
			-- explosionParams.damageFlags
		-- )
	-- end
-- end
-- edithMod:AddCallback(JumpLib.Callbacks.PLAYER_LAND, edithMod.TechXStomp, {
    -- tag = "edithMod_EdithJump",
-- })