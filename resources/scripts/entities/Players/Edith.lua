local mod = edithMod
local game = edithMod.Enums.Utils.Game
local room = game:GetRoom()
local sfx = edithMod.Enums.Utils.SFX
local level = game:GetLevel()

local DegreesToDirection = {
	[0] = Direction.RIGHT,
	[90] = Direction.DOWN,
	[180] = Direction.LEFT,
	[270] = Direction.UP,
	[360] = Direction.RIGHT,
}

function mod:InitEdithJump(player)
	local playerData = edithMod:GetData(player)
	
	local target = playerData.EdithTarget
	local targetPos = target.Position
	local playerPos = player.Position
	
	local distance = playerPos:Distance(targetPos)
	
	local jumpSpeed = 1.5
	
	
	local jumpFlags = (  
		JumpLib.Flags.DISABLE_SHOOTING_INPUT |
		JumpLib.Flags.DISABLE_LASER_FOLLOW 
		
	)
		
	local soundeffect = SoundEffect.SOUND_SHELLGAME
	local div = 25
		
	if player.CanFly then
		jumpSpeed = 1
		div = 18
		soundeffect = SoundEffect.SOUND_ANGEL_WING
	end
		
	sfx:Play(soundeffect)
		
	local epicFetusMult = player:HasCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS) and 3 or 1
	local jumpHeight = (10 + (distance / 40) / div) * epicFetusMult
			
			
	-- EffectVariant.POOF01
	local variant = 99
			
	local DustCloud = Isaac.Spawn(
		EntityType.ENTITY_EFFECT, 
		EffectVariant.POOF01, 
		1, 
		player.Position, 
		Vector.Zero, 
		player
	)
	-- DustCloud.Color = Color(1, 0, 0, 1)
	
	DustCloud.DepthOffset = -100
		
	local config = {
		Height = jumpHeight,
		Speed = jumpSpeed,
		Tags = "edithMod_EdithJump",
		Flags = jumpFlags
	}
				
	for _, entity in ipairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.TARGET)) do
		entity:Remove()
	end
		
	JumpLib:Jump(player, config)
end

function setEdithJumps(player, jumps)
	local playerData = edithMod:GetData(player)
	
	if playerData.ExtraJumps then
		playerData.ExtraJumps = jumps
	end
end

function mod:SetEdithStats(player, cacheFlag)
	if player:GetPlayerType() ~= edithMod.Enums.PlayerType.PLAYER_EDITH then return end

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
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.SetEdithStats)

local function IsFalling(entity)
    local data = JumpLib.Internal:GetData(entity)
    if (data.Fallspeed or 0) > (data.StaticHeightIncrease or 1) then
        return true
    end
    return false
end

function mod:EdithInit(player)
	if player:GetPlayerType() ~= edithMod.Enums.PlayerType.PLAYER_EDITH then return end

	local playerSprite = player:GetSprite()

	if playerSprite:GetFilename() ~= "gfx/001.000.editha_player.anm2" and not player:IsCoopGhost() then
		playerSprite:Load("gfx/001.000.editha_player.anm2", true)
		playerSprite:Update()
	end

	edithMod.ForceCharacterCostume(player, edithMod.Enums.PlayerType.PLAYER_EDITH, edithMod.Enums.NullItemID.ID_EDITH_SCARF)
end
edithMod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, edithMod.EdithInit)

function edithMod:WeaponManager(player)			
	if player:GetPlayerType() ~= edithMod.Enums.PlayerType.PLAYER_EDITH then return end
	
	local weapon = player:GetWeapon(1)
	if weapon then
		local OverridableWeapons = {
			[WeaponType.WEAPON_BRIMSTONE] = true,
			[WeaponType.WEAPON_KNIFE] = true,
			[WeaponType.WEAPON_LASER] = true,
			[WeaponType.WEAPON_BOMBS] = true,
			[WeaponType.WEAPON_ROCKETS] = true,
			[WeaponType.WEAPON_TECH_X] = true,
			[WeaponType.WEAPON_SPIRIT_SWORD] = true
		}
	
		local override = OverridableWeapons[weapon:GetWeaponType()] or false
	
		if override == true then
			local newWeapon = Isaac.CreateWeapon(WeaponType.WEAPON_TEARS, player)
		
			Isaac.DestroyWeapon(weapon)
			player:EnableWeaponType(WeaponType.WEAPON_TEARS, true)
			player:SetWeapon(newWeapon, 1)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, edithMod.WeaponManager)

