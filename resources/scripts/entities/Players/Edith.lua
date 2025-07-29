local mod = EdithRebuilt
local enums = mod.Enums
local sounds = enums.SoundEffect
local misc = enums.Misc
local players = enums.PlayerType
local costumes = enums.NullItemID
local utils = enums.Utils
local tables = enums.Tables
local level = utils.Level
local game = utils.Game 
local sfx = utils.SFX
local JumpParams = tables.JumpParams
local saveManager = mod.SaveManager
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
	KeyStompPress = mod.IsKeyStompPressed,
	EdithDash = mod.EdithDash,
	GetTarget = mod.GetEdithTarget,
	GetData = mod.CustomDataWrapper.getData,
	SpawnTarget = mod.SpawnEdithTarget,
	FeedbackMan = mod.LandFeedbackManager,
	EdithWeapons = mod.ManageEdithWeapons,
	DashBehavior = mod.DashItemBehavior,
	CustomDrop = mod.CustomDropBehavior,
	Round = mod.Round,
	DefensiveStomp = mod.IsDefensiveStomp,
	VecToDir = mod.VectorToDirection
}

---@param player EntityPlayer
---@param jumps integer
local function setEdithJumps(player, jumps)
	local playerData = funcs.GetData(player)
	playerData.ExtraJumps = jumps
end

---@param velocidad number
---@return integer
local function GetStompCooldown(velocidad)
	return math.ceil(18 + (velocidad - 1) * -10)
end

---@param player EntityPlayer
---@return integer
local function GetNumTears(player)
	return player:GetMultiShotParams(WeaponType.WEAPON_TEARS):GetNumTears()
end

---Helper function for Edith's cooldown color manager
---@param player EntityPlayer
---@param intensity number
---@param duration integer
function Edith:ColorCooldown(player, intensity, duration)
	local pcolor = player.Color
	local col = pcolor:GetColorize()
	local tint = pcolor:GetTint()
	local off = pcolor:GetOffset()
	local Red = off.R + (intensity + ((col.R + tint.R) * 0.2))
	local Green = off.G + (intensity + ((col.G + tint.G) * 0.2))
	local Blue = off.B + (intensity + ((col.B + tint.B) * 0.2))
		
	pcolor:SetOffset(Red, Green, Blue)
	player:SetColor(pcolor, duration, 100, true, false)
end

---@param player EntityPlayer
function Edith:EdithInit(player)
	if not funcs.IsEdith(player, false) then return end
	mod.SetNewANM2(player, "gfx/EdithAnim.anm2")
	mod.ForceCharacterCostume(player, players.PLAYER_EDITH, costumes.ID_EDITH_SCARF)
	funcs.GetData(player).EdithJumpTimer = 20
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
	tear.Velocity = funcs.VelTarget(tear, target, player.ShotSpeed * 10)
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
	if not funcs.IsEdith(player, false) then return end
	if player:IsDead() then funcs.RemoveTarget(player) return end

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

	if player.FrameCount > 0 and (isMoving or isKeyStompPressed or (hasMarked and isShooting)) and not isPitfall then
		funcs.SpawnTarget(player)
	end

	funcs.EdithWeapons(player)
	funcs.CustomDrop(player, jumpData)
	funcs.DashBehavior(player)

	local target = funcs.GetTarget(player)
	if not target then return end
	if isMoving then
		local input = {
			up = Input.GetActionValue(ButtonAction.ACTION_UP, player.ControllerIndex),
			down = Input.GetActionValue(ButtonAction.ACTION_DOWN, player.ControllerIndex),
			left = Input.GetActionValue(ButtonAction.ACTION_LEFT, player.ControllerIndex),
			right = Input.GetActionValue(ButtonAction.ACTION_RIGHT, player.ControllerIndex),
		}

		local VectorX = ((input.left > 0.3 and -input.left) or (input.right > 0.3 and input.right) or 0) * (game:GetRoom():IsMirrorWorld() and -1 or 1)
		local VectorY = ((input.up > 0.3 and -input.up) or (input.down > 0.3 and input.down) or 0)
		local friction = target:GetSprite():IsPlaying("Blink") and 0.5 or 0.775

		target.Velocity = target.Velocity + Vector(VectorX, VectorY):Normalized():Resized(3.5)
		target:MultiplyFriction(friction)
	else
		target:MultiplyFriction(0.8)
	end

	if isKeyStompPressed and not isJumping then
		setEdithJumps(player, GetNumTears(player))
	end

	if playerData.EdithJumpTimer == 0 and playerData.ExtraJumps > 0 and not isJumping then
		mod.InitEdithJump(player)
		playerData.isJumping = true
	end
	
	local dir = funcs.TargetDis(player) <= 5 and Direction.DOWN or funcs.VecToDir(funcs.TargetDir(player))
	
	if isJumping or (not isShooting) or (funcs.KeyStompPress(player)) then
		player:SetHeadDirection(dir, 1, true)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, Edith.EdithJumpHandler)

local SoundPick = {
	[1] = SoundEffect.SOUND_STONE_IMPACT, 
	[2] = sounds.SOUND_EDITH_STOMP,
	[3] = sounds.SOUND_FART_REVERB,
	[4] = sounds.SOUND_VINE_BOOM,
}

