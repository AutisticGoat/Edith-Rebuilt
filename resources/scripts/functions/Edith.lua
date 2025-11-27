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
local Player = include("resources.scripts.functions.Player")
local Math = include("resources.scripts.functions.Maths")
local VecDir = include("resources.scripts.functions.VecDir")
local jump = include("resources.scripts.functions.Jump")
local data = mod.CustomDataWrapper.getData
local Edith = {}

---@class EdithJumpStompParams
---@field Damage number
---@field Radius number
---@field Knockback number
---@field Jumps integer
---@field Cooldown integer
---@field JumpStartPos Vector
---@field JumpStartDist number
---@field CoalBonus number
---@field BombStomp boolean
---@field RocketLaunch boolean
---@field IsDefensiveStomp boolean
---@field StompedEntities Entity[]

local DefaultStompParams = {
    Damage = 0,
    Radius = 0,
    Knockback = 0,
    Jumps = 0,
    Cooldown = 0,
    JumpStartPos = Vector(0, 0),
    JumpStartDist = 0,
    CoalBonus = 0,
    BombStomp = false,
    RocketLaunch = false,
    IsDefensiveStomp = false,
    StompedEntities = {},
} --[[@as EdithJumpStompParams]]

---@param player EntityPlayer
function Edith.GetJumpStompParams(player)
    data(player).JumpParams = data(player).JumpParams or DefaultStompParams 
    local params = data(player).JumpParams ---@cast params EdithJumpStompParams

    return params
end

local params = Edith.GetJumpStompParams

---@param player EntityPlayer
---@param jumps integer
function Edith.SetJumps(player, jumps)
	params(player).Jumps = jumps
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
function Edith.ManageEdithWeapons(player)
	local weapon = player:GetWeapon(1)

	if not weapon then return end
	if not mod.When(weapon:GetWeaponType(), tables.OverrideWeapons, false) then return end
	local newWeapon = Isaac.CreateWeapon(WeaponType.WEAPON_TEARS, player)
	Isaac.DestroyWeapon(weapon)
	player:EnableWeaponType(WeaponType.WEAPON_TEARS, true)
	player:SetWeapon(newWeapon, 1)	
end

---@param player EntityPlayer
---@param params EdithJumpStompParams
---@param keyStomp boolean
---@param jumping boolean
---@param vestige boolean
function Edith.JumpTriggerManager(player, params, keyStomp, jumping, vestige)
    if keyStomp and not jumping and not vestige then
		Edith.SetJumps(player, Edith.GetNumTears(player))
	end

	if params.Cooldown == 0 and params.Jumps > 0 and not jumping and not vestige then
		jump.InitEdithJump(player, JumpTags.EdithJump, vestige)	
	end
end

---@param player EntityPlayer
---@param isVestige boolean
function Edith.SetVestigeSprite(player, isVestige)
	if not isVestige then return end
	for i = 0, 14 do
		player:GetSprite():ReplaceSpritesheet(i, "gfx/characters/costumes/characterEdithVestige.png", true)
	end
end

---@param player EntityPlayer
---@param jumping boolean
---@param shooting boolean
---@param keyStomp boolean
function Edith.HeadDirectionManager(player, jumping, shooting, keyStomp)
    local dir = mod.GetEdithTargetDistance(player) <= 5 and Direction.DOWN or VecDir.VectorToDirection(mod.GetEdithTargetDirection(player))
	
	if not (jumping or (not shooting) or (keyStomp)) then return end
	player:SetHeadDirection(dir, 1, true)
end

---@param player EntityPlayer
---@param jumpData JumpData
function Edith.CustomDropBehavior(player, jumpData)
	if not mod.IsEdith(player, false) then return end
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
	local edithTarget = mod.GetEdithTarget(player)

	if not edithTarget then return end
	local effects = player:GetEffects()
	local hasMarsEffect = effects:HasCollectibleEffect(CollectibleType.COLLECTIBLE_MARS)
	local hasAnyPonyEffect = effects:HasCollectibleEffect(CollectibleType.COLLECTIBLE_PONY) or effects:HasCollectibleEffect(CollectibleType.COLLECTIBLE_WHITE_PONY)
	local direction = mod.GetEdithTargetDirection(player, false)
	local distance = mod.GetEdithTargetDistance(player)

	if hasMarsEffect or hasAnyPonyEffect then
		mod.EdithDash(player, direction, distance, 50)
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

	mod.EdithDash(player, direction, distance, 50)
	player:UseActiveItem(activeItem)
	player:SetActiveCharge(usedCharge, ActiveSlot.SLOT_PRIMARY)
end

---@param player EntityPlayer
---@param jumpIntData InternalJumpData
---@param jumpParams EdithJumpStompParams
function Edith.DefensiveStompManager(player, jumpIntData, jumpParams)
    if not mod.IsKeyStompPressed(player) then return end
	if jumpIntData.UpdateFrame ~= 9 then return end
	if mod.IsVestigeChallenge() then return end

	local CanFly = player.CanFly
	local HeightMult = CanFly and 0.8 or 0.65
	local JumpSpeed = CanFly and 1.2 or 1.5

	jumpParams.IsDefensiveStomp = true
	mod.SetColorCooldown(player, -0.8, 10)
	sfx:Play(SoundEffect.SOUND_STONE_IMPACT, 1, 0, false, 0.8)
	
	jumpIntData.StaticHeightIncrease = jumpIntData.StaticHeightIncrease * HeightMult
	jumpIntData.StaticJumpSpeed = JumpSpeed
end

