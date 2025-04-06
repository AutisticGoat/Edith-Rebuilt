local mod = edithMod
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
local misc = enums.Misc

local funcs = {
	IsEdith = mod.IsEdith,
	GetData = mod.GetData,
	TargetMov = mod.IsEdithTargetMoving,
	VecToAngle = mod.vectorToAngle,
	GetTPS = mod.GetTPS,
	Switch = mod.When,
	log = mod.Log,
	exp = mod.exp,
	FeedbackMan = mod.LandFeedbackManager
}

local hopSounds = {
	[1] = SoundEffect.SOUND_STONE_IMPACT,
	[2] = sounds.SOUND_YIPPEE,
	[3] = sounds.SOUND_SPRING,
}

local parryJumpSounds = {
	[1] = SoundEffect.SOUND_STONE_IMPACT,
	[2] = sounds.SOUND_PIZZA_TAUNT,
	[3] = sounds.SOUND_VINE_BOOM,
	[4] = sounds.SOUND_FART_REVERB,
	[5] = sounds.SOUND_SOLARIAN,
	[6] = sounds.SOUND_MACHINE,
	[7] = sounds.SOUND_MECHANIC,
	[8] = sounds.SOUND_KNIGHT,
}

function mod:TaintedEdithInit(player)
	if not funcs.IsEdith(player, true) then return end
	mod.SetNewANM2(player, "gfx/EdithTaintedAnim.anm2")
	mod.ForceCharacterCostume(player, players.PLAYER_EDITH_B, costumes.ID_EDITH_B_SCARF)
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.TaintedEdithInit)

local function resetCharges(player)
	local playerData = funcs.GetData(player)
	playerData.ImpulseCharge = 0
	playerData.BirthrightCharge = 0
	-- playerData.MoveBrCharge = 0
	-- playerData.MoveCharge = 0
end

---@param player EntityPlayer
---@param cooldown integer
---@param useQuitJump boolean
---@param resetChrg boolean
local function stopTEdithHops(player, cooldown, useQuitJump, resetChrg)
	local playerData = funcs.GetData(player)
	playerData.IsHoping = false
	player:MultiplyFriction(0.5)
	playerData.HopVector = Vector(0, 0)
	
	cooldown = cooldown or 0
	useQuitJump = useQuitJump or false
	
	if useQuitJump then
		JumpLib:QuitJump(player)
	end
			
	if resetChrg then
		resetCharges(player)
	end

	player:SetMinDamageCooldown(cooldown)
end

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
	local room = game:GetRoom()
	local jumpHeight = 8
	local jumpSpeed = 2.5
	
	local isChap4 = mod:isChap4()
	local BackDrop = room:GetBackdropType()
	local variant = room:HasWater() and EffectVariant.BIG_SPLASH or (isChap4 and EffectVariant.POOF02 or EffectVariant.POOF01)
	local subType = room:HasWater() and 1 or (isChap4 and 66 or 1)
	
	sfx:Play(SoundEffect.SOUND_SHELLGAME)
	
	local DustCloud = Isaac.Spawn(
		EntityType.ENTITY_EFFECT, 
		variant, 
		subType, 
		player.Position, 
		Vector.Zero, 
		player
	)	

	local var = DustCloud.Variant
	local color = Color.Default

	local switch = {
		[EffectVariant.BIG_SPLASH] = function()
			color = backdropColors[BackDrop] or Color(0.7, 0.75, 1)
		end,
		[EffectVariant.POOF02] = function()
			color = backdropColors[BackDrop] or Color(1, 0, 0)
		end,
		[EffectVariant.POOF01] = function()
			if room:HasWater() then
				color = backdropColors[BackDrop]
			end
		end
	}
	switch[var]()

	local dustSprite = DustCloud:GetSprite()
	
	dustSprite.PlaybackSpeed = room:HasWater() and 1.3 or 2	
	DustCloud.DepthOffset = -100
	DustCloud:SetColor(color, -1, 100, false, false)
	
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
	
	return tags["edithMod_TaintedEdithJump"] or false
end