---@param player EntityPlayer
---@return boolean
local function isNearTrapdoor(player)
	local room = game:GetRoom()
	local playerPos = player.Position
	local gent, GentType

	for i = 1, room:GetGridSize() do
		gent = room:GetGridEntity(i)

		if not gent then goto Break end
		GentType = gent:GetType()

		if GentType == GridEntityType.GRID_GRAVITY then return true end
		if not funcs.Switch(GentType, tables.DisableLandFeedbackGrids, false) then
			return playerPos:Distance(gent.Position) <= 20
		end
		::Break::
	end
	return false
end

---@param player EntityPlayer
function Edith:OnStartingJump(player)
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_LUMP_OF_COAL) then return end
	funcs.GetData(player).CoalBonus = mod.RandomFloat(nil, 0.5, 0.6) * funcs.TargetDis(player) / 40
end
mod:AddCallback(JumpLib.Callbacks.POST_ENTITY_JUMP, Edith.OnStartingJump, JumpParams.EdithJump)

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

	local IsDefensiveStomp = funcs.DefensiveStomp(player)
	local CanFly = player.CanFly
	local flightMult = {
		Damage = CanFly == true and 1.5 or 1,
		Knockback = CanFly == true and 1.2 or 1,
		Radius = CanFly == true and 1.3 or 1,
	}
	local distance = funcs.TargetDis(player)
	local tearsMult = funcs.GetTPS(player) / 2.73
	local chapter = math.ceil(level:GetStage() / 2)
	local playerDamage = player.Damage
	local radius = math.min((24 + ((player.TearRange / 40) - 9) * 2) * flightMult.Radius, 80)
	local knockbackFormula = math.min(50, (7.7 + playerDamage ^ 1.2) * flightMult.Knockback) * player.ShotSpeed
	local coalBonus = playerData.CoalBonus or 0
	local damageBase = 10 + (5.25 * (chapter - 1))
	local DamageStat = playerDamage + ((playerDamage / 5.25) - 1)
	local multishotMult = funcs.Round(mod.exp(GetNumTears(player), 1, 0.68), 2)
	local birthrightMult = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and 1.2 or 1
	local bloodClotMult = player:HasCollectible(CollectibleType.COLLECTIBLE_BLOOD_CLOT) and 1.1 or 1
	local RawFormula = (((((damageBase + (DamageStat * tearsMult)) * multishotMult) * birthrightMult) * bloodClotMult) * flightMult.Damage) + coalBonus
	local damageFormula = math.max(funcs.Round(RawFormula, 2), 1)
	local stompDamage = IsDefensiveStomp and 0 or damageFormula
	local Cooldown = GetStompCooldown(player.MoveSpeed)

	mod:EdithStomp(player, radius, stompDamage, knockbackFormula, true)
	edithTarget:GetSprite():Play("Idle")
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

	player:SetMinDamageCooldown(25)

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
function Edith:EdithPEffectUpdate(player)
	if not funcs.IsEdith(player, false) then return end
	local playerData = funcs.GetData(player)

	playerData.EdithJumpTimer = math.max(playerData.EdithJumpTimer - 1, 0)

	if playerData.EdithJumpTimer == 1 and player.FrameCount > 20 then
		Edith:ColorCooldown(player, 0.6, 5)
		local EdithSave = saveManager.GetSettingsSave().EdithData
		sfx:Play(funcs.Switch(EdithSave.CooldownSound or 1, tables.CooldownSounds), 2)
	end

	if not funcs.GetTarget(player) then return end
	if not playerData.isJumping then return end

	local div = (funcs.KeyStompPress(player) and player.CanFly) and 70 or 50
	funcs.EdithDash(player, funcs.TargetDir(player, false), funcs.TargetDis(player), div)
end
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, Edith.EdithPEffectUpdate)

---@param player EntityPlayer
---@param data JumpConfig
function Edith:EdithBomb(player, data)
	local jumpinternalData = JumpLib.Internal:GetData(player)

	mod.FallBehavior(player)
	mod.BombFall(player, data)

	if not funcs.KeyStompPress(player) then return end
	if jumpinternalData.UpdateFrame ~= 9 then return end

	local CanFly = player.CanFly
	local HeightMult = CanFly and 0.8 or 0.65
	local JumpSpeed = CanFly and 1.2 or 1.5

	funcs.GetData(player).IsDefensiveStomp = true
	Edith:ColorCooldown(player, -0.8, 10)
	sfx:Play(SoundEffect.SOUND_BIRD_FLAP, 1, 0, false, 1.3)
	
	jumpinternalData.StaticHeightIncrease = jumpinternalData.StaticHeightIncrease * HeightMult
	jumpinternalData.StaticJumpSpeed = JumpSpeed
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_UPDATE_60, Edith.EdithBomb, JumpParams.EdithJump)

function Edith:EdithOnNewRoom()
	for _, player in pairs(PlayerManager.GetPlayers()) do
		if not funcs.IsEdith(player, false) then goto Break end
		mod:ChangeColor(player, _, _, _, 1)
		funcs.RemoveTarget(player)
		setEdithJumps(player, 0)
		::Break::
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
	local player = mod.GetPlayerFromRef(source)

	if not player then return end
	if not funcs.IsEdith(player, false) then return end
	if not JumpLib:GetData(player).Jumping then return end  
	local HasHeels = player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_HEELS)

	if not (familiar or (HasHeels and damage == 12)) then return end
	return false
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, Edith.DamageStuff)

---@param ID CollectibleType
---@param player EntityPlayer
function Edith:OnEsauJrUse(ID, _, player)
	if not funcs.Switch(ID, tables.RemoveTargetItems, false) then return end
	funcs.RemoveTarget(player)
end
mod:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, Edith.OnEsauJrUse)