---@param player EntityPlayer
---@param jumpdata JumpConfig|JumpData
---@param jumpParams EdithJumpStompParams
function Edith.FallBehavior(player, jumpdata, jumpParams)
	local distance = mod.GetEdithTargetDistance(player)

	if jumpParams.IsDefensiveStomp then return end
	if not (player.CanFly and ((mod.IsEdithTargetMoving(player) and distance <= 50) or distance <= 5)) then return end

	if not (jumpdata.Fallspeed < 8.5 and JumpLib:IsFalling(player)) then return end
	sfx:Play(SoundEffect.SOUND_SHELLGAME)
	JumpLib:SetSpeed(player, 10 + (jumpdata.Height / 10))
end

---@param player EntityPlayer
---@param jumpConfig JumpData
---@param jumpParams EdithJumpStompParams
function Edith.BombFall(player, jumpConfig, jumpParams)	
	if mod.IsVestigeChallenge() then return end
	if mod.IsDefensiveStomp(player) then return end
	if not Input.IsActionTriggered(ButtonAction.ACTION_BOMB, player.ControllerIndex) then return end

	local HasDrFetus = player:HasCollectible(CollectibleType.COLLECTIBLE_DR_FETUS)

	if not (HasDrFetus or player:GetNumBombs() > 0 or player:HasGoldenBomb()) then return end

	local playerData = data(player) 

	jumpParams.BombStomp = true

	if player:HasCollectible(CollectibleType.COLLECTIBLE_ROCKET_IN_A_JAR) then 
		local TargetAnglev = mod.GetEdithTargetDirection(player, false):GetAngleDegrees()
		local bomb = Isaac.Spawn(EntityType.ENTITY_BOMB, BombVariant.BOMB_ROCKET, 0, player.Position, Vector.Zero, player):ToBomb() ---@cast bomb EntityBomb
		bomb:SetRocketAngle(TargetAnglev)
		bomb:SetRocketSpeed(40)
		local ShouldKeepBomb = HasDrFetus or player:HasGoldenBomb()

		if not ShouldKeepBomb then
			player:AddBombs(-1)
		end

		sfx:Play(SoundEffect.SOUND_ROCKET_LAUNCH)
		
		Edith.ExplosionRecoil(player, jumpParams)

		jumpParams.RocketLaunch = true
		data(bomb).IsEdithRocket = true
		return
	end

	if playerData.RocketLaunch then return end
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
        MultiShot = Math.Round(Math.exp(Edith.GetNumTears(player), 1, 0.68), 2),
        Birthtight = mod.PlayerHasBirthright(player) and 1.2 or 1,
        BloodClot = player:HasCollectible(CollectibleType.COLLECTIBLE_BLOOD_CLOT) and 1.1 or 1,
        Flight = Player.CanFly and 1.25 or 1,
        RocketLaunch = params.RocketLaunch and 1.2 or 1
    }
	local playerDamage = player.Damage
	local coalBonus = params.CoalBonus or 0
	local damageBase = 15 + (5.75 * (chapter - 1))
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
	local stompDamage = (mod.IsVestigeChallenge() and 40 + player.Damage/2) or damageFormula

    params.Damage = stompDamage
end

---@param player EntityPlayer
---@param params EdithJumpStompParams
function Edith.StompKnockbackManager(player, params)
    local flightMult = player.CanFly and 1.15 or 1
	params.Knockback = math.min(50, (10 ^ 1.2) * flightMult) * player.ShotSpeed
end

---@param player EntityPlayer
---@param params EdithJumpStompParams
function Edith.StompCooldownManager(player, params)
    local Cooldown = Edith.GetStompCooldown(player.MoveSpeed)
    
    params.Cooldown = (
        params.IsDefensiveStomp and math.max(Cooldown - 5, 10) or
        (params.Jumps > 0 and 5 * (Cooldown / 20) or Cooldown)
    )
end

---@param player EntityPlayer
---@param params EdithJumpStompParams
function Edith.StompTargetRemover(player, params)
    if jump.IsKeyStompPressed(player) or mod.IsEdithTargetMoving(player) then return end
    if params.Jumps > 0 then return end
    mod.RemoveEdithTarget(player)
end 

---@param player EntityPlayer
---@param params EdithJumpStompParams
---@param bomb? EntityBomb
function Edith.ExplosionRecoil(player, params,bomb)
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

	if not (jumpParams.Cooldown == 1 and player.FrameCount > 20) then return end
    mod.SetColorCooldown(player, 0.6, 5)
    local EdithSave = mod.GetConfigData("EdithData") ---@cast EdithSave EdithData
    local soundTab = tables.CooldownSounds[EdithSave.JumpCooldownSound or 1]
    local pitch = soundTab.Pitch == 1.2 and (soundTab.Pitch * mod.RandomFloat(player:GetDropRNG(), 1, 1.1)) or soundTab.Pitch
    sfx:Play(soundTab.SoundID, 2, 0, false, pitch)
    jumpParams.StompedEntities = nil
    jumpParams.IsDefensiveStomp = false
end

---@param player EntityPlayer
function Edith.JumpMovement(player)
	if mod.IsVestigeChallenge() then return end
	if not mod.GetEdithTarget(player) then return end
	if not Edith.IsJumping(player) then return end

	local div = (mod.IsKeyStompPressed(player) and player.CanFly) and 70 or 50
	mod.EdithDash(player, mod.GetEdithTargetDirection(player, false), mod.GetEdithTargetDistance(player), div)
end

---@param player EntityPlayer
---@param params EdithJumpStompParams
function Edith.BombStompManager(player, params)
    if not params.BombStomp then return end
    if player:GetNumBombs() > 0 and not player:HasGoldenBomb() and not player:HasCollectible(CollectibleType.COLLECTIBLE_ROCKET_IN_A_JAR) then
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
function Edith.IsJumping(player)
    return JumpLib:GetData(player).Jumping
end

return Edith
