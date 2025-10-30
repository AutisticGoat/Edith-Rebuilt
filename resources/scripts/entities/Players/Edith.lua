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
local data = mod.CustomDataWrapper.getData
local Edith = {}

---@param player EntityPlayer
---@param jumps integer
local function setEdithJumps(player, jumps)
	local playerData = data(player)
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

---@param player EntityPlayer
function Edith:EdithInit(player)
	if not mod.IsEdith(player, false) then return end
	mod.SetNewANM2(player, "gfx/EdithAnim.anm2")
	mod.ForceCharacterCostume(player, players.PLAYER_EDITH, costumes.ID_EDITH_SCARF)
	data(player).EdithJumpTimer = 20
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, Edith.EdithInit)

---@param player EntityPlayer
function Edith:EdithJumpHandler(player)
	if not mod.IsEdith(player, false) then return end

	local playerData = data(player)
	if player:IsDead() then mod.RemoveEdithTarget(player); playerData.isJumping = false return end

	local isMoving = mod.IsEdithTargetMoving(player)
	local isKeyStompPressed = mod.IsKeyStompPressed(player)
	local hasMarked = player:HasCollectible(CollectibleType.COLLECTIBLE_MARKED)
	local isShooting = mod:IsPlayerShooting(player)
	local jumpData = JumpLib:GetData(player)
	local isPitfall = JumpLib:IsPitfalling(player)
	local isJumping = jumpData.Jumping 

	playerData.isJumping = playerData.isJumping or false
	playerData.ExtraJumps = playerData.ExtraJumps or 0

	if player.FrameCount > 0 and (isMoving or isKeyStompPressed or (hasMarked and isShooting)) and not isPitfall then
		mod.SpawnEdithTarget(player)
	end

	mod.ManageEdithWeapons(player)
	mod.CustomDropBehavior(player, jumpData)
	mod.DashItemBehavior(player)

	local target = mod.GetEdithTarget(player)
	if not target then return end

	local friction
	if isMoving then
		local input = {
			up = Input.GetActionValue(ButtonAction.ACTION_UP, player.ControllerIndex),
			down = Input.GetActionValue(ButtonAction.ACTION_DOWN, player.ControllerIndex),
			left = Input.GetActionValue(ButtonAction.ACTION_LEFT, player.ControllerIndex),
			right = Input.GetActionValue(ButtonAction.ACTION_RIGHT, player.ControllerIndex),
		}

		local VectorX = ((input.left > 0.3 and -input.left) or (input.right > 0.3 and input.right) or 0) * (game:GetRoom():IsMirrorWorld() and -1 or 1)
		local VectorY = ((input.up > 0.3 and -input.up) or (input.down > 0.3 and input.down) or 0)
		friction = target:GetSprite():IsPlaying("Blink") and 0.5 or 0.775

		target.Velocity = target.Velocity + Vector(VectorX, VectorY):Normalized():Resized(4)
	end

	target:MultiplyFriction(friction or 0.8)

	if isKeyStompPressed and not isJumping then
		setEdithJumps(player, GetNumTears(player))
	end

	if playerData.EdithJumpTimer == 0 and playerData.ExtraJumps > 0 and not isJumping then
		mod.InitEdithJump(player)
		playerData.isJumping = true
	end
	
	local dir = mod.GetEdithTargetDistance(player) <= 5 and Direction.DOWN or mod.VectorToDirection(mod.GetEdithTargetDirection(player))
	
	if not (isJumping or (not isShooting) or (isKeyStompPressed)) then return end
	player:SetHeadDirection(dir, 1, true)
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, Edith.EdithJumpHandler)

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
		if not mod.When(GentType, tables.DisableLandFeedbackGrids, false) then
			return playerPos:Distance(gent.Position) <= 20
		end
		::Break::
	end
	return false
end

