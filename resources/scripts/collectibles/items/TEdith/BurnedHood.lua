local mod = edithMod
local enums = mod.Enums
local items = enums.CollectibleType
local misc = enums.Misc
local utils = enums.Utils
local sfx = utils.SFX
local game = utils.Game
local sounds = enums.SoundEffect
local tables = enums.Tables
local jumpFlags = tables.JumpFlags
local BrokenHood = {}
local funcs = {
    GetData = mod.GetData,
    FeedbackMan = mod.LandFeedbackManager
}

local backdropColors = tables.BackdropColors
function BrokenHood:InitTaintedEdithJump(player)
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
	local color = Color(1, 1, 1)

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

	DustCloud.SpriteScale = DustCloud.SpriteScale * player.SpriteScale.X
	DustCloud.DepthOffset = -100
	DustCloud:SetColor(color, -1, 100, false, false)

	local config = {
		Height = jumpHeight,
		Speed = jumpSpeed,
		Tags = "BrokenHoodParry",
		Flags = jumpFlags.TEdithJump
	}
	JumpLib:Jump(player, config)
end

local parryJumpSounds = {
	[1] = SoundEffect.SOUND_ROCK_CRUMBLE,
	[2] = sounds.SOUND_PIZZA_TAUNT,
	[3] = sounds.SOUND_VINE_BOOM,
	[4] = sounds.SOUND_FART_REVERB,
	[5] = sounds.SOUND_SOLARIAN,
	[6] = sounds.SOUND_MACHINE,
	[7] = sounds.SOUND_MECHANIC,
	[8] = sounds.SOUND_KNIGHT,
}

---comment
---@param player EntityPlayer
function BrokenHood:OnUse(_, _, player)
    if JumpLib:GetData(player).Jumping then return end
    BrokenHood:InitTaintedEdithJump(player)
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, BrokenHood.OnUse,items.COLLECTIBLE_BURNED_HOOD)

local damageBase = 13.5
---@param player EntityPlayer
---@param data JumpData
function BrokenHood:ParryJump(player, data)
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
	local BirthrightMult = hasBirthright and 1.2 or 1
	local DamageFormula = rawFormula * BirthrightMult

	for _, ent in pairs(ImpreciseParryEnts) do
		local entPos = ent.Position
		local newVelocity = ((playerPos - entPos) * -1):Resized(20)

		if ent:IsActiveEnemy() and ent:IsVulnerableEnemy() then
			ent:AddConfusion(EntityRef(player), 90, false)
		end

		ent:AddKnockback(EntityRef(player), newVelocity, 5, true)
	end

	for _, ent in pairs(PerfectParryEnts) do
		local proj = ent:ToProjectile()

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
			ent:TakeDamage(DamageFormula, 0, EntityRef(player), 0)
			if ent.HitPoints <= DamageFormula then
				sfx:Play(SoundEffect.SOUND_MEATY_DEATHS)
				game:ShakeScreen(20)
			end
		end
		isenemy = true
		player:SetMinDamageCooldown(20)
	end

	playerData.ParryCounter = isenemy and 10 or 20

	if isenemy == true then
		game:MakeShockwave(playerPos, 0.035, 0.025, 2)
		playerData.ImpulseCharge = playerData.ImpulseCharge + 20
	end

	local lasers = Isaac.FindByType(EntityType.ENTITY_LASER) ---@type EntityLaser[]

	for _, laser in ipairs(lasers) do
		local laserData = mod.GetData(laser)
		local LaserCapsule = Capsule(laser.Position, laserData.EndPoint, laser.Size)
		local DebugShape = DebugRenderer.Get(1, true)    
		DebugShape:Capsule(LaserCapsule)

		for _, player in ipairs(Isaac.FindInCapsule(LaserCapsule, EntityPartition.PLAYER)) do
			local degree = mod.vectorToAngle((player.Position - laser.Position) * -1)
			local divineShield = Isaac.Spawn(
				EntityType.ENTITY_EFFECT,
				EffectVariant.DIVINE_INTERVENTION,
				0,
				playerPos,
				Vector.Zero,
				player
			):ToEffect()

			if not divineShield then return end	

			local shieldData = mod.GetData(divineShield)
			shieldData.ParryShield = true 
			shieldData.StaticPos = player.Position
			divineShield.Rotation = degree
			divineShield.Timeout = 1			
		end
	end

	funcs.FeedbackMan(player, parryJumpSounds, Color(1, 1, 1, 0), isenemy)
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, BrokenHood.ParryJump, {
    tag = "BrokenHoodParry"
})