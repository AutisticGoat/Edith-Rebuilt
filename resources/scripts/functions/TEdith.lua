---@diagnostic disable: undefined-global, param-type-mismatch
local mod = EdithRebuilt
local enums = mod.Enums
local misc = enums.Misc
local utils = enums.Utils
local game = utils.Game
local sfx = utils.SFX
local data = mod.CustomDataWrapper.getData
local jumpFlags = enums.Tables.JumpFlags
local jumpTags = enums.Tables.JumpTags
local maths = require("resources.scripts.functions.Maths")
local helpers = require("resources.scripts.functions.Helpers")
local Player = require("resources.scripts.functions.Player")
local StatusEffects = require("resources.scripts.functions.StatusEffects")
local TargetArrow = require("resources.scripts.functions.TargetArrow")
local Land = require("resources.scripts.functions.Land")
local TEdith = {}

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
---@field IsHoping boolean
---@field IsParryJump boolean
---@field GrudgeDash boolean

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
	GrudgeDash = falses

} --[[@as TEdithHopParryParams]]

---@param player EntityPlayer
---@return TEdithHopParryParams
function TEdith.GetHopParryParams(player)
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
function TEdith.StopTEdithHops(player, cooldown, useQuitJump, resetChrg)
	if not Player.IsEdith(player, true) then return end

	local HopParams = TEdith.GetHopParryParams(player)

	HopParams.IsHoping = false
	HopParams.HopDirection = Vector.Zero

	player:MultiplyFriction(0.5)

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

---@param player EntityPlayer
---@param hopParams TEdithHopParryParams
function TEdith.HopDashMovementManager(player, hopParams)
	local HopVec = hopParams.HopDirection
	local isHopVecZero = HopVec.X == 0 and HopVec.Y == 0
	local isJumping = JumpLib:GetData(player).Jumping
	local IsGrudge = helpers.IsGrudgeChallenge()
	local chargeMult = (TEdith.GetHopDashCharge(player, false, false) / 100)
	local VelMult = IsGrudge and 1.2 or 1 

	-- print(isHopVecZero)

	if not isHopVecZero then
		if not isJumping and not IsGrudge then
			TEdith.InitTaintedEdithHop(player)
		end
		hopParams.IsHoping = true
	end

	-- if not isJumping then return end
	local smoothFactor = 0.225
	local targetVel = (((HopVec * 2) * (10 + (player.MoveSpeed - 1))) * chargeMult) * VelMult
	player.Velocity = player.Velocity + (targetVel - player.Velocity) * smoothFactor

	hopParams.GrudgeDash = not isHopVecZero

	-- if IsGrudge and not isHopVecZero then
	-- 	game:ShakeScreen(2)
	-- 	sfx:Play(SoundEffect.SOUND_STONE_IMPACT)
	-- end
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
	local posDifLenght = posDif:Length()
	local maxDist = 2.5
	local BaseCharge = helpers.IsGrudgeChallenge() and 9.5 or 8
	local targetframecount = arrow.FrameCount
	local chargeAdd = BaseCharge * maths.exp(player.MoveSpeed, 1, 1.5)
	HopParams.HopDirection = posDif:Normalized()

	local arrowVel = data(player).movementVector
	local HopVec = arrowVel

	-- Calcula la velocidad objetivo (la que ya usabas)
	local targetVel = HopVec:Resized(10)

	if posDifLenght >= maxDist then
		targetVel = targetVel - (posDif:Normalized() * (posDifLenght / maxDist))
	end

	local smoothFactor = 0.5
	arrow.Velocity = arrow.Velocity + (targetVel - arrow.Velocity) * smoothFactor

	if targetframecount < 2 and HopParams.IsHoping == true then
		TEdith.StopTEdithHops(player, 20, true, true)
		Land.LandFeedbackManager(player, Land.GetLandSoundTable(true), misc.BurntSaltColor, false)
	end

	if targetframecount > 1 and (not HopParams.IsHoping and not isJumping) then
		TEdith.AddHopDashCharge(player, chargeAdd, 0.5)
	end
