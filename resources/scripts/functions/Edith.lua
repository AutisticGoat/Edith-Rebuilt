local mod = EdithRebuilt
local enums = mod.Enums
local utils = enums.Utils
local game = utils.Game
local level = utils.Level
local sfx = utils.SFX
local misc = enums.Misc
local tables = enums.Tables
local JumpTags = tables.JumpTags
local jumpFlags = tables.JumpFlags
local challenges = enums.Challenge
local Player = require("resources.scripts.functions.Player")
local Math = require("resources.scripts.functions.Maths")
local VecDir = require("resources.scripts.functions.VecDir")
local TargetArrow = require("resources.scripts.functions.TargetArrow")
local modRNG = require("resources.scripts.functions.RNG")
local Helpers = require("resources.scripts.functions.Helpers")
local data = mod.DataHolder.GetEntityData
local Edith = {}

---@class EdithJumpStompParams
---@field Damage number
---@field Radius number
---@field Knockback number
---@field CanJump false
---@field Cooldown integer
---@field JumpStartPos Vector
---@field JumpStartDist number
---@field CoalBonus number
---@field BombStomp boolean
---@field RocketLaunch boolean
---@field IsDefensiveStomp boolean
---@field StompedEntities Entity[]

---@param player EntityPlayer
function Edith.GetJumpStompParams(player)
	local DefaultStompParams = {
		Damage = 0,
		Radius = 0,
		Knockback = 0,
		CanJump = false,
		Cooldown = 0,
		JumpStartPos = Vector(0, 0),
		JumpStartDist = 0,
		CoalBonus = 0,
		BombStomp = false,
		RocketLaunch = false,
		IsDefensiveStomp = false,
		StompedEntities = {},
	} --[[@as EdithJumpStompParams]]

    data(player).JumpParams = data(player).JumpParams or DefaultStompParams 
    local params = data(player).JumpParams ---@cast params EdithJumpStompParams

    return params
end

local params = Edith.GetJumpStompParams

---Method used for Edith's dash behavior (Like A Pony/White Pony or Mars usage)
---@param player EntityPlayer
---@param dir Vector
---@param dist number
---@param div number
function Edith.EdithDash(player, dir, dist, div)
	player.Velocity = player.Velocity + dir * dist / div
end

---@param velocidad number
---@return integer
function Edith.GetStompCooldown(velocidad)
	return math.ceil(18 + (velocidad - 1) * -10)
end

---@param player EntityPlayer
---@return integer
function Edith.GetNumTears(player)
	return player:GetMultiShotParams(WeaponType.WEAPON_TEARS):GetNumTears()
end

---@param player EntityPlayer
---@param params EdithJumpStompParams
---@param keyStomp boolean
---@param jumping boolean
---@param vestige boolean
function Edith.JumpTriggerManager(player, params, keyStomp, jumping, vestige)
	local commonConditional = not jumping and not vestige

	if keyStomp and params.Cooldown == 0 and params.CanJump and commonConditional then
		Edith.InitEdithJump(player, JumpTags.EdithJump, vestige)	
	end
end

---@param player EntityPlayer
---@param jumping boolean
---@param shooting boolean
---@param keyStomp boolean
function Edith.HeadDirectionManager(player, jumping, shooting, keyStomp)
    local dir = TargetArrow.GetEdithTargetDistance(player) <= 5 and Direction.DOWN or VecDir.VectorToDirection(TargetArrow.GetEdithTargetDirection(player))
	
	if not (jumping or (not shooting) or (keyStomp)) then return end
	player:SetHeadDirection(dir, 1, true)
end

---@param player EntityPlayer
---@param jumpData JumpData
function Edith.CustomDropBehavior(player, jumpData)
	if not Player.IsEdith(player, false) then return end
	local playerData = data(player)
	playerData.ShouldDrop = playerData.ShouldDrop or false

	if playerData.ShouldDrop == false then
	---@diagnostic disable-next-line: undefined-field
		player:SetActionHoldDrop(0)
	end

	if not jumpData.Jumping then playerData.ShouldDrop = false return end
	if not Input.IsActionTriggered(ButtonAction.ACTION_DROP, player.ControllerIndex) then return end
	if not (jumpData.Height > 10 and not JumpLib:IsFalling(player)) then return end
	playerData.ShouldDrop = true
	---@diagnostic disable-next-line: undefined-field
	player:SetActionHoldDrop(119)
end

