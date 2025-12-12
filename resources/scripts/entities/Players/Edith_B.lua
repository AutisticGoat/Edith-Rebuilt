---@diagnostic disable: undefined-global
local mod = EdithRebuilt
local enums = mod.Enums
local utils = enums.Utils
local game = utils.Game
local sfx = utils.SFX
local tables = enums.Tables
local jumpTags = tables.JumpTags
local jumpParams = tables.JumpParams
local misc = enums.Misc
local modules = mod.Modules
local VecDir = modules.VEC_DIR
local maths = modules.MATHS
local land = modules.LAND
local Player = modules.PLAYER
local TargetArrow = modules.TARGET_ARROW
local TEdithMod = modules.TEDITH
local Helpers = modules.HELPERS
local Maths = modules.MATHS
local data = mod.CustomDataWrapper.getData
local TEdith = {}

---@param player EntityPlayer
function TEdith:TaintedEdithInit(player)
	if not Player.IsEdith(player, true) then return end
	Player.SetNewANM2(player, "gfx/EdithTaintedAnim.anm2")
	player:AddNullCostume(enums.NullItemID.ID_EDITH_B_SCARF)
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, TEdith.TaintedEdithInit)

local function isTaintedEdithJump(player)
	return JumpLib:GetData(player).Tags["edithRebuilt_TaintedEdithJump"] or false
end

---@param player EntityPlayer	
function mod:TaintedEdithUpdate(player)
	if not Player.IsEdith(player, true) then return end

	local playerData = data(player)
	local isJumping = JumpLib:GetData(player).Jumping
	local HopParams = TEdithMod.GetHopParryParams(player)
	local isArrowMoving = TargetArrow.IsEdithTargetMoving(player)
	local arrow = TargetArrow.GetEdithTarget(player, true)
	local colorChange = math.min((HopParams.HopStaticCharge) / 100, 1) * 0.5
	local colorBRChange = math.min(HopParams.HopStaticBRCharge / 100, 1) * 0.1

	if isArrowMoving then
		TargetArrow.SpawnEdithTarget(player, true)
	end
	
	if arrow then
		TEdithMod.HopDashChargeManager(player, arrow)
	else
		TEdithMod.HopDashMovementManager(player, HopParams)
	end

	if colorChange > 0 and colorChange <= 1 then
		player:SetColor(Color(1, 1, 1, 1, colorChange, colorBRChange, 0), 5, 100, true, false)
	end

	TEdithMod.ParryCooldownManager(player, HopParams)

	playerData.ParryReadyGlowCount = (
		not isTaintedEdithJump(player) and
		not TargetArrow.GetEdithTarget(player, true) and
		(playerData.ParryReadyGlowCount and playerData.ParryReadyGlowCount < 20 ) and 
		maths.Clamp(playerData.ParryReadyGlowCount + 1, 1, 20) or 0
	)

	if playerData.ParryReadyGlowCount == 20 then
		player:SetColor(Color(1, 1, 1, 1, colorChange + 0.3, 0, 0), 5, 100, true, false)
	end

	if (player:CollidesWithGrid() and HopParams.IsHoping == true) and not isJumping or Helpers.IsDogmaAppearCutscene() then
		TEdithMod.StopTEdithHops(player, 20, true, not playerData.TaintedEdithTarget)
	end

	if not isArrowMoving and arrow then
		TargetArrow.RemoveEdithTarget(player, true)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, mod.TaintedEdithUpdate)

function mod:EdithPlayerUpdate(player)
	if not Player.IsEdith(player, true) then return end

	Player.ManageEdithWeapons(player)

	local IsJumping = JumpLib:GetData(player).Jumping
	local arrow = TargetArrow.GetEdithTarget(player, true)
	local HopParams = TEdithMod.GetHopParryParams(player)

	TEdithMod.ArrowMovementManager(player, HopParams)

	if Helpers.IsKeyStompTriggered(player) then
		if HopParams.ParryCooldown == 0 and not isTaintedEdithJump(player) and not HopParams.IsParryJump then
			if HopParams.IsHoping then
				TEdithMod.StopTEdithHops(player, 0, true, true)
			end
			TEdithMod.InitTaintedEdithParryJump(player, jumpTags.TEdithJump)
		end
	end

	-- if HopParams.IsHoping == true then
	-- 	TEdithMod.ResetHopDashCharge(player, false, true)
	-- else
	-- 	playerData.MoveBrCharge = playerData.BirthrightCharge
	-- 	playerData.MoveCharge = playerData.ImpulseCharge

	-- 	if not IsJumping then
	-- 		player:MultiplyFriction(0.5)
	-- 	end
	-- end

	if Player.IsPlayerShooting(player) then return end

	local faceDirection = VecDir.VectorToDirection(HopParams.HopDirection)
	local chosenDir = faceDirection	or Direction.DOWN

	if HopParams.IsHoping or (arrow and arrow.Visible == true) then
		chosenDir = faceDirection
	elseif VecDir.VectorEquals(HopParams.HopDirection, Vector.Zero) then
		chosenDir = Direction.DOWN
	end

	player:SetHeadDirection(chosenDir, 1, true)
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, mod.EdithPlayerUpdate)

