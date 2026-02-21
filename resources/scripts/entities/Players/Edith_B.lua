---@diagnostic disable: undefined-global
local mod = EdithRebuilt
local enums = mod.Enums
local utils = enums.Utils
local game = utils.Game
local sfx = utils.SFX
local costumes = enums.NullItemID
local tables = enums.Tables
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
local effects = modules.STATUS_EFFECTS
local data = mod.DataHolder.GetEntityData
local TEdith = {}

---@param player EntityPlayer
function TEdith:TaintedEdithInit(player)
	if not Player.IsEdith(player, true) then return end
	Player.SetNewANM2(player, "gfx/EdithTaintedAnim.anm2")
	player:AddNullItemEffect(costumes.T_EDITH, true)
	Player.SetCustomSprite(player, true)
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, TEdith.TaintedEdithInit)

local function isTaintedEdithJump(player)
	return JumpLib:GetData(player).Tags["edithRebuilt_TaintedEdithJump"] or false
end

---@param ent Entity
mod:AddCallback(enums.Callbacks.PERFECT_PARRY_KILL, function(_, _, ent)
	data(ent).KilledByParry = true
end)

mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, function(_, npc)
	if npc:IsBoss() then return end
	if not effects.EntHasStatusEffect(npc, "Cinder") then return end 
	if not data(npc).KilledByParry then return end

	return true
end)

---@param player EntityPlayer	
function mod:TaintedEdithUpdate(player)
	if not Player.IsEdith(player, true) then return end

	local HopParams = TEdithMod.GetHopParryParams(player)
	local isArrowMoving = TargetArrow.IsEdithTargetMoving(player)
	local arrow = TargetArrow.GetEdithTarget(player, true)
	local IsMoving = HopParams.IsHoping or HopParams.GrudgeDash
	local charge = TEdithMod.GetHopDashCharge(player, false)
	local Peffects = player:GetEffects()
	local pData = data(player)
	local CanRedirectMove = TEdithMod.GetHopDashCharge(player, false) > 0 and TEdithMod.GetHopDashCharge(player, true) <= 0

	pData.IsRedirectioningMove = CanRedirectMove and (arrow ~= nil)

	if player.CanFly and charge >= 85 and not Peffects:HasCollectibleEffect(CollectibleType.COLLECTIBLE_LEO) then
		Peffects:AddCollectibleEffect(CollectibleType.COLLECTIBLE_LEO, false, 1)
	else
		Peffects:RemoveCollectibleEffect(CollectibleType.COLLECTIBLE_LEO, -1)
	end

	if not IsMoving then
		HopParams.HopCooldown = math.max(HopParams.HopCooldown -1, 0)
	end

	if HopParams.HopCooldown == 1 then
		sfx:Play(SoundEffect.SOUND_STONE_IMPACT, 0.5, 0, false, 1.8)
		player:SetColor(Color(1, 1, 1, 1, 0, 0.3, 0), 5, 100, true, false)
	end

	if isArrowMoving and HopParams.HopCooldown == 0 then
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

	if isArrowMoving then
		pData.PressCount = pData.PressCount or 0 
		pData.PressCount = pData.PressCount + 1

		if pData.IsRedirectioningMove then
			if pData.PressCount == 20 then
				TEdithMod.ResetHopDashCharge(player, true, true)
				TEdithMod.StopTEdithHops(player, 0, false, true, true, true)
				TargetArrow.RemoveEdithTarget(player, true)
				player:SetColor(Color(0.6, 0.6, 0.6, 1), 5, 1000, true, false)
				pData.PressCount = 0
			elseif pData.PressCount == 5 then
				player:SetColor(Color(1, 1, 1, 1, 0.3, 0.3, 0.3), 5, 1000, true, false)
			elseif pData.PressCount == 2 then
				player:SetMinDamageCooldown(20)
				player:MultiplyFriction(0.4)
			end
		end
	end

	TEdithMod.WaterCurrentManager(player)

	if arrow and not isArrowMoving then
		if pData.IsRedirectioningMove then
			if pData.PressCount <= 2 then
				TargetArrow.RemoveEdithTarget(player, true)
				TEdithMod.StopTEdithHops(player, 20, false, true, true, false)
				player:SetColor(Color(1, 1, 1, 1, 0, 0.1, 0.3), 5, 1000, true, false)
			elseif pData.PressCount >= 5 then
				TargetArrow.RemoveEdithTarget(player, true)			
			end
		else
			TargetArrow.RemoveEdithTarget(player, true)
		end
		pData.PressCount = 0
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, mod.TaintedEdithUpdate)

