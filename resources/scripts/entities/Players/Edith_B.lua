local game = edithMod.Enums.Utils.Game
local room = edithMod.Enums.Utils.Room
local mod = edithMod
local sfx = edithMod.Enums.Utils.SFX
local rng = edithMod.Enums.Utils.RNG

local Tags = {
	TEdithJump = "edithMod_TaintedEdithJump",
	TEdithParry = "edithMod_TaintedEdithParry"
}

local DegreesToDirection = {
	[0] = Direction.RIGHT,
	[90] = Direction.DOWN,
	[180] = Direction.LEFT,
	[270] = Direction.UP,
	[360] = Direction.RIGHT,
}

function mod:TaintedEdithInit(player)
	if player:GetPlayerType() ~= edithMod.Enums.PlayerType.PLAYER_EDITH_B then return end

	local playerSprite = player:GetSprite()

	if playerSprite:GetFilename() ~= "gfx/EdithTaintedAnim.anm2" and not player:IsCoopGhost() then
		playerSprite:Load("gfx/EdithTaintedAnim.anm2", true)
		playerSprite:Update()
	end
	
	-- player:AddNullCostume(edithMod.Enums.NullItemID.ID_EDITH_B_SCARF)
	
	edithMod.ForceCharacterCostume(player, edithMod.Enums.PlayerType.PLAYER_EDITH_B, edithMod.Enums.NullItemID.ID_EDITH_B_SCARF)
end
edithMod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, edithMod.TaintedEdithInit)

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

local function stopTEdithHops(player, cooldown, useQuitJump, resetChrg)
	local playerData = edithMod:GetData(player)
		playerData.IsHoping = false
	player:MultiplyFriction(0.5)
	playerData.HopVector = Vector(0, 0)
	
	cooldown = cooldown or 0
	useQuitJump = useQuitJump or false
	
	if useQuitJump then
		JumpLib:QuitJump(player)
	end
			
	player:SetMinDamageCooldown(cooldown)
	
	if resetChrg == true then
		resetCharges(player)
	end
end

local jumpFlags = (
	JumpLib.Flags.COLLISION_GRID
	| JumpLib.Flags.COLLISION_ENTITY
	| JumpLib.Flags.OVERWRITABLE
	| JumpLib.Flags.DISABLE_COOL_BOMBS
	| JumpLib.Flags.IGNORE_CONFIG_OVERRIDE
	| JumpLib.Flags.FAMILIAR_FOLLOW_ORBITALS
)

function edithMod:InitTaintedEdithJump(player)
	local playerData = edithMod:GetData(player)
	local jumpHeight = 6.5
	local jumpSpeed = 2.8 * edithMod:Log(playerData.ImpulseCharge, 100)
	
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
	local jumpHeight = 10
	local jumpSpeed = 2.5
	
	local isChap4 = edithMod:isChap4()
	local BackDrop = room:GetBackdropType()
	local variant = room:HasWater() and EffectVariant.BIG_SPLASH or (isChap4 and EffectVariant.POOF02 or EffectVariant.POOF01)
	local subType = room:HasWater() and 1 or (isChap4 and 66 or 1)
	
	sfx:Play(SoundEffect.SOUND_SHELLGAME)
	
	local DustCloud = Isaac.Spawn(
		EntityType.ENTITY_EFFECT, 
		variant, 
		subType, 
		player.Position, 
		Vector.Zero, 
		player
	)	

	if room:HasWater() then
		local customColor = {
			[BackdropType.CORPSE3] = {0.75, 0.2, 0.2},
			[BackdropType.DROSS] = {92/255, 81/255, 71/255},
		}		
			
		local color = customColor[BackDrop] or {0.7, 0.75, 1}
		
		-- for k, v in pairs(color) do print(v) end
		edithMod:ChangeColor(DustCloud, table.unpack(color))
	end
	
	if isChap4 then
		if not room:HasWater() then
		DustCloud.SpriteScale = DustCloud.SpriteScale * 1.5
		local redChange = 0.6
		
		local colorMap = {
			[BackdropType.BLUE_WOMB] = {0, 0, 0, 0.3, 0.4, 0.6},
			[BackdropType.CORPSE] = {0, 0, 0, 0.62, 0.65, 0.62},
			[BackdropType.CORPSE2] = {0, 0, 0, 0.55, 0.57, 0.55},
		}
		
		local color = colorMap[BackDrop] or {redChange, 0, 0, 0, 0, 0}
		edithMod:ChangeColor(DustCloud, table.unpack(color))
		end
	end
	
	local dustSprite = DustCloud:GetSprite()
	
	dustSprite.PlaybackSpeed = room:HasWater() and 1.3 or 2	
	DustCloud.DepthOffset = -100
	
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

