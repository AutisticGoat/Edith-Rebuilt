local game = edithMod.Enums.Utils.Game
local room = game:GetRoom()
local mod = edithMod
local sfx = edithMod.Enums.Utils.SFX

local Tags = {
	TEdithJump = "edithMod_TaintedEdithJump",
	TEdithParry = "edithMod_TaintedEdithParry"
}


function mod:EdithInit(player)
	if player:GetPlayerType() ~= edithMod.Enums.PlayerType.PLAYER_EDITH_B then return end

	local playerSprite = player:GetSprite()

	if playerSprite:GetFilename() ~= "gfx/001.000.edithabplayer.anm2" and not player:IsCoopGhost() then
		playerSprite:Load("gfx/001.000.edithb_player.anm2", true)
		playerSprite:Update()
	end

	edithMod.ForceCharacterCostume(player, edithMod.Enums.PlayerType.PLAYER_EDITH_B, edithMod.Enums.NullItemID.ID_EDITH_B_SCARF)
	
	
end
edithMod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, edithMod.EdithInit)



local DegreesToDirection = {
	[0] = Direction.RIGHT,
	[90] = Direction.DOWN,
	[180] = Direction.LEFT,
	[270] = Direction.UP,
	[360] = Direction.RIGHT,
}

function edithMod:SetTaintedEdithStats(player, cacheFlag)
	if player:GetPlayerType() ~= edithMod.Enums.PlayerType.PLAYER_EDITH_B then return end

	local cacheActions = {
		[CacheFlag.CACHE_DAMAGE] = function()
			player.Damage = player.Damage * 1.5
		end,
		[CacheFlag.CACHE_RANGE] = function()
			player.TearRange = edithMod.rangeUp(player.TearRange, 2.5)
		end,
		[CacheFlag.CACHE_TEARFLAG] = function()
			player.TearFlags = player.TearFlags | TearFlags.TEAR_TURN_HORIZONTAL
		end,
	}
	edithMod.SwitchCase(cacheFlag, cacheActions)
	local color = player.Color
	
	-- color.R = 0.3
	-- color.G = 0.3
	-- color.B = 0.3
	
	-- color:SetColorize(0.2, 0.2, 0.2, 1)
	
	-- player.Color = color
end
edithMod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, edithMod.SetTaintedEdithStats)

local function resetCharges(player)
	local playerData = edithMod:GetData(player)
	if playerData.ImpulseCharge then
		playerData.ImpulseCharge = 0
	end
	
	if playerData.BirthrightCharge then
		playerData.BirthrightCharge = 0
	end
end

local function stopTEdithHops(player, cooldown, useQuitJump)
	local playerData = edithMod:GetData(player)
	playerData.IsHoping = false
	player:MultiplyFriction(0.5)
	playerData.HopVector = Vector(0, 0)
	
	cooldown = cooldown or 0
	useQuitJump = useQuitJump or false
	
	if useQuitJump then
		JumpLib:QuitJump(player)
	end
	
	-- print(JumpLib.Data)
	
	player:SetMinDamageCooldown(cooldown)
	
	resetCharges(player)
end


function edithMod:InitTaintedEdithJump(player)
	local jumpHeight = 6.5
	local jumpSpeed = 2.8
			
	local jumpFlags = (
		JumpLib.Flags.COLLISION_GRID
		| JumpLib.Flags.COLLISION_ENTITY
		| JumpLib.Flags.OVERWRITABLE
		| JumpLib.Flags.DISABLE_COOL_BOMBS
		| JumpLib.Flags.IGNORE_CONFIG_OVERRIDE
		| JumpLib.Flags.FAMILIAR_FOLLOW_ORBITALS
	)
	
	local config = {
		Height = jumpHeight,
		Speed = jumpSpeed,
		Tags = Tags.TEdithJump,
		Flags = jumpFlags
	}
	JumpLib:Jump(player, config)
end

