local mod = EdithRebuilt
local enums = mod.Enums
local utils = enums.Utils
local game = utils.Game
local level = utils.Level
local misc = enums.Misc
local tables = enums.Tables
local Player = include("resources.scripts.functions.Player")
local Math = include("resources.scripts.functions.Maths")
local helpers = include("resources.scripts.functions.helpers")
local targetArrow = include("resources.scripts.functions.targetArrow")
local jump = include("resources.scripts.functions.jump")
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
	if not helpers.When(weapon:GetWeaponType(), tables.OverrideWeapons, false) then return end
	local newWeapon = Isaac.CreateWeapon(WeaponType.WEAPON_TEARS, player)
	Isaac.DestroyWeapon(weapon)
	player:EnableWeaponType(WeaponType.WEAPON_TEARS, true)
	player:SetWeapon(newWeapon, 1)	
end

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
    -- if jump.IsKeyStompPressed(player) or targetArrow.IsEdithTargetMoving(player) then return end
    -- if params.Jumps > 0 then return end

    print("Triggered remove functions")
    mod.RemoveEdithTarget(player)
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

return Edith
