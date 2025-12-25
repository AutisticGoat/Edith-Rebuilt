---@diagnostic disable: undefined-global
local mod = EdithRebuilt
local enums = mod.Enums
local utils = enums.Utils
local game = utils.Game
local sfx = utils.SFX
local costumes = enums.NullItemID
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
local Creeps = modules.CREEPS
local ModRNG = modules.RNG
local data = mod.DataHolder.GetEntityData
local TEdith = {}

---@param player EntityPlayer
function TEdith:TaintedEdithInit(player)
	if not Player.IsEdith(player, true) then return end
	Player.SetNewANM2(player, "gfx/EdithTaintedAnim.anm2")

	local isGrudge = Helpers.IsGrudgeChallenge()
	local costume = isGrudge and costumes.ID_EDITH_B_GRUDGE_SCARF or costumes.ID_EDITH_B_SCARF
	local HopParams = TEdithMod.GetHopParryParams(player)

	data(player).movementVector = Vector.Zero
	HopParams.HopDirection = Vector.Zero

	player:AddNullCostume(costume)
	Player.SetChallengeSprite(player, Isaac.GetChallenge())
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

	if isArrowMoving then
		TargetArrow.SpawnEdithTarget(player, true)
	end

	if arrow then
		TEdithMod.HopDashChargeManager(player, arrow)
	else
		TEdithMod.HopDashMovementManager(player, HopParams)

		if TEdithMod.GetHopDashCharge(player, false, true) < 10 then
			HopParams.HopMoveCharge = 0
			HopParams.HopStaticCharge = 0
			HopParams.HopDirection = Vector.Zero
		end
	end

	TEdithMod.ParryCooldownManager(player, HopParams)

	if (player:CollidesWithGrid() and HopParams.IsHoping == true) and not isJumping or Helpers.IsDogmaAppearCutscene() then
		TEdithMod.StopTEdithHops(player, 20, true, not playerData.TaintedEdithTarget)
	end

	if not isArrowMoving and arrow then
		TargetArrow.RemoveEdithTarget(player, true)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, mod.TaintedEdithUpdate)

---@param player EntityPlayer
function mod:EdithPlayerUpdate(player)
	if not Player.IsEdith(player, true) then return end

	Player.ManageEdithWeapons(player)

	local playerData = data(player)
	local HopParams = TEdithMod.GetHopParryParams(player)
	local IsJumping = JumpLib:GetData(player).Jumping
	local arrow = TargetArrow.GetEdithTarget(player, true)
	local IsGrudge = Helpers.IsGrudgeChallenge()
	local input = {
		up = Input.GetActionValue(ButtonAction.ACTION_UP, player.ControllerIndex),
		down = Input.GetActionValue(ButtonAction.ACTION_DOWN, player.ControllerIndex),
		left = Input.GetActionValue(ButtonAction.ACTION_LEFT, player.ControllerIndex),
		right = Input.GetActionValue(ButtonAction.ACTION_RIGHT, player.ControllerIndex),
	}

	local MovX = (((input.left > 0.3 and -input.left) or (input.right > 0.3 and input.right)) or 0) * (game:GetRoom():IsMirrorWorld() and -1 or 1)
	local MovY = (input.up > 0.3 and -input.up) or (input.down > 0.3 and input.down) or 0

	playerData.movementVector = Vector(MovX, MovY):Normalized() 

	HopParams.IsParryJump = HopParams.IsParryJump or false

	if Helpers.IsKeyStompTriggered(player) then
		if HopParams.ParryCooldown == 0 and not isTaintedEdithJump(player) and not HopParams.IsParryJump then
			if HopParams.IsHoping then
				TEdithMod.StopTEdithHops(player, 0, true, true)
			end
			if not IsGrudge then
				TEdithMod.InitTaintedEdithParryJump(player, jumpTags.TEdithJump)
				-- TargetArrow.RemoveEdithTarget(player, true)
			else
				local PerfectParry, _ = TEdithMod.ParryLandManager(player, true)
				land.LandFeedbackManager(player, land.GetLandSoundTable(true, true), misc.BurntSaltColor, true)

				if PerfectParry then
					TEdithMod.AddHopDashCharge(player, 20, 0.5)
				end
			end
		end
	end

	if HopParams.IsHoping == true then
		TEdithMod.ResetHopDashCharge(player, false, true)
	elseif not IsJumping then
		player:MultiplyFriction(0.5)
	end

	if Helpers.IsGrudgeChallenge() and HopParams.GrudgeDash and player.Velocity:Length() > 0.15 then
		game:ShakeScreen(2)
		sfx:Play(SoundEffect.SOUND_STONE_IMPACT, 0.3, 0, false, 1.2)
	end

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

local damageBase = 3.5
---@param player EntityPlayer
function mod:EdithHopLanding(player)	
	local HopParams = TEdithMod.GetHopParryParams(player)
	local tearRange = player.TearRange / 40
	local Knockbackbase = (player.ShotSpeed * 10) + 2
	local Charge = TEdithMod.GetHopDashCharge(player, false, true)
	local BRCharge = HopParams.HopMoveBRCharge

	local rng = player:GetDropRNG()

	--- Pendiente de rehacer
	HopParams.HopDamage = (((damageBase + player.Damage) / 3.5) * (Charge + BRCharge) / 100) * (Charge / 100) 
	HopParams.HopKnockback = Knockbackbase * maths.exp(Charge / 100, 1, 1.5)
	HopParams.HopRadius = math.min((30 + (tearRange - 9)), 35)

	if Charge >= 100 and ModRNG.RandomBoolean(rng) then
		for i = 1, 5 do
			Creeps.SpawnCinderCreep(player, player.Position + Vector(0, 20):Rotated(i * (360/5)), damage, 6)
		end
	end

	player:SpawnWaterImpactEffects(player.Position, Vector(1, 1), 1)	
	land.LandFeedbackManager(player, land.GetLandSoundTable(true), misc.BurntSaltColor)
	land.TaintedEdithHop(player, HopParams)
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, mod.EdithHopLanding, jumpParams.TEdithHop)

---@param player EntityPlayer
function TEdith:EdithParryJump(player)
	if TargetArrow.GetEdithTarget(player, true) then 
		TEdithMod.ResetHopDashCharge(player, true, true)
	end

	local perfectParry, EnemiesInImpreciseParry = TEdithMod.ParryLandManager(player, true)
	local parryAdd = perfectParry and 20 or ((EnemiesInImpreciseParry and 5) or -15)

	land.LandFeedbackManager(player, land.GetLandSoundTable(true, perfectParry), misc.BurntSaltColor, perfectParry)

	if not parryAdd then return end
	TEdithMod.AddHopDashCharge(player, parryAdd, 0.75)
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, TEdith.EdithParryJump, jumpParams.TEdithJump)

---@param player EntityPlayer
---@param flags DamageFlag
---@param source EntityRef
---@return boolean?
function TEdith:TaintedEdithDamageManager(player, _, flags, source)
	local HopParams = TEdithMod.GetHopParryParams(player)

	if source.Type == EntityType.ENTITY_SLOT then return end
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