---@param player EntityPlayer
function Edith:OnStartingJump(player)
	data(player).JumpStartPos = player.Position
	data(player).JumpStartDist = mod.GetEdithTargetDistance(player)

	if not player:HasCollectible(CollectibleType.COLLECTIBLE_LUMP_OF_COAL) then return end
	local rng = player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_LUMP_OF_COAL)
	data(player).CoalBonus = mod.RandomFloat(rng, 0.5, 0.6) * mod.GetEdithTargetDistance(player) / 40
end
mod:AddCallback(JumpLib.Callbacks.POST_ENTITY_JUMP, Edith.OnStartingJump, JumpParams.EdithJump)

---@param player EntityPlayer
---@param pitfall boolean
function Edith:EdithLanding(player, _, pitfall)
	local playerData = data(player)
	local edithTarget = mod.GetEdithTarget(player)

	if not edithTarget then return end
	playerData.ExtraJumps = math.max(playerData.ExtraJumps - 1, 0)

	if pitfall then
		mod.RemoveEdithTarget(player)
		playerData.isJumping = false
		return
	end

	if isNearTrapdoor(player) == false then
		mod.LandFeedbackManager(player, mod:GetLandSoundTable(false), player.Color, false)
	end

	local IsDefensiveStomp = mod.IsDefensiveStomp(player)
	local CanFly = player.CanFly
	local flightMult = {
		Damage = CanFly == true and 1.5 or 1,
		Knockback = CanFly == true and 1.2 or 1,
		Radius = CanFly == true and 1.3 or 1,
	}
	local distance = mod.GetEdithTargetDistance(player)
	local chapter = math.ceil(level:GetStage() / 2)
	local playerDamage = player.Damage
	local radius = math.min((28 + ((player.TearRange / 40) - 9) * 2) * flightMult.Radius, 80)
	local knockbackFormula = math.min(50, (7.7 + playerDamage ^ 1.2) * flightMult.Knockback) * player.ShotSpeed
	local coalBonus = playerData.CoalBonus or 0
	local damageBase = 12 + (5.75 * (chapter - 1))
	local DamageStat = playerDamage + ((playerDamage / 5.25) - 1)
	local multishotMult = mod.Round(mod.exp(GetNumTears(player), 1, 0.68), 2)
	local birthrightMult = mod.PlayerHasBirthright(player) and 1.2 or 1
	local bloodClotMult = player:HasCollectible(CollectibleType.COLLECTIBLE_BLOOD_CLOT) and 1.1 or 1
	local RawFormula = (((((damageBase + (DamageStat)) * multishotMult) * birthrightMult) * bloodClotMult) * flightMult.Damage) + coalBonus
	local damageFormula = math.max(mod.Round(RawFormula, 2), 1)
	local stompDamage = IsDefensiveStomp and 0 or damageFormula
	local Cooldown = GetStompCooldown(player.MoveSpeed)

	if playerData.RocketLaunch then
		stompDamage = stompDamage * 1.35
		radius = radius * 1.35
	end

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

	if not mod.IsKeyStompPressed(player) and not mod.IsEdithTargetMoving(player) then
		if distance <= 5 and distance >= 60 then
			player.Position = edithTarget.Position
		end
		if playerData.ExtraJumps <= 0 then
			mod.RemoveEdithTarget(player)
		end
	end
	playerData.IsFalling = false

	-------- Bomb Stomp --------
	if playerData.BombStomp == true then
		if player:GetNumBombs() > 0 and not player:HasGoldenBomb() and not player:HasCollectible(CollectibleType.COLLECTIBLE_ROCKET_IN_A_JAR) then
			player:AddBombs(-1)
		end

		if not player:HasCollectible(CollectibleType.COLLECTIBLE_ROCKET_IN_A_JAR) then
			game:BombExplosionEffects(player.Position, 100, player.TearFlags, misc.ColorDefault, player, 1, false, false, 0)
		end

		if player:HasCollectible(CollectibleType.COLLECTIBLE_FAST_BOMBS) then
			playerData.EdithJumpTimer = 3
		end

		playerData.BombStomp = false
	end
	-------- Bomb Stomp  end --------
	
	playerData.isJumping = false
	playerData.RocketLaunch = false
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, Edith.EdithLanding, JumpParams.EdithJump)