function mod:TaintedEdithUpdate(player)
	if not funcs.IsEdith(player, true) then return end

	local playerData = funcs.GetData(player)
	local jumpData = JumpLib:GetData(player)
	local isJumping = jumpData.Jumping
	local room = game:GetRoom()
	local input = {
		up = Input.IsActionPressed(ButtonAction.ACTION_UP, player.ControllerIndex),
		down = Input.IsActionPressed(ButtonAction.ACTION_DOWN, player.ControllerIndex),
		left = Input.IsActionPressed(ButtonAction.ACTION_LEFT, player.ControllerIndex),
		right = Input.IsActionPressed(ButtonAction.ACTION_RIGHT, player.ControllerIndex)
	}

	playerData.movementVector = playerData.movementVector or Vector.Zero
	playerData.movementVector.Y = (input.up and -1) or (input.down and 1) or 0
	playerData.movementVector.X = (input.left and -1) or (input.right and 1) or 0
	playerData.ImpulseCharge = playerData.ImpulseCharge or 0
	playerData.BirthrightCharge = playerData.BirthrightCharge or 0
	playerData.ParryCounter = playerData.ParryCounter or 20

	local NormalizedMovementVector = playerData.movementVector:Normalized()

	if room:IsMirrorWorld() then
		playerData.movementVector.X = playerData.movementVector.X * -1
	end
	
	if playerData.ParryCounter > 0 then
		if isTaintedEdithJump(player) ~= true then
			playerData.ParryCounter = playerData.ParryCounter - 1
		end

		if playerData.ParryCounter == 1 then
			player:SetColor(Color(1, 1, 1, 1, 0.5, 0, 0), 5, 100, true, false)
			sfx:Play(SoundEffect.SOUND_STONE_IMPACT)
		end
	end
		
	playerData.HopVector = playerData.HopVector or Vector.Zero
	
	if player:CollidesWithGrid() then
		if not isJumping then
			stopTEdithHops(player, 20, true, playerData.TaintedEdithTarget == nil)
		end
	end

	local target = funcs.TargetMov(player) and mod:SpawnTaintedArrow(player)
	local HopVec = playerData.HopVector

	if target then
		local posDif = target.Position - player.Position
		local posDifLenght = posDif:Length()	
		local posDifNormal = posDif:Normalized()
		local maxDist = 2.5
		local dir = funcs.VecToAngle(HopVec)	
		local faceDirection = tables.DegreesToDirection[dir]

		playerData.HopVector = posDif:Normalized()		

		if target.FrameCount < 2 and playerData.IsHoping == true then
			stopTEdithHops(player, 20, true, true)
			funcs.FeedbackMan(player, hopSounds, misc.BurnedSaltColor, false)
		end

		target.Velocity = NormalizedMovementVector:Resized(10)
		if posDifLenght >= maxDist then
			target.Velocity = target.Velocity - (posDifNormal * (posDifLenght / (maxDist))) 
		end
		
		if not mod:IsPlayerShooting(player) then
			player:SetHeadDirection(faceDirection, 2, true)
		end
			
		local baseTearsStat = 2.73
		local tearMult = funcs.GetTPS(player) / baseTearsStat							
		local jumpData = JumpLib:GetData(player)
		local isJumping = jumpData.Jumping
		local chargeAdd = 10 * funcs.exp(tearMult, 1, 1.5)
		local hasBirthright = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)
		local shouldChargeBrCharge = hasBirthright and playerData.ImpulseCharge >= 100

		if target.FrameCount > 1 then
			if playerData.IsHoping == false and isJumping == false then
				playerData.ImpulseCharge = math.min(playerData.ImpulseCharge + chargeAdd, 100)
				playerData.BirthrightCharge = shouldChargeBrCharge and math.min(playerData.BirthrightCharge + (chargeAdd * 0.5), 100) or 0
			end
		end
	else
		if playerData.MoveCharge and playerData.MoveCharge >= 10 then
			if playerData.IsHoping == true then
				player.Velocity = (HopVec) * (7 + (player.MoveSpeed - 1)) * (playerData.MoveCharge / 100)
			end
					
			if not (HopVec.X == 0 and HopVec.Y == 0) then
				if not isJumping then
					mod:InitTaintedEdithHop(player)
				end
				playerData.IsHoping = true
			end
		else
			if not funcs.TargetMov(player) and playerData.IsHoping == false then
				resetCharges(player)
			end
		end
		mod:RemoveTaintedEdithTargetArrow(player)
	end	