end

--- Misc function used to manage some perfect parry stuff (i made it to be able to return something in the main parry function sorry)
---@param player EntityPlayer
---@param IsTaintedEdith? boolean
---@param isenemy? boolean
local function PerfectParryMisc(player, IsTaintedEdith, isenemy)
	if not isenemy then return end
	game:MakeShockwave(player.Position, 0.035, 0.025, 2)

	if not IsTaintedEdith then return end

    local playerData = data(player)
    local hasBirthright = Player.PlayerHasBirthright(player)
end

---@param ent Entity
---@param capsule1 Capsule
---@param capsule2 Capsule
local function IsEntInTwoCapsules(ent, capsule1, capsule2)
	local Capsule1Ents = Isaac.FindInCapsule(capsule1)
	local Capsule2Ents = Isaac.FindInCapsule(capsule2)
	local PtrHashEnt = GetPtrHash(ent)
	local IsInsideCapsule1, IsInsideCapsule2 = false, false

	for _, Entity in ipairs(Capsule1Ents) do
		if PtrHashEnt == GetPtrHash(Entity) then
			IsInsideCapsule1 = true
			break
		end
	end

	for _, Entity in ipairs(Capsule2Ents) do
		if PtrHashEnt == GetPtrHash(Entity) then
			IsInsideCapsule2 = true
			break
		end
	end

	return IsInsideCapsule1 and IsInsideCapsule2
end

---Function used to trigger Tainted Edith and Burnt Hood's parry-jump
---@param player EntityPlayer
---@param tag string
function TEdith.InitTaintedEdithParryJump(player, tag)
	local jumpHeight = 8
	local jumpSpeed = 2.5
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

---@param PerfectParry boolean
local function GrudgeUnlockManager(PerfectParry)
	local pgd = Isaac.GetPersistentGameData()
	local GrudgeAch = enums.Achievements.ACHIEVEMENT_GRUDGE
	if pgd:Unlocked(GrudgeAch) then return end

	local saveManager = mod.SaveManager
	local PersistentData = saveManager.GetPersistentSave()

	if not PersistentData then return end

	PersistentData.ConsecutiveParries = PersistentData.ConsecutiveParries or 0
	
	if PerfectParry then
		PersistentData.ConsecutiveParries = PersistentData.ConsecutiveParries + 1
	else
		PersistentData.ConsecutiveParries = 0
	end

	if PersistentData.ConsecutiveParries == 5 then
		pgd:TryUnlock(GrudgeAch)
	end
end

