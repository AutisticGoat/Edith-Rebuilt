local mod = edithMod
local enums = mod.Enums
local utils = enums.Utils
local rng = utils.RNG
local game = utils.Game
local sfx = utils.SFX
local tables = enums.Tables

local jumpFlags = tables.JumpFlags
local jumpTags = tables.JumpTags

function mod:TaintedEdithInit(player)
	if not edithMod:IsEdith(player, true) then return end

	local playerSprite = player:GetSprite()

	if playerSprite:GetFilename() ~= "gfx/EdithTaintedAnim.anm2" and not player:IsCoopGhost() then
		playerSprite:Load("gfx/EdithTaintedAnim.anm2", true)
		playerSprite:Update()
	end
		
	edithMod.ForceCharacterCostume(player, edithMod.Enums.PlayerType.PLAYER_EDITH_B, edithMod.Enums.NullItemID.ID_EDITH_B_SCARF)
end
edithMod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, edithMod.TaintedEdithInit)

local function resetCharges(player)
	local playerData = edithMod:GetData(player)
	if playerData.ImpulseCharge then
		playerData.ImpulseCharge = 0
	end
	
	if playerData.BirthrightCharge then
		playerData.BirthrightCharge = 0
	end
end

---comment
---@param player EntityPlayer
---@param cooldown integer
---@param useQuitJump boolean
---@param resetChrg boolean
local function stopTEdithHops(player, cooldown, useQuitJump, resetChrg)
	local playerData = edithMod:GetData(player)
	playerData.IsHoping = false
	player:MultiplyFriction(0.5)
	playerData.HopVector = Vector(0, 0)
	
	cooldown = cooldown or 0
	useQuitJump = useQuitJump or false
	
	if useQuitJump then
		JumpLib:QuitJump(player)
	end
			
	player:SetMinDamageCooldown(cooldown)
	
	if resetChrg == true then
		resetCharges(player)
	end
end

function edithMod:InitTaintedEdithHop(player)
	local playerData = edithMod:GetData(player)
	local jumpHeight = 6.5
	local jumpSpeed = 2.8 * edithMod:Log(playerData.MoveCharge, 100)
	
	local config = {
		Height = jumpHeight,
		Speed = jumpSpeed,
		Tags = jumpTags.TEdithHop,
		Flags = jumpFlags.TEdithHop
	}
	JumpLib:Jump(player, config)
end

local backdropColors = tables.BackdropColors
function edithMod:InitTaintedEdithJump(player)
	local room = game:GetRoom()
	local jumpHeight = 8
	local jumpSpeed = 2.5
	
	local isChap4 = edithMod:isChap4()
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

local hopSounds = {
	[1] = SoundEffect.SOUND_STONE_IMPACT,
	[2] = edithMod.Enums.SoundEffect.SOUND_YIPPEE,
	[3] = edithMod.Enums.SoundEffect.SOUND_SPRING,
}

local parryJumpSounds = {
	[1] = SoundEffect.SOUND_STONE_IMPACT,
	[2] = edithMod.Enums.SoundEffect.SOUND_PIZZA_TAUNT,
	[3] = edithMod.Enums.SoundEffect.SOUND_VINE_BOOM,
	[4] = edithMod.Enums.SoundEffect.SOUND_FART_REVERB,
	[5] = edithMod.Enums.SoundEffect.SOUND_SOLARIAN,
}

