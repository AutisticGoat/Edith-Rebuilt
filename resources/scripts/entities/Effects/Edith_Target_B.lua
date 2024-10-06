local game = edithMod.Enums.Utils.Game
-- local sfx = SFXManager()

realTaintedEdithDashCharge = 0
taintedEdithDashCharge = 0
taintedEdithTargetAngle = 0

function edithMod:TaintedEdithTargetLogic(effect)
	-- local player = effect.SpawnerEntity:ToPlayer()
	-- local playerData = edithMod:GetData(player)
	
	if player then
		-- if player:GetPlayerType() ~= edithMod.Enums.PlayerType.PLAYER_EDITH_B then return end
	
		local maxdistance = 10
		
		if (effect.Position - player.Position):Length() > maxdistance then
			
		end
	end
end
edithMod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, edithMod.TaintedEdithTargetLogic, edithMod.Enums.EffectVariant.EFFECT_EDITH_B_TARGET)


-- edithMod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, fx)
	-- fx.Velocity = fx.Velocity * 0.5
	-- if fx.DepthOffset ~= -50 then fx.DepthOffset = -50 end
	-- local fd = fx:GetData()
	-- local room = game:GetRoom()
	-- local bdType = room:GetBackdropType()
	
	-- if fx.Parent then
		-- local p = fx.Parent:ToPlayer()
		-- local boostmax = 1
		-- local d = p:GetData()
		-- local k_up = Input.IsActionPressed(ButtonAction.ACTION_UP, p.ControllerIndex)
		-- local k_down = Input.IsActionPressed(ButtonAction.ACTION_DOWN, p.ControllerIndex)
		-- local k_left = Input.IsActionPressed(ButtonAction.ACTION_LEFT, p.ControllerIndex)
		-- local k_right = Input.IsActionPressed(ButtonAction.ACTION_RIGHT, p.ControllerIndex)
		-- local ismoving = (k_down or k_right or k_left or k_up)
		
		-- if not d.LastTargetPosition then
			-- d.LastTargetPosition = Vector.Zero
		-- end
		
		-- if not d.renderPosition then
			-- d.renderPosition = Vector.Zero
		-- end
		
		-- d.renderPosition = -(p.Position - fx.Position):Normalized()
		
		-- if d.edithMod_B_boost and d.edithMod_B_boost > 0 and not ismoving then
			-- d.edithMod_B_dashing = true 
			-- d.edithMod_B_startvel = -(p.Position - fx.Position):Normalized() * d.edithMod_B_boost

			-- d.edithMod_B_boost = d.edithMod_B_boost
			-- fx:Remove() 
			-- d.LastTargetPosition = fx.Position
			-- d.edithMod_B_target = nil
			-- sfx:Play(SoundEffect.SOUND_SCAMPER, 0.75, 0, false, 0.8, 0)
		-- end
		-- local maxdist = 10
		
		-- if (fx.Position - p.Position):Length() > maxdist then
			-- fx.Velocity = fx.Velocity - (fx.Position - p.Position):Normalized() * ((fx.Position - p.Position):Length() / (maxdist / 3))
			
			-- if ismoving and d.edithMod_B_boost then
				-- if d.edithMod_B_boost + (boostmax / 20) < boostmax then
					-- d.edithMod_B_boost = d.edithMod_B_boost + (boostmax / 20)
				-- end
			-- end
		-- else
			-- if d.edithMod_B_boost > 0 then d.edithMod_B_boost = d.edithMod_B_boost - (boostmax / 60) end
			-- if d.atlas and d.edithMod_B_movevec then
				-- if (d.edithMod_B_movevec.Y > 0 and fx.Velocity.Y < 0) or (d.edithMod_B_movevec.Y < 0 and fx.Velocity.Y > 0) then fx.Velocity = Vector(fx.Velocity.X, -fx.Velocity.Y) end
				-- if (d.edithMod_B_movevec.X > 0 and fx.Velocity.X < 0) or (d.edithMod_B_movevec.X < 0 and fx.Velocity.X > 0) then fx.Velocity = Vector(-fx.Velocity.X, fx.Velocity.Y) end
			-- end
		-- end
	-- end
-- end, EffectVariant.EFFECT_EDITH_B_TARGET)
