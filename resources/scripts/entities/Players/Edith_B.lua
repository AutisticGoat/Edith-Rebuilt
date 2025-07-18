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
local costumes = enums.NullItemID
local callback = enums.Callbacks
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
	Clamp = TSIL.Utils.Math.Clamp
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

function TEdith:TaintedEdithInit(player)
	if not funcs.IsEdith(player, true) then return end
	mod.SetNewANM2(player, "gfx/EdithTaintedAnim.anm2")
	mod.ForceCharacterCostume(player, players.PLAYER_EDITH_B, costumes.ID_EDITH_B_SCARF)

	funcs.GetData(player).HopVector = Vector.Zero
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, TEdith.TaintedEdithInit)

function mod:InitTaintedEdithHop(player)
	local playerData = funcs.GetData(player)
	local jumpHeight = 6.5 
	local jumpSpeed = 2.8 * funcs.log(playerData.MoveCharge, 100)

	local config = {
		Height = jumpHeight,
		Speed = jumpSpeed,
		Tags = jumpTags.TEdithHop,
		Flags = jumpFlags.TEdithHop
	}
	JumpLib:Jump(player, config)
end

local backdropColors = tables.BackdropColors
function mod:InitTaintedEdithJump(player)
	local jumpHeight = 8
	local jumpSpeed = 2.5
	local room = game:GetRoom()
	local RoomWater = room:HasWater()
	local isChap4 = mod:isChap4()
	local BackDrop = room:GetBackdropType()
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
	)

	local color = DustCloud.Color
	local switch = {
		[EffectVariant.BIG_SPLASH] = function()
			color = backdropColors[BackDrop] or Color(0.7, 0.75, 1)
		end,
		[EffectVariant.POOF02] = function()
			color = backdropColors[BackDrop] or Color(1, 0, 0)
		end,
		[EffectVariant.POOF01] = function()
			if RoomWater then
				color = backdropColors[BackDrop]
			end
		end
	}

	mod.When(DustCloud.Variant, switch)

	DustCloud.SpriteScale = DustCloud.SpriteScale * player.SpriteScale.X
	DustCloud.DepthOffset = -100
	DustCloud:SetColor(color, -1, 100, false, false)
	DustCloud:GetSprite().PlaybackSpeed = RoomWater and 1.3 or 2	

	local config = {
		Height = jumpHeight,
		Speed = jumpSpeed,
		Tags = jumpTags.TEdithJump,
		Flags = jumpFlags.TEdithJump
	}
	JumpLib:Jump(player, config)
end

local function isTaintedEdithJump(player)
	local jumpData = JumpLib:GetData(player)
	local tags = jumpData.Tags

	return tags["edithRebuilt_EdithJump"] or false
end