---@param player EntityPlayer
function Edith.DashItemBehavior(player)
	local edithTarget = TargetArrow.GetEdithTarget(player)

	if not edithTarget then return end
	local effects = player:GetEffects()
	local hasMarsEffect = effects:HasCollectibleEffect(CollectibleType.COLLECTIBLE_MARS)
	local hasAnyPonyEffect = effects:HasCollectibleEffect(CollectibleType.COLLECTIBLE_PONY) or effects:HasCollectibleEffect(CollectibleType.COLLECTIBLE_WHITE_PONY)
	local direction = TargetArrow.GetEdithTargetDirection(player, false)
	local distance = TargetArrow.GetEdithTargetDistance(player)

	if hasMarsEffect or hasAnyPonyEffect then
		Edith.EdithDash(player, direction, distance, 50)
	end

	if player.Velocity:Length() <= 3 then
		effects:RemoveCollectibleEffect(CollectibleType.COLLECTIBLE_PONY, -1)
		effects:RemoveCollectibleEffect(CollectibleType.COLLECTIBLE_WHITE_PONY, -1)
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

	Edith.EdithDash(player, direction, distance, 50)
	player:UseActiveItem(activeItem)
	player:SetActiveCharge(usedCharge, ActiveSlot.SLOT_PRIMARY)
end

---@param player EntityPlayer
---@param jumpIntData InternalJumpData
---@param jumpParams EdithJumpStompParams
function Edith.DefensiveStompManager(player, jumpIntData, jumpParams)

	local config = Helpers.GetConfigData("EdithData")

	if not config then return end

    if not Helpers.IsKeyStompPressed(player) then return end
	if jumpIntData.UpdateFrame ~= config.DefensiveStompWindow then return end
	if Helpers.IsVestigeChallenge() then return end

	local CanFly = player.CanFly
	local HeightMult = CanFly and 0.8 or 0.65
	local JumpSpeed = CanFly and 1.2 or 1.5

	jumpParams.IsDefensiveStomp = true
	Player.SetColorCooldown(player, -0.8, 10)
	sfx:Play(SoundEffect.SOUND_STONE_IMPACT, 1, 0, false, 0.8)
	
	jumpIntData.StaticHeightIncrease = jumpIntData.StaticHeightIncrease * HeightMult
	jumpIntData.StaticJumpSpeed = JumpSpeed
end

---@param player EntityPlayer
---@param jumpdata JumpConfig|JumpData
---@param jumpParams EdithJumpStompParams
function Edith.FallBehavior(player, jumpdata, jumpParams)
	local distance = TargetArrow.GetEdithTargetDistance(player)

	if jumpParams.IsDefensiveStomp then return end
	if not (player.CanFly and ((TargetArrow.IsEdithTargetMoving(player) and distance <= 50) or distance <= 5)) then return end

	if not (jumpdata.Fallspeed < 8.5 and JumpLib:IsFalling(player)) then return end
	sfx:Play(SoundEffect.SOUND_SHELLGAME)
	JumpLib:SetSpeed(player, 10 + (jumpdata.Height / 10))
end

---@param player EntityPlayer
---@param jumpConfig JumpData
---@param jumpParams EdithJumpStompParams
function Edith.BombFall(player, jumpConfig, jumpParams)	
	if Helpers.IsVestigeChallenge() then return end
	if jumpParams.IsDefensiveStomp then return end
	if not Input.IsActionTriggered(ButtonAction.ACTION_BOMB, player.ControllerIndex) then return end

	local HasBombReplaceTearItem = (
		player:HasCollectible(CollectibleType.COLLECTIBLE_DR_FETUS) or
		player:HasCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS)
	)
	if not (HasBombReplaceTearItem or player:GetNumBombs() > 0 or player:HasGoldenBomb()) then return end
	jumpParams.BombStomp = true

	if player:HasCollectible(CollectibleType.COLLECTIBLE_ROCKET_IN_A_JAR) then 
		local TargetAnglev = TargetArrow.GetEdithTargetDirection(player, false):GetAngleDegrees()
		local bomb = Isaac.Spawn(EntityType.ENTITY_BOMB, BombVariant.BOMB_ROCKET, 0, player.Position, Vector.Zero, player):ToBomb() ---@cast bomb EntityBomb
		bomb:SetRocketAngle(TargetAnglev)
		bomb:SetRocketSpeed(40)
		local ShouldKeepBomb = HasBombReplaceTearItem or player:HasGoldenBomb()

		if not ShouldKeepBomb then
			player:AddBombs(-1)
		end

		sfx:Play(SoundEffect.SOUND_ROCKET_LAUNCH)
		
		Edith.ExplosionRecoil(player, jumpParams)

		jumpParams.RocketLaunch = true
		data(bomb).IsEdithRocket = true
		return
	end

	if jumpParams.RocketLaunch then return end
	JumpLib:SetSpeed(player, 8 + (jumpConfig.Height / 10))
