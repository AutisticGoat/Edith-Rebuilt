local mod = edithMod
local enums = mod.Enums
local misc = enums.Misc
local players = enums.PlayerType
local costumes = enums.NullItemID
local utils = enums.Utils
local tables = enums.Tables
local game, sfx = utils.Game, utils.SFX
local jumpFlags = tables.JumpFlags
local jumpTags = tables.JumpTags
local JumpParams = tables.JumpParams
local funcs = {
	Switch = mod.When,
	ForceSalt = mod.ForceSaltTear,
	TargetDis = mod.GetEdithTargetDistance,
	TargetDir = mod.GetEdithTargetDirection,
	TargetMov = mod.IsEdithTargetMoving,
	GetTPS = mod.GetTPS,
	ClosestEnemy = mod.GetClosestEnemy,
	IsEdith = mod.IsEdith,
	RandomNum = mod.RandomNumber,
	RemoveTarget = mod.RemoveEdithTarget,
	VelTarget = mod.ChangeVelToTarget,
	SetVec = mod.SetVector,
	VecToAng = mod.vectorToAngle,
	KeyStompPress = mod.IsKeyStompPressed,
	EdithDash = mod.EdithDash,
	GetTarget = mod.GetEdithTarget,
	GetData = mod.GetData,
	SpawnTarget = mod.SpawnEdithTarget,
}	

function mod:InitEdithJump(player)
	local distance = funcs.TargetDis(player)
	local jumpSpeed = player.CanFly and 1 or 1.5
	local soundeffect = player.CanFly and SoundEffect.SOUND_ANGEL_WING or SoundEffect.SOUND_SHELLGAME
	local div = player.CanFly and 15 or 25

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

---@param player EntityPlayer
---@param jumps integer
local function setEdithJumps(player, jumps)
	local playerData = funcs.GetData(player)
	playerData.ExtraJumps = jumps
end

---@param player EntityPlayer
function mod:EdithInit(player)
	if not funcs.IsEdith(player, false) then return end
	local playerSprite = player:GetSprite()

	if playerSprite:GetFilename() ~= "gfx/EdithAnim.anm2" and not player:IsCoopGhost() then
		playerSprite:Load("gfx/EdithAnim.anm2", true)
		playerSprite:Update()
	end

	edithMod.ForceCharacterCostume(player, players.PLAYER_EDITH, costumes.ID_EDITH_SCARF)
end
edithMod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, edithMod.EdithInit)

function mod:EdithSaltTears(tear)
	local player = edithMod:GetPlayerFromTear(tear)

	if not player then return end
	if not funcs.IsEdith(player, false) then return end

	funcs.ForceSalt(tear)

	local shotSpeed = player.ShotSpeed * 10
	local closestEnemy = funcs.ClosestEnemy(player)

	if closestEnemy and not player:HasCollectible(CollectibleType.COLLECTIBLE_MARKED) then
		tear.Velocity = funcs.VelTarget(player, closestEnemy, shotSpeed)
	
		local playerPos = player.Position	
		local tearDisplacement = player:GetTearDisplacement()
		local multiShot = player:GetMultiShotParams(WeaponType.WEAPON_TEARS)
		local tearCounts = multiShot:GetNumTears()
		local faceDir = funcs.Switch(funcs.VecToAng(tear.Velocity), tables.DegreesToDirection, Direction.DOWN)
		local ticksPerSecond = funcs.GetTPS(player)

		if tearCounts < 2 then
			local randomFactor = funcs.RandomNum(3000, 5000) / 1000
			local adjustmentVector = misc.HeadAdjustVec
			local headAxis = funcs.Switch(faceDir, tables.HeadAxis, "Hor")
			local tearDis = (tearDisplacement * randomFactor) * (shotSpeed / 10)
			local SetX, SetY = headAxis == "Ver" and tearDis or 0, headAxis == "Hor" and tearDis or 0
			funcs.SetVec(adjustmentVector, SetX, SetY)
			local directionAdjustment = funcs.Switch(faceDir, tables.DirectionToVector, Vector.Zero):Resized(shotSpeed)
					
			tear.Position = playerPos + directionAdjustment + adjustmentVector	
		end

		local directionFrames = math.ceil(10 * (2.73 / ticksPerSecond)) + 10
		player:SetHeadDirection(faceDir, directionFrames, true)
	end

	if not player:HasCollectible(CollectibleType.COLLECTIBLE_MARKED) then return end	
	local target = funcs.GetTarget(player)
	if not target then return end
	tear.Velocity = funcs.VelTarget(tear, target, shotSpeed)
end
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, mod.EdithSaltTears)

function mod:EdithKnockbackTears(tear)
	local player = edithMod:GetPlayerFromTear(tear)

	if not player then return end
	if not funcs.IsEdith(player, false) then return end
	if tear.FrameCount ~= 1 then return end

	tear.Mass = tear.Mass * 10
end
mod:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, mod.EdithKnockbackTears)