function mod:OnNewRoom()
	for _, player in ipairs(PlayerManager.GetPlayers()) do
		if not Player.IsEdith(player, true) then goto continue end
		Helpers.ChangeColor(player, _, _, _, 1)
		TEdithMod.StopTEdithHops(player, 0, true, true)
		TargetArrow.RemoveEdithTarget(player, true)
		::continue::
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.OnNewRoom)

local jets = 4
local ndegree = 360/jets
local damageBase = 3.5
---@param player EntityPlayer
function TEdith:TEdithHopLanding(player)	
	local HopParams = TEdithMod.GetHopParryParams(player)
	local tearRange = player.TearRange / 40
	local Knockbackbase = (player.ShotSpeed * 10) + 2
	local Charge = TEdithMod.GetHopDashCharge(player, false, true)
	local BRCharge = HopParams.HopMoveBRCharge

	HopParams.HopDamage = (((damageBase + player.Damage) / 3.5) * (Charge + BRCharge) / 100) * (Charge / 100) 
	HopParams.HopKnockback = Knockbackbase * maths.exp(Charge / 100, 1, 1.5)
	HopParams.HopRadius = math.min((30 + (tearRange - 9)), 35)

	player:SpawnWaterImpactEffects(player.Position, Vector(1, 1), 1)	
	land.LandFeedbackManager(player, land.GetLandSoundTable(true), misc.BurntSaltColor)
	land.TaintedEdithHop(player, HopParams.HopRadius, HopParams.HopDamage, HopParams.HopKnockback)
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, TEdith.TEdithHopLanding, jumpParams.TEdithHop)

---@param player EntityPlayer
function TEdith:TEdithParryLanding(player)
	if TargetArrow.GetEdithTarget(player, true) then
		TEdithMod.ResetHopDashCharge(player, true, true)
	end

	local perfectParry, EnemiesInImpreciseParry = TEdithMod.ParryLandManager(player, true)
	local parryAdd = perfectParry and 20 or ((EnemiesInImpreciseParry and 5) or -15)

	land.LandFeedbackManager(player, land.GetLandSoundTable(true, perfectParry), misc.BurntSaltColor, perfectParry)

	if not parryAdd then return end
	TEdithMod.AddHopDashCharge(player, parryAdd, 0.75)
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, TEdith.TEdithParryLanding, jumpParams.TEdithJump)

---@param player EntityPlayer
---@param flags DamageFlag
---@return boolean?
function TEdith:TaintedEdithDamageManager(player, _, flags)
	local HopParams = TEdithMod.GetHopParryParams(player)

	if not Player.IsEdith(player, true) then return end
	if not (HopParams.IsHoping == true and HopParams.HopMoveCharge >= 30) then return end
	if Maths.HasBitFlags(flags, DamageFlag.DAMAGE_RED_HEARTS) then return end
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
		local HopParams = TEdithMod.GetHopParryParams(player)
		local playerData = data(player)
		local dashCharge = HopParams.HopStaticCharge
		local dashBRCharge = HopParams.HopStaticBRCharge
		local offset = misc.ChargeBarcenterVector

		if not dashCharge or not dashBRCharge then return end

		playerData.ChargeBar = playerData.ChargeBar or Sprite("gfx/TEdithChargebar.anm2", true)
		playerData.BRChargeBar = playerData.BRChargeBar or Sprite("gfx/TEdithBRChargebar.anm2", true)

		if Player.PlayerHasBirthright(player) and not playerData.BRChargeBar:IsFinished("Disappear") then
			offset = misc.ChargeBarleftVector
		end

		HudHelper.RenderChargeBar(playerData.ChargeBar, dashCharge, 100, playerpos + offset)
		HudHelper.RenderChargeBar(playerData.BRChargeBar, dashBRCharge, 100, playerpos + misc.ChargeBarrightVector)
	end
}, HudHelper.HUDType.EXTRA)