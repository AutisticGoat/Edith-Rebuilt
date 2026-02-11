---@diagnostic disable: undefined-global, param-type-mismatch
local mod = EdithRebuilt
local enums = mod.Enums
local misc = enums.Misc
local utils = enums.Utils
local game = utils.Game
local sfx = utils.SFX
local jumpFlags = enums.Tables.JumpFlags
local jumpTags = enums.Tables.JumpTags
local maths = require("resources.scripts.functions.Maths")
local helpers = require("resources.scripts.functions.Helpers")
local Player = require("resources.scripts.functions.Player")
local Land = require("resources.scripts.functions.Land")
local TEdith = {}
local data = mod.DataHolder.GetEntityData

---@class TEdithHopParryParams
---@field HopDamage number
---@field HopRadius number
---@field HopKnockback number
---@field HopDirection Vector
---@field HopMoveCharge number
---@field HopMoveBRCharge number
---@field HopStaticCharge number -- Used to render ChargeBar and ChargeBar mechanics when TEdith isn't moving
---@field HopStaticBRCharge number -- Used to render ChargeBar and ChargeBar mechanics when TEdith isn't moving
---@field ParryDamage number
---@field ParryRadius number
---@field ParryKnockback number
---@field ParryCooldown number
---@field ImpreciseParriedEnemies Entity[]
---@field ParriedEnemies Entity[]
---@field IsHoping boolean
---@field IsParryJump boolean
---@field GrudgeDash boolean
---@field HopCooldown integer

---@param player EntityPlayer
---@return TEdithHopParryParams
function TEdith.GetHopParryParams(player)
	local DefaultHopDashParams = {
		HopDamage = 0,
		HopRadius = 0,
		HopKnockback = 0,
		HopDirection = Vector.Zero,
		IsHoping = false,
		IsParryJump = false,
		HopMoveCharge = 0,
		HopMoveBRCharge = 0,
		HopStaticCharge = 0,
		HopStaticBRCharge = 0,
		ParryDamage = 0,
		ParryKnockback = 0,
		ParryRadius = 0,
		ParryCooldown = 0,
		ParriedEnemies = {},
		ImpreciseParriedEnemies = {},
		GrudgeDash = false,
		HopCooldown = 0

	} --[[@as TEdithHopParryParams]]
	local playerData = data(player)
    playerData.HopDashParams = playerData.HopDashParams or DefaultHopDashParams
    local params = playerData.HopDashParams ---@cast params TEdithHopParryParams

    return params
end

---@param player EntityPlayer
---@param Static boolean --- `true` to get Static charge, otherwise gets Move charge 
---@param checkBirthright? boolean --- Setting it to `true` will add Birthright charge to the returned value
---@return number
function TEdith.GetHopDashCharge(player, Static, checkBirthright)
	local hopParams = TEdith.GetHopParryParams(player)
	local charge = Static and hopParams.HopStaticCharge or hopParams.HopMoveCharge
	local chargeBR = Static and hopParams.HopStaticBRCharge or hopParams.HopMoveBRCharge

	if not charge then return 0 end
	return charge + (checkBirthright and chargeBR or 0)
end

---@param player EntityPlayer
---@param HopParams TEdithHopParryParams
function TEdith.ParryCooldownManager(player, HopParams)
	local colorChange = math.min((HopParams.HopStaticCharge) / 100, 1) * 0.5
	local colorBRChange = math.min(HopParams.HopStaticBRCharge / 100, 1) * 0.1
	local playerData = data(player)
	local ParryCooldown = HopParams.ParryCooldown

	playerData.ParryReadyGlowCount = playerData.ParryReadyGlowCount or 0

	local GlowCount = playerData.ParryReadyGlowCount

	if ParryCooldown < 1 then
		playerData.ParryReadyGlowCount = GlowCount + 1
	end

	if GlowCount > 20 then
		playerData.ParryReadyGlowCount = 0
	end

	if colorChange > 0 and colorChange <= 1 then
		player:SetColor(Color(1, 1, 1, 1, colorChange, colorBRChange, 0), 5, 100, true, false)
	end

	if GlowCount == 20 and ParryCooldown == 0 then
		sfx:Play(SoundEffect.SOUND_STONE_IMPACT, 0.5, 0, false, 1.3)
		player:SetColor(Color(1, 1, 1, 1, colorChange + 0.3, 0, 0), 5, 100, true, false)
	end
	
	if ParryCooldown == 1 and player.FrameCount > 20 then
		player:SetColor(Color(1, 1, 1, 1, 0.5 + colorChange), 5, 100, true, false)
		sfx:Play(SoundEffect.SOUND_STONE_IMPACT)
		playerData.ParryReadyGlowCount = 0
	end

	if TEdith.IsTaintedEdithJump(player) ~= true then
		HopParams.ParryCooldown = math.max(ParryCooldown - 1, 0)
	end
end

---Reset both Tainted Edith's Move charge and Birthright charge
---@param player EntityPlayer
---@param Move boolean Resets both `HopMoveCharge` and HopMoveBRCharge
---@param Static boolean Resets both `HopStaticCharge` and `HopStaticBRCharge`
function TEdith.ResetHopDashCharge(player, Move, Static)
	local hopParams = TEdith.GetHopParryParams(player)

	if Move then
		hopParams.HopMoveCharge = 0
		hopParams.HopMoveBRCharge = 0
	end

	if Static then
		hopParams.HopStaticCharge = 0
		hopParams.HopStaticBRCharge = 0
	end
end

function TEdith.IsTaintedEdithJump(player)
	return JumpLib:GetData(player).Tags["edithRebuilt_TaintedEdithJump"] or false
end

---@param player EntityPlayer
---@param HopParams TEdithHopParryParams
function TEdith.ArrowMovementManager(player, HopParams)
	local playerData = data(player)
	local input = {
		up = Input.GetActionValue(ButtonAction.ACTION_UP, player.ControllerIndex),
		down = Input.GetActionValue(ButtonAction.ACTION_DOWN, player.ControllerIndex),
		left = Input.GetActionValue(ButtonAction.ACTION_LEFT, player.ControllerIndex),
		right = Input.GetActionValue(ButtonAction.ACTION_RIGHT, player.ControllerIndex),
	}

	HopParams.IsParryJump = HopParams.IsParryJump or false

	local MovX = (((input.left > 0.3 and -input.left) or (input.right > 0.3 and input.right)) or 0) * (game:GetRoom():IsMirrorWorld() and -1 or 1)
	local MovY = (input.up > 0.3 and -input.up) or (input.down > 0.3 and input.down) or 0

	playerData.movementVector = Vector(MovX, MovY):Normalized() 
end

---Helper function to stop Tainted Edith's hop-dash
---@param player EntityPlayer
---@param cooldown integer
---@param useQuitJump boolean
---@param resetChrg boolean
---@param resetHopcooldown boolean
---@param notreduceFriction? boolean
function TEdith.StopTEdithHops(player, cooldown, useQuitJump, resetChrg, resetHopcooldown, notreduceFriction)
	if not Player.IsEdith(player, true) then return end
	local HopParams = TEdith.GetHopParryParams(player)
	local IsMoving = HopParams.IsHoping or HopParams.GrudgeDash
	notreduceFriction = notreduceFriction or false

	if not IsMoving then return end

	Land.TaintedEdithHop(player, HopParams)

	HopParams.IsHoping = false
	HopParams.GrudgeDash = false
	HopParams.HopDirection = Vector.Zero

	if resetHopcooldown then
		HopParams.HopCooldown = 8
	end

	if not notreduceFriction then
		player:MultiplyFriction(0.5)
	end

	cooldown = cooldown or 0
	useQuitJump = useQuitJump or false

	if useQuitJump then
		JumpLib:QuitJump(player)
	end

	if resetChrg then
		TEdith.ResetHopDashCharge(player, true, true)
	end

	player:SetMinDamageCooldown(cooldown)
end

local function HopCurve(t)
    return 1 - ((1 - t) ^ 2)
end

---@param player EntityPlayer
---@param hopParams TEdithHopParryParams
function TEdith.HopDashMovementManager(player, hopParams)
	local charge = TEdith.GetHopDashCharge(player, false, false)

	if charge < 10 then return end

	local HopVec = hopParams.HopDirection
	local isHopVecZero = HopVec.X == 0 and HopVec.Y == 0
	local isJumping = JumpLib:GetData(player).Jumping
	local IsGrudge = helpers.IsGrudgeChallenge()
	local chargeMult = (charge / 100)
	local VelMult = IsGrudge and 1.2 or 1 
	local speedBase = IsGrudge and 10 or 9

	if not isHopVecZero then
		if not isJumping and not IsGrudge then
			TEdith.InitTaintedEdithHop(player)
		end
		hopParams.IsHoping = true
	end

	local smoothFactor = 0.25
	local targetVel = (((HopVec * 2) * (speedBase + (player.MoveSpeed - 1))) * HopCurve(chargeMult)) * VelMult

	player.Velocity = player.Velocity + (targetVel - player.Velocity) * smoothFactor
	hopParams.GrudgeDash = (IsGrudge and HopVec:Length() > 0)
end

---@param player EntityPlayer
---@param charge number
---@param BRMult number
function TEdith.AddHopDashCharge(player, charge, BRMult)
	local HopParams = TEdith.GetHopParryParams(player)
	local shouldAddToBrCharge = Player.PlayerHasBirthright(player) and HopParams.HopMoveCharge >= 100

	HopParams.HopMoveCharge = maths.Clamp(HopParams.HopMoveCharge + charge, 0, 100)
	HopParams.HopStaticCharge = maths.Clamp(HopParams.HopStaticCharge + charge, 0, 100)

	if not shouldAddToBrCharge then return end
	HopParams.HopMoveBRCharge = maths.Clamp(HopParams.HopMoveBRCharge + (charge * BRMult), 0, 100)
	HopParams.HopStaticBRCharge = maths.Clamp(HopParams.HopStaticBRCharge + (charge * BRMult), 0, 100)
end

---@param player EntityPlayer
---@param arrow EntityEffect
function TEdith.HopDashChargeManager(player, arrow)
	local HopParams = TEdith.GetHopParryParams(player)
	local posDif = arrow.Position - player.Position
	local VecSize = data(player).IsRedirectioningMove and 25 or 10
	local posDifLenght = posDif:Length()
	local maxDist = 2.5 * (10 / VecSize)
	local BaseCharge = helpers.IsGrudgeChallenge() and 9 or 8
	local targetframecount = arrow.FrameCount
	local chargeAdd = BaseCharge * maths.exp(player.MoveSpeed, 1, 1.5)
	HopParams.HopDirection = posDif:Normalized()

	local arrowVel = data(player).movementVector
	local HopVec = arrowVel
	local targetVel = HopVec:Resized(VecSize)

	if posDifLenght >= maxDist then
		targetVel = targetVel - (posDif:Normalized() * (posDifLenght / maxDist))
	end

	local smoothFactor = 0.5
	arrow.Velocity = arrow.Velocity + (targetVel - arrow.Velocity) * smoothFactor

	if targetframecount > 1 and (not HopParams.IsHoping and not isJumping) and HopParams.HopCooldown == 0 then
		TEdith.AddHopDashCharge(player, chargeAdd, 0.5)
	end
end

---Function used to trigger Tainted Edith and Burnt Hood's parry-jump
---@param player EntityPlayer
---@param tag string
function TEdith.InitTaintedEdithParryJump(player, tag)
	local jumpHeight = 8
	local jumpSpeed = 5.5
	local room = game:GetRoom()
	local RoomWater = room:HasWater()
	local isChap4 = helpers.IsChap4()
	local variant = RoomWater and EffectVariant.BIG_SPLASH or (isChap4 and EffectVariant.POOF02 or EffectVariant.POOF01)
	local subType = RoomWater and 1 or (isChap4 and 66 or 1)
	
	sfx:Play(SoundEffect.SOUND_SHELLGAME)
	
	local DustCloud = Isaac.Spawn(
		EntityType.ENTITY_EFFECT, 
		variant, 
		subType, 
		player.Position, 
		Vector.Zero, 
		player
	) ---@cast DustCloud EntityEffect 

    helpers.SetBloodEffectColor(DustCloud)

	DustCloud.SpriteScale = DustCloud.SpriteScale * player.SpriteScale.X
	DustCloud.DepthOffset = -100
	DustCloud:GetSprite().PlaybackSpeed = RoomWater and 1.3 or 2	

	local config = {
		Height = jumpHeight,
		Speed = jumpSpeed,
		Tags = tag,
		Flags = jumpFlags.TEdithJump
	}
	JumpLib:Jump(player, config)
	data(player).IsParryJump = true
end

---@param player EntityPlayer
---@param IsGrudge boolean
---@param HopParams TEdithHopParryParams
function TEdith.ParryTriggerManager(player, IsGrudge, HopParams)
	if not IsGrudge then
		if not HopParams.IsHoping then
			TEdith.InitTaintedEdithParryJump(player, jumpTags.TEdithJump)
		else
			TEdith.StopTEdithHops(player, 0, true, true, false)
			local PerfectParry = Land.ParryLandManager(player, HopParams, true)
			Land.LandFeedbackManager(player, Land.GetLandSoundTable(true, PerfectParry), misc.BurntSaltColor, PerfectParry)

			if PerfectParry then
				TEdith.AddHopDashCharge(player, 20, 0.5)
			end
		end
	else
		local PerfectParry = Land.ParryLandManager(player, HopParams, true)
		Land.LandFeedbackManager(player, Land.GetLandSoundTable(true, true), misc.BurntSaltColor, true)

		if PerfectParry then
			TEdith.AddHopDashCharge(player, 20, 0.5)
		end
	end
end	

local JumpHeightParams = {
	growth = 0.35, 
	offset = 0.65, 
	curve = 1
}

---@param player any
function TEdith.InitTaintedEdithHop(player)
	local charge = TEdith.GetHopDashCharge(player, false, false)
	if not charge or charge <= 0 then return end

	local jumpHeight = maths.HopHeightCalc(6, charge, JumpHeightParams)
	local jumpSpeed = 3 * maths.Log(charge, 100)
	local config = {
		Height = jumpHeight,
		Speed = jumpSpeed,
		Tags = jumpTags.TEdithHop,
		Flags = jumpFlags.TEdithHop
	}
	JumpLib:Jump(player, config) 
end

return TEdith