---@param player EntityPlayer
local function TintEnemies(player)
	for _, enemy in ipairs(Isaac.FindInRadius(player.Position, misc.PerfectParryRadius + 4, EntityPartition.ENEMY)) do
		if Helpers.IsEnemy(enemy) then 
			enemy:SetColor(Color(1, 1, 1, 1, 2), 5, 100, true, false)
		end
	end
end

---@param player EntityPlayer
function mod:EdithPlayerUpdate(player)
	if not Player.IsEdith(player, true) then return end

	Player.ManageEdithWeapons(player)

	local playerData = data(player)
	local HopParams = TEdithMod.GetHopParryParams(player)
	local MiscConfig = Helpers.GetConfigData("MiscData")
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

	TintEnemies(player)

	if Helpers.IsKeyStompTriggered(player) then
		if HopParams.ParryCooldown == 0 and not isTaintedEdithJump(player) and not HopParams.IsParryJump then
			TEdithMod.ParryTriggerManager(player, IsGrudge, HopParams)
		elseif HopParams.ParryCooldown > 0 and HopParams.ParryCooldown >= playerData.MaxParryCooldown - 6 then
			player:SetColor(Color(1, 1, 1, 1, 0.3), 3, 1, true, false)
			playerData.StoredInput = true
		end
	elseif playerData.StoredInput and HopParams.ParryCooldown <= 0 then
		TEdithMod.ParryTriggerManager(player, IsGrudge, HopParams)
		playerData.StoredInput = false
	end

	if ShouldReduceFriction then
		player:MultiplyFriction(0.5)
	end

	if HopParams.IsHoping == true then
		TEdithMod.ResetHopDashCharge(player, false, true)
	end

	if Helpers.IsGrudgeChallenge() and HopParams.GrudgeDash and player.Velocity:Length() > 0.15 then		
		if MiscConfig and MiscConfig.EnableShakescreen and HopParams.HopMoveCharge > 50 then
			game:ShakeScreen(2)
		end
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
		data(player).PressCount = 0

		if game:GetRoom():GetType() == RoomType.ROOM_DUNGEON then
			TEdithMod.StopTEdithHops(player, 0, true, true, true, true)
		end
		::continue::
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.OnNewRoom)

function mod:OnNewFloor()
	for _, player in ipairs(PlayerManager.GetPlayers()) do
		if not Player.IsEdith(player, true) then goto continue end
		TEdithMod.StopTEdithHops(player, 0, true, true, true)
		data(player).PressCount = 0
		::continue::
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.OnNewFloor)

local damageBase = 3.5
---@param player EntityPlayer
function mod:EdithHopLanding(player)	
	local HopParams = TEdithMod.GetHopParryParams(player)
	local tearRange = player.TearRange / 40
	local Knockbackbase = (player.ShotSpeed * 10) + 8
	local Charge = TEdithMod.GetHopDashCharge(player, false, true)
	local BRCharge = HopParams.HopMoveBRCharge

	--- Pendiente de rehacer
	HopParams.HopDamage = (((damageBase + player.Damage) / 3.5) * (Charge + BRCharge) / 100) * (Charge / 100) 
	HopParams.HopKnockback = Knockbackbase * maths.exp(Charge / 100, 1, 1.5)
	HopParams.HopRadius = math.min((30 + (tearRange - 9)), 35)

	player:SpawnWaterImpactEffects(player.Position, Vector(1, 1), 1)	
	land.LandFeedbackManager(player, land.GetLandSoundTable(true), misc.BurntSaltColor)
	land.TaintedEdithHop(player, HopParams)
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, mod.EdithHopLanding, jumpParams.TEdithHop)

