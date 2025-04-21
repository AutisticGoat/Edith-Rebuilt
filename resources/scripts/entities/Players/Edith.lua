local mod = edithMod
local enums = mod.Enums
local sounds = enums.SoundEffect
local misc = enums.Misc
local players = enums.PlayerType
local costumes = enums.NullItemID
local utils = enums.Utils
local tables = enums.Tables
local game, sfx = utils.Game, utils.SFX
local jumpFlags = tables.JumpFlags
local jumpTags = tables.JumpTags
local JumpParams = tables.JumpParams
local Edith = {}
local funcs = {
	Switch = mod.When,
	ForceSalt = mod.ForceSaltTear,
	TargetDis = mod.GetEdithTargetDistance,
	TargetDir = mod.GetEdithTargetDirection,
	TargetMov = mod.IsEdithTargetMoving,
	GetTPS = mod.GetTPS,
	ClosestEnemy = mod.GetClosestEnemy,
	IsEdith = mod.IsEdith,
	RemoveTarget = mod.RemoveEdithTarget,
	VelTarget = mod.ChangeVelToTarget,
	SetVec = mod.SetVector,
	VecToAng = mod.vectorToAngle,
	KeyStompPress = mod.IsKeyStompPressed,
	EdithDash = mod.EdithDash,
	GetTarget = mod.GetEdithTarget,
	GetData = mod.GetData,
	SpawnTarget = mod.SpawnEdithTarget,
	FeedbackMan = mod.LandFeedbackManager,
}	

function Edith.InitEdithJump(player)
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
function Edith:EdithInit(player)
	if not funcs.IsEdith(player, false) then return end
	mod.SetNewANM2(player, "gfx/EdithAnim.anm2")
	mod.ForceCharacterCostume(player, players.PLAYER_EDITH, costumes.ID_EDITH_SCARF)
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, Edith.EdithInit)

function Edith:EdithSaltTears(tear)
	local player = mod:GetPlayerFromTear(tear)

	if not player then return end
	if not funcs.IsEdith(player, false) then return end

	funcs.ForceSalt(tear)

	local shotSpeed = player.ShotSpeed * 10
	mod.ShootTearToNearestEnemy(tear, player, misc.NearEnemyDetectionDist)

	if not player:HasCollectible(CollectibleType.COLLECTIBLE_MARKED) then return end	
	local target = funcs.GetTarget(player)
	if not target then return end
	tear.Velocity = funcs.VelTarget(tear, target, shotSpeed)
end
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, Edith.EdithSaltTears)

function Edith:EdithKnockbackTears(tear)
	local player = mod:GetPlayerFromTear(tear)

	if not player then return end
	if not funcs.IsEdith(player, false) then return end
	if tear.FrameCount ~= 1 then return end

	tear.Mass = tear.Mass * 10
end
mod:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, Edith.EdithKnockbackTears)