---@param player EntityPlayer
function Edith:EdithPEffectUpdate(player)
	if not mod.IsEdith(player, false) then return end

	local playerData = data(player)

	if playerData.RocketLaunch then return end

	playerData.EdithJumpTimer = math.max(playerData.EdithJumpTimer - 1, 0)

	if playerData.EdithJumpTimer == 1 and player.FrameCount > 20 then
		mod.SetColorCooldown(player, 0.6, 5)
		local EdithSave = mod.GetConfigData("EdithData") ---@cast EdithSave EdithData
		local soundTab = tables.CooldownSounds[EdithSave.JumpCooldownSound or 1]
		local pitch = soundTab.Pitch == 1.2 and (soundTab.Pitch * mod.RandomFloat(player:GetDropRNG(), 1, 1.1)) or soundTab.Pitch
		sfx:Play(soundTab.SoundID, 2, 0, false, pitch)
		playerData.StompedEntities = nil
		playerData.IsDefensiveStomp = false
	end

	if not mod.GetEdithTarget(player) then return end
	if not playerData.isJumping then return end

	local div = (mod.IsKeyStompPressed(player) and player.CanFly) and 70 or 50
	mod.EdithDash(player, mod.GetEdithTargetDirection(player, false), mod.GetEdithTargetDistance(player), div)
end
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, Edith.EdithPEffectUpdate)

---@param player EntityPlayer
---@param jumpdata JumpConfig
function Edith:EdithBomb(player, jumpdata)
	local jumpinternalData = JumpLib.Internal:GetData(player)

	mod.FallBehavior(player)
	mod.BombFall(player, jumpdata)

	if not mod.IsKeyStompPressed(player) then return end
	if jumpinternalData.UpdateFrame ~= 9 then return end

	local CanFly = player.CanFly
	local HeightMult = CanFly and 0.8 or 0.65
	local JumpSpeed = CanFly and 1.2 or 1.5

	data(player).IsDefensiveStomp = true
	mod.SetColorCooldown(player, -0.8, 10)
	sfx:Play(SoundEffect.SOUND_STONE_IMPACT, 1, 0, false, 0.8)
	
	jumpinternalData.StaticHeightIncrease = jumpinternalData.StaticHeightIncrease * HeightMult
	jumpinternalData.StaticJumpSpeed = JumpSpeed
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_UPDATE_60, Edith.EdithBomb, JumpParams.EdithJump)

function Edith:EdithOnNewRoom()
	for _, player in pairs(PlayerManager.GetPlayers()) do
		if not mod.IsEdith(player, false) then goto Break end
		mod:ChangeColor(player, _, _, _, 1)
		mod.RemoveEdithTarget(player)
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
	if not mod.IsEdith(player, false) then return end
	if not JumpLib:GetData(player).Jumping then return end  
	local HasHeels = player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_HEELS)

	if not (familiar or (HasHeels and damage == 12)) then return end
	return false
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, Edith.DamageStuff)

---@param ID CollectibleType
---@param player EntityPlayer
function Edith:OnActiveItemRemoveTarget(ID, _, player)
	if not mod.When(ID, tables.RemoveTargetItems, false) then return end
	mod.RemoveEdithTarget(player)
end
mod:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, Edith.OnActiveItemRemoveTarget)

---@param bomb EntityBomb
function Edith:OnBombExplode(bomb)
	if not bomb:GetSprite():IsPlaying("Explode") then return end
	local player 
	for _, ent in ipairs(Isaac.FindInRadius(bomb.Position, mod.GetBombRadiusFromDamage(bomb.ExplosionDamage), EntityPartition.PLAYER)) do
		player = ent:ToPlayer() ---@cast player EntityPlayer

		if not mod.IsEdith(player, false) then goto continue end
		if not data(player).isJumping then goto continue end

		mod.ExplosionRecoil(player, bomb)

		::continue::
	end
end
mod:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, Edith.OnBombExplode)