function mod:EdithSaltTears(tear)
	local player = edithMod:GetPlayerFromTear(tear)
	
	-- print(tear.Height)
	
    if player:GetPlayerType() ~= edithMod.Enums.PlayerType.PLAYER_EDITH then return end
    
	edithMod.ForceSaltTear(tear)
	
	
	
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_MARKED) then return end
	
	local playerData = edithMod:GetData(player)
			
	if not playerData.EdithTarget then return end
	
	local tearPos = tear.Position
	local targetPos = playerData.EdithTarget.Position
	local shotSpeed = player.ShotSpeed * 10
	
	tear.Velocity = (((tearPos - targetPos) * -1):Normalized()):Resized(shotSpeed)
end
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, mod.EdithSaltTears)

function mod:EdithKnockbackTears(tear)
	local player = edithMod:GetPlayerFromTear(tear)

	if not player then return end

	if player:GetPlayerType() ~= edithMod.Enums.PlayerType.PLAYER_EDITH then return end

	if tear.FrameCount ~= 1 then return end

	tear.Mass = tear.Mass * 10
end
mod:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, mod.EdithKnockbackTears)

function mod:EdithJumpHandler(player)
	local playerSprite = player:GetSprite()
	local playerData = edithMod:GetData(player)
	local room = game:GetRoom()

	local multiShot = player:GetMultiShotParams(WeaponType.WEAPON_TEARS)

	local isMoving = edithMod:IsEdithTargetMoving(player)
	local isKeyStompPressed = edithMod:IsKeyStompPressed(player)
	local hasMarked = player:HasCollectible(CollectibleType.COLLECTIBLE_MARKED)
	local isShooting = edithMod:IsPlayerShooting(player)
	local isJumping = JumpLib:GetData(player).Jumping

	if player:GetPlayerType() ~= edithMod.Enums.PlayerType.PLAYER_EDITH then return end
		
	local MovementForce = {
		up = Input.GetActionValue(ButtonAction.ACTION_UP, player.ControllerIndex),
		down = Input.GetActionValue(ButtonAction.ACTION_DOWN, player.ControllerIndex),
		left = Input.GetActionValue(ButtonAction.ACTION_LEFT, player.ControllerIndex),
		right = Input.GetActionValue(ButtonAction.ACTION_RIGHT, player.ControllerIndex),
	}

	if not playerData.ExtraJumps then
		playerData.ExtraJumps = 0
	end

	if player:IsDead() == true then
		edithMod:RemoveEdithTarget(player)
	end
	
	playerData.EdithTarget = playerData.EdithTarget or nil

	local input = {
		up = Input.IsActionPressed(ButtonAction.ACTION_UP, player.ControllerIndex),
		down = Input.IsActionPressed(ButtonAction.ACTION_DOWN, player.ControllerIndex),
		left = Input.IsActionPressed(ButtonAction.ACTION_LEFT, player.ControllerIndex),
		right = Input.IsActionPressed(ButtonAction.ACTION_RIGHT, player.ControllerIndex)
	}

	playerData.EdithJumpTimer = playerData.EdithJumpTimer or 20

	if playerData.EdithJumpTimer > 0 then
		playerData.EdithJumpTimer = playerData.EdithJumpTimer - 1
	end
		
	local target = playerData.EdithTarget
		
	if isMoving or isKeyStompPressed or (hasMarked and isShooting) then
		if not target then
			if player.ControlsEnabled == true then
				playerData.EdithTarget = Isaac.Spawn(EntityType.ENTITY_EFFECT,
				edithMod.Enums.EffectVariant.EFFECT_EDITH_TARGET,
				0,
				player.Position,
				Vector.Zero,
				player):ToEffect()
			end
		else
			local movementVector = Vector(0, 0)
			local CharSpeed = player.MoveSpeed + 2

			local targetSprite = target:GetSprite()


			movementVector.X = (
				(input.left and -1 * MovementForce.left) or 
				(input.right and 1 * MovementForce.right) or 
				0
			)
			movementVector.Y = (
				(input.up and -1 * MovementForce.up) or 
				(input.down and 1 * MovementForce.down) or
				0
			)
			
			if room:IsMirrorWorld() then
				movementVector.X = movementVector.X * -1
			end


			local resizer = math.max(CharSpeed, 1)
			local NormalMovement = movementVector:Normalized()

			local targetVel = target.Velocity

			target.Velocity = (targetVel + (NormalMovement * resizer))
			target:MultiplyFriction(0.9)
			
			-- if targetSprite:GetAnimation() == "Blin"
		end
	end
	
	if target then
		local targetSprite = target:GetSprite()
		local isBlinking = targetSprite:GetAnimation() == "Blink"
		local playerPos = player.Position
		local targetPos = target.Position
		
		local distance = playerPos:Distance(targetPos)
		
		if isKeyStompPressed then
			if not isJumping then
			
				local multTears = multiShot:GetNumTears()
				setEdithJumps(player, multTears)
			end
		end
		
		if edithMod:IsKeyStompPressed(player) then
			target.Velocity = target.Velocity * 0.6
		end
		
		if playerData.EdithJumpTimer == 0 and playerData.ExtraJumps > 0 then
			if not isJumping then
				mod:InitEdithJump(player)
			end
		end
				
		local direction = (targetPos - playerPos):Normalized()
		local angle = edithMod:vectorToAngle(direction.X, direction.Y)
		local faceDirection = DegreesToDirection[angle]
				
		local isClose = distance <= 5
		local isShooting = edithMod:IsPlayerShooting(player)
		local isStomping = edithMod:IsKeyStompPressed(player)

		if isJumping then
			player:SetHeadDirection(isClose and Direction.DOWN or faceDirection, 1, true)
		else
			if not isShooting then
				player:SetHeadDirection(isClose and Direction.DOWN or faceDirection, 1, true)
			end
			if isStomping then
				player:SetHeadDirection(isClose and Direction.DOWN or faceDirection, 1, true)
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, mod.EdithJumpHandler)

