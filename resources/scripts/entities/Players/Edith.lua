local mod = edithMod
local enums = mod.Enums
local players = enums.PlayerType
local costumes = enums.NullItemID
local utils = enums.Utils
local tables = enums.Tables
local game, sfx = utils.Game, utils.SFX
local jumpFlags = tables.JumpFlags
local jumpTags = tables.JumpTags

function mod:InitEdithJump(player)
	local playerData = edithMod:GetData(player)
	local target = playerData.EdithTarget
	local targetPos = target.Position
	local playerPos = player.Position
	local distance = playerPos:Distance(targetPos)
	local jumpSpeed = 1.5
	local soundeffect = SoundEffect.SOUND_SHELLGAME
	local div = 25
		
	if player.CanFly then
		jumpSpeed = 1
		div = 15
		soundeffect = SoundEffect.SOUND_ANGEL_WING
	end
		
	sfx:Play(soundeffect)
		
	local epicFetusMult = player:HasCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS) and 3 or 1
	local jumpHeight = (10 + (distance / 40) / div) * epicFetusMult
				
	local DustCloud = Isaac.Spawn(
		EntityType.ENTITY_EFFECT, 
		EffectVariant.POOF01, 
		1, 
		player.Position, 
		Vector.Zero, 
		player
	)	
	DustCloud.DepthOffset = -100
		
	local config = {
		Height = jumpHeight,
		Speed = jumpSpeed,
		Tags = jumpTags.EdithJump,
		Flags = jumpFlags.EdithJump,
	}

	JumpLib:Jump(player, config)
end

---comment
---@param player EntityPlayer
---@param jumps integer
local function setEdithJumps(player, jumps)
	local playerData = edithMod:GetData(player)
	
	if playerData.ExtraJumps then
		playerData.ExtraJumps = jumps
	end
end

---comment
---@param player EntityPlayer
function mod:EdithInit(player)
	if not edithMod:IsEdith(player, false) then return end
	local playerSprite = player:GetSprite()

	if playerSprite:GetFilename() ~= "gfx/EdithAnim.anm2" and not player:IsCoopGhost() then
		playerSprite:Load("gfx/EdithAnim.anm2", true)
		playerSprite:Update()
	end

	edithMod.ForceCharacterCostume(player, players.PLAYER_EDITH, costumes.ID_EDITH_SCARF)
end
edithMod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, edithMod.EdithInit)

function edithMod:WeaponManager(player)	
	if not edithMod:IsEdith(player, false) then return end
	local weapon = player:GetWeapon(1)
	
	if not weapon then return end
	local override = tables.OverrideWeapons[weapon:GetWeaponType()] or false

	if override == false then return end
	local newWeapon = Isaac.CreateWeapon(WeaponType.WEAPON_TEARS, player)
	Isaac.DestroyWeapon(weapon)
	player:EnableWeaponType(WeaponType.WEAPON_TEARS, true)
	player:SetWeapon(newWeapon, 1)
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, edithMod.WeaponManager)

function mod:EdithSaltTears(tear)
	local player = edithMod:GetPlayerFromTear(tear)

	if not player then return end
	if not edithMod:IsEdith(player, false) then return end

	local shotSpeed = player.ShotSpeed * 10

	edithMod.ForceSaltTear(tear)

	local closestEnemy = edithMod:GetClosestEnemy(player)

	

	if closestEnemy and not player:HasCollectible(CollectibleType.COLLECTIBLE_MARKED) then
		local playerPosition = player.Position	
		local tearDisplacement = player:GetTearDisplacement()
		local shotSpeedAdjustment = player.ShotSpeed * 10
	
		-- Calculate the velocity towards the closest enemy
		tear.Velocity = ((playerPosition - closestEnemy.Position) * -1):Normalized():Resized(shotSpeed)
	
		-- Generate a random number for vertical/horizontal adjustment
		local randomFactor = edithMod:RandomNumber(3000, 5000) / 1000
		local adjustmentVector = Vector(0, 0)
		local faceDirection = tables.DegreesToDirection[edithMod:vectorToAngle(tear.Velocity)]
		local isHorizontalAnimation = (faceDirection == Direction.LEFT or faceDirection == Direction.RIGHT)
	
		-- Determine the adjustment vector based on the face direction
		if isHorizontalAnimation then
			adjustmentVector = Vector(0, tearDisplacement * randomFactor)
		else
			adjustmentVector = Vector(tearDisplacement * randomFactor, 0)
		end
	
		-- Calculate the tear position adjustment
		local directionAdjustment = tables.DirectionToVector[faceDirection]:Resized(shotSpeedAdjustment)
		tear.Position = playerPosition + directionAdjustment + adjustmentVector
	
		-- Calculate the frames for head direction change
		local ticksPerSecond = edithMod:GetTPS(player)
		local directionFrames = math.ceil(10 * (2.73 / ticksPerSecond)) + 10
	
		-- Set the player's head direction
		player:SetHeadDirection(faceDirection, directionFrames, true)
	end

	if not player:HasCollectible(CollectibleType.COLLECTIBLE_MARKED) then return end	
	local playerData = edithMod:GetData(player)
			
	if not playerData.EdithTarget then return end
	
	local tearPos = tear.Position
	local targetPos = playerData.EdithTarget.Position
	
	tear.Velocity = (((tearPos - targetPos) * -1):Normalized()):Resized(shotSpeed)
