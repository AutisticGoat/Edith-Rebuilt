---@diagnostic disable: undefined-global
local mod = EdithRebuilt
local enums = mod.Enums
local utils = enums.Utils
local sounds = enums.SoundEffect
local game = utils.Game
local sfx = utils.SFX
local tables = enums.Tables
local jumpFlags = tables.JumpFlags
local jumpTags = tables.JumpTags
local jumpParams = tables.JumpParams
local players = enums.PlayerType
local misc = enums.Misc
local TEdith = {}
local funcs = {
	IsEdith = mod.IsEdith,
	GetData = mod.CustomDataWrapper.getData,
	TargetMov = mod.IsEdithTargetMoving,
	GetTPS = mod.GetTPS,
	Switch = mod.When,
	log = mod.Log,
	exp = mod.exp,
	FeedbackMan = mod.LandFeedbackManager,
	Clamp = mod.Clamp
}

local hopSounds = {
	[1] = SoundEffect.SOUND_STONE_IMPACT,
	[2] = sounds.SOUND_YIPPEE,
	[3] = sounds.SOUND_SPRING,
}

local parryJumpSounds = {
	[1] = SoundEffect.SOUND_ROCK_CRUMBLE,
	[2] = sounds.SOUND_PIZZA_TAUNT,
	[3] = sounds.SOUND_VINE_BOOM,
	[4] = sounds.SOUND_FART_REVERB,
	[5] = sounds.SOUND_SOLARIAN,
	[6] = sounds.SOUND_MACHINE,
	[7] = sounds.SOUND_MECHANIC,
	[8] = sounds.SOUND_KNIGHT,
	[9] = sounds.SOUND_BLOQUEO,
}

---@generic growth, offset, curve
---@param const number
---@param var number
---@param params { growth: number, offset: number, curve: number }
---@return number
local function HopHeightCalc(const, var, params)
    -- Validaciones estrictas
    assert(type(var) == "number", "var should be a number")
    assert(var >= 0 and var <= 100, "var should be a number between 0 and 100")

    -- Caso exclusivo cuando variable es exactamente 100
    if var == 100 then return const end

	local limit = 0.999999
    local growth = math.max(0, params.growth or 1) 
    local offset = funcs.Clamp(params.offset or 0, -1, 1) 
    local curve = math.max(0.1, math.min(params.curve or 1, 10))
	local formula = (var / 100) ^ curve * growth + offset
    local progresion = math.min(formula, limit)

    -- Resultado final garantizado que nunca iguala la constante
    return const * funcs.Clamp(progresion, 0, limit)
end

---@param player EntityPlayer
---@param charge number
---@param BRMult number
function TEdith.AddHopDashCharge(player, charge, BRMult)
	local playerData = funcs.GetData(player)
	local shouldChargeBrCharge = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and playerData.ImpulseCharge >= 100

	playerData.ImpulseCharge = funcs.Clamp(playerData.ImpulseCharge + charge, 0, 100)
	playerData.BirthrightCharge = shouldChargeBrCharge and funcs.Clamp(playerData.BirthrightCharge + (charge * BRMult), 0, 100) or 0
end

---@param player EntityPlayer
---@param checkBirthright? boolean
---@return number
function TEdith.GetHopDashCharge(player, checkBirthright)
	local playerData = funcs.GetData(player)
	if not playerData.ImpulseCharge then return 0 end
	return playerData.ImpulseCharge + (checkBirthright and playerData.BirthrightCharge or 0)
end
---Reset both Tainted Edith's Move charge and Birthright charge
---@param player EntityPlayer
function TEdith.ResetHopDashCharge(player)
	if TEdith.GetHopDashCharge(player) == 0 then return end

	local playerData = funcs.GetData(player)
	playerData.ImpulseCharge = 0
	playerData.BirthrightCharge = 0
end

---Helper function to stop Tainted Edith's hop-dash
---@param player EntityPlayer
---@param cooldown integer
---@param useQuitJump boolean
---@param resetChrg boolean
function TEdith.StopTEdithHops(player, cooldown, useQuitJump, resetChrg)
	if not mod.IsEdith(player, true) then return end

	local playerData = funcs.GetData(player)
	playerData.IsHoping = false
	playerData.HopVector = Vector.Zero
	player:MultiplyFriction(0.5)

	cooldown = cooldown or 0
	useQuitJump = useQuitJump or false

	if useQuitJump then
		JumpLib:QuitJump(player)
	end

	if resetChrg then
		TEdith.ResetHopDashCharge(player)
	end

	player:SetMinDamageCooldown(cooldown)
end

function TEdith:TaintedEdithInit(player)
	if not funcs.IsEdith(player, true) then return end
	mod.SetNewANM2(player, "gfx/EdithTaintedAnim.anm2")
	mod.ForceCharacterCostume(player, players.PLAYER_EDITH_B, enums.NullItemID.ID_EDITH_B_SCARF)
	funcs.GetData(player).HopVector = Vector.Zero
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, TEdith.TaintedEdithInit)

---@param tear EntityTear
function TEdith:OnTaintedShootTears(tear)
	local player = mod:GetPlayerFromTear(tear)
	if not player then return end
	if not funcs.IsEdith(player, true) then return end

	mod.ForceSaltTear(tear, true)
end
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, TEdith.OnTaintedShootTears)

local JumpHeightParams = {
	growth = 0.35, 
	offset = 0.65, 
	curve = 1
}

function mod:InitTaintedEdithHop(player)
	local charge = funcs.GetData(player).MoveCharge
	local jumpHeight = HopHeightCalc(6, charge, JumpHeightParams)
	local jumpSpeed = 2.8 * funcs.log(charge, 100)
	local config = {
		Height = jumpHeight,
		Speed = jumpSpeed,
		Tags = jumpTags.TEdithHop,
		Flags = jumpFlags.TEdithHop
	}
	JumpLib:Jump(player, config)
end

local function isTaintedEdithJump(player)
	return JumpLib:GetData(player).Tags["edithRebuilt_EdithJump"] or false
end

---@param player EntityPlayer	
function mod:TaintedEdithUpdate(player)
	if not funcs.IsEdith(player, true) then return end

	local playerData = funcs.GetData(player)
	local isJumping = JumpLib:GetData(player).Jumping

	playerData.ImpulseCharge = playerData.ImpulseCharge or 0
	playerData.BirthrightCharge = playerData.BirthrightCharge or 0
	playerData.ParryCounter = playerData.ParryCounter or 20
	playerData.movementVector = playerData.movementVector or Vector.Zero

	local colorChange = math.min((playerData.ImpulseCharge) / 100, 1) * 0.5
	local colorBRChange = math.min(playerData.BirthrightCharge / 100, 1) * 0.1
	local charge = playerData.MoveCharge

	if colorChange > 0 and colorChange <= 1 then
		player:SetColor(Color(1, 1, 1, 1, colorChange, colorBRChange, 0), 5, 100, true, false)
	end

	if playerData.ParryCounter > 0 then
		if isTaintedEdithJump(player) ~= true then
			playerData.ParryCounter = playerData.ParryCounter - 1
		end

		if playerData.ParryCounter == 1 then
			player:SetColor(Color(1, 1, 1, 1, 0.5), 5, 100, true, false)
			sfx:Play(SoundEffect.SOUND_STONE_IMPACT)
		end
	end

	playerData.HopVector = playerData.HopVector or Vector.Zero

	if (player:CollidesWithGrid() and playerData.IsHoping == true) and not isJumping then
		TEdith.StopTEdithHops(player, 20, true, not playerData.TaintedEdithTarget)
	end

	if mod.IsDogmaAppearCutscene() then
		TEdith.StopTEdithHops(player, 0, false, true)
	end

	if funcs.TargetMov(player) then
		mod.SpawnEdithTarget(player, true)
	end

	local target = mod.GetEdithTarget(player, true)
	local HopVec = playerData.HopVector

	if target then
		local posDif = target.Position - player.Position
		local posDifLenght = posDif:Length()	
		local maxDist = 2.5
		local targetframecount = target.FrameCount
		local tearMult = funcs.GetTPS(player) / 2.73							
		local chargeAdd = 8.25 * funcs.exp(tearMult, 1, 1.5)
		playerData.HopVector = posDif:Normalized()

		if targetframecount < 2 and playerData.IsHoping == true then
			TEdith.StopTEdithHops(player, 20, true, true)
			funcs.FeedbackMan(player, hopSounds, misc.BurntSaltColor, false)
		end

		target.Velocity = playerData.movementVector:Resized(10)
		if posDifLenght >= maxDist then
			target.Velocity = target.Velocity - (posDif:Normalized() * (posDifLenght / maxDist)) 
		end

		if targetframecount > 1 then
			if not playerData.IsHoping and not isJumping then
				TEdith.AddHopDashCharge(player, chargeAdd, 0.5)
			end
		end
	else
		local isHopVecZero = HopVec.X == 0 and HopVec.Y == 0
		if charge and charge >= 10 then
			if playerData.IsHoping == true then
				player.Velocity = (HopVec) * (10 + (player.MoveSpeed - 1)) * (charge / 100)
			end
					
			if not isHopVecZero then
				if not isJumping then
					mod:InitTaintedEdithHop(player)
				end
				playerData.IsHoping = true
			end
		else
			if not funcs.TargetMov(player) and playerData.IsHoping == false and not isHopVecZero then
				TEdith.ResetHopDashCharge(player)
				playerData.HopVector = Vector.Zero
			end
		end
	end
	
	if not funcs.TargetMov(player) and target then
		mod.RemoveEdithTarget(player, true)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, mod.TaintedEdithUpdate)

function mod:EdithPlayerUpdate(player)
	if not funcs.IsEdith(player, true) then return end
	local playerData = funcs.GetData(player)
	local IsJumping = JumpLib:GetData(player).Jumping
	local arrow = mod.GetEdithTarget(player, true)
	local input = {
		up = Input.GetActionValue(ButtonAction.ACTION_UP, player.ControllerIndex),
		down = Input.GetActionValue(ButtonAction.ACTION_DOWN, player.ControllerIndex),
		left = Input.GetActionValue(ButtonAction.ACTION_LEFT, player.ControllerIndex),
		right = Input.GetActionValue(ButtonAction.ACTION_RIGHT, player.ControllerIndex),
	}

	playerData.IsParryJump = playerData.IsParryJump or false

	local MovX = (((input.left > 0.3 and -input.left) or (input.right > 0.3 and input.right)) or 0) * (game:GetRoom():IsMirrorWorld() and -1 or 1)
	local MovY = (input.up > 0.3 and -input.up) or (input.down > 0.3 and input.down) or 0

	playerData.movementVector = Vector(MovX, MovY):Normalized() 

	if mod:IsKeyStompTriggered(player) then
		if playerData.ParryCounter == 0 and not isTaintedEdithJump(player) and not playerData.IsParryJump then
			if playerData.IsHoping then
				TEdith.StopTEdithHops(player, 0, true, true)
			end
			mod:InitTaintedEdithParryJump(player, jumpTags.TEdithJump)
		end
	end
	
	playerData.MoveCharge = playerData.MoveCharge or 0
	playerData.MoveBrCharge = playerData.MoveBrCharge or 0
	playerData.ImpulseCharge = playerData.ImpulseCharge or 0
	playerData.BirthrightCharge = playerData.BirthrightCharge or 0

	if playerData.IsHoping == true then
		TEdith.ResetHopDashCharge(player)
	else
		playerData.MoveBrCharge = playerData.BirthrightCharge
		playerData.MoveCharge = playerData.ImpulseCharge

		if not IsJumping then
			player:MultiplyFriction(0.5)
		end
	end

	if mod:IsPlayerShooting(player) then return end

	local faceDirection = mod.VectorToDirection(playerData.HopVector)
	local chosenDir = faceDirection	or Direction.DOWN

	if playerData.IsHoping or (arrow and arrow.Visible == true) then
		chosenDir = faceDirection
	elseif mod.VectorEquals(playerData.HopVector, Vector.Zero) then
		chosenDir = Direction.DOWN
	end

	player:SetHeadDirection(chosenDir, 1, true)
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, mod.EdithPlayerUpdate)

function mod:OnNewRoom()
	for _, player in ipairs(PlayerManager.GetPlayers()) do
		if not funcs.IsEdith(player, true) then return end
		mod:ChangeColor(player, _, _, _, 1)
		TEdith.StopTEdithHops(player, 0, true, true)
		mod.RemoveEdithTarget(player, true)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.OnNewRoom)

local damageBase = 3.5
---@param player EntityPlayer
function mod:EdithHopLanding(player)	
	local playerData = funcs.GetData(player)
	local tearRange = player.TearRange / 40
	local Knockbackbase = (player.ShotSpeed * 10) + 2
	local Charge = playerData.MoveCharge
	local BRCharge = playerData.MoveBrCharge
	local HopParams = {
		Radius = math.min((30 + (tearRange - 9)), 35),
		Knockback = Knockbackbase * funcs.exp(Charge / 100, 1, 1.5),
		Damage = (((damageBase + player.Damage) / 1.75) * (Charge + BRCharge) / 100) * (Charge / 100) 
	}

	if BRCharge > 0 then
		local jets = 4
		local ndegree = 360/jets
		for i = 1, jets do
			mod.SpawnFireJet(player ,player.Position + Vector(20, 0):Rotated(ndegree*i), HopParams.Damage, false, 0.8)
		end
	end

	player:SpawnWaterImpactEffects(player.Position, Vector(1, 1), 1)	
	funcs.FeedbackMan(player, hopSounds, misc.BurntSaltColor)
	mod:TaintedEdithHop(player, HopParams.Radius, HopParams.Damage, HopParams.Knockback)	
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, mod.EdithHopLanding, jumpParams.TEdithHop)

---@param player EntityPlayer
function TEdith:EdithParryJump(player)
	local perfectParry = mod.ParryLandManager(player, true)
	local tableRef = perfectParry and parryJumpSounds or hopSounds
	local parryAdd = perfectParry and 20 or -10
	funcs.FeedbackMan(player, tableRef, misc.BurntSaltColor, perfectParry)
	TEdith.AddHopDashCharge(player, parryAdd, 0.75)

	if not mod.GetEdithTarget(player, true) then return end
	TEdith.ResetHopDashCharge(player)
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, TEdith.EdithParryJump, jumpParams.TEdithJump)

function TEdith:TaintedEdithDamageManager(player, damage, flags)
	local playerData = funcs.GetData(player)

	if not funcs.IsEdith(player, true) then return end
	if not (playerData.IsHoping == true and playerData.MoveCharge >= 30) then return end
	if mod.HasBitFlags(flags, DamageFlag.DAMAGE_RED_HEARTS) then return end
	return false
end
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, TEdith.TaintedEdithDamageManager)

function TEdith:HudBarRender(player)
	if not funcs.IsEdith(player, true) then return end

	local playerpos = game:GetRoom():WorldToScreenPosition(player.Position)
	local playerData = funcs.GetData(player)
	local dashCharge = playerData.ImpulseCharge 
	local dashBRCharge = playerData.BirthrightCharge 
	local offset = misc.ChargeBarcenterVector

	if not dashCharge or not dashBRCharge then return end

	playerData.ChargeBar = playerData.ChargeBar or Sprite("gfx/TEdithChargebar.anm2", true)
	playerData.BRChargeBar = playerData.BRChargeBar or Sprite("gfx/TEdithBRChargebar.anm2", true)
	
	if player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and not playerData.BRChargeBar:IsFinished("Disappear") then
		offset = misc.ChargeBarleftVector
	end

	HudHelper.RenderChargeBar(playerData.ChargeBar, dashCharge, 100, playerpos + offset)
	HudHelper.RenderChargeBar(playerData.BRChargeBar, dashBRCharge, 100, playerpos + misc.ChargeBarrightVector)
end
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_RENDER, TEdith.HudBarRender)