end

---@param bomb EntityBomb
function mod:BombUpdate(bomb)
	if not data(bomb).IsEdithRocket then return end
	local rocketHeight = JumpLib:GetData(bomb).Height

	if rocketHeight <= 15 then
		JumpLib:QuitJump(bomb)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_BOMB_RENDER, mod.BombUpdate)

---@param player EntityPlayer
---@param target EntityEffect
---@param isMoving boolean
function Edith.TargetMovementManager(player, target, isMoving)
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
end 

---@param player EntityPlayer
---@param params EdithJumpStompParams
function Edith.StompRadiusManager(player, params)
    local base = 35
    local flightMult = player.CanFly and 1.25 or 1
    local range = Player.GetPlayerRange(player)
    local factor = range/9 - (1 - (range/9))
    local RocketLaunchMult = params.RocketLaunch and 1.2 or 1

    params.Radius = ((base + factor) * flightMult) * RocketLaunchMult
end

---@param player EntityPlayer
---@param params EdithJumpStompParams
function Edith.StompDamageManager(player, params)
    local chapter = math.ceil(level:GetStage() / 2)
    local mults = {
        MultiShot = Math.Round(Math.exp(Edith.GetNumTears(player), 1, 0.5), 2),
        Birthtight = Player.PlayerHasBirthright(player) and 1.2 or 1,
        BloodClot = player:HasCollectible(CollectibleType.COLLECTIBLE_BLOOD_CLOT) and 1.1 or 1,
        Flight = Player.CanFly and 1.25 or 1,
        RocketLaunch = params.RocketLaunch and 1.2 or 1
    }
	local playerDamage = player.Damage
	local coalBonus = params.CoalBonus or 0
	local damageBase = 12 + (6 * (chapter - 1))
	local DamageStat = playerDamage + ((playerDamage / 5.25) - 1)
    local RawFormula = (
        (damageBase + DamageStat) *
        mults.MultiShot *
        mults.Birthtight * 
        mults.BloodClot * 
        mults.Flight * 
        mults.RocketLaunch
    ) + coalBonus

	local damageFormula = math.max(Math.Round(RawFormula, 2), 1)
	local stompDamage = (Helpers.IsVestigeChallenge() and 40 + player.Damage/2) or damageFormula

    params.Damage = not params.IsDefensiveStomp and stompDamage or 0
end

---@param player EntityPlayer
---@param params EdithJumpStompParams
function Edith.StompKnockbackManager(player, params)
    local flightMult = player.CanFly and 1.15 or 1
	params.Knockback = math.min(50, (7 ^ 1.2) * flightMult) * player.ShotSpeed
end

---@param player EntityPlayer
---@param params EdithJumpStompParams
function Edith.StompCooldownManager(player, params)
    local Cooldown = Edith.GetStompCooldown(player.MoveSpeed)
    
    params.Cooldown = (params.IsDefensiveStomp and math.max(Cooldown - 5, 10) or Cooldown)
end

---@param player EntityPlayer
---@param params EdithJumpStompParams
function Edith.StompTargetRemover(player, params)
    if Helpers.IsKeyStompPressed(player) or TargetArrow.IsEdithTargetMoving(player) then return end
    -- if params.CanJump then return end
    TargetArrow.RemoveEdithTarget(player)
end 

---@param player EntityPlayer
---@param params EdithJumpStompParams
---@param bomb? EntityBomb
function Edith.ExplosionRecoil(player, params, bomb)
	if not JumpLib:GetData(player).Jumping then return end

	JumpLib:Jump(player, {
		Height = 10,
		Speed = 1.5,
		Tags = JumpTags.EdithJump,
		Flags = jumpFlags.EdithJump,
	})

	local velTarget = (
		bomb and (player.Position - bomb.Position) or 
		-player.Velocity
	):Normalized()

	player.Velocity = velTarget:Resized(15)
	params.RocketLaunch = true
end