---@param player EntityPlayer	
function mod:TaintedEdithUpdate(player)
	if not funcs.IsEdith(player, true) then return end

	local playerData = funcs.GetData(player)
	local jumpData = JumpLib:GetData(player)
	local isJumping = jumpData.Jumping

	playerData.ImpulseCharge = playerData.ImpulseCharge or 0
	playerData.BirthrightCharge = playerData.BirthrightCharge or 0
	playerData.ParryCounter = playerData.ParryCounter or 20

	local colorChange = math.min((playerData.ImpulseCharge) / 100, 1) * 0.5
	local colorBRChange = math.min(playerData.BirthrightCharge / 100, 1) * 0.1

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

	if player:CollidesWithGrid() and playerData.IsHoping == true then
		if not isJumping then
			mod.stopTEdithHops(player, 20, true, playerData.TaintedEdithTarget == nil)
		end
	end

	if mod.IsDogmaAppearCutscene() then
		mod.stopTEdithHops(player, 0, false, true)
	end

	if funcs.TargetMov(player) then
		mod.SpawnEdithTarget(player, true)
	end

	local target = mod.GetEdithTarget(player, true)
	local HopVec = playerData.HopVector

	if target then
		local posDif = target.Position - player.Position
		local posDifLenght = posDif:Length()	
		local posDifNormal = posDif:Normalized()
		local maxDist = 2.5

		playerData.HopVector = posDif:Normalized()

		if target.FrameCount < 2 and playerData.IsHoping == true then
			mod.stopTEdithHops(player, 20, true, true)
			funcs.FeedbackMan(player, hopSounds, misc.BurntSaltColor, false)
		end

		target.Velocity = playerData.movementVector:Resized(10)
		if posDifLenght >= maxDist then
			target.Velocity = target.Velocity - (posDifNormal * (posDifLenght / (maxDist))) 
		end

		local tearMult = funcs.GetTPS(player) / 2.73							
		local chargeAdd = 8.25 * funcs.exp(tearMult, 1, 1.5)
		local hasBirthright = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)
		local shouldChargeBrCharge = hasBirthright and playerData.ImpulseCharge >= 100

		if target.FrameCount > 1 then
			if not playerData.IsHoping and not isJumping then
				playerData.ImpulseCharge = funcs.Clamp(playerData.ImpulseCharge + chargeAdd, 0, 100)
				playerData.BirthrightCharge = shouldChargeBrCharge and funcs.Clamp(playerData.BirthrightCharge + (chargeAdd * 0.5), 0, 100) or 0
			end
		end
	else
		if playerData.MoveCharge and playerData.MoveCharge >= 10 then
			if playerData.IsHoping == true then
				player.Velocity = (HopVec) * (9.5 + (player.MoveSpeed - 1)) * (playerData.MoveCharge / 100)
			end
					
			if not (HopVec.X == 0 and HopVec.Y == 0) then
				if not isJumping then
					mod:InitTaintedEdithHop(player)
				end
				playerData.IsHoping = true
			end
		else
			if not funcs.TargetMov(player) and playerData.IsHoping == false then
				mod.resetCharges(player)
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

	local MovX = (((input.left > 0.5 and -input.left) or (input.right > 0.5 and input.right)) or 0) * (game:GetRoom():IsMirrorWorld() and -1 or 1)
	local MovY = (input.up > 0.5 and -input.up) or (input.down > 0.5 and input.down) or 0

	playerData.movementVector = Vector(MovX, MovY):Normalized() 

	if mod:IsKeyStompTriggered(player) then
		if playerData.ParryCounter == 0 and not isTaintedEdithJump(player) and not playerData.IsParryJump then
			playerData.IsParryJump = true

			if playerData.IsHoping then
				mod.stopTEdithHops(player, 0, true, true)
			end
			mod:InitTaintedEdithJump(player)
		end
	end
	
	playerData.MoveCharge = playerData.MoveCharge or 0
	playerData.MoveBrCharge = playerData.MoveBrCharge or 0
	playerData.ImpulseCharge = playerData.ImpulseCharge or 0
	playerData.BirthrightCharge = playerData.BirthrightCharge or 0

	if playerData.IsHoping == true then
		mod.resetCharges(player)
	else
		playerData.MoveBrCharge = playerData.BirthrightCharge
		playerData.MoveCharge = playerData.ImpulseCharge

		if not IsJumping then
			player:MultiplyFriction(0.5)
		end
	end	

	local isShooting = mod:IsPlayerShooting(player)
	local faceDirection = TSIL.Vector.VectorToDirection(playerData.HopVector)
	local chosenDir = faceDirection	or Direction.DOWN

	if playerData.IsHoping or (arrow and arrow.Visible == true) then
		chosenDir = faceDirection
	else
		if TSIL.Vector.VectorEquals(playerData.HopVector, Vector.Zero) then
			chosenDir = Direction.DOWN
		end
	end

	if not isShooting then
		player:SetHeadDirection(chosenDir, 2, true)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, mod.EdithPlayerUpdate)

---@param player EntityPlayer
---@param position Vector
---@param damage number
---@param useDefaultMult? boolean
---@param scale number
local function spawnFireJet(player, position, damage, useDefaultMult, scale)
	useDefaultMult = useDefaultMult or false
	local playerData = funcs.GetData(player)
	local Fire = Isaac.Spawn(
		EntityType.ENTITY_EFFECT,
		EffectVariant.FIRE_JET,
		0,
		position,
		Vector.Zero,
		player
	)
	Fire.SpriteScale = Fire.SpriteScale * (scale or 1)
	Fire.CollisionDamage = damage * useDefaultMult and 1 or (playerData.MoveBrCharge / 100) 
end

function mod:OnNewRoom()
	for _, player in ipairs(PlayerManager.GetPlayers()) do
		if not funcs.IsEdith(player, true) then return end
		mod:ChangeColor(player, _, _, _, 1)
		mod.stopTEdithHops(player, 0, true, true)
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
		Damage = ((damageBase + player.Damage) / 1.75) * (Charge + BRCharge) / 100 ---@type number
	}
	
	if playerData.MoveBrCharge > 0 then
		local jets = 4
		local ndegree = 360/jets
		for i = 1, jets do
			spawnFireJet(player,player.Position + Vector(20, 0):Rotated(ndegree*i), HopParams.Damage, false, 0.8)
		end
	end

	player:SpawnWaterImpactEffects(player.Position, Vector(1, 1), 1)	
	funcs.FeedbackMan(player, hopSounds, misc.BurntSaltColor)

	mod:TaintedEdithHop(player, HopParams.Radius, HopParams.Damage, HopParams.Knockback)	
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, mod.EdithHopLanding, jumpParams.TEdithHop)

---@param tear EntityTear
function mod:OnTaintedShootTears(tear)
	local player = mod:GetPlayerFromTear(tear)
	if not player then return end
	if not funcs.IsEdith(player, true) then return end

	mod.ForceSaltTear(tear, true)
end
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, mod.OnTaintedShootTears)

