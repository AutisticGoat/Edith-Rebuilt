local mod = EdithRebuilt
local enums = mod.Enums
local sounds = enums.SoundEffect
local misc = enums.Misc
local players = enums.PlayerType
local costumes = enums.NullItemID
local utils = enums.Utils
local tables = enums.Tables
local level = utils.Level
local game, sfx = utils.Game, utils.SFX
local JumpParams = tables.JumpParams
local Edith = {}

local funcs = {
	Switch = mod.When,
	ForceSalt = mod.ForceSaltTear,
	TargetDis = mod.GetEdithTargetDistance,
	TargetDir = mod.GetEdithTargetDirection,
	TargetMov = mod.IsEdithTargetMoving,
	GetTPS = mod.GetTPS,
	IsEdith = mod.IsEdith,
	RemoveTarget = mod.RemoveEdithTarget,
	VelTarget = mod.ChangeVelToTarget,
	SetVec = mod.SetVector,
	VecToAng = mod.vectorToAngle,
	KeyStompPress = mod.IsKeyStompPressed,
	EdithDash = mod.EdithDash,
	GetTarget = mod.GetEdithTarget,
	GetData = mod.CustomDataWrapper.getData,
	SpawnTarget = mod.SpawnEdithTarget,
	FeedbackMan = mod.LandFeedbackManager,
	EdithWeapons = mod.ManageEdithWeapons,
	DashBehavior = mod.DashItemBehavior,
	CustomDrop = mod.CustomDropBehavior,
	Round = TSIL.Utils.Math.Round,
}

---@param player EntityPlayer
---@param jumps integer
local function setEdithJumps(player, jumps)
	local playerData = funcs.GetData(player)
	playerData.ExtraJumps = jumps
end

---@param velocidad number
---@return integer
local function calcularCooldown(velocidad)
	local base = 18
	local sub = -10
	local cooldown = base + (velocidad - 1) * sub

	return math.ceil(cooldown)
end

---@param player EntityPlayer
---@return integer
local function GetNumTears(player)
	local params = player:GetMultiShotParams(WeaponType.WEAPON_TEARS)
	return params:GetNumTears()
end

---@param player EntityPlayer
function Edith:EdithInit(player)
	if not funcs.IsEdith(player, false) then return end
	mod.SetNewANM2(player, "gfx/EdithAnim.anm2")
	mod.ForceCharacterCostume(player, players.PLAYER_EDITH, costumes.ID_EDITH_SCARF)

	local playerData = funcs.GetData(player)
	playerData.EdithJumpTimer = 20
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, Edith.EdithInit)

function Edith:EdithSaltTears(tear)
	local player = mod:GetPlayerFromTear(tear)

	if not player then return end
	if not funcs.IsEdith(player, false) then return end

	funcs.ForceSalt(tear)

	if not player:HasCollectible(CollectibleType.COLLECTIBLE_MARKED) then return end
	local target = funcs.GetTarget(player)
	if not target then return end
	local shotSpeed = player.ShotSpeed * 10
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

local CooldownSounds = {
	[1] = SoundEffect.SOUND_STONE_IMPACT,
	[2] = SoundEffect.SOUND_BEEP
}