function edithMod:InitTaintedEdithParry(player)
	local playerData = edithMod:GetData(player)
	
	local jumpHeight = 9
	local jumpSpeed = 2.5
	
	if playerData.IsHoping then
		jumpHeight = 6.5
		jumpSpeed = 2.8
	end
			
	local jumpFlags = (
		JumpLib.Flags.COLLISION_GRID
		| JumpLib.Flags.COLLISION_ENTITY
		| JumpLib.Flags.OVERWRITABLE
		| JumpLib.Flags.DISABLE_COOL_BOMBS
		| JumpLib.Flags.IGNORE_CONFIG_OVERRIDE
		| JumpLib.Flags.FAMILIAR_FOLLOW_ORBITALS
	)
	
	local config = {
		Height = jumpHeight,
		Speed = jumpSpeed,
		Tags = Tags.TEdithParry,
		Flags = jumpFlags
	}
	JumpLib:Jump(player, config)
end

local function isTaintedEdithParry(player)
	local jumpData = JumpLib:GetData(player)
	local tags = jumpData.Tags
	
	return tags["edithMod_TaintedEdithParry"] or false
end

local movementVector = Vector(0, 0)
function edithMod:TaintedEdithUpdate(player)
	local playerData = edithMod:GetData()
	
	if player:GetPlayerType() ~= edithMod.Enums.PlayerType.PLAYER_EDITH_B then return end
	
	local aceleration = edithMod:GetAceleration(player)

	local playerData = edithMod:GetData(player)

	local input = {
		up = Input.IsActionPressed(ButtonAction.ACTION_UP, player.ControllerIndex),
		down = Input.IsActionPressed(ButtonAction.ACTION_DOWN, player.ControllerIndex),
		left = Input.IsActionPressed(ButtonAction.ACTION_LEFT, player.ControllerIndex),
		right = Input.IsActionPressed(ButtonAction.ACTION_RIGHT, player.ControllerIndex)
	}

	if input.up then
		movementVector.Y = -1
	elseif input.down then
		movementVector.Y = 1
	else
		movementVector.Y = 0
	end

	if input.left then
		movementVector.X = -1
	elseif input.right then
		movementVector.X = 1
	else
		movementVector.X = 0
	end

	if room:IsMirrorWorld() then
		movementVector.X = movementVector.X * -1
	end
	
	local isJumping = JumpLib:GetData(player).Jumping
	
	local jumpData = JumpLib:GetData(player)

	local NormalizedMovementVector = movementVector:Normalized()
	
	playerData.ImpulseCharge = playerData.ImpulseCharge or 0
	playerData.BirthrightCharge = playerData.BirthrightCharge or 0
	
	playerData.ParryCounter = playerData.ParryCounter or 60
	
	if playerData.ParryCounter > 0 then
		-- if not isJumping then
		if isTaintedEdithParry(player) ~= true then
			playerData.ParryCounter = playerData.ParryCounter - 1
		end
	end
		
	playerData.HopVector = playerData.HopVector or Vector(0, 0 )
	
	if edithMod:IsEdithTargetMoving(player) then
		if not playerData.TaintedEdithTarget then
			if playerData.IsHoping then
				playerData.IsHoping = false
				stopTEdithHops(player, 0, true)
			end
				
			player:MultiplyFriction(0.8)
			
			if player.ControlsEnabled == true then
				playerData.TaintedEdithTarget = Isaac.Spawn(	
					EntityType.ENTITY_EFFECT,
					edithMod.Enums.EffectVariant.EFFECT_EDITH_B_TARGET,
					0,
					player.Position,
					NormalizedMovementVector * 10,
					player
				):ToEffect()
				
				playerData.TaintedEdithTarget.DepthOffset = -100
				
				
				local sprite = playerData.TaintedEdithTarget:GetSprite()
				
				sprite = -180
			end
		else
			local target = playerData.TaintedEdithTarget
		
			local posDif = target.Position - player.Position
			local posDifLenght = (posDif):Length()
									
			local maxDist = 2.5
			
			target.Velocity = NormalizedMovementVector * 10
			
			if posDifLenght >= maxDist then
				target.Velocity = target.Velocity - (posDif:Normalized() * (posDifLenght / (maxDist)))
			end
			
			playerData.HopVector = posDif:Normalized()		
			
			local HopVec = playerData.HopVector
						
			local dir = edithMod:vectorToAngle(HopVec.X, HopVec.Y)
			
			local faceDirection = DegreesToDirection[dir]
			player:SetHeadDirection(faceDirection, 2, true)
			
			local baseTearsStat = 2.73
			local tearMult = edithMod:GetTPS(player) / baseTearsStat
						
			-- print(tearMult)
			local chargeAdd = 5 * edithMod:exponentialFunction(tearMult, 1, 1.5)

			
			
			-- print(chargeAdd)
			
			-- local MaxCharge = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and 200 or 100
		
			-- print(MaxCharge)
			
			-- print(faceDirection)
			if playerData.IsHoping == false and target ~= nil then
				playerData.ImpulseCharge = math.min(playerData.ImpulseCharge + chargeAdd, 100)
				
				if player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) then
					if playerData.ImpulseCharge >= 100 then
						playerData.BirthrightCharge = math.min(playerData.BirthrightCharge + chargeAdd, 100)
					end
				end
			end
		end	
	else
		
		local target = playerData.TaintedEdithTarget
		
		local HopVec = playerData.HopVector 
		
		if playerData.ImpulseCharge >= 10 then
			
		
			if playerData.IsHoping == true then
				player.Velocity = ((HopVec) * (6 + (player.MoveSpeed - 1)) * playerData.ImpulseCharge / 100) 
			end
			
			-- 
			
			if not (HopVec.X == 0 and HopVec.Y == 0) then
				if not isJumping then
					edithMod:InitTaintedEdithJump(player)
				end
				playerData.IsHoping = true
			end
		end
		
		if edithMod:IsKeyStompTriggered(player) then
			if playerData.ParryCounter == 0 and isTaintedEdithParry(player) == false then
				edithMod:InitTaintedEdithParry(player)
				stopTEdithHops(player)
			end
		end
	
		if playerData.TaintedEdithTarget then
			playerData.TaintedEdithTarget:Remove()
			playerData.TaintedEdithTarget = nil
		end
	end	
	
	if player:CollidesWithGrid() then
		stopTEdithHops(player, 20, true)
	end
