local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local misc = enums.Misc
local utils = enums.Utils
local sfx = utils.SFX
local game = utils.Game
local sounds = enums.SoundEffect
local tables = enums.Tables
local jumpFlags = tables.JumpFlags
local BurntHood = {}
local funcs = {
    GetData = mod.CustomDataWrapper.getData,
    FeedbackMan = mod.LandFeedbackManager
}

local backdropColors = tables.BackdropColors
function BurntHood:InitTaintedEdithJump(player)
	local room = game:GetRoom()
	local jumpHeight = 8
	local jumpSpeed = 2.5
	local isChap4 = mod:isChap4()
	local BackDrop = room:GetBackdropType()
	local hasWater = room:HasWater()
	local variant = hasWater and EffectVariant.BIG_SPLASH or (isChap4 and EffectVariant.POOF02 or EffectVariant.POOF01)
	local subType = hasWater and 1 or (isChap4 and 66 or 1)
	
	sfx:Play(SoundEffect.SOUND_SHELLGAME)
	
	local DustCloud = Isaac.Spawn(
		EntityType.ENTITY_EFFECT, 
		variant, 
		subType, 
		player.Position, 
		Vector.Zero, 
		player
	)

	local color = Color(1, 1, 1)
	local switch = {
		[EffectVariant.BIG_SPLASH] = function()
			color = backdropColors[BackDrop] or Color(0.7, 0.75, 1)
		end,
		[EffectVariant.POOF02] = function()
			color = backdropColors[BackDrop] or Color(1, 0, 0)
		end,
		[EffectVariant.POOF01] = function()
			if hasWater then
				color = backdropColors[BackDrop]
			end
		end
	}
	switch[variant]()

	DustCloud.SpriteScale = DustCloud.SpriteScale * player.SpriteScale.X
	DustCloud.DepthOffset = -100
	DustCloud:SetColor(color, -1, 100, false, false)
	DustCloud:GetSprite().PlaybackSpeed = hasWater and 1.3 or 2	

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
function BurntHood:OnUse(_, _, player)
    if JumpLib:GetData(player).Jumping then return end
    BurntHood:InitTaintedEdithJump(player)
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, BurntHood.OnUse,items.COLLECTIBLE_BURNT_HOOD)

local damageBase = 13.5
---@param player EntityPlayer
function BurntHood:ParryJump(player)
	local rawFormula = ((damageBase + player.Damage ) / 1.5) 
	local isenemy = false
	local playerPos = player.Position
	local capsule = Capsule(player.Position, Vector.One, 0, misc.PerfectParryRadius)
	local capsuleTwo = Capsule(player.Position, Vector.One, 0, misc.ImpreciseParryRadius)	
	local proj
	local spawner
	local targetPos
	local newVelocity

	for _, ent in pairs(Isaac.FindInCapsule(capsuleTwo, misc.ParryPartitions)) do
		if mod.IsEnemy(ent) then
			ent:AddConfusion(EntityRef(player), 90, false)
		end
		mod.TriggerPush(ent, player, 20, 5, true)
	end

	for _, ent in pairs(Isaac.FindInCapsule(capsule, misc.ParryPartitions)) do
		proj = ent:ToProjectile()
		if proj then
			spawner = proj.Parent or proj.SpawnerEntity
			targetPos = spawner and spawner.Position or proj.Position
			newVelocity = ((playerPos - targetPos) * -1):Resized(25)

			proj.FallingAccel = -0.1
			proj.FallingSpeed = 0
			proj.Height = -23
			proj:AddProjectileFlags(misc.NewProjectilFlags)

			ent:AddKnockback(EntityRef(player), newVelocity, 5, true)
		else
			ent:TakeDamage(rawFormula, 0, EntityRef(player), 0)
			if ent.HitPoints <= rawFormula then
				sfx:Play(SoundEffect.SOUND_MEATY_DEATHS)
				game:ShakeScreen(20)
				player:AddActiveCharge(90, ActiveSlot.SLOT_PRIMARY, true, false, true)
			end
		end
		isenemy = true
		player:SetMinDamageCooldown(20)
	end

	funcs.GetData(player).ParryCounter = isenemy and 10 or 20

	if isenemy == true then
		game:MakeShockwave(playerPos, 0.035, 0.025, 2)
	end

	funcs.FeedbackMan(player, parryJumpSounds, Color(1, 1, 1, 0), isenemy)
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, BurntHood.ParryJump, {
    tag = "BrokenHoodParry"
})