---Helper function used to manage Tainted Edith and Burnt Hood's parry-lands 
---@param player EntityPlayer
---@param IsTaintedEdith? boolean 
---@return boolean PerfectParry Returns a boolean that tells if there was a perfect parry 
---@return boolean EnemiesInImpreciseParry
function TEdith.ParryLandManager(player, IsTaintedEdith)
	local HopParams = TEdith.GetHopParryParams(player)
	local damageBase = 13.5
	local DamageStat = player.Damage 
	local rawFormula = (damageBase + DamageStat) / 1.5 
	local PerfectParry = false
	local EnemiesInImpreciseParry = false
	local ImpreciseParryCapsule = Capsule(player.Position, Vector.One, 0, misc.ImpreciseParryRadius)	
	local PerfectParryCapsule = Capsule(player.Position, Vector.One, 0, misc.PerfectParryRadius)
	local hasBirthright = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)
	local BirthrightMult = hasBirthright and 1.25 or 1
	local hasBirthcake = BirthcakeRebaked and player:HasTrinket(BirthcakeRebaked.Birthcake.ID) or false
	local DamageFormula = (rawFormula * BirthrightMult) * (hasBirthcake and 1.15 or 1)
	local shouldTriggerFireJets = IsTaintedEdith and hasBirthright or Player.IsJudasWithBirthright(player)
	local spawner, targetEnt, proj
	local damageFlag = Player.PlayerHasBirthright(player) and DamageFlag.DAMAGE_FIRE or 0

	if IsTaintedEdith then
		local damageIncrease = 1 + (HopParams.HopStaticCharge + HopParams.HopStaticBRCharge) / 400
		DamageFormula = DamageFormula * damageIncrease
	end

	HopParams.ParryDamage = DamageFormula

	local tearsMult = (Player.GetplayerTears(player) / 2.73) 
	local CinderTime = maths.SecondsToFrames((4 * tearsMult))

	for _, ent in pairs(Isaac.FindInCapsule(ImpreciseParryCapsule, misc.ParryPartitions)) do
		if ent:ToTear() then goto continue end
		local pushMult = StatusEffects.EntHasStatusEffect(ent, enums.EdithStatusEffects.CINDER) and 1.5 or 1
		helpers.TriggerPush(ent, player, 20 * pushMult)

		if not helpers.IsEnemy(ent) then goto continue end
		if IsEntInTwoCapsules(ent, ImpreciseParryCapsule, PerfectParryCapsule) then goto continue end		

		ent:TakeDamage(DamageFormula * 0.25, 0, EntityRef(player), 0)
		StatusEffects.SetStatusEffect(enums.EdithStatusEffects.CINDER, ent, CinderTime, player)
		EnemiesInImpreciseParry = true
		::continue::
	end

	for _, ent in pairs(Isaac.FindInCapsule(PerfectParryCapsule, misc.ParryPartitions)) do
		Isaac.RunCallback(enums.Callbacks.PERFECT_PARRY, player, ent, HopParams)
		proj = ent:ToProjectile()
		 
		if proj then
			spawner = proj.Parent or proj.SpawnerEntity
			targetEnt = spawner or helpers.GetNearestEnemy(player) or proj

			proj.FallingAccel = -0.1
			proj.FallingSpeed = 0
			proj.Height = -23
			proj:AddProjectileFlags(misc.NewProjectilFlags)
			proj:AddKnockback(EntityRef(player), (targetEnt.Position - player.Position):Resized(25), 5, false)

			if shouldTriggerFireJets then
				proj:AddProjectileFlags(ProjectileFlags.FIRE_SPAWN)
			end
		else
			local tear = ent:ToTear()
		
			if ent.Type == EntityType.ENTITY_STONEY then
				ent:ToNPC().State = NpcState.STATE_SPECIAL
			end

			if tear then
				helpers.BoostTear(tear, 20, 1.5 + ((HopParams.HopStaticCharge + HopParams.HopStaticBRCharge) / 100))

				if hasBirthright then
					tear:AddTearFlags(TearFlags.TEAR_BURN)
				end
			end

			ent:TakeDamage(HopParams.ParryDamage, damageFlag, EntityRef(player), 0)
			if hasBirthright then
				ent:AddBurn(EntityRef(player), 123, 5)				
			end
			sfx:Play(SoundEffect.SOUND_MEATY_DEATHS)

			if ent.Type == EntityType.ENTITY_FIREPLACE and ent.Variant ~= 4 then
				ent:Kill()
			end

			if ent.HitPoints <= HopParams.ParryDamage then
				Isaac.RunCallback(enums.Callbacks.PERFECT_PARRY_KILL, player, ent)
				Land.AddExtraGore(ent, player)
			end
		end
		PerfectParry = true		
	end

	player:SetMinDamageCooldown(PerfectParry and 30 or 15)
	PerfectParryMisc(player, IsTaintedEdith, PerfectParry)

	HopParams.ParryCooldown = IsTaintedEdith and (PerfectParry and (hasBirthcake and 8 or 10) or 15) or 0
	HopParams.IsParryJump = false

	GrudgeUnlockManager(PerfectParry)

	return PerfectParry, EnemiesInImpreciseParry
end

return TEdith