end
edithMod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, edithMod.TaintedEdithUpdate)

function edithMod:RenderTaintedEdith(player)
	local playerData = edithMod:GetData(player)
	
	playerData.HopVector = playerData.HopVector or Vector(0, 0)
	
	local HopVec = playerData.HopVector
	
	local isShooting = edithMod:IsPlayerShooting(player)
	
	local HopVectorDegree = edithMod:vectorToAngle(HopVec.X, HopVec.Y)
	
	local faceDirection = DegreesToDirection[HopVectorDegree]
	
	if playerData.IsHoping then
		if not isShooting then
			player:SetHeadDirection(faceDirection, 2, true)
		end
	end	
end
edithMod:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, edithMod.RenderTaintedEdith)

local function spawnFireJet(player, radius, damage)
	local playerData = edithMod:GetData(player)
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) then return end

	for _, enemy in ipairs(Isaac.FindInRadius(player.Position, radius, EntityPartition.ENEMY)) do
		
	
		local BirthrightFire = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.FIRE_JET, 0, enemy.Position, Vector.Zero, player):ToEffect()
		
		local mult = (playerData.BirthrightCharge / 100) or 1
		
		local baseDamage = damage 
		
		BirthrightFire.CollisionDamage = baseDamage * mult
	end
end

function edithMod:OnNewRoom()
	local players = PlayerManager.GetPlayers()
	
	for _, player in ipairs(players) do
		if player:GetPlayerType() ~= edithMod.Enums.PlayerType.PLAYER_EDITH_B then return end
		
		stopTEdithHops(player, 0, true)
	end
end
edithMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, edithMod.OnNewRoom)