end
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, mod.TaintedEdithUpdate)

function mod:EdithPlayerUpdate(player)
	local playerData = funcs.GetData(player)

	if mod:IsKeyStompTriggered(player) then
		if playerData.ParryCounter == 0 and isTaintedEdithJump(player) == false  then
			stopTEdithHops(player, 0, true, true)
			mod:InitTaintedEdithJump(player)
		end
	end

	playerData.MoveBrCharge = playerData.MoveBrCharge or 0
	playerData.MoveCharge = playerData.MoveCharge or 0
	playerData.ImpulseCharge = playerData.ImpulseCharge or 0
	playerData.BirthrightCharge = playerData.BirthrightCharge or 0

	if playerData.IsHoping == true then
		resetCharges(player)
	else
		playerData.MoveBrCharge = playerData.BirthrightCharge
		playerData.MoveCharge = playerData.ImpulseCharge
	end	
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, mod.EdithPlayerUpdate)

---@param player EntityPlayer
function mod:RenderTaintedEdith(player)
	if not funcs.IsEdith(player, true) then return end

	local arrow = mod.GetTaintedArrow(player)
	local playerData = funcs.GetData(player)
	local HopVec = playerData.HopVector
	local isShooting = mod:IsPlayerShooting(player)
	local HopVectorDegree = mod.vectorToAngle(HopVec)
	local faceDirection = funcs.Switch(HopVectorDegree, tables.DegreesToDirection, Direction.DOWN)
	local chosenDir = Direction.DOWN	

	if playerData.IsHoping or (arrow and arrow.Visible == true) then
		chosenDir = faceDirection
	end

	if not isShooting then
		player:SetHeadDirection(chosenDir, 1, true)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, mod.RenderTaintedEdith)

local function spawnFireJet(player, radius, damage)
	local playerData = funcs.GetData(player)
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) then return end

	for _, enemy in ipairs(Isaac.FindInRadius(player.Position, radius, EntityPartition.ENEMY)) do
		local BirthrightFire = Isaac.Spawn(
			EntityType.ENTITY_EFFECT,
			EffectVariant.FIRE_JET,
			0,
			enemy.Position,
			Vector.Zero,
			player
		):ToEffect()
		local mult = (playerData.BirthrightCharge / 100) or 1
		
		BirthrightFire.CollisionDamage = damage * mult
	end
end

function mod:OnNewRoom()
	local players = PlayerManager.GetPlayers()
	
	for _, player in ipairs(players) do
		if not funcs.IsEdith(player, true) then return end
		mod:ChangeColor(player, _, _, _, 1)
		stopTEdithHops(player, 0, true, true)
		mod:RemoveTaintedEdithTargetArrow(player)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.OnNewRoom)

---comment
---@param player EntityPlayer
function mod:EdithLanding(player)	
	local playerData = funcs.GetData(player)
	local tearRange = player.TearRange / 40
	local damageBase = 3.5
	local DamageStat = player.Damage
	
	playerData.HopParams = {
		Radius = math.min((30 + (tearRange - 9)), 35),
		Knockback = math.min(50, (7.7 + DamageStat ^ 1.2)) * player.ShotSpeed,
		Damage = ((damageBase + DamageStat) / 2.5) * (playerData.MoveCharge + playerData.BirthrightCharge) / 100,
	}
	
	local HopParams = playerData.HopParams

	player:SpawnWaterImpactEffects(player.Position, Vector(1, 1), 1)	
	funcs.FeedbackMan(player, hopSounds, misc.BurnedSaltColor)
	
	mod:TaintedEdithStomp(player, HopParams.Radius, HopParams.Damage, HopParams.Knockback, false)	
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, mod.EdithLanding, jumpParams.TEdithHop)

function mod:OnTaintedShootTears(tear)
	local player = mod:GetPlayerFromTear(tear)
	if not player then return end
	if not funcs.IsEdith(player, true) then return end

	mod.ForceSaltTear(tear, true)
	mod.ShootTearToNearestEnemy(tear, player)
end
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, mod.OnTaintedShootTears)