---comment
---@param player EntityPlayer
function Edith:EdithJumpHandler(player)
	local room = game:GetRoom()
	if not funcs.IsEdith(player, false) then return end

	

	local playerData = funcs.GetData(player)	
	local isMoving = funcs.TargetMov(player)
	local isKeyStompPressed = funcs.KeyStompPress(player)
	local hasMarked = player:HasCollectible(CollectibleType.COLLECTIBLE_MARKED)
	local isShooting = mod:IsPlayerShooting(player)
	local isJumping = JumpLib:GetData(player).Jumping
		
	local MovementForce = {
		up = Input.GetActionValue(ButtonAction.ACTION_UP, player.ControllerIndex),
		down = Input.GetActionValue(ButtonAction.ACTION_DOWN, player.ControllerIndex),
		left = Input.GetActionValue(ButtonAction.ACTION_LEFT, player.ControllerIndex),
		right = Input.GetActionValue(ButtonAction.ACTION_RIGHT, player.ControllerIndex),
	}

	playerData.ExtraJumps = playerData.ExtraJumps or 0
	playerData.EdithJumpTimer = playerData.EdithJumpTimer or 20

	if player:IsDead() then return end

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

	if not isJumping then
		player:MultiplyFriction(0.5)
	end

	local target = funcs.GetTarget(player)

	if not target then return end
	if isMoving then
		local movementVector = Vector.Zero
		local CharSpeed = player.MoveSpeed + 2
		local InverseX = room:IsMirrorWorld() and -1 or 1

		movementVector.X = (
			(input.left and -1 * MovementForce.left) or 
			(input.right and 1 * MovementForce.right) or 
			0
		) * InverseX
		movementVector.Y = (
			(input.up and -1 * MovementForce.up) or 
			(input.down and 1 * MovementForce.down) or
			0
		)

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
		Edith.InitEdithJump(player)
	end	

	target.Velocity = (isKeyStompPressed and target.Velocity * 0.6) or target.Velocity

	local distance = funcs.TargetDis(player)
	local direction = funcs.TargetDir(player)
	local angle = funcs.VecToAng(direction)				
	
	local isClose = distance <= 5
	local isShooting = mod:IsPlayerShooting(player)
	local isStomping = funcs.KeyStompPress(player)
	local faceDirection = funcs.Switch(angle, tables.DegreesToDirection, Direction.DOWN) 
	local dir = isClose and Direction.DOWN or faceDirection

	if isJumping or (not isShooting) or (isStomping) then
		player:SetHeadDirection(dir, 1, true)
	end

	--- Weapon Manager ---
	local weapon = player:GetWeapon(1)
	
	if not weapon then return end
	local override = funcs.Switch(weapon:GetWeaponType(), tables.OverrideWeapons, false)

	if not override then return end
	local newWeapon = Isaac.CreateWeapon(WeaponType.WEAPON_TEARS, player)
	Isaac.DestroyWeapon(weapon)
	player:EnableWeaponType(WeaponType.WEAPON_TEARS, true)
	player:SetWeapon(newWeapon, 1)	
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, Edith.EdithJumpHandler)

local SoundPick = {
	[1] = SoundEffect.SOUND_STONE_IMPACT, ---@type SoundEffect
	[2] = sounds.SOUND_EDITH_STOMP,
	[3] = sounds.SOUND_FART_REVERB,
	[4] = sounds.SOUND_VINE_BOOM,
}

local entityTypes = { 
	[GridEntityType.GRID_TRAPDOOR] = true, 
	[GridEntityType.GRID_STAIRS] = true, 
	[GridEntityType.GRID_GRAVITY] = true,
}
---@param player EntityPlayer
---@return boolean
local function isNearTrapdoor(player)
	local room = game:GetRoom()
	local gridSize = room:GetGridSize()
	
	for i = 1, gridSize do
		local gent = room:GetGridEntity(i)

		if not gent then goto Break end
		local GentType = gent:GetType()
		local isValidGentType = mod.When(GentType, entityTypes, false)

		if GentType == GridEntityType.GRID_GRAVITY then return true end
		if isValidGentType then
			local distance = (player.Position - gent.Position):Length()	
			return distance <= 20 
		end
		::Break::
	end
	return false
end

---@param player EntityPlayer
---@param data JumpData
---@param pitfall boolean
function Edith:EdithLanding(player, data, pitfall)
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
		funcs.FeedbackMan(player, SoundPick, player.Color, false)
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
	
	local multishotMult = TSIL.Utils.Math.Round(mod.exp(tearCount, 1, 0.68), 2)
	local birthrightMult = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and 1.2 or 1		
	local bloodClotMult = player:HasCollectible(CollectibleType.COLLECTIBLE_BLOOD_CLOT) and 1.1 or 1
	local RawFormula = ((((damageBase + (DamageStat * tearsMult)) * multishotMult) * birthrightMult) * bloodClotMult) * flightMult.Damage
	local damageFormula = TSIL.Utils.Math.Round(RawFormula, 2)
	local stompDamage = funcs.KeyStompPress(player) and 0 or math.max(damageFormula, 1)
	
	mod:EdithStomp(player, radius, stompDamage, knockbackFormula, true)

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

		game:BombExplosionEffects(player.Position, 100, player.TearFlags, misc.ColorDefault, player, 1, false, false, 0)
		playerData.BombStomp = false
	end
	-------- Bomb Stomp  end --------
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, Edith.EdithLanding, JumpParams.EdithJump)