function mod:EdithLanding(player, data, pitfall)
	-- sfx:Play(SoundEffect.SOUND_STONE_IMPACT)
	
	local playerData = edithMod:GetData(player)
	
	local saveData = edithMod.saveManager.GetDeadSeaScrollsSave()
	
	local stompVolume = saveData.taintedStompVolume	
	
	local volume = 1
	local volumeAdjust = (stompVolume / 100) ^ 2
	
	sfx:Play(SoundEffect.SOUND_STONE_IMPACT, volumeAdjust, 0, false, 1, 0)
	
	local tearRange = player.TearRange / 40
	local radius = math.min((30 + (tearRange - 8) * 1.5), 50) -- Hop radius 
	local knockbackFormula = math.min(50, (7.7 + player.Damage ^ 1.2)) * player.ShotSpeed
		
	local tearsMult = edithMod:GetTPS(player) / 2.73

	local damageBase = 10 + (3.5)
	local DamageStat = player.Damage + ((player.Damage / 5.25) - 1)

	local rawFormula = ((damageBase + DamageStat) / 2.5) * (playerData.ImpulseCharge + playerData.BirthrightCharge) / 100
	
	edithMod:TaintedEdithStomp(player, radius, rawFormula, knockbackFormula, false)	
	
	
	
	local FireDamage = (player.Damage / 2) + 10
	spawnFireJet(player, radius, FireDamage)
end
mod:AddCallback(JumpLib.Callbacks.PLAYER_LAND, mod.EdithLanding, {
    tag = Tags.TEdithJump,
})

function edithMod:OnTaintedShootTears(tear)
	local player = edithMod:GetPlayerFromTear(tear)
	if player:GetPlayerType() ~= edithMod.Enums.PlayerType.PLAYER_EDITH_B then return end

	edithMod.ForceSaltTear(tear, true)
end
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, edithMod.OnTaintedShootTears)

function mod:EdithParry(player, data)
	local playerData = edithMod:GetData(player)
	playerData.ParryCounter = 30
	
	local saveData = edithMod.saveManager.GetDeadSeaScrollsSave()
	
	local stompVolume = saveData.taintedStompVolume

	local volume = 1
	local volumeAdjust = (stompVolume / 100) ^ 2
	
	sfx:Play(SoundEffect.SOUND_STONE_IMPACT, volume * volumeAdjust, 0, false, 1, 0)
		
	local tearRange = player.TearRange / 40
	
	local knockbackFormula = math.min(50, (8 + player.Damage ^ 1.5)) * player.ShotSpeed
	local ParryRadius = math.min((30 + (tearRange - 7) * 4), 70)
	
	local birthrightMult = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and 1.5 or 1
	
	local damageBase = 10 + (3.5)
	local DamageStat = player.Damage + ((player.Damage / 5.25) - 1)

	local rawFormula = ((damageBase + DamageStat) / 1.8) * birthrightMult
		
	edithMod:TaintedEdithStomp(player, ParryRadius, rawFormula, knockbackFormula, false)
	
	local FireDamage = player.Damage / 2 + rawFormula
	
	spawnFireJet(player, ParryRadius, FireDamage)
	
	resetCharges(player)
	player:SetMinDamageCooldown(20)
end
mod:AddCallback(JumpLib.Callbacks.PLAYER_LAND, mod.EdithParry, {
    tag = Tags.TEdithParry,
})

function edithMod:OverrideTaintedInputs(entity, input, action)
	if not entity then return end
	
	local player = entity:ToPlayer()
	
	if not player then return end
	
	if player:GetPlayerType() ~= edithMod.Enums.PlayerType.PLAYER_EDITH_B then return end
	
	if input == 2 then
		local actions = {
			[ButtonAction.ACTION_LEFT] = 0,
			[ButtonAction.ACTION_RIGHT] = 0,
			[ButtonAction.ACTION_UP] = 0,
			[ButtonAction.ACTION_DOWN] = 0,
		}
		return actions[action]
	end
end
edithMod:AddCallback(ModCallbacks.MC_INPUT_ACTION, edithMod.OverrideTaintedInputs)

function edithMod:TaintedEdithDamageManager(player, damage, flags, source, cooldown)
	local playerData = edithMod:GetData(player)
	
	if player:GetPlayerType() == edithMod.Enums.PlayerType.PLAYER_EDITH_B then
		if playerData.IsHoping == true then
			return false
		end
	end