local damageBase = 13.5
---@param player EntityPlayer
function mod:EdithParryJump(player)
	local DamageStat = player.Damage 
	local rawFormula = ((damageBase + DamageStat) / 1.5) 
	local isenemy = false
	local playerPos = player.Position
	local playerData = funcs.GetData(player)

	local capsule = Capsule(player.Position, Vector.One, 0, misc.PerfectParryRadius)
	local capsuleTwo = Capsule(player.Position, Vector.One, 0, misc.ImpreciseParryRadius)	

	local ImpreciseParryEnts = Isaac.FindInCapsule(capsuleTwo, misc.ParryPartitions)
	local PerfectParryEnts = Isaac.FindInCapsule(capsule, misc.ParryPartitions)
	local hasBirthright = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)
	local BirthrightMult = hasBirthright and 1.25 or 1
	local hasBirthcake = BirthcakeRebaked and player:HasTrinket(BirthcakeRebaked.Birthcake.ID) or false
	local DamageFormula = (rawFormula * BirthrightMult) * (hasBirthcake and 1.15 or 1)
	
	local saveManager = mod.SaveManager

	if not saveManager then return end
	if not saveManager.IsLoaded() then return end

	local settings = saveManager:GetSettingsSave()
	if not settings then return end

	local TEdithData = settings.TEdithData
	local cooldown

	for _, ent in pairs(ImpreciseParryEnts) do
		local entPos = ent.Position
		local newVelocity = ((playerPos - entPos) * -1):Resized(20)

		if ent:IsActiveEnemy() and ent:IsVulnerableEnemy() then
			ent:AddConfusion(EntityRef(player), 90, false)
		end

		if not ent:ToTear() then
			ent:AddKnockback(EntityRef(player), newVelocity, 5, true)
		end

		cooldown = 10
	end

	for _, ent in pairs(PerfectParryEnts) do
		local proj = ent:ToProjectile()

		Isaac.RunCallback(callback.PERFECT_PARRY, player, ent)

		if proj then
			local spawner = proj.Parent or proj.SpawnerEntity
			local targetPos = spawner and spawner.Position or proj.Position
			local newVelocity = ((playerPos - targetPos) * -1):Resized(25)

			proj.FallingAccel = -0.1
			proj.FallingSpeed = 0
			proj.Height = -23
			proj:AddProjectileFlags(misc.NewProjectilFlags)

			if hasBirthright then
				proj:AddProjectileFlags(ProjectileFlags.FIRE_SPAWN)
			end

			ent:AddKnockback(EntityRef(player), newVelocity, 5, true)
		else
			local tear = ent:ToTear()
			if hasBirthright then
				local jets = 6
				local ndegree = 360 / jets

				for i = 1, jets do
					local jetPos = playerPos + Vector(35, 0):Rotated(ndegree*i)
					spawnFireJet(player, jetPos, DamageFormula / 1.5, true, 1)				
				end
			end
		
			if ent.Type == EntityType.ENTITY_STONEY then
				ent:ToNPC().State = NpcState.STATE_SPECIAL
			end

			if tear then
				ent.Velocity = ent.Velocity:Resized(20)
				tear:AddTearFlags(TearFlags.TEAR_KNOCKBACK | TearFlags.TEAR_QUADSPLIT)
			end

			ent:TakeDamage(DamageFormula, 0, EntityRef(player), 0)
			sfx:Play(SoundEffect.SOUND_MEATY_DEATHS)

			if ent.HitPoints <= DamageFormula then
				Isaac.RunCallback(callback.PERFECT_PARRY_KILL, player, ent)
				
				if TEdithData.EnableGore then
					mod.AddExtraGore(ent)
				end
			end
		end
		isenemy = true
		cooldown = 20
	end

	if cooldown then
		player:SetMinDamageCooldown(cooldown)
	end

	playerData.ParryCounter = isenemy and (hasBirthcake and 8 or 10) or 15

	if isenemy == true then
		game:MakeShockwave(playerPos, 0.035, 0.025, 2)
		playerData.ImpulseCharge = playerData.ImpulseCharge + 20

		if playerData.ImpulseCharge >= 100 and hasBirthright then
			playerData.BirthrightCharge = playerData.BirthrightCharge + 15
		end

		if TEdithData.EnableGore then
			mod.AddExtraGore(ent)
		end
	end
	
	local tableRef = isenemy and parryJumpSounds or hopSounds
	funcs.FeedbackMan(player, tableRef, misc.BurntSaltColor, isenemy)

	playerData.IsParryJump = false

	-- local lasers = Isaac.FindByType(EntityType.ENTITY_LASER) ---@type EntityLaser[]
	-- if #lasers < 1 then return end

	-- for _, laser in ipairs(lasers) do
		
	-- end
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, mod.EdithParryJump, jumpParams.TEdithJump)
function mod:TaintedEdithDamageManager(player)
	local playerData = funcs.GetData(player)
	if not funcs.IsEdith(player, true) then return end

	if playerData.IsHoping == true and playerData.MoveCharge >= 30 then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, mod.TaintedEdithDamageManager)

function mod:HudBarRender(player)
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
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_RENDER, mod.HudBarRender)