---comment
---@return Entity[]
local function getParriableEnemies()
	local roomEntities = Isaac.GetRoomEntities()
	local enemies = {}
	for _, ent in ipairs(roomEntities) do
		if ent:IsActiveEnemy() and ent:IsVulnerableEnemy() or ent:ToProjectile() then
			table.insert(enemies, ent)
		end
	end
	return enemies
end

local damageBase = 13.5
---@param player EntityPlayer
---@param data JumpData
function mod:EdithParryJump(player, data)
	local DamageStat = player.Damage 
	local rawFormula = ((damageBase + DamageStat) / 1.5) 
	local isenemy = false
	local playerData = funcs.GetData(player)
	local ParryEnts = getParriableEnemies()
	local playerPos = player.Position

	for _, ent in ipairs(ParryEnts) do 
		local entPos = ent.Position
		local distance = entPos:Distance(playerPos)
		local proj = ent:ToProjectile()
		local newVelocity = ((playerPos - entPos) * -1):Resized(20)

		if distance <= misc.ImpreciseParryRadius then
			ent:AddKnockback(EntityRef(player), newVelocity, 5, true)
			if ent:IsActiveEnemy() and ent:IsVulnerableEnemy() then
				ent:AddConfusion(EntityRef(player), 90, false)
			end
		end

		if distance <= misc.PerfectParryRadius then 
			playerData.ParryCounter = 15
			playerData.ImpulseCharge = playerData.ImpulseCharge + 20
			player:SetMinDamageCooldown(20)
			isenemy = true

			if proj then
				local spawner = proj.Parent or proj.SpawnerEntity
				local targetPos = spawner and spawner.Position or proj.Position
				local newVelocity = ((playerPos - targetPos) * -1):Resized(25)

				proj.FallingAccel = -0.1
				proj.FallingSpeed = 0
				proj.Height = -23

				proj.ProjectileFlags = proj.ProjectileFlags | ProjectileFlags.HIT_ENEMIES | ProjectileFlags.CANT_HIT_PLAYER

				ent:AddKnockback(EntityRef(player), newVelocity, 5, true)
			else
				ent:TakeDamage(rawFormula, 0, EntityRef(player), 0)
				if ent.HitPoints <= rawFormula then
					sfx:Play(SoundEffect.SOUND_MEATY_DEATHS)
					game:ShakeScreen(20)
				end
			end
		end
	end

	playerData.ParryCounter = isenemy and 10 or 20

	local tableRef = (isenemy and parryJumpSounds) or hopSounds
	funcs.FeedbackMan(player, tableRef, misc.BurnedSaltColor, isenemy)
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, mod.EdithParryJump, jumpParams.TEdithJump)

function mod:TaintedEdithDamageManager(player)
	local playerData = funcs.GetData(player)
	if not funcs.IsEdith(player, false) then return end

	if playerData.IsHoping == true then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, mod.TaintedEdithDamageManager)

function mod:HudBarRender(player)
	if not funcs.IsEdith(player, true) then return end

	local room = game:GetRoom()
	local playerpos = room:WorldToScreenPosition(player.Position)
	local playerData = funcs.GetData(player)
	local dashCharge = playerData.ImpulseCharge
	local dashBRCharge = playerData.BirthrightCharge
	local offset = misc.ChargeBarcenterVector

	-- mod.RenderAreaOfEffect(player, misc.ImpreciseParryRadius, Color(0, 0, 1))
	-- mod.RenderAreaOfEffect(player, misc.PerfectParryRadius, Color(1, 0, 0))

	if not playerData.ChargeBar then
		playerData.ChargeBar = Sprite("gfx/TEdithChargebar.anm2", true)
	end

	if not playerData.BRChargeBar then
		playerData.BRChargeBar = Sprite("gfx/TEdithBRChargebar.anm2", true)
	end

	local chargeBar, BRChargebar = playerData.ChargeBar, playerData.BRChargeBar
	
	if player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and not BRChargebar:IsFinished("Disappear") then
		offset = misc.ChargeBarleftVector
	end

	HudHelper.RenderChargeBar(chargeBar, dashCharge, 100, playerpos + offset)
	HudHelper.RenderChargeBar(BRChargebar, dashBRCharge, 100, playerpos + misc.ChargeBarrightVector)
end
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_RENDER, mod.HudBarRender)