end
edithMod:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, edithMod.TaintedEdithDamageManager)

function edithMod:RenderChargeBar(player)
	if room:GetRenderMode() == RenderMode.RENDER_WATER_REFLECT then return end

	local players = PlayerManager.GetPlayers()

	for _, player in ipairs(players) do
		local data = edithMod:GetData(player)
		local room = game:GetRoom()

		local update = true

		local chargeBar = data.TaintedEdithChargebar

		if not chargeBar then
			data.TaintedEdithChargebar = Sprite()
			data.TaintedEdithChargebar:Load("gfx/chargebar.anm2", true)
		else
			if not data.ImpulseCharge then return end
				chargeBar.PlaybackSpeed = 0.5
			if not chargeBar:IsPlaying("Disappear") and (not data.IsHoping == true) and data.ImpulseCharge ~= 0 then
				if data.ImpulseCharge < 100 and not (chargeBar:GetAnimation() == "Charged") then
					chargeBar:SetFrame("Charging", math.ceil(data.ImpulseCharge))
					update = false
				else
					if chargeBar:GetAnimation() == "Charging" then
						chargeBar:Play("StartCharged", true)
					elseif chargeBar:IsFinished("StartCharged") and not (chargeBar:GetAnimation() == "Charged") then
						chargeBar:Play("Charged", true)
					end
				end
			else
				if chargeBar:IsFinished("Disappear") then
					chargeBar = nil
				else	
					if not data.IsHoping and data.ImpulseCharge > 0 then
						chargeBar:SetFrame("Charging", math.ceil(data.ImpulseCharge))
					end
				end
			end
		end
				
		if chargeBar then
			if (chargeBar:GetAnimation() ~= "Disappear") and data.IsHoping == true then
				chargeBar:Play("Disappear", false)
			end
		end
			
		data.TaintedEdithChargebar.Offset = Vector(0, 10)
		data.TaintedEdithChargebar:Render(room:WorldToScreenPosition(player.Position), Vector.Zero, Vector.Zero)
			
		if update then
		   data.TaintedEdithChargebar:Update()
		end
	end
end
edithMod:AddCallback(ModCallbacks.MC_POST_RENDER, edithMod.RenderChargeBar)

function edithMod:RenderBirthrightChargeBar(player)
    local data = edithMod:GetData(player)
    local room = game:GetRoom()

    if room:GetRenderMode() == RenderMode.RENDER_WATER_REFLECT then
        return
    end

	local update = true

	local chargeBar = data.TaintedEdithBirthrightChargebar

	if not chargeBar then
		data.TaintedEdithBirthrightChargebar = Sprite()
		data.TaintedEdithBirthrightChargebar:Load("gfx/chargebar.anm2", true)
	else
		if not data.BirthrightCharge then return end
			chargeBar.PlaybackSpeed = 0.5
		if not chargeBar:IsPlaying("Disappear") and (not data.IsHoping == true) and data.BirthrightCharge ~= 0 then
			if data.BirthrightCharge < 100 and not (chargeBar:GetAnimation() == "Charged") then
				chargeBar:SetFrame("Charging", math.ceil(data.BirthrightCharge))
				update = false
			else
				if chargeBar:GetAnimation() == "Charging" then
					chargeBar:Play("StartCharged", true)
				elseif chargeBar:IsFinished("StartCharged") and not (chargeBar:GetAnimation() == "Charged") then
					chargeBar:Play("Charged", true)
				end
			end
		else
			if chargeBar:IsFinished("Disappear") then
				chargeBar = nil
			end
		end
	end
			
	if chargeBar then
		if (chargeBar:GetAnimation() ~= "Disappear") and data.IsHoping == true then
			chargeBar:Play("Disappear", false)
		end
	end
		
	data.TaintedEdithBirthrightChargebar.Offset = Vector(0, 25)
    data.TaintedEdithBirthrightChargebar:Render(room:WorldToScreenPosition(player.Position), Vector.Zero, Vector.Zero)
		
	if update then
       data.TaintedEdithBirthrightChargebar:Update()
    end
end
edithMod:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, edithMod.RenderBirthrightChargeBar)
