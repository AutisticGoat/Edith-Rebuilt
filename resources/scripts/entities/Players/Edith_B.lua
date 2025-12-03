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
local modules = mod.Modules
local VecDir = modules.VEC_DIR
local helpers = modules.HELPERS
local maths = modules.MATHS
local land = modules.LAND
local Player = modules.PLAYER
local TargetArrow = modules.TARGET_ARROW
local TEdithMod = modules.TEDITH
local data = mod.CustomDataWrapper.getData
local TEdith = {}

---@Class 

---@param player EntityPlayer
---@param checkBirthright? boolean
---@return number
function TEdith.GetHopDashCharge(player, checkBirthright)
	local playerData = data(player)
	if not playerData.ImpulseCharge then return 0 end
	return playerData.ImpulseCharge + (checkBirthright and playerData.BirthrightCharge or 0)
end

---Reset both Tainted Edith's Move charge and Birthright charge
---@param player EntityPlayer
function TEdith.ResetHopDashCharge(player)
	if TEdith.GetHopDashCharge(player) == 0 then return end

	local playerData = data(player)
	playerData.ImpulseCharge = 0
	playerData.BirthrightCharge = 0
end

---Helper function to stop Tainted Edith's hop-dash
---@param player EntityPlayer
---@param cooldown integer
---@param useQuitJump boolean
---@param resetChrg boolean
function TEdith.StopTEdithHops(player, cooldown, useQuitJump, resetChrg)
	if not Player.IsEdith(player, true) then return end

	local playerData = data(player)
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

---@param player EntityPlayer
function TEdith:TaintedEdithInit(player)
	if not Player.IsEdith(player, true) then return end
	Player.SetNewANM2(player, "gfx/EdithTaintedAnim.anm2")
	player:AddNullCostume(enums.NullItemID.ID_EDITH_B_SCARF)
	-- mod.ForceCharacterCostume(player, players.PLAYER_EDITH_B, enums.NullItemID.ID_EDITH_B_SCARF)
	
	local playerData = data(player)

	playerData.HopVector = Vector.Zero
	playerData.MoveCharge = playerData.MoveCharge or 0
	playerData.MoveBrCharge = playerData.MoveBrCharge or 0
	playerData.ImpulseCharge = playerData.ImpulseCharge or 0
	playerData.BirthrightCharge = playerData.BirthrightCharge or 0
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, TEdith.TaintedEdithInit)

local JumpHeightParams = {
	growth = 0.35, 
	offset = 0.65, 
	curve = 1
}

function mod:InitTaintedEdithHop(player)
	local charge = data(player).MoveCharge
	local jumpHeight = TEdithMod.HopHeightCalc(6, charge, JumpHeightParams)
	local jumpSpeed = 2.8 * maths.Log(charge, 100)
	local config = {
		Height = jumpHeight,
		Speed = jumpSpeed,
		Tags = jumpTags.TEdithHop,
		Flags = jumpFlags.TEdithHop
	}
	JumpLib:Jump(player, config) 
end

local function isTaintedEdithJump(player)
	return JumpLib:GetData(player).Tags["edithRebuilt_TaintedEdithJump"] or false
end