local burntSaltColor = Color(0.3, 0.3, 0.3, 1)
local function TaintedEdithFeedBackManager(player, isJump, playParrySound)
	local rng = edithMod.Enums.Utils.RNG	
	local room = game:GetRoom()
	local BackDrop = room:GetBackdropType()
	
	isJump = isJump or false
	playParrySound = playParrySound or false

	local saveData = edithMod.saveManager.GetDeadSeaScrollsSave()
	local tEdithdata = saveData.TEdithData

	local pitch = rng:RandomInt(90, 110) * 0.01

	local stompVolume = tEdithdata.taintedStompVolume	
	local volume = isJump and 2 or 1
	local volumeAdjust = (stompVolume / 100) ^ 2
	
	local realVolume = volumeAdjust * volume
		
	local chosenSound = edithMod:isChap4() and SoundEffect.SOUND_MEATY_DEATHS or ((isJump and playParrySound)and parryJumpSounds[tEdithdata.TaintedParrySound] or hopSounds[tEdithdata.TaintedHopSound]) 
	
	sfx:Play(chosenSound, realVolume, 0, false, pitch, 0)
	local hasWater = room:HasWater()

	local Variant = hasWater and EffectVariant.BIG_SPLASH or EffectVariant.POOF02
	local SubType = hasWater and 2 or (edithMod:isChap4() and 3 or 1)

	local stompGFX = Isaac.Spawn(
		EntityType.ENTITY_EFFECT, 
		Variant, 
		SubType, 
		player.Position, 
		Vector.Zero, 
		player
	):ToEffect()

	if not stompGFX then return end
	local scaleMut = hasWater and (isJump and 0.8 or 0.5) or (isJump and 0.6 or 0.35)
	
	stompGFX.SpriteScale = stompGFX.SpriteScale * scaleMut

	if room:HasWater() then
		sfx:Play(edithMod.Enums.SoundEffect.SOUND_WATERSPLASH, (volume - 0.5) * volumeAdjust, 0, false, 1.5 + (rng:RandomFloat()), 0)
	end

	local color = Color.Default

	local switch = {
		[EffectVariant.BIG_SPLASH] = function()
			color = backdropColors[BackDrop] or Color(0.7, 0.75, 1)
		end,
		[EffectVariant.POOF02] = function()
			color = BackDrop == BackdropType.DROSS and Color.Default or backdropColors[BackDrop] 
		end,
	}

	switch[Variant]()

	if color == nil then
		color = Color.Default
	end

	stompGFX:SetColor(color, -1, 100, false, false)
	edithMod:SpawnSaltGib(player, isJump and 6 or 1 , burntSaltColor, 5, "StompGib")
end

function edithMod:TaintedEdithUpdate(player)
	if not edithMod:IsEdith(player, true) then return end

	local playerData = edithMod:GetData(player)
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
	playerData.ImpulseCharge = playerData.ImpulseCharge or 0

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
	
	local target 

	if edithMod:IsEdithTargetMoving(player) then
		target = edithMod:SpawnTaintedArrow(player)
	end

	local HopVec = playerData.HopVector

	if target then
		local posDif = target.Position - player.Position
		local posDifLenght = posDif:Length()	
		local posDifNormal = posDif:Normalized()
		local maxDist = 2.5

		if target.FrameCount < 1 and playerData.IsHoping == true then
			stopTEdithHops(player, 20, true, true)
		end

		target.Velocity = NormalizedMovementVector:Resized(10)
		if posDifLenght >= maxDist then
			target.Velocity = target.Velocity - (posDifNormal * (posDifLenght / (maxDist)))
		end

		playerData.HopVector = posDif:Normalized()		
							
		local dir = edithMod:vectorToAngle(HopVec)	
		local faceDirection = tables.DegreesToDirection[dir]

		player:SetHeadDirection(faceDirection, 2, true)
				
		local baseTearsStat = 2.73
		local tearMult = edithMod:GetTPS(player) / baseTearsStat							
		local jumpData = JumpLib:GetData(player)
		local isJumping = jumpData.Jumping
		local chargeAdd = 7 * edithMod:exponentialFunction(tearMult, 1, 1.5)
		local hasBirthright = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)

		if playerData.IsHoping == false and isJumping == false then
			playerData.ImpulseCharge = math.min(playerData.ImpulseCharge + chargeAdd, 100)

			if hasBirthright and playerData.ImpulseCharge >= 100 then
				playerData.BirthrightCharge = math.min(playerData.BirthrightCharge + (chargeAdd * 0.6), 100)
			end
		end
	else
		if playerData.MoveCharge >= 10 then
			if playerData.IsHoping == true then
				player.Velocity = (HopVec) * (6 + (player.MoveSpeed - 1)) * (playerData.MoveCharge / 100)
			end
					
			if not (HopVec.X == 0 and HopVec.Y == 0) then
				if not isJumping then
					edithMod:InitTaintedEdithHop(player)
				end
				playerData.IsHoping = true
			end
		else
			resetCharges(player)
		end
		edithMod:RemoveTaintedEdithTargetArrow(player)
	end	

	if player:CollidesWithGrid() then
		if not isJumping then
			stopTEdithHops(player, 20, true, playerData.TaintedEdithTarget == nil)
		end
	end