end
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, mod.EdithSaltTears)

function mod:EdithKnockbackTears(tear)
	local player = edithMod:GetPlayerFromTear(tear)

	if not player then return end
	if not edithMod:IsEdith(player, false) then return end
	if tear.FrameCount ~= 1 then return end

	tear.Mass = tear.Mass * 10
end
mod:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, mod.EdithKnockbackTears)

---comment
---@param player EntityPlayer
function mod:EdithJumpHandler(player)
	local room = game:GetRoom()
	if not edithMod:IsEdith(player, false) then return end

	local playerData = edithMod:GetData(player)	
	local multiShot = player:GetMultiShotParams(WeaponType.WEAPON_TEARS)
	local isMoving = edithMod:IsEdithTargetMoving(player)
	local isKeyStompPressed = edithMod:IsKeyStompPressed(player)
	local hasMarked = player:HasCollectible(CollectibleType.COLLECTIBLE_MARKED)
	local isShooting = edithMod:IsPlayerShooting(player)
	local isJumping = JumpLib:GetData(player).Jumping
		
	local MovementForce = {
		up = Input.GetActionValue(ButtonAction.ACTION_UP, player.ControllerIndex),
		down = Input.GetActionValue(ButtonAction.ACTION_DOWN, player.ControllerIndex),
		left = Input.GetActionValue(ButtonAction.ACTION_LEFT, player.ControllerIndex),
		right = Input.GetActionValue(ButtonAction.ACTION_RIGHT, player.ControllerIndex),
	}

	playerData.ExtraJumps = playerData.ExtraJumps or 0

	if player:IsDead() == true then
		edithMod:RemoveEdithTarget(player)
	end
		
	local input = {
		up = Input.IsActionPressed(ButtonAction.ACTION_UP, player.ControllerIndex),
		down = Input.IsActionPressed(ButtonAction.ACTION_DOWN, player.ControllerIndex),
		left = Input.IsActionPressed(ButtonAction.ACTION_LEFT, player.ControllerIndex),
		right = Input.IsActionPressed(ButtonAction.ACTION_RIGHT, player.ControllerIndex)
	}
	
	playerData.EdithJumpTimer = playerData.EdithJumpTimer or 20

	playerData.EdithJumpTimer = math.max(playerData.EdithJumpTimer - 1, 0)

	if isMoving or isKeyStompPressed or (hasMarked and isShooting) then
		edithMod:SpawnEdithTarget(player)
	end

	local target = playerData.EdithTarget

	if not target then return end

	if isMoving then
		local movementVector = Vector(0, 0)
		local CharSpeed = player.MoveSpeed + 2

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

		local InverseX = room:IsMirrorWorld() and -1 or 1
		movementVector.X = movementVector.X * InverseX

		local resizer = math.max(CharSpeed, 1)
		local NormalMovement = movementVector:Normalized()
		local targetVel = target.Velocity

		target.Velocity = (targetVel + (NormalMovement * resizer))
		target:MultiplyFriction(0.9)
	end

	if isKeyStompPressed and not isJumping then
		local multTears = multiShot:GetNumTears()
		setEdithJumps(player, multTears)
	end

	if playerData.EdithJumpTimer == 0 and playerData.ExtraJumps > 0 and not isJumping then
		mod:InitEdithJump(player)
	end	

	target.Velocity = (isKeyStompPressed and target.Velocity * 0.6) or target.Velocity

	local playerPos = player.Position
	local targetPos = target.Position
	local distance = playerPos:Distance(targetPos)
	local direction = (targetPos - playerPos):Normalized()
	local angle = edithMod:vectorToAngle(direction)				
	local faceDirection = tables.DegreesToDirection[angle]
	local isClose = distance <= 5
	local isShooting = edithMod:IsPlayerShooting(player)
	local isStomping = edithMod:IsKeyStompPressed(player)
	local dir = isClose and Direction.DOWN or faceDirection

	if isJumping or (not isShooting) or (isStomping) then
		player:SetHeadDirection(dir, 1, true)
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

local function feedbackManager(player, saveData)
	local room = game:GetRoom()

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
	local _ = nil
	edithMod:SpawnSaltGib(player, isStomping and 4 or 10, _, 10, "StompGib")
end

---comment
---@param player EntityPlayer
---@return boolean
local function isNearTrapdoor(player)
	local room = game:GetRoom()

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

---comment
---@param player EntityPlayer
---@param data JumpData
---@param pitfall boolean
function mod:EdithLanding(player, data, pitfall)
	local room = edithMod.Enums.Utils.Room	
	
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
	
-------- Stomp Sound Manager --------
	
-------- Stomp Sound Manager end --------

-------- Stomp Visuals Manager --------
	if isNearTrapdoor(player) == false then
		feedbackManager(player, saveData)
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
	
	local tearsMult = tears / 2.73
	
	local damageBase = 10 + (5.25 * (level - 1))
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
		
		if playerData.ExtraJumps > 0 then
			playerData.EdithJumpTimer = hasEpicFetus and 30 or 10
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

-------- Bomb Stomp --------
	if playerData.BombStomp == true then
		if player:GetNumBombs() > 0 and not player:HasGoldenBomb() then
			player:AddBombs(-1)
		end

		game:BombExplosionEffects(player.Position, 100, TearFlags.TEAR_NORMAL, Color.Default, player, 1, false, false, 0)
		playerData.BombStomp = false
	end
-------- Bomb Stomp  end --------
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, mod.EdithLanding, {
    tag = jumpTags.EdithJump,
})

---comment
---@param player EntityPlayer
---@param data JumpData
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
	local isMovingTarget = edithMod:IsEdithTargetMoving(player)
	
	if iskeystomp and player.CanFly then
		div = 70
	end
			
	if not playerData.IsFalling or playerData.IsFalling == false then
		if player.CanFly and ((isMovingTarget and distance <= 50) or distance <= 5) then
			if not iskeystomp then
				if JumpLib:IsFalling(player) then
					playerData.IsFalling = true
					sfx:Play(SoundEffect.SOUND_SHELLGAME)
					player:MultiplyFriction(0.05)
					JumpLib:SetSpeed(player, 10 + (data.Height / 10))
				end
			end
		end
	end
	
	player:ClearEntityFlags(EntityFlag.FLAG_SLIPPERY_PHYSICS)
	player.Velocity = player.Velocity + (direction * distance) / div
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_UPDATE_30, mod.EdithJumpLibStuff, {tag = jumpTags.EdithJump})

function mod:EdithBomb(player, data)
	local playerData = edithMod:GetData(player)
	if player:GetNumBombs() <= 0 and not player:HasGoldenBomb() then return end
	if not Input.IsActionTriggered(ButtonAction.ACTION_BOMB, player.ControllerIndex) then return end

	JumpLib:SetSpeed(player, 10 + (data.Height / 10))
	playerData.BombStomp = true
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_UPDATE_60, mod.EdithBomb, {tag = jumpTags.EdithJump})

function mod:EdithOnNewRoom()	
	local players = PlayerManager.GetPlayers()

	for _, player in pairs(players) do
		if edithMod:IsEdith(player, false) then
			local newColor = player.Color
			edithMod:RemoveEdithTarget(player)
			setEdithJumps(player, 0)	
			
			newColor.A = 1
			player.Color = newColor
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.EdithOnNewRoom)

---comment
---@param damage number
---@param source EntityRef
---@return boolean?
function edithMod:DamageStuff(_, damage, _, source, _)	
	if source.Type == 0 then return end
	local ent = source.Entity

	local player = ent:ToPlayer()
	local familiar = ent:ToFamiliar()
		
	if familiar then
		local famPlayer = familiar.Player
		if famPlayer and edithMod:IsEdith(famPlayer, false) then
			if edithMod:IsKeyStompPressed(famPlayer) then
				return false
			end
		end
	end
		
	if player and edithMod:IsEdith(player, false) then
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

---comment
---@param player EntityPlayer
function edithMod:SuplexUse(player)
	if not edithMod:IsEdith(player, false) then return end
		
	local playerData = edithMod:GetData(player)
	local edithTarget = playerData.EdithTarget

	if not edithTarget or not edithTarget:Exists() then return end
	
	local playerPos = player.Position
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
	
	local IsMoveBasedActive = tables.MovementBasedActives[ActiveItem] or false
	local itemConfig = Isaac.GetItemConfig():GetCollectible(ActiveItem)
	local MaxItemCharge = itemConfig.MaxCharges
	local CurrentItemCharge = PrimActiveslot.Charge
	local ItemBatteryCharge = PrimActiveslot.BatteryCharge
	
	local totalItemCharge = CurrentItemCharge + ItemBatteryCharge
	local usedCharge = totalItemCharge - MaxItemCharge

	if not IsMoveBasedActive then return end
	if totalItemCharge < MaxItemCharge then return end
	if not Input.IsActionTriggered(ButtonAction.ACTION_ITEM, player.ControllerIndex) then return end

	player.Velocity = player.Velocity + direction * distance / 50
	player:UseActiveItem(ActiveItem)
	player:SetActiveCharge(usedCharge, ActiveSlot.SLOT_PRIMARY)
end
edithMod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, edithMod.SuplexUse)

---comment
---@param player EntityPlayer
function edithMod:OnEsauJrUse(_, _, player, _, _, _)
	edithMod:RemoveEdithTarget(player)
end
edithMod:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, edithMod.OnEsauJrUse, CollectibleType.COLLECTIBLE_ESAU_JR)