local hopSounds = {
	[1] = SoundEffect.SOUND_STONE_IMPACT,
	[2] = edithMod.Enums.SoundEffect.SOUND_YIPPEE,
	[3] = edithMod.Enums.SoundEffect.SOUND_SPRING,
}

local parryJumpSounds = {
	[1] = SoundEffect.SOUND_STONE_IMPACT,
	[2] = edithMod.Enums.SoundEffect.SOUND_PIZZA_TAUNT,
	[3] = edithMod.Enums.SoundEffect.SOUND_VINE_BOOM,
	[4] = edithMod.Enums.SoundEffect.SOUND_FART_REVERB,
}

local burtSaltColor = Color(0.3, 0.3, 0.3, 1)
local function TaintedEdithFeedBackManager(player, room, isParryJump)
	local rng = edithMod.Enums.Utils.RNG	
	local BackDrop = room:GetBackdropType()

	isParryJump = isParryJump or false
	
	local saveData = edithMod.saveManager.GetDeadSeaScrollsSave()
	
	local pitch = rng:RandomInt(90, 110) * 0.01

	local stompVolume = saveData.taintedStompVolume	
	local volume = isParryJump and 2 or 1
	local volumeAdjust = (stompVolume / 100) ^ 2
	
	local realVolume = volumeAdjust * volume
		
	local chosenSound = edithMod:isChap4() and SoundEffect.SOUND_MEATY_DEATHS or (isParryJump and parryJumpSounds[saveData.TaintedParrySound] or hopSounds[saveData.TaintedHopSound]) 
	
	sfx:Play(chosenSound, realVolume, 0, false, pitch, 0)

	if room:HasWater() then
		sfx:Play(edithMod.Enums.SoundEffect.SOUND_WATERSPLASH, (volume - 0.5) * volumeAdjust, 0, false, 1.5 + (rng:RandomFloat()), 0)
	end

	if room:HasWater() then
		local WaterSplash = Isaac.Spawn(
			EntityType.ENTITY_EFFECT, 
			EffectVariant.BIG_SPLASH, 
			2, 
			player.Position + Vector(0, 6), 
			Vector.Zero,
			player
		)
		
		local scaleMut = isParryJump and 0.8 or 0.5
		
		WaterSplash.SpriteScale = WaterSplash.SpriteScale * scaleMut
		
		local customColor = {
			[BackdropType.CORPSE3] = {0.75, 0.2, 0.2},
			[BackdropType.DROSS] = {92/255, 81/255, 71/255},
		}		
		local color = customColor[BackDrop] or {0.7, 0.75, 1}
		edithMod:ChangeColor(WaterSplash, table.unpack(color))
	else
		local CloudSubType = edithMod:isChap4() and 3 or 1
		local DustCloud = Isaac.Spawn(
			EntityType.ENTITY_EFFECT, 
			EffectVariant.POOF02, 
			CloudSubType, 
			player.Position, 
			Vector.Zero, 
			player
		)
		
		local scaleMut = isParryJump and 0.6 or 0.35 
		
		DustCloud.SpriteScale = DustCloud.SpriteScale * scaleMut
		
		local dustSprite = DustCloud:GetSprite()
	
		dustSprite.PlaybackSpeed = isParryJump and 1.3 or 1.7
		
		local colorMap = {
			[BackdropType.BLUE_WOMB] = {0, 0, 0, 0.3, 0.4, 0.6},
			[BackdropType.CORPSE] = {0, 0, 0, 0.62, 0.65, 0.62},
			[BackdropType.CORPSE2] = {0, 0, 0, 0.55, 0.57, 0.55},
		}
		local color = colorMap[BackDrop] or {1, 1, 1}
		edithMod:ChangeColor(DustCloud, table.unpack(color))
	end
	edithMod:SpawnSaltGib(player, isParryJump and 6 or 1 , burtSaltColor, 5, "StompGib")
end

function edithMod:TaintedEdithUpdate(player)
	local playerData = edithMod:GetData(player)
	local jumpData = JumpLib:GetData(player)
	local isJumping = jumpData.Jumping
		
	playerData.movementVector = playerData.movementVector or Vector.Zero
	
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
		playerData.movementVector.Y = -1
	elseif input.down then
		playerData.movementVector.Y = 1
	else
		playerData.movementVector.Y = 0
	end

	if input.left then
		playerData.movementVector.X = -1
	elseif input.right then
		playerData.movementVector.X = 1
	else
		playerData.movementVector.X = 0
	end

	if room:IsMirrorWorld() then
		playerData.movementVector.X = playerData.movementVector.X * -1
	end

	local NormalizedMovementVector = playerData.movementVector:Normalized()
	
	playerData.ImpulseCharge = playerData.ImpulseCharge or 0
	playerData.BirthrightCharge = playerData.BirthrightCharge or 0
	
	playerData.ParryCounter = playerData.ParryCounter or 30
	
	if playerData.ParryCounter > 0 then
		if isTaintedEdithParry(player) ~= true then
			playerData.ParryCounter = playerData.ParryCounter - 1
		end
	end
		
	playerData.HopVector = playerData.HopVector or Vector.Zero
	
	if edithMod:IsEdithTargetMoving(player) then
		if not playerData.TaintedEdithTarget then
			if playerData.IsHoping then
				if isJumping then
				stopTEdithHops(player, 0, true, true)
				TaintedEdithFeedBackManager(player, room)
				end
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
						
			local dir = edithMod:vectorToAngle(HopVec)
			
			local faceDirection = DegreesToDirection[dir]
			player:SetHeadDirection(faceDirection, 2, true)
			
			local baseTearsStat = 2.73
			local tearMult = edithMod:GetTPS(player) / baseTearsStat
						
			local chargeAdd = 5 * edithMod:exponentialFunction(tearMult, 1, 1.5)
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
			
			if not (HopVec.X == 0 and HopVec.Y == 0) then
				if not isJumping then
					edithMod:InitTaintedEdithJump(player)
				end
				playerData.IsHoping = true
			end
		else
			resetCharges(player)
		end
		
		if edithMod:IsKeyStompTriggered(player) then
			if playerData.ParryCounter == 0 and isTaintedEdithParry(player) == false then
				stopTEdithHops(player, 0, true, true)
				edithMod:InitTaintedEdithParry(player)
			end
		end
		edithMod:RemoveTaintedEdithTargetArrow(player)
	end	
		
	if player:CollidesWithGrid() then
		if not isJumping then
			stopTEdithHops(player, 20, true, playerData.TaintedEdithTarget == nil)
		end
	end
	
	-- print(playerData.TaintedEdithTarget)
end
edithMod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, edithMod.TaintedEdithUpdate)


function edithMod:RenderTaintedEdith(player)
	if player:GetPlayerType() ~= edithMod.Enums.PlayerType.PLAYER_EDITH_B then return end

	local playerData = edithMod:GetData(player)
	local HopVec = playerData.HopVector
	local isShooting = edithMod:IsPlayerShooting(player)
	local HopVectorDegree = edithMod:vectorToAngle(playerData.HopVector)
	local shootDegree = edithMod:vectorToAngle(player:GetShootingInput()) 
	local faceDirection = DegreesToDirection[HopVectorDegree]
	local shootDirection = DegreesToDirection[shootDegree] 
		
	local defaultFaceDir = Direction.DOWN
	
	local chosenDir 
	
	if isShooting then
		chosenDir = shootDirection
	else
		chosenDir = faceDirection
		if not playerData.TaintedEdithTarget then
			if not playerData.IsHoping then
				chosenDir = defaultFaceDir
			end
		end
	end
	player:SetHeadDirection(chosenDir, 2, true)
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
		edithMod:ChangeColor(player, _, _, _, 1)
		stopTEdithHops(player, 0, true, true)
		edithMod:RemoveTaintedEdithTargetArrow(player)
	end
end
edithMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, edithMod.OnNewRoom)

function mod:EdithLanding(player, data, pitfall)	
	local playerData = edithMod:GetData(player)
	local tearRange = player.TearRange / 40
	local damageBase = 13.5
	local DamageStat = player.Damage + ((player.Damage / 5.25) - 1)
	local rawFormula = ((damageBase + DamageStat) / 2.5) * (playerData.ImpulseCharge + playerData.BirthrightCharge) / 100
	
	playerData.HopParams = {
		hopRadius = math.min((30 + (tearRange - 8) * 1.5), 50),
		knockbackFormula = math.min(50, (7.7 + player.Damage ^ 1.2)) * player.ShotSpeed,
		Damage = ((damageBase + DamageStat) / 2.5) * (playerData.ImpulseCharge + playerData.BirthrightCharge) / 100,
	}
	
	local HopParams = playerData.HopParams
	
	-- for k, v in pairs(HopParams) do
		-- print(k, v)
	-- end
		
	-- local room = game:GetRoom()
	
	player:SpawnWaterImpactEffects(player.Position, Vector(1, 1), 1)
	
	-- player:SpawnWaterImpactEffects(Vector(300, 200), Vector.Zero, 100)
	
	TaintedEdithFeedBackManager(player, room)
		
	
	local radius = math.min((30 + (tearRange - 8) * 1.5), 50) -- Hop radius 
	local knockbackFormula = math.min(50, (7.7 + player.Damage ^ 1.2)) * player.ShotSpeed
		
	local tearsMult = edithMod:GetTPS(player) / 2.73
	
	edithMod:TaintedEdithStomp(player, radius, rawFormula, knockbackFormula, false)	
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
	
	local room = game:GetRoom()
			
	local tearRange = player.TearRange / 40
	
	local knockbackFormula = math.min(50, (8 + player.Damage ^ 1.5)) * player.ShotSpeed
	local ParryRadius = math.min((30 + (tearRange - 7) * 4), 70)
	
	local birthrightMult = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and 1.5 or 1
	
	local damageBase = 13.5
	local DamageStat = player.Damage + ((player.Damage / 5.25) - 1)

	local rawFormula = ((damageBase + DamageStat) / 1.8) * birthrightMult
		
	edithMod:TaintedEdithStomp(player, ParryRadius, rawFormula, knockbackFormula, false)
	
	local FireDamage = player.Damage / 2 + rawFormula
	
	spawnFireJet(player, ParryRadius, FireDamage)
	
	resetCharges(player)
	player:SetMinDamageCooldown(20)
	
	TaintedEdithFeedBackManager(player, room, true)
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
	
	-- if player:GetPlayerType() == edithMod.Enums.PlayerType.PLAYER_EDITH_B then
		-- if playerData.IsHoping == true then
			-- return false
		-- end
	-- end
end
edithMod:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, edithMod.TaintedEdithDamageManager)

local redArea = Color(1, 0, 0, 1)
local blueArea = Color(0, 0.2, 1, 1)

local offsetTargetVector = Vector(0, 10)
function edithMod:RenderChargeBar(player)
	if room:GetRenderMode() == RenderMode.RENDER_WATER_REFLECT then return end
	
	-- local HopParams = playerData.HopParams
	
		-- edithMod.RenderAreaOfEffect(player, HopParams.hopRadius, redArea)
		-- edithMod.RenderAreaOfEffect(player, 120, blueArea)
	
	local data = edithMod:GetData(player)
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
				-- chargeBar = nil
			else	
				if not data.IsHoping and data.ImpulseCharge > 0 then
					chargeBar:SetFrame("Charging", math.ceil(data.ImpulseCharge))
				end
			end
		end
	end
				
	if chargeBar then
		if (chargeBar:GetAnimation() ~= "Disappear") and data.IsHoping == true or data.ImpulseCharge == 0 then
			chargeBar:Play("Disappear", false)
			chargeBar.PlaybackSpeed = 1
		end
	end
				
	data.TaintedEdithChargebar.Offset = offsetTargetVector
	data.TaintedEdithChargebar:Render(room:WorldToScreenPosition(player.Position), Vector.Zero, Vector.Zero)
		
	if update then
	   data.TaintedEdithChargebar:Update()
	end
end
edithMod:AddCallback(ModCallbacks.MC_PRE_PLAYER_RENDER, edithMod.RenderChargeBar)

-- function edithMod:RenderBirthrightChargeBar(player)
    -- local data = edithMod:GetData(player)
    -- local room = game:GetRoom()

	-- if not player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) then return end

    -- if room:GetRenderMode() == RenderMode.RENDER_WATER_REFLECT then
        -- return
    -- end

	-- local update = true

	-- local chargeBar = data.TaintedEdithBirthrightChargebar

	-- if not chargeBar then
		-- data.TaintedEdithBirthrightChargebar = Sprite()
		-- data.TaintedEdithBirthrightChargebar:Load("gfx/chargebar.anm2", true)
	-- else
		-- if not data.BirthrightCharge then return end
			-- chargeBar.PlaybackSpeed = 0.5
		-- if not chargeBar:IsPlaying("Disappear") and (not data.IsHoping == true) and data.BirthrightCharge ~= 0 then
			-- if data.BirthrightCharge < 100 and not (chargeBar:GetAnimation() == "Charged") then
				-- chargeBar:SetFrame("Charging", math.ceil(data.BirthrightCharge))
				-- update = false
			-- else
				-- if chargeBar:GetAnimation() == "Charging" then
					-- chargeBar:Play("StartCharged", true)
				-- elseif chargeBar:IsFinished("StartCharged") and not (chargeBar:GetAnimation() == "Charged") then
					-- chargeBar:Play("Charged", true)
				-- end
			-- end
		-- else
			-- if chargeBar:IsFinished("Disappear") then
				-- chargeBar = nil
			-- end
		-- end
	-- end
			
	-- if chargeBar then
		-- if (chargeBar:GetAnimation() ~= "Disappear") and data.IsHoping == true then
			-- chargeBar:Play("Disappear", false)
		-- end
	-- end
		
	-- data.TaintedEdithBirthrightChargebar.Offset = Vector(0, 25)
    -- data.TaintedEdithBirthrightChargebar:Render(room:WorldToScreenPosition(player.Position), Vector.Zero, Vector.Zero)
		
	-- if update then
       -- data.TaintedEdithBirthrightChargebar:Update()
    -- end
-- end
-- edithMod:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, edithMod.RenderBirthrightChargeBar)


-- Isaac.GetItemConfig():GetCollectible(CollectibleType.COLLECTIBLE_FLIP).MaxCharges = 4