end
edithMod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, edithMod.TaintedEdithUpdate)

function edithMod:EdithPlayerUpdate(player)
	local playerData = edithMod:GetData(player)

	if edithMod:IsKeyStompTriggered(player) then
		if playerData.ParryCounter == 0 and isTaintedEdithJump(player) == false then
			stopTEdithHops(player, 0, true, true)
			edithMod:InitTaintedEdithJump(player)
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
edithMod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, edithMod.EdithPlayerUpdate)

function edithMod:RenderTaintedEdith(player)
	if not edithMod:IsEdith(player, true) then return end

	local playerData = edithMod:GetData(player)
	local HopVec = playerData.HopVector
	local isShooting = edithMod:IsPlayerShooting(player)
	local HopVectorDegree = edithMod:vectorToAngle(HopVec)
	local shootDegree = edithMod:vectorToAngle(player:GetShootingInput()) 
	local faceDirection = tables.DegreesToDirection[HopVectorDegree]
	local shootDirection = tables.DegreesToDirection[shootDegree] 
		
	local defaultFaceDir = Direction.DOWN
	
	local chosenDir 
	
	if isShooting then
		chosenDir = shootDirection
	else
		chosenDir = faceDirection
		if not playerData.TaintedEdithTarget then
			if not playerData.IsHoping then
				chosenDir = defaultFaceDir
			end
		end
	end
	player:SetHeadDirection(chosenDir, 2, true)
end
edithMod:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, edithMod.RenderTaintedEdith)

local function spawnFireJet(player, radius, damage)
	local playerData = edithMod:GetData(player)
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
		local baseDamage = damage 
		
		BirthrightFire.CollisionDamage = baseDamage * mult
	end
end

function edithMod:OnNewRoom()
	local players = PlayerManager.GetPlayers()
	
	for _, player in ipairs(players) do
		if not edithMod:IsEdith(player, true) then return end
		edithMod:ChangeColor(player, _, _, _, 1)
		stopTEdithHops(player, 0, true, true)
		edithMod:RemoveTaintedEdithTargetArrow(player)
	end
end
edithMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, edithMod.OnNewRoom)

---comment
---@param player EntityPlayer
function mod:EdithLanding(player)	
	local playerData = edithMod:GetData(player)
	local tearRange = player.TearRange / 40
	local damageBase = 3.5
	local DamageStat = player.Damage
	
	print(player.Damage)

	playerData.HopParams = {
		Radius = math.min((30 + (tearRange - 9)), 35),
		Knockback = math.min(50, (7.7 + DamageStat ^ 1.2)) * player.ShotSpeed,
		Damage = ((damageBase + DamageStat) / 2.5) * (playerData.MoveCharge + playerData.BirthrightCharge) / 100,
	}
	
	local HopParams = playerData.HopParams

	player:SpawnWaterImpactEffects(player.Position, Vector(1, 1), 1)	
	TaintedEdithFeedBackManager(player, false)
	
	edithMod:TaintedEdithStomp(player, HopParams.Radius, HopParams.Damage, HopParams.Knockback, false)	
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, mod.EdithLanding, {
    tag = jumpTags.TEdithHop,
})