---@param player EntityPlayer
function TEdith:EdithParryJump(player)
	local HopParams = TEdithMod.GetHopParryParams(player)

	if TargetArrow.GetEdithTarget(player, true) then 
		TEdithMod.ResetHopDashCharge(player, true, true)
	end

	local perfectParry, EnemiesInImpreciseParry = land.ParryLandManager(player, HopParams, true)
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

mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
	for _, player in ipairs(PlayerManager.GetPlayers()) do
		if not (Player.IsEdith(player, true) and RoomTransition:GetTransitionMode() ~= 3) then goto continue end

		local playerpos = game:GetRoom():WorldToScreenPosition(player.Position)
		local HopParams = TEdithMod.GetHopParryParams(player)
		local playerData = data(player)
		local dashCharge = HopParams.HopStaticCharge
		local dashBRCharge = HopParams.HopStaticBRCharge
		local offset = misc.ChargeBarcenterVector

		if game:GetRoom():IsMirrorWorld() then
			playerpos.X = (Helpers.GetScreenCenter().X * 2 - playerpos.X)
		end

		if not dashCharge or not dashBRCharge then return end

		playerData.ChargeBar = playerData.ChargeBar or Sprite("gfx/TEdithChargebar.anm2", true)
		playerData.BRChargeBar = playerData.BRChargeBar or Sprite("gfx/TEdithBRChargebar.anm2", true)

		if Player.PlayerHasBirthright(player) and not playerData.BRChargeBar:IsFinished("Disappear") then
			offset = misc.ChargeBarleftVector
		end

		Helpers.RenderChargeBar(playerData.ChargeBar, dashCharge, 100, playerpos + offset)
		Helpers.RenderChargeBar(playerData.BRChargeBar, dashBRCharge, 100, playerpos + misc.ChargeBarrightVector)

		::continue::
	end
end)

---@param player EntityPlayer
---@param grid GridEntity
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_GRID_COLLISION, function(_, player, _, grid)
	if not grid then return end
	if not Player.IsEdith(player, true) then return end

	local playerData = data(player)
	local params = TEdithMod.GetHopParryParams(player)
	local charge = TEdithMod.GetHopDashCharge(player, false, false)
	local isMoving = params.IsHoping or params.GrudgeDash
	local arrow = TargetArrow.GetEdithTarget(player, true)
	local rock = grid:ToRock()
	local poop = grid:ToPoop()
	local tnt = grid:ToTNT()
	local IsJumping = JumpLib:GetData(player).Jumping

	if not isMoving then return end

	if grid:GetType() == GridEntityType.GRID_ROCKB and not IsJumping and not arrow then
		TEdithMod.StopTEdithHops(player, 20, true, not playerData.TaintedEdithTarget, true)
	end

	if rock or poop or tnt then
		if charge >= 50 then
			grid:Destroy()
		else
			if not arrow then
				TEdithMod.StopTEdithHops(player, 20, true, not playerData.TaintedEdithTarget, true)
			end
		end
	else 
		if not IsJumping and not arrow then
			TEdithMod.StopTEdithHops(player, 20, true, not playerData.TaintedEdithTarget, true)
		end
	end
end)

---@param player EntityPlayer
---@param collider Entity
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_COLLISION, function (_, player, collider)
	if not Player.IsEdith(player, true) then return end
	if collider.Type ~= EntityType.ENTITY_FIREPLACE then return end
	if collider.Variant ~= 4 then return end
	if player:HasInstantDeathCurse() then return end

	TEdithMod.StopTEdithHops(player, 20, true, true, true)
end)