local function SetVectorSize(Vector, x, y)
	Vector.X = x
	Vector.Y = y
end	

local function UpdateVectorSize(Vector, xTrue, yTrue, xFalse, yFalse, player)
	local vectorSizes = {
		[true] = { x = xTrue, y = yTrue },
		[false] = { x = xFalse, y = yFalse },
	}
	
	local isStomping = edithMod:IsKeyStompPressed(player)
	local size = vectorSizes[isStomping]
	
	SetVectorSize(Vector, size.x, size.y)
end

local function changeColor(entity, r, g, b, a, ro, go, bo)
	local color = entity.Color 

	color.R = r or 1
	color.G = g or 1
	color.B = b or 1
	color.A = a or 1
	color.RO = ro or 0
	color.GO = go or 0
	color.BO = bo or 0
	
	entity.Color = color
end

local function feedbackManager(player, saveData, room)
	local isStomping = edithMod:IsKeyStompPressed(player)
	local volume = isStomping and 1.5 or 2
	local stompVolume = saveData and saveData.stompVolume or 100
	local stompSound = saveData and saveData.stompsound or 1

	local SoundPick = {
		[1] = SoundEffect.SOUND_STONE_IMPACT,
		[2] = edithMod.Enums.SoundEffect.SOUND_EDITH_STOMP,
		[3] = edithMod.Enums.SoundEffect.SOUND_FART_REVERB,
		[4] = edithMod.Enums.SoundEffect.SOUND_VINE_BOOM,
	}

	local volumeAdjust = (stompVolume / 100) ^ 2

	local soundId = (edithMod:isChap4() and SoundEffect.SOUND_MEATY_DEATHS) or SoundPick[stompSound]

	sfx:Play(soundId, volume * volumeAdjust, 0, false, 1, 0)

	if room:HasWater() then
		sfx:Play(edithMod.Enums.SoundEffect.SOUND_EDITH_STOMP_WATER, (volume - 0.5) * volumeAdjust, 0, false, 1, 0)
	end

	local isStomping = edithMod:IsKeyStompPressed(player)
	local vectorSize = Vector(0, 0)
	local shakescreenOption = saveData and saveData.shakescreen or 1
	
	if shakescreenOption == true then
		game:ShakeScreen(isStomping and 6 or 10)
	end

	local playerSprite = player:GetSprite()

	local vector
	if room:HasWater() then
		local WaterSplash = Isaac.Spawn(
			EntityType.ENTITY_EFFECT, 
			EffectVariant.BIG_SPLASH, 
			2, 
			player.Position + Vector(0, 6), 
			Vector.Zero,
			player
		)
		
		UpdateVectorSize(vectorSize, 0.6, 0.6, 0.7, 0.8, player)
		WaterSplash.SpriteScale = vectorSize * player.SpriteScale.X
		local BackDrop = room:GetBackdropType()
	
		local customColor = {
			[BackdropType.CORPSE3] = {0.75, 0.2, 0.2, 1, 0, 0, 0},
			[BackdropType.DROSS] = {92/255, 81/255, 71/255, 1, 0, 0, 0},
		}
		
		local color = customColor[BackDrop]
		if color then
			changeColor(WaterSplash, table.unpack(color))
		else
			changeColor(WaterSplash, 0.7, 0.75, 1, 1)
		end
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
		
		UpdateVectorSize(vectorSize, 0.6, 0.6, 0.7, 0.8, player)
				
		DustCloud.SpriteScale = vectorSize * player.SpriteScale.X
		
		if edithMod:isChap4() then
			local bdType = room:GetBackdropType()
			local colorMap = {
				[BackdropType.BLUE_WOMB] = {0, 0, 0, 1, 0.3, 0.4, 0.6},
				[BackdropType.CORPSE] = {0, 0, 0, 1, 0.62, 0.65, 0.62},
				[BackdropType.CORPSE2] = {0, 0, 0, 1, 0.55, 0.57, 0.55},
			}

			local color = colorMap[bdType]
			if color then
				changeColor(DustCloud, table.unpack(color))
			else
				changeColor(DustCloud, 1, 1, 1, 1, 0, 0, 0)
			end			
		end
	end
	edithMod:SpawnSaltGib(player, isStomping and 4 or 10, _, 5, "StompGib")