---@param player EntityPlayer	
function mod:TaintedEdithUpdate(player)
	if not Player.IsEdith(player, true) then return end

	local playerData = data(player)
	local isJumping = JumpLib:GetData(player).Jumping

	playerData.ImpulseCharge = playerData.ImpulseCharge or 0
	playerData.BirthrightCharge = playerData.BirthrightCharge or 0
	playerData.ParryCounter = playerData.ParryCounter or 20
	playerData.movementVector = playerData.movementVector or Vector.Zero

	local colorChange = math.min((playerData.ImpulseCharge) / 100, 1) * 0.5
	local colorBRChange = math.min(playerData.BirthrightCharge / 100, 1) * 0.1
	local charge = playerData.MoveCharge
	local isArrowMoving = TargetArrow.IsEdithTargetMoving(player)

	if colorChange > 0 and colorChange <= 1 then
		player:SetColor(Color(1, 1, 1, 1, colorChange, colorBRChange, 0), 5, 100, true, false)
	end

	if playerData.ParryCounter > 0 then
		if isTaintedEdithJump(player) ~= true then
			playerData.ParryCounter = playerData.ParryCounter - 1
		end

		if playerData.ParryCounter == 1 and player.FrameCount > 20 then
			player:SetColor(Color(1, 1, 1, 1, 0.5 + colorChange), 5, 100, true, false)
			
			sfx:Play(SoundEffect.SOUND_STONE_IMPACT)
			playerData.ParryReadyGlowCount = 0
		end
	end

	playerData.ParryReadyGlowCount = (
		not isTaintedEdithJump(player) and
		not mod.GetEdithTarget(player, true) and
		(playerData.ParryReadyGlowCount and playerData.ParryReadyGlowCount < 20 ) and 
		maths.Clamp(playerData.ParryReadyGlowCount + 1, 1, 20) or 0
	)

	if playerData.ParryReadyGlowCount == 20 then
		player:SetColor(Color(1, 1, 1, 1, colorChange + 0.3, 0, 0), 5, 100, true, false)
	end

	if (player:CollidesWithGrid() and playerData.IsHoping == true) and not isJumping or mod.IsDogmaAppearCutscene() then
		TEdith.StopTEdithHops(player, 20, true, not playerData.TaintedEdithTarget)
	end

	if isArrowMoving then
		mod.SpawnEdithTarget(player, true)
	end

	local target = mod.GetEdithTarget(player, true)
	local HopVec = playerData.HopVector

	if target then
		local posDif = target.Position - player.Position
		local posDifLenght = posDif:Length()
		local maxDist = 2.5
		local targetframecount = target.FrameCount
		local chargeAdd = 8.25 * maths.exp(player.MoveSpeed, 1, 1.5)
		playerData.HopVector = posDif:Normalized()

		if targetframecount < 2 and playerData.IsHoping == true then
			TEdith.StopTEdithHops(player, 20, true, true)
			land.LandFeedbackManager(player, mod:GetLandSoundTable(true), misc.BurntSaltColor, false)
		end

		target.Velocity = playerData.movementVector:Resized(10)
		if posDifLenght >= maxDist then
			target.Velocity = target.Velocity - (posDif:Normalized() * (posDifLenght / maxDist)) 
		end

		if targetframecount > 1 and (not playerData.IsHoping and not isJumping) then
			TEdithMod.AddHopDashCharge(player, chargeAdd, 0.5)
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
			if not isArrowMoving and playerData.IsHoping == false and not isHopVecZero then
				TEdith.ResetHopDashCharge(player)
				playerData.HopVector = Vector.Zero
			end
		end
	end

	if not isArrowMoving and target then
		mod.RemoveEdithTarget(player, true)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, mod.TaintedEdithUpdate)

function mod:EdithPlayerUpdate(player)
	if not Player.IsEdith(player, true) then return end

	Player.ManageEdithWeapons(player)

	local playerData = data(player)
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

	local faceDirection = VecDir.VectorToDirection(playerData.HopVector)
	local chosenDir = faceDirection	or Direction.DOWN

	if playerData.IsHoping or (arrow and arrow.Visible == true) then
		chosenDir = faceDirection
	elseif VecDir.VectorEquals(playerData.HopVector, Vector.Zero) then
		chosenDir = Direction.DOWN
	end

	player:SetHeadDirection(chosenDir, 1, true)
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, mod.EdithPlayerUpdate)

function mod:OnNewRoom()
	for _, player in ipairs(PlayerManager.GetPlayers()) do
		if not Player.IsEdith(player, true) then goto continue end
		mod:ChangeColor(player, _, _, _, 1)
		TEdith.StopTEdithHops(player, 0, true, true)
		mod.RemoveEdithTarget(player, true)
		::continue::
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.OnNewRoom)