function edithMod:OnTaintedShootTears(tear)
	local player = edithMod:GetPlayerFromTear(tear)
	if not player then return end
	if not edithMod:IsEdith(player, true) then return end

	edithMod.ForceSaltTear(tear, true)
end
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, edithMod.OnTaintedShootTears)

---comment
---@return Entity[]
local function getParriableenemies()
	local roomEntities = Isaac.GetRoomEntities()
	local enemies = {}
	for _, ent in ipairs(roomEntities) do
		if (ent:IsActiveEnemy() and ent:IsVulnerableEnemy() or ent:ToProjectile()) then
			table.insert(enemies, ent)
		end
	end
	return enemies
end

local perfectParryRadius = 20
local impreciseParryRadius = 45

---comment
---@param player EntityPlayer
---@param data JumpData
function mod:EdithParryJump(player, data)
	local damageBase = 13.5
	local DamageStat = player.Damage 
	local rawFormula = ((damageBase + DamageStat) / 1.8) 
	local isenemy = false
	local playerData = edithMod:GetData(player)

	playerData.ParryCounter = 20

	local ParryEnts = getParriableenemies()
	local playerPos = player.Position

	for _, ent in ipairs(ParryEnts) do 
		local entPos = ent.Position
		local distance = entPos:Distance(playerPos)
		if distance <= impreciseParryRadius then
			local newVelocity = (playerPos - entPos):Resized(50)
			local proj = ent:ToProjectile()


			if proj then
				newVelocity = (playerPos - ent.SpawnerEntity.Position):Resized(30)
				print(proj.Damage)
			end

			ent:AddKnockback(EntityRef(player), newVelocity, 15, true)

			if distance <= perfectParryRadius then
				playerData.ParryCounter = 15
				ent:TakeDamage(rawFormula, 0, EntityRef(player), 0)
				player:SetMinDamageCooldown(20)
				isenemy = true
				if proj then
					proj.ProjectileFlags = proj.ProjectileFlags | ProjectileFlags.HIT_ENEMIES | ProjectileFlags.CANT_HIT_PLAYER
				end
			end
		end
	end
	TaintedEdithFeedBackManager(player, true, isenemy)
end	
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, mod.EdithParryJump, {
	tag = jumpTags.TEdithJump,
})

function edithMod:TaintedEdithDamageManager(player, damage, flags, source, cooldown)
	local playerData = edithMod:GetData(player)
	if not edithMod:IsEdith(player, false) then return end

	if playerData.IsHoping == true then
		return false
	end
end
edithMod:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, edithMod.TaintedEdithDamageManager)

local leftVector = Vector(-8, 10)
local centerVector = Vector(0, 10)
local rightVector = Vector(8, 10)

local tEdithChargeBar = Sprite()
local tEdithBrightChargebar = Sprite()

tEdithChargeBar:Load("gfx/TEdithChargebar.anm2", true)
tEdithBrightChargebar:Load("gfx/TEdithBRChargebar.anm2", true)

function mod:HudBarRender(player)
	if not edithMod:IsEdith(player, true) then return end

	local room = game:GetRoom()
	local playerpos = room:WorldToScreenPosition(player.Position)
	local playerData = edithMod:GetData(player)
	local dashCharge = playerData.ImpulseCharge
	local dashBRCharge = playerData.BirthrightCharge
	local offset = centerVector

	
	if player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and (playerData.MoveBrCharge > 0 and playerData.MoveCharge ~= 0) or (isTaintedEdithJump(player)) then
		offset = leftVector
	end

	HudHelper.RenderChargeBar(tEdithChargeBar, dashCharge, 100, playerpos + offset)
	HudHelper.RenderChargeBar(tEdithBrightChargebar, dashBRCharge, 100, playerpos + rightVector)
end
edithMod:AddCallback(ModCallbacks.MC_PRE_PLAYER_RENDER, mod.HudBarRender)