---@param player EntityPlayer
---@param jumpParams EdithJumpStompParams
function Edith.CooldownUpdate(player, jumpParams)
    jumpParams.Cooldown = math.max(jumpParams.Cooldown - 1, 0)

	jumpParams.CanJump = jumpParams.Cooldown == 0

	if not (jumpParams.Cooldown == 1 and player.FrameCount > 20) then return end
    Player.SetColorCooldown(player, 0.6, 5)
    local EdithSave = Helpers.GetConfigData("EdithData") ---@cast EdithSave EdithData
    local soundTab = tables.CooldownSounds[EdithSave.JumpCooldownSound or 1]
    local pitch = soundTab.Pitch == 1.2 and (soundTab.Pitch * modRNG.RandomFloat(player:GetDropRNG(), 1, 1.1)) or soundTab.Pitch
    sfx:Play(soundTab.SoundID, 2, 0, false, pitch)
    jumpParams.StompedEntities = nil
    jumpParams.IsDefensiveStomp = false
end

---@param player EntityPlayer
function Edith.JumpMovement(player)
	if Helpers.IsVestigeChallenge() then return end
	if not TargetArrow.GetEdithTarget(player) then return end
	if not Edith.IsJumping(player) then return end

	local div = (Helpers.IsKeyStompPressed(player) and player.CanFly) and 70 or 50
	Edith.EdithDash(player, TargetArrow.GetEdithTargetDirection(player, false), TargetArrow.GetEdithTargetDistance(player), div)
end

---@param player EntityPlayer
---@param params EdithJumpStompParams
function Edith.BombStompManager(player, params)
    if not params.BombStomp then return end

	local HasBombReplaceTearItem = (
		player:HasCollectible(CollectibleType.COLLECTIBLE_DR_FETUS) or
		player:HasCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS)
	)

    if not HasBombReplaceTearItem and (player:GetNumBombs() > 0 and not player:HasGoldenBomb()) and not player:HasCollectible(CollectibleType.COLLECTIBLE_ROCKET_IN_A_JAR) then
        player:AddBombs(-1)
    end

    if not player:HasCollectible(CollectibleType.COLLECTIBLE_ROCKET_IN_A_JAR) then
        game:BombExplosionEffects(player.Position, 100, player.TearFlags, misc.ColorDefault, player, 1, false, false, 0)
    end

    if player:HasCollectible(CollectibleType.COLLECTIBLE_FAST_BOMBS) then
        params.Cooldown = 3
    end

    params.BombStomp = false
end

---@param player EntityPlayer
---@param jumpTag? string
---@param vestige? boolean
function Edith.InitEdithJump(player, jumpTag, vestige)	
	vestige = vestige or false
    jumpTag = jumpTag or JumpTags.EdithJump

	local canFly = player.CanFly
	local jumpSpeed = vestige and (3.75 + (player.MoveSpeed - 1)) or canFly and 1.3 or 1.85
	local soundeffect = canFly and SoundEffect.SOUND_ANGEL_WING or SoundEffect.SOUND_SHELLGAME
	local div = vestige and 1 or (canFly and 25 or 15)
	local base = vestige and 40 or (canFly and 15 or 13)
	local epicFetusMult = player:HasCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS) and 3 or 1
	local jumpHeight = (base + (TargetArrow.GetEdithTargetDistance(player) / 40) / div) * epicFetusMult
	local room = game:GetRoom()
	local isChap4 = Helpers.IsChap4()
	local hasWater = room:HasWater()
	local variant = hasWater and EffectVariant.BIG_SPLASH or (isChap4 and EffectVariant.POOF02 or EffectVariant.POOF01)
	local subType = (isChap4 and 66 or 1)
	local DustCloud = Isaac.Spawn(
		EntityType.ENTITY_EFFECT, 
		variant, 
		subType, 
		player.Position, 
		Vector.Zero, 
		player
	):ToEffect() ---@cast DustCloud EntityEffect 
	sfx:Play(soundeffect)

    Helpers.SetBloodEffectColor(DustCloud)

	DustCloud.SpriteScale = DustCloud.SpriteScale * player.SpriteScale.X
	DustCloud.DepthOffset = -100
	DustCloud:GetSprite().PlaybackSpeed = hasWater and 1.3 or 2	

	local config = {
		Height = jumpHeight,
		Speed = jumpSpeed,
		Tags = jumpTag,
		Flags = jumpFlags.EdithJump,
	}

	JumpLib:Jump(player, config)
end

---@param familiar EntityFamiliar
function Edith:MoveBloodClotsToEdith(familiar)
	local player = familiar.Player

	if not Edith.IsJumping(player) then return end
	familiar.Velocity = player.Velocity	
end
mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, Edith.MoveBloodClotsToEdith, 254)

---@param player EntityPlayer
function Edith.IsJumping(player)
    return JumpLib:GetData(player).Jumping
end

return Edith