---@param player EntityPlayer
---@param data JumpData
function Edith:EdithJumpLibStuff(player, data)
	if not funcs.GetTarget(player) then return end

	local iskeystomp = funcs.KeyStompPress(player)
	local direction = funcs.TargetDir(player)
	local distance = funcs.TargetDis(player)
	local div = (iskeystomp and player.CanFly) and 70 or 50
	local isMovingTarget = funcs.TargetMov(player)
	
	funcs.EdithDash(player, direction, distance, div)

	if not JumpLib:IsFalling(player) then return end
	if not (player.CanFly and ((isMovingTarget and distance <= 50) or distance <= 5)) then return end
	
	if data.Fallspeed < 7 then
		sfx:Play(SoundEffect.SOUND_SHELLGAME)
	end

	JumpLib:SetSpeed(player, 10 + (data.Height / 10))
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_UPDATE_30, Edith.EdithJumpLibStuff, JumpParams.EdithJump)

function Edith:EdithBomb(player, data)
	if player:GetNumBombs() <= 0 and not player:HasGoldenBomb() then return end
	if not Input.IsActionTriggered(ButtonAction.ACTION_BOMB, player.ControllerIndex) then return end
	if funcs.KeyStompPress(player) then return end
	local playerData = funcs.GetData(player)
	playerData.BombStomp = true
	JumpLib:SetSpeed(player, 10 + (data.Height / 10))
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_UPDATE_60, Edith.EdithBomb, JumpParams.EdithJump)

function Edith:EdithOnNewRoom()	
	local players = PlayerManager.GetPlayers()

	for _, player in pairs(players) do
		if funcs.IsEdith(player, false) then
			mod:ChangeColor(player, _, _, _, 1)
			funcs.RemoveTarget(player)
			setEdithJumps(player, 0)	
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, Edith.EdithOnNewRoom)

---@param damage number
---@param source EntityRef
---@return boolean?
function Edith:DamageStuff(_, damage, _, source, _)
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
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, Edith.DamageStuff)

---@param player EntityPlayer
function Edith:SuplexUse(player)
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
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, Edith.SuplexUse)

---@param player EntityPlayer
function Edith:OnEsauJrUse(_, _, player)
	funcs.RemoveTarget(player)
end
mod:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, Edith.OnEsauJrUse, CollectibleType.COLLECTIBLE_ESAU_JR)

function Edith:CustomDropButton(player)
	local isJumping = JumpLib:GetData(player).Jumping
	local height = JumpLib:GetData(player).Height
	local IsFalling = JumpLib:IsFalling(player)
	local playerData = funcs.GetData(player)

	playerData.ShouldDrop = playerData.ShouldDrop or false
	

	if playerData.ShouldDrop == false then
		player:SetActionHoldDrop(0)
	end

	-- if JumpLib:GetData(player).Height > 0 then
	-- 	print(JumpLib:GetData(player).Height)
	-- end
	-- for k, v in pairs(JumpLib:GetData(player)) do
	-- 	print(k, v)
	-- end

	if not isJumping then playerData.ShouldDrop = false return end
		-- print(Input.IsActionTriggered(ButtonAction.ACTION_DROP, player.ControllerIndex))

	if not Input.IsActionTriggered(ButtonAction.ACTION_DROP, player.ControllerIndex) then return end
		
	if not (height > 10 and not IsFalling) then return end
		playerData.ShouldDrop = true
		player:SetActionHoldDrop(119)
	-- end
	
		


	-- print(player:GetActionHoldDrop())
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE,	 Edith.CustomDropButton)

-- function Edith:Render(player)
-- 	mod.RenderAreaOfEffect(player, misc.NearEnemyDetectionDist, Color(1, 1, 1))
-- end
-- mod:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, Edith.Render)