local jets = 4
local ndegree = 360/jets
local damageBase = 3.5
---@param player EntityPlayer
function mod:EdithHopLanding(player)	
	local playerData = data(player)
	local tearRange = player.TearRange / 40
	local Knockbackbase = (player.ShotSpeed * 10) + 2
	local Charge = playerData.MoveCharge
	local BRCharge = playerData.MoveBrCharge
	local HopParams = {
		Radius = math.min((30 + (tearRange - 9)), 35),
		Knockback = Knockbackbase * maths.exp(Charge / 100, 1, 1.5),
		Damage = (((damageBase + player.Damage) / 3.5) * (Charge + BRCharge) / 100) * (Charge / 100) 
	}

	player:SpawnWaterImpactEffects(player.Position, Vector(1, 1), 1)	
	land.LandFeedbackManager(player, mod:GetLandSoundTable(true), misc.BurntSaltColor)
	land.TaintedEdithHop(player, HopParams.Radius, HopParams.Damage, HopParams.Knockback)
	
	if BRCharge <= 0 then return end
	for i = 1, jets do
		mod.SpawnFireJet(player ,player.Position + Vector(20, 0):Rotated(ndegree*i), HopParams.Damage, false, 0.8)
	end
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, mod.EdithHopLanding, jumpParams.TEdithHop)

---@param player EntityPlayer
function TEdith:EdithParryJump(player)
	if mod.GetEdithTarget(player, true) then 
		TEdith.ResetHopDashCharge(player)
	end

	local perfectParry, EnemiesInImpreciseParry = TEdithMod.ParryLandManager(player, true)
	local parryAdd = perfectParry and 20 or (not EnemiesInImpreciseParry and -15)

	land.LandFeedbackManager(player, mod:GetLandSoundTable(true, perfectParry), misc.BurntSaltColor, perfectParry)

	if not parryAdd then return end
	TEdithMod.AddHopDashCharge(player, parryAdd, 0.75)
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, TEdith.EdithParryJump, jumpParams.TEdithJump)

function TEdith:TaintedEdithDamageManager(player, _, flags)
	local playerData = data(player)

	if not Player.IsEdith(player, true) then return end
	if not (playerData.IsHoping == true and playerData.MoveCharge >= 30) then return end
	if mod.HasBitFlags(flags, DamageFlag.DAMAGE_RED_HEARTS) then return end
	return false
end
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, TEdith.TaintedEdithDamageManager)

HudHelper.RegisterHUDElement({
	Name = "EdithRebuilt_TaintedEdithChargeBars",
	Priority = HudHelper.Priority.NORMAL,
	Condition = function(player)
		return Player.IsEdith(player, true) and RoomTransition:GetTransitionMode() ~= 3
	end,
	XPadding = 0,
	YPadding = 0,
	OnRender = function(player)
		local playerpos = game:GetRoom():WorldToScreenPosition(player.Position)
		local playerData = data(player)
		local dashCharge = playerData.ImpulseCharge 
		local dashBRCharge = playerData.BirthrightCharge 
		local offset = misc.ChargeBarcenterVector

		if not dashCharge or not dashBRCharge then return end

		playerData.ChargeBar = playerData.ChargeBar or Sprite("gfx/TEdithChargebar.anm2", true)
		playerData.BRChargeBar = playerData.BRChargeBar or Sprite("gfx/TEdithBRChargebar.anm2", true)

		if mod.PlayerHasBirthright(player) and not playerData.BRChargeBar:IsFinished("Disappear") then
			offset = misc.ChargeBarleftVector
		end

		HudHelper.RenderChargeBar(playerData.ChargeBar, dashCharge, 100, playerpos + offset)
		HudHelper.RenderChargeBar(playerData.BRChargeBar, dashBRCharge, 100, playerpos + misc.ChargeBarrightVector)
	end
}, HudHelper.HUDType.EXTRA)