---comment
---@param player EntityPlayer
function mod:EdithJumpHandler(player)
	local room = game:GetRoom()
	if not funcs.IsEdith(player, false) then return end

	local playerData = funcs.GetData(player)	
	local isMoving = funcs.TargetMov(player)
	local isKeyStompPressed = funcs.KeyStompPress(player)
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
	playerData.EdithJumpTimer = playerData.EdithJumpTimer or 20

	if player:IsDead() == true then
		funcs.RemoveTarget(player)
	end

	local input = {
		up = Input.IsActionPressed(ButtonAction.ACTION_UP, player.ControllerIndex),
		down = Input.IsActionPressed(ButtonAction.ACTION_DOWN, player.ControllerIndex),
		left = Input.IsActionPressed(ButtonAction.ACTION_LEFT, player.ControllerIndex),
		right = Input.IsActionPressed(ButtonAction.ACTION_RIGHT, player.ControllerIndex)
	}

	playerData.EdithJumpTimer = math.max(playerData.EdithJumpTimer - 1, 0)

	if isMoving or isKeyStompPressed or (hasMarked and isShooting) then
		funcs.SpawnTarget(player)
	end

	local target = funcs.GetTarget(player)

	if not target then return end

	if isMoving then
		local movementVector = Vector.Zero
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
		local multiShot = player:GetMultiShotParams(WeaponType.WEAPON_TEARS)
		local multTears = multiShot:GetNumTears()
		setEdithJumps(player, multTears)
	end

	if playerData.EdithJumpTimer == 0 and playerData.ExtraJumps > 0 and not isJumping then
		mod:InitEdithJump(player)
	end	

	target.Velocity = (isKeyStompPressed and target.Velocity * 0.6) or target.Velocity

	local distance = funcs.TargetDis(player)
	local direction = funcs.TargetDir(player)
	local angle = funcs.VecToAng(direction)				
	local faceDirection = funcs.Switch(angle, tables.DegreesToDirection, Direction.DOWN) 
	local isClose = distance <= 5
	local isShooting = edithMod:IsPlayerShooting(player)
	local isStomping = funcs.KeyStompPress(player)
	local dir = isClose and Direction.DOWN or faceDirection

	if isJumping or (not isShooting) or (isStomping) then
		player:SetHeadDirection(dir, 1, true)
	end

	--- Weapon Manager ---
	local weapon = player:GetWeapon(1)
	
	if not weapon then return end
	local override = funcs.Switch(weapon:GetWeaponType(), tables.OverrideWeapons, false)

	if override == false then return end
	local newWeapon = Isaac.CreateWeapon(WeaponType.WEAPON_TEARS, player)
	Isaac.DestroyWeapon(weapon)
	player:EnableWeaponType(WeaponType.WEAPON_TEARS, true)
	player:SetWeapon(newWeapon, 1)	
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, mod.EdithJumpHandler)

local SoundPick = {
	[1] = SoundEffect.SOUND_STONE_IMPACT, ---@type SoundEffect
	[2] = edithMod.Enums.SoundEffect.SOUND_EDITH_STOMP,
	[3] = edithMod.Enums.SoundEffect.SOUND_FART_REVERB,
	[4] = edithMod.Enums.SoundEffect.SOUND_VINE_BOOM,
}

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

---@param player EntityPlayer
---@param data JumpData
---@param pitfall boolean
function mod:EdithLanding(player, data, pitfall)
	local playerData = funcs.GetData(player)	
	local edithTarget = funcs.GetTarget(player)
	
	if not edithTarget then return end

	local distance = funcs.TargetDis(player)
	local level = game:GetLevel()
	local stage = level:GetStage()
	
	playerData.ExtraJumps = math.max(playerData.ExtraJumps - 1, 0)
						
	if pitfall then
		funcs.RemoveTarget(player)
		return
	end

	if isNearTrapdoor(player) == false then
		edithMod.LandFeedbackManager(player, SoundPick, Color.Default, false)
	end

	local tears = funcs.GetTPS(player)
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
	local stompDamage = funcs.KeyStompPress(player) and 0 or math.max(damageFormula, 1)
	
	edithMod:EdithStomp(player, radius, stompDamage, knockbackFormula, true)

	local targetSprte = playerData.EdithTarget:GetSprite()

	targetSprte:Play("Idle")

	player:MultiplyFriction(0.05)
	
	if funcs.KeyStompPress(player) then
		playerData.EdithJumpTimer = 20
	else
		local hasEpicFetus = player:HasCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS) 
		
		if playerData.ExtraJumps > 0 then
			playerData.EdithJumpTimer = hasEpicFetus and 30 or 5
		else
			playerData.EdithJumpTimer = 30
		end
	end
	
	player:SetMinDamageCooldown(20)
	
	if not funcs.KeyStompPress(player) and not funcs.TargetMov(player) then
		if distance <= 5 and distance >= 60 then
			player.Position = playerData.EdithTarget.Position
		end
		if playerData.ExtraJumps <= 0 then
			funcs.RemoveTarget(player)
		end
	end
	
	playerData.IsFalling = false

	-------- Bomb Stomp --------
	if playerData.BombStomp == true then
		if player:GetNumBombs() > 0 and not player:HasGoldenBomb() then
			player:AddBombs(-1)
		end

		game:BombExplosionEffects(player.Position, 100, player.TearFlags, Color.Default, player, 1, false, false, 0)
		playerData.BombStomp = false
	end
	-------- Bomb Stomp  end --------
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, mod.EdithLanding, JumpParams.EdithJump)

---@param ent Entity
local function CustomAfterImage(ent)
	local entSprite = ent:GetSprite()
	print(entSprite:GetFilename())
	local newSprite = Sprite(entSprite:GetFilename(), true)


	entSprite:Render(Isaac.WorldToScreen(ent.Position), Vector.Zero, Vector.Zero)
end



---comment
---@param player EntityPlayer
---@param data JumpData
function mod:EdithJumpLibStuff(player, data)
	if not funcs.GetTarget(player) then return end

	local iskeystomp = funcs.KeyStompPress(player)
	local direction = funcs.TargetDir(player)
	local distance = funcs.TargetDis(player)
	local div = (iskeystomp and player.CanFly) and 70 or 50
	local isMovingTarget = funcs.TargetMov(player)
	
	funcs.EdithDash(player, direction, distance, div)

	CustomAfterImage(player)

	if not JumpLib:IsFalling(player) then return end
	if not (player.CanFly and ((isMovingTarget and distance <= 50) or distance <= 5)) then return end
	
	if data.Fallspeed < 7 then
		sfx:Play(SoundEffect.SOUND_SHELLGAME)
	end

	JumpLib:SetSpeed(player, 10 + (data.Height / 10))
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_UPDATE_30, mod.EdithJumpLibStuff, JumpParams.EdithJump)

function mod:EdithBomb(player, data)
	local playerData = funcs.GetData(player)
	if player:GetNumBombs() <= 0 and not player:HasGoldenBomb() then return end
	if not Input.IsActionTriggered(ButtonAction.ACTION_BOMB, player.ControllerIndex) then return end
	JumpLib:SetSpeed(player, 10 + (data.Height / 10))
	playerData.BombStomp = true
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_UPDATE_60, mod.EdithBomb, JumpParams.EdithJump)

function mod:EdithOnNewRoom()	
	local players = PlayerManager.GetPlayers()

	for _, player in pairs(players) do
		if funcs.IsEdith(player, false) then
			local newColor = player.Color
			funcs.RemoveTarget(player)
			setEdithJumps(player, 0)	
			
			newColor.A = 1
			player.Color = newColor
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.EdithOnNewRoom)

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
		if famPlayer and funcs.IsEdith(famPlayer, false) and funcs.KeyStompPress(famPlayer) then
			return false
		end
	end

	if player and funcs.IsEdith(player, false) and funcs.KeyStompPress(player) then
		if player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_HEELS) and damage == 12 then
			return false
		end
	end
end
edithMod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, edithMod.DamageStuff)

---comment
---@param player EntityPlayer
function edithMod:SuplexUse(player)
	if not funcs.IsEdith(player, false) then return end
	local edithTarget = funcs.GetTarget(player)

	if not edithTarget or not edithTarget:Exists() then return end
	local effects = player:GetEffects()
	local hasMarsEffect = effects:HasCollectibleEffect(CollectibleType.COLLECTIBLE_MARS)
	local direction = funcs.TargetDir(player)
	local distance = funcs.TargetDis(player)

	if hasMarsEffect then
		funcs.EdithDash(player, direction, distance, 50)
	end

	local primaryActiveSlot = player:GetActiveItemDesc(ActiveSlot.SLOT_PRIMARY)
	local activeItem = primaryActiveSlot.Item

	if activeItem == 0 then return end

	local isMoveBasedActive = tables.MovementBasedActives[activeItem] or false
	local itemConfig = Isaac.GetItemConfig():GetCollectible(activeItem)
	local maxItemCharge = itemConfig.MaxCharges
	local currentItemCharge = primaryActiveSlot.Charge
	local itemBatteryCharge = primaryActiveSlot.BatteryCharge
	local totalItemCharge = currentItemCharge + itemBatteryCharge
	local usedCharge = totalItemCharge - maxItemCharge

	if not isMoveBasedActive or totalItemCharge < maxItemCharge then return end
	if not Input.IsActionTriggered(ButtonAction.ACTION_ITEM, player.ControllerIndex) then return end

	funcs.EdithDash(player, direction, distance, 50)
	player:UseActiveItem(activeItem)
	player:SetActiveCharge(usedCharge, ActiveSlot.SLOT_PRIMARY)
end
edithMod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, edithMod.SuplexUse)

---@param player EntityPlayer
function edithMod:OnEsauJrUse(_, _, player, _, _, _)
	funcs.RemoveTarget(player)
end
edithMod:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, edithMod.OnEsauJrUse, CollectibleType.COLLECTIBLE_ESAU_JR)