end

local function isNearTrapdoor(player, room)
	local gridSize = room:GetGridSize()
	local entityTypes = { 
		[GridEntityType.GRID_TRAPDOOR] = true, 
		[GridEntityType.GRID_STAIRS] = true, 
		[GridEntityType.GRID_GRAVITY] = true,
	}

	for i = 1, gridSize do
		local gent = room:GetGridEntity(i)
		
		if gent then
			if gent:GetType() == GridEntityType.GRID_GRAVITY then
				return true
			end
		end
		
		if gent and entityTypes[gent:GetType()] then
			local distance = (player.Position - gent.Position):Length()	
			return distance <= 20 
		end
	end
	return false
end

function mod:EdithLanding(player, data, pitfall)
	local room = game:GetRoom()
	local playerData = edithMod:GetData(player)
	local edithTarget = playerData.EdithTarget
	local playerSprite = player:GetSprite()
	
	if not edithTarget then return end

	local distance = player.Position:Distance(edithTarget.Position)
	local saveData = edithMod.saveManager.GetDeadSeaScrollsSave()
	local stompVolume = saveData and saveData.stompVolume or 100
	local stompSound = saveData and saveData.stompsound or 1
	local shakescreenOption = saveData and saveData.shakescreen or 1
	
	local level = game:GetLevel()
	local stage = level:GetStage()
	
	playerData.ExtraJumps = math.max(playerData.ExtraJumps - 1, 0)
						
	if pitfall then
		edithMod:RemoveEdithTarget(player)
		return
	end
	
	-- print(player:CollidesWi`qthGrid())
-------- Stomp Sound Manager --------
	
-------- Stomp Sound Manager end --------

-------- Stomp Visuals Manager --------
	if isNearTrapdoor(player, room) == false then
		feedbackManager(player, saveData, room)
	end
-------- Stomp Visuals Manager end --------

-------- Stomp Damage Manager --------
	local tears = edithMod:GetTPS(player)
	local level = math.ceil(stage / 2)
		
	local flightMult = {
		Damage = player.CanFly == true and 1.5 or 1,
		Knockback = player.CanFly == true and 1.2 or 1,
		Radius = player.CanFly == true and 1.3 or 1,
	}
	
	local tearRange = player.TearRange / 40
	local radius = math.min((24 + (tearRange - 9) * 2) * flightMult.Radius, 80)
	local knockbackFormula = math.min(50, (7.7 + player.Damage ^ 1.2) * flightMult.Knockback) * player.ShotSpeed
	
	local tearsMult = edithMod:GetTPS(player) / 2.73
	
	local damageBase = 10 + (3.5 * (level - 1))
	local DamageStat = player.Damage + ((player.Damage / 5.25) - 1)
	
	local multiShot = player:GetMultiShotParams(WeaponType.WEAPON_TEARS) 
	local tearCount = multiShot:GetNumTears()
	
	local multishotMult = TSIL.Utils.Math.Round(edithMod:exponentialFunction(tearCount, 1, 0.68), 2)
		
	local birthrightMult = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and 1.2 or 1
		
	local bloodClotMult = player:HasCollectible(CollectibleType.COLLECTIBLE_BLOOD_CLOT) and 1.1 or 1
		
	local RawFormula = ((((damageBase + (DamageStat * tearsMult)) * multishotMult) * birthrightMult) * bloodClotMult) * flightMult.Damage
	
	
	
	local damageFormula = TSIL.Utils.Math.Round(RawFormula, 2)

	local stompDamage = edithMod:IsKeyStompPressed(player) and 0 or math.max(damageFormula, 1)
	
	edithMod:EdithStomp(player, radius, stompDamage, knockbackFormula, true)
-------- Stomp Damage Manager end --------

-------- Other stuff ---------
	local targetSprte = playerData.EdithTarget:GetSprite()

	targetSprte:Play("Idle")

	player:MultiplyFriction(0.05)
	
	if edithMod:IsKeyStompPressed(player) then
		playerData.EdithJumpTimer = 20
	else
	
	local hasEpicFetus = player:HasCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS) 
	
	local baseofensiveTimer = 30
	local baseDeffensiveTimer = 20
	-- local cooldown = 20
	
	if playerData.ExtraJumps > 0 then
		if player:HasCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS) then
				playerData.EdithJumpTimer = 30
			else
				-- cooldown = 1
				playerData.EdithJumpTimer = 10
			end
		else
			playerData.EdithJumpTimer = 30
		end
	end
	
	player:SetMinDamageCooldown(20)
	
	if not edithMod:IsKeyStompPressed(player) and not edithMod:IsEdithTargetMoving(player) then
		if distance <= 5 and distance >= 60 then
			player.Position = playerData.EdithTarget.Position
		end
		if playerData.ExtraJumps <= 0 then
			edithMod:RemoveEdithTarget(player)
		end
	end
	
	playerData.IsFalling = false
-------- Other stuff end ---------	
end
mod:AddCallback(JumpLib.Callbacks.PLAYER_LAND, mod.EdithLanding, {
    tag = "edithMod_EdithJump",
})

function mod:EdithJumpLibStuff(player, data)
	local playerData = edithMod:GetData(player)
	if not playerData.EdithTarget then return end

	local targetPos = playerData.EdithTarget.Position
	local playerPos = player.Position
	local posDif = targetPos - playerPos

	local iskeystomp = edithMod:IsKeyStompPressed(player)

	local direction = (posDif):Normalized()
	local distance = (posDif):Length()

	local div = 50
	local aceleration = edithMod:GetAceleration(player)
	
	local isMovingTarget = edithMod:IsEdithTargetMoving(player)
	
	if iskeystomp and player.CanFly then
		div = 70
	end
	
	local jumpData = JumpLib:GetData(player)
	
	local aceleration = edithMod:GetAceleration(player)
	
	if not playerData.IsFalling or playerData.IsFalling == false then
		if player.CanFly then
			if IsFalling(player) then
				playerData.IsFalling = true
				sfx:Play(SoundEffect.SOUND_SHELLGAME)
				player:MultiplyFriction(0.05)
				JumpLib:SetSpeed(player, 10 + (data.Height / 10))
			end
		end
	end
	player.Velocity = player.Velocity + direction * distance / div
end
mod:AddCallback(JumpLib.Callbacks.PLAYER_UPDATE_30, mod.EdithJumpLibStuff, {tag = "edithMod_EdithJump"})

function mod:EdithOnNewRoom()	
	for i, entity in pairs(Isaac.FindByType(EntityType.ENTITY_PLAYER, 0, -1, false, false)) do
		local player = entity:ToPlayer()
		if player:GetPlayerType() == edithMod.Enums.PlayerType.PLAYER_EDITH then
			edithMod:RemoveEdithTarget(player)
			setEdithJumps(player, 0)	
			local newColor = player.Color
			if newColor.A == 0 then
				newColor.A = 1
				player.Color = newColor
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.EdithOnNewRoom)

function edithMod:OverrideInputs(entity, input, action)
	if not entity then return end
	
	local player = entity:ToPlayer()
	
	if player:GetPlayerType() ~= edithMod.Enums.PlayerType.PLAYER_EDITH then return end
	
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
edithMod:AddCallback(ModCallbacks.MC_INPUT_ACTION, edithMod.OverrideInputs)

function edithMod:PlayerDamageManager(player, damage, flags, source, countdown)
	if player:GetPlayerType() ~= edithMod.Enums.PlayerType.PLAYER_EDITH then return end
	
	if flags == DamageFlag.DAMAGE_SPIKES or flags == DamageFlag.DAMAGE_ACID then
		return false
	end
end
edithMod:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, edithMod.PlayerDamageManager)

function edithMod:DamageStuff(entity, damage, flags, source, countdown)	
	if source.Type == 0 then return end

	local player = source.Entity:ToPlayer()
	local familiar = source.Entity:ToFamiliar()
		
	if familiar then
		local famPlayer = familiar.Player
		if famPlayer and famPlayer:GetPlayerType() == edithMod.Enums.PlayerType.PLAYER_EDITH then
			if edithMod:IsKeyStompPressed(famPlayer) then
				return false
			end
		end
	end
		
	if player and player:GetPlayerType() == edithMod.Enums.PlayerType.PLAYER_EDITH then
		if edithMod:IsKeyStompPressed(player) then
			if player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_HEELS) then
				if damage == 12 then
					return false
				end
			end
		end
	end
end
edithMod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, edithMod.DamageStuff)

function edithMod:SuplexUse(player)
	if player:GetPlayerType() ~= edithMod.Enums.PlayerType.PLAYER_EDITH then return end
		
	local playerData = edithMod:GetData(player)
	local edithTarget = playerData.EdithTarget
	
	local playerPos = player.Position

	if not edithTarget or not edithTarget:Exists() then return end
	
	local effects = player:GetEffects()
	
	local hasMarsEffect = effects:HasCollectibleEffect(CollectibleType.COLLECTIBLE_MARS)
	
	local targetPos = edithTarget.Position
	local direction = (targetPos - playerPos):Normalized()
	local distance = (targetPos - playerPos):Length()
	
	if hasMarsEffect then
		player.Velocity = player.Velocity + direction * distance / 50
	end
	
	local PrimActiveslot = player:GetActiveItemDesc(ActiveSlot.SLOT_PRIMARY)
	local ActiveItem = PrimActiveslot.Item
	
	if ActiveItem == 0 then return end
		
	local MovementBasedActives = {
		[CollectibleType.COLLECTIBLE_SUPLEX] = true,
		[CollectibleType.COLLECTIBLE_PONY] = true,
		[CollectibleType.COLLECTIBLE_WHITE_PONY] = true,
	}
	
	local IsMoveBasedActive = MovementBasedActives[ActiveItem] or false
	
	local itemConfig = Isaac.GetItemConfig():GetCollectible(ActiveItem)
	local MaxItemCharge = itemConfig.MaxCharges
	local CurrentItemCharge = PrimActiveslot.Charge
	local ItemBatteryCharge = PrimActiveslot.BatteryCharge
	
	local totalItemCharge = CurrentItemCharge + ItemBatteryCharge
	local usedCharge = totalItemCharge - MaxItemCharge

	if IsMoveBasedActive then
		if totalItemCharge >= MaxItemCharge then
			if Input.IsActionTriggered(ButtonAction.ACTION_ITEM, player.ControllerIndex) then
				player.Velocity = player.Velocity + direction * distance / 50
				player:UseActiveItem(ActiveItem)
				
				player:SetActiveCharge(usedCharge, ActiveSlot.SLOT_PRIMARY)
			end
		end
	end
end
edithMod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, edithMod.SuplexUse)

function edithMod:OnEsauJrUse(Id, RNG, player, flags, slot, data)
	local playerData = edithMod:GetData(player)
	local edithTarget = playerData.EdithTarget
	
	if edithTarget and edithTarget:Exists() then
		edithMod:RemoveEdithTarget(player)
	end

end
edithMod:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, edithMod.OnEsauJrUse, CollectibleType.COLLECTIBLE_ESAU_JR)

function mod:SetMaxConsumables(player, tags, value)
	if tags == "maxcoins" then
		return 9999
	elseif tags == "maxbombs" then
		return 10
	elseif tags == "maxkeys" then
		return 100
	end
end
-- mod:AddCallback(ModCallbacks.MC_EVALUATE_CUSTOM_CACHE, mod.SetMaxConsumables)

function mod:Mierda(player)
	-- player:AddCustomCacheTag("maxcoins", true)
	-- print(player:GetCustomCacheValue("maxcoins"))
end
edithMod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, edithMod.Mierda)