---comment
---@param player EntityPlayer
function Edith:EdithJumpHandler(player)
	if not funcs.IsEdith(player, false) then return end

	-- print(calcularCooldown(player.MoveSpeed))

	local room = game:GetRoom()
	local playerData = funcs.GetData(player)
	local isMoving = funcs.TargetMov(player)
	local isKeyStompPressed = funcs.KeyStompPress(player)
	local hasMarked = player:HasCollectible(CollectibleType.COLLECTIBLE_MARKED)
	local isShooting = mod:IsPlayerShooting(player)
	local jumpData = JumpLib:GetData(player)
	local isPitfall = JumpLib:IsPitfalling(player)
	local isJumping = jumpData.Jumping
 
	playerData.isJumping = playerData.isJumping or false
	playerData.ExtraJumps = playerData.ExtraJumps or 0

	if player:IsDead() then funcs.RemoveTarget(player) return end

	if player.FrameCount > 0 and (isMoving or isKeyStompPressed or (hasMarked and isShooting)) and not isPitfall then
		funcs.SpawnTarget(player)
	end

	funcs.EdithWeapons(player)
	funcs.CustomDrop(player, jumpData)
	funcs.DashBehavior(player)

	local target = funcs.GetTarget(player)
	if not target then return end

	local targetSprite = target:GetSprite()

	if isMoving then
		local MovementForce = {
			up = Input.GetActionValue(ButtonAction.ACTION_UP, player.ControllerIndex),
			down = Input.GetActionValue(ButtonAction.ACTION_DOWN, player.ControllerIndex),
			left = Input.GetActionValue(ButtonAction.ACTION_LEFT, player.ControllerIndex),
			right = Input.GetActionValue(ButtonAction.ACTION_RIGHT, player.ControllerIndex),
		}

		local input = {
			up = Input.IsActionPressed(ButtonAction.ACTION_UP, player.ControllerIndex),
			down = Input.IsActionPressed(ButtonAction.ACTION_DOWN, player.ControllerIndex),
			left = Input.IsActionPressed(ButtonAction.ACTION_LEFT, player.ControllerIndex),
			right = Input.IsActionPressed(ButtonAction.ACTION_RIGHT, player.ControllerIndex)
		}

		local InverseX = room:IsMirrorWorld() and -1 or 1
		local VectorX = ((input.left and -1 * MovementForce.left) or (input.right and 1 * MovementForce.right) or 0) * InverseX
		local VectorY = ((input.up and -1 * MovementForce.up) or (input.down and 1 * MovementForce.down) or 0)
		local NormalMovement = Vector(VectorX, VectorY):Normalized()
		local friction = targetSprite:IsPlaying("Blink") and 0.5 or 0.775

		target.Velocity = (target.Velocity + (NormalMovement:Resized(3.5)))
		target:MultiplyFriction(friction)
	else
		target:MultiplyFriction(0.8)
	end

	if isKeyStompPressed and not isJumping then
		local multiShot = player:GetMultiShotParams(WeaponType.WEAPON_TEARS)
		local multTears = multiShot:GetNumTears()
		setEdithJumps(player, multTears)
	end

	if playerData.EdithJumpTimer == 0 and playerData.ExtraJumps > 0 and not isJumping then
		mod.InitEdithJump(player)
		playerData.isJumping = true
	end

	local distance = funcs.TargetDis(player)
	local direction = funcs.TargetDir(player)
	local angle = funcs.VecToAng(direction)
	local isClose = distance <= 5
	local isShooting = mod:IsPlayerShooting(player)
	local isStomping = funcs.KeyStompPress(player)
	local faceDirection = funcs.Switch(angle, tables.DegreesToDirection, Direction.DOWN)
	local dir = isClose and Direction.DOWN or faceDirection

	mod:TargetDoorManager(target, player, 25)

	if isJumping or (not isShooting) or (isStomping) then
		player:SetHeadDirection(dir, 1, true)
	end
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
	local playerPos = player.Position

	for i = 1, gridSize do
		local gent = room:GetGridEntity(i)

		if not gent then goto Break end
		local GentType = gent:GetType()
		local isValidGentType = funcs.Switch(GentType, entityTypes, false)

		if GentType == GridEntityType.GRID_GRAVITY then return true end
		if not isValidGentType then
			local distance = (playerPos - gent.Position):Length()
			return (distance <= 20)
		end
		::Break::
	end
	return false
end

---@param player EntityPlayer
---@param pitfall boolean
function Edith:EdithLanding(player, _, pitfall)
	local playerData = funcs.GetData(player)
	local edithTarget = funcs.GetTarget(player)

	if not edithTarget then return end
	playerData.ExtraJumps = math.max(playerData.ExtraJumps - 1, 0)

	if pitfall then
		funcs.RemoveTarget(player)
		playerData.isJumping = false
		return
	end

	if isNearTrapdoor(player) == false then
		funcs.FeedbackMan(player, SoundPick, player.Color, false)
	end

	local IsDefensiveStomp = playerData.IsDefensiveStomp
	local CanFly = player.CanFly
	local distance = funcs.TargetDis(player)
	local stage = level:GetStage()
	local tears = funcs.GetTPS(player)
	local level = math.ceil(stage / 2)

	local flightMult = {
		Damage = CanFly == true and 1.5 or 1,
		Knockback = CanFly == true and 1.2 or 1,
		Radius = CanFly == true and 1.3 or 1,
	}

	local tearRange = player.TearRange / 40
	local radius = math.min((24 + (tearRange - 9) * 2) * flightMult.Radius, 80)
	local knockbackFormula = math.min(50, (7.7 + player.Damage ^ 1.2) * flightMult.Knockback) * player.ShotSpeed

	local tearsMult = tears / 2.73

	local damageBase = 10 + (5.25 * (level - 1))
	local DamageStat = player.Damage + ((player.Damage / 5.25) - 1)

	local multiShot = player:GetMultiShotParams(WeaponType.WEAPON_TEARS)
	local tearCount = multiShot:GetNumTears()

	local multishotMult = funcs.Round(mod.exp(tearCount, 1, 0.68), 2)
	local birthrightMult = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and 1.2 or 1
	local bloodClotMult = player:HasCollectible(CollectibleType.COLLECTIBLE_BLOOD_CLOT) and 1.1 or 1
	local RawFormula = ((((damageBase + (DamageStat * tearsMult)) * multishotMult) * birthrightMult) * bloodClotMult) * flightMult.Damage
	local damageFormula = funcs.Round(RawFormula, 2)
	local stompDamage = IsDefensiveStomp and 0 or math.max(damageFormula, 1)

	mod:EdithStomp(player, radius, stompDamage, knockbackFormula, true)

	local targetSprte = playerData.EdithTarget:GetSprite()
	local Cooldown = calcularCooldown(player.MoveSpeed)
	targetSprte:Play("Idle")
	player:MultiplyFriction(0.05)

	if IsDefensiveStomp then
		playerData.EdithJumpTimer = math.max(Cooldown - 5, 10)
	else
		local hasEpicFetus = player:HasCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS)

		if playerData.ExtraJumps > 0 then
			playerData.EdithJumpTimer = math.floor((hasEpicFetus and 30 or 5) * (Cooldown / 20))
		else
			playerData.EdithJumpTimer = Cooldown
		end
	end

	player:SetMinDamageCooldown(20)

	if not funcs.KeyStompPress(player) and not funcs.TargetMov(player) then
		if distance <= 5 and distance >= 60 then
			player.Position = edithTarget.Position
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
	
	playerData.IsDefensiveStomp = false
	playerData.isJumping = false
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, Edith.EdithLanding, JumpParams.EdithJump)

---@param player EntityPlayer
function Edith:EdithJumpLibStuff(player)
	if not funcs.IsEdith(player, false) then return end
	local playerData = funcs.GetData(player)
	playerData.EdithJumpTimer = playerData.EdithJumpTimer or 20
	playerData.EdithJumpTimer = math.max(playerData.EdithJumpTimer - 1, 0)

	if playerData.EdithJumpTimer == 1 and player.FrameCount > 20 then
		player:SetColor(misc.JumpReadyColor, 5, 100, true, false)
		local saveManager = EdithRebuilt.SaveManager
		local EdithSave = saveManager.GetSettingsSave().EdithData
		local sound = EdithSave.CooldownSound or 1
		sfx:Play(funcs.Switch(sound, CooldownSounds), 2)
	end

	if not funcs.GetTarget(player) then return end
	if not playerData.isJumping == true then return end
	
	local iskeystomp = funcs.KeyStompPress(player)
	local direction = funcs.TargetDir(player)
	local distance = funcs.TargetDis(player)
	local div = (iskeystomp and player.CanFly) and 70 or 50

	funcs.EdithDash(player, direction, distance, div)
end
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, Edith.EdithJumpLibStuff)

local defensiveColor = Color(0.2, 0.2, 0.2)
---@param player EntityPlayer
---@param data JumpConfig
function Edith:EdithBomb(player, data)
	local jumpinternalData = JumpLib.Internal:GetData(player)
	local playerData = funcs.GetData(player)

	if funcs.KeyStompPress(player) then
		if jumpinternalData.UpdateFrame == 9 then
			playerData.IsDefensiveStomp = true
			player:SetColor(defensiveColor, 10, 100, true, false)
			sfx:Play(SoundEffect.SOUND_BIRD_FLAP, 1, 0, false, 1.3)
			local HeightMult = player.CanFly and 0.8 or 0.65
			local JumpSpeed = player.CanFly and 1.2 or 1.5
			jumpinternalData.StaticHeightIncrease = jumpinternalData.StaticHeightIncrease * HeightMult
			jumpinternalData.StaticJumpSpeed = JumpSpeed
		end
	end

	mod.FallBehavior(player)
	mod.BombFall(player, data)
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_UPDATE_60, Edith.EdithBomb, JumpParams.EdithJump)

function Edith:EdithOnNewRoom()
	local players = PlayerManager.GetPlayers()

	for _, player in pairs(players) do
		if funcs.IsEdith(player, false) then
			mod:ChangeColor(player.Color, _, _, _, 1)
			funcs.RemoveTarget(player)
			setEdithJumps(player, 0)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, Edith.EdithOnNewRoom)

---@param damage number
---@param source EntityRef
---@return boolean?
function Edith:DamageStuff(_, damage, _, source)
	if source.Type == 0 then return end

	local ent = source.Entity
	local familiar = ent:ToFamiliar()
	local player = ent:ToPlayer() or familiar and familiar.Player

	if not player then return end
	if not funcs.IsEdith(player, false) then return end

	local HasHeels = player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_HEELS)

	if not JumpLib:GetData(player).Jumping then return end  
	if not (familiar or (HasHeels and damage == 12)) then return end

	return false
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, Edith.DamageStuff)

local RemoveTargetItems = {
	[CollectibleType.COLLECTIBLE_ESAU_JR] = true,
	[CollectibleType.COLLECTIBLE_CLICKER] = true,
}

---@param ID CollectibleType
---@param player EntityPlayer
function Edith:OnEsauJrUse(ID, _, player)
	local shouldRemoveItem = funcs.Switch(ID, RemoveTargetItems, false)
	if not shouldRemoveItem then return end
	funcs.RemoveTarget(player)
end
mod:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, Edith.OnEsauJrUse)