---@diagnostic disable: undefined-global, param-type-mismatch
local mod = EdithRebuilt
local enums = mod.Enums
local utils = enums.Utils
local game = utils.Game
local sfx = utils.SFX
local misc = enums.Misc
local ConfigDataTypes = enums.ConfigDataTypes
local tables = enums.Tables
local sounds = enums.SoundEffect
local callbacks = enums.Callbacks
local status = enums.EdithStatusEffects
local data = mod.DataHolder.GetEntityData
local Math = require("resources.scripts.functions.Maths")
local Helpers = require("resources.scripts.functions.Helpers")
local modRNG = require("resources.scripts.functions.RNG")
local Player = require("resources.scripts.functions.Player")
local Edith  = require("resources.scripts.functions.Edith")
local StatusEffect = require("resources.scripts.functions.StatusEffects")
local Land = {}

local damageFlags = DamageFlag.DAMAGE_CRUSH | DamageFlag.DAMAGE_IGNORE_ARMOR

---@param ent Entity
---@param dealEnt Entity
---@param damage number
---@param knockback number
function Land.LandDamage(ent, dealEnt, damage, knockback)	
	if not Helpers.IsEnemy(ent) then return end

	ent:TakeDamage(damage, damageFlags, EntityRef(dealEnt), 0)
	Helpers.TriggerPush(ent, dealEnt, knockback)
end

local LandSounds = {
	Edith = {
		[1] = SoundEffect.SOUND_STONE_IMPACT, 
		[2] = sounds.SOUND_EDITH_STOMP,
		[3] = sounds.SOUND_FART_REVERB,
		[4] = sounds.SOUND_VINE_BOOM,
	},
	TEdith = {
		Hop = {
			[1] = SoundEffect.SOUND_STONE_IMPACT,
			[2] = sounds.SOUND_YIPPEE,
			[3] = sounds.SOUND_SPRING,
		},
		Parry = {
			[1] = SoundEffect.SOUND_ROCK_CRUMBLE,
			[2] = sounds.SOUND_PIZZA_TAUNT,
			[3] = sounds.SOUND_VINE_BOOM,
			[4] = sounds.SOUND_FART_REVERB,
			[5] = sounds.SOUND_SOLARIAN,
			[6] = sounds.SOUND_MACHINE,
			[7] = sounds.SOUND_MECHANIC,
			[8] = sounds.SOUND_KNIGHT,
			[9] = sounds.SOUND_BLOQUEO,
			[10] = sounds.SOUND_NAUTRASH,
			[11] = sounds.SOUND_HAWK_TUAH,
		}
	}
}

---@param tainted boolean
---@param isParryLand? boolean
---@return table
function Land.GetLandSoundTable(tainted, isParryLand)
	local TEdithSounds = LandSounds.TEdith
	return tainted and (isParryLand and TEdithSounds.Parry or TEdithSounds.Hop) or LandSounds.Edith
end

---@param ent Entity
---@param player EntityPlayer
function Land.AddExtraGore(ent, player)
	local enabledExtraGore

	if Player.IsEdith(player, false) then
		enabledExtraGore = Helpers.GetConfigData(ConfigDataTypes.EDITH).EnableExtraGore
	elseif Player.IsEdith(player, true) then
		enabledExtraGore = Helpers.GetConfigData(ConfigDataTypes.TEDITH).EnableExtraGore
	end

	if not enabledExtraGore then return end
	if not ent:ToNPC() then return end

	ent:AddEntityFlags(EntityFlag.FLAG_EXTRA_GORE)
	ent:MakeBloodPoof(nil, nil, 0.5)
	sfx:Play(SoundEffect.SOUND_DEATH_BURST_LARGE)
end

local KeyRequiredChests = {
	[PickupVariant.PICKUP_LOCKEDCHEST] = true,
	[PickupVariant.PICKUP_ETERNALCHEST] = true,
	[PickupVariant.PICKUP_OLDCHEST] = true,
	[PickupVariant.PICKUP_MEGACHEST] = true,
}

local Chests = {
	[PickupVariant.PICKUP_CHEST] = true,
	[PickupVariant.PICKUP_BOMBCHEST] = true,
	[PickupVariant.PICKUP_SPIKEDCHEST] = true,
	[PickupVariant.PICKUP_ETERNALCHEST] = true,
	[PickupVariant.PICKUP_MIMICCHEST] = true,
	[PickupVariant.PICKUP_OLDCHEST] = true,
	[PickupVariant.PICKUP_WOODENCHEST] = true,
	[PickupVariant.PICKUP_MEGACHEST] = true,
	[PickupVariant.PICKUP_HAUNTEDCHEST] = true,
	[PickupVariant.PICKUP_LOCKEDCHEST] = true,
	[PickupVariant.PICKUP_REDCHEST] = true
}

---@param pickup EntityPickup
---@return boolean
function IsKeyRequiredChest(pickup)
	return Helpers.When(pickup.Variant, KeyRequiredChests, false)
end

---@param pickup EntityPickup
---@return boolean
local function IsChest(pickup)
	return Helpers.When(pickup.Variant, Chests, false)
end

---@param player EntityPlayer
---@return boolean
local function CanUseKey(player)
	return (player:GetNumKeys() > 0 or player:HasGoldenKey())
end

---@param pickup EntityPickup
local function MegaChestManager(player, pickup)
	if not CanUseKey(player) then return end
	if pickup.SubType == 0 then return end
	local sprite = pickup:GetSprite()
	sprite:Play("Idle")

	if not sprite:IsPlaying("UseKey") or sprite:IsFinished("UseKey") then
		sprite:Play("UseKey")
	end

	player:TryUseKey()
end

local NonTriggerAnimPickupVar = {
	[PickupVariant.PICKUP_COLLECTIBLE] = true,
	[PickupVariant.PICKUP_TRINKET] = true,
	[PickupVariant.PICKUP_BROKEN_SHOVEL] = true,
	[PickupVariant.PICKUP_SHOPITEM] = true,
	[PickupVariant.PICKUP_PILL] = true,
	[PickupVariant.PICKUP_TAROTCARD] = true,
	[PickupVariant.PICKUP_LIL_BATTERY] = true,
	[PickupVariant.PICKUP_THROWABLEBOMB] = true,
	[PickupVariant.PICKUP_BED] = true,
	[PickupVariant.PICKUP_MOMSCHEST] = true,
	[PickupVariant.PICKUP_TROPHY] = true,
}

---@param player EntityPlayer
---@param pickup EntityPickup
function Land.PickupManager(player, pickup)
	local room = game:GetRoom()
	local IsStopAnimPickup = Helpers.When(pickup.Variant, NonTriggerAnimPickupVar, false)
	local IsEternalHeart = (pickup.Variant == PickupVariant.PICKUP_HEART and pickup.SubType == HeartSubType.HEART_ETERNAL)
	local IsMegaChest = (pickup.Variant == PickupVariant.PICKUP_MEGACHEST)

	if (IsStopAnimPickup or IsEternalHeart) then
		player:StopExtraAnimation()
	end

	if not IsChest(pickup) then return end
	if room:GetType() == RoomType.ROOM_CHALLENGE then
		player:StopExtraAnimation()
		pickup.Position = player.Position
		pickup.Velocity = Vector(0, 0)
	elseif IsMegaChest then
		MegaChestManager(player, pickup)
	elseif IsKeyRequiredChest(pickup) then
		if CanUseKey(player) then
			player:TryUseKey()
			pickup:TryOpenChest(player)
		end
	else
		pickup:TryOpenChest()
	end
end

---@param parent EntityPlayer
---@param ent EntityPickup
local function PickupLandHandler(parent, ent)
	local var = ent.Variant
	local pickup = ent:ToPickup() ---@cast pickup EntityPickup

	if not pickup then return end

	local isFlavorTextPickup = Helpers.When(var, tables.BlacklistedPickupVariants, false)
	local IsLuckyPenny = var == PickupVariant.PICKUP_COIN and ent.SubType == CoinSubType.COIN_LUCKYPENNY
	local room = game:GetRoom()
	local IsPickedUp = pickup:GetSprite():IsPlaying("Collect")

	if Helpers.IsVestigeChallenge() then
		Land.PickupManager(parent, pickup)
	end

	if isFlavorTextPickup or IsLuckyPenny or IsPickedUp then return end
	parent:ForceCollide(pickup, true)

	if not Player.IsEdith(parent, false) then return end

	if not (var == PickupVariant.PICKUP_BOMBCHEST and Player.IsEdith(parent, false)) then return end
	pickup:TryOpenChest(parent)

	if room:GetType() == RoomType.ROOM_CHALLENGE then
		Ambush.StartChallenge()
	end
end

---@param parent EntityPlayer
---@param ent EntitySlot
local function SlotLandManager(parent, ent)
	local var = ent.Variant
	local slot = ent:ToSlot() ---@cast slot EntitySlot
	
	if not slot then return end
	
	local TriggerDamageSlots = {
		[SlotVariant.BLOOD_DONATION_MACHINE] = true,
		[SlotVariant.DEVIL_BEGGAR] = true,
		[SlotVariant.CONFESSIONAL] = true,
	}

	if slot:GetState() == SlotState.DESTROYED then return end
	if not Helpers.When(var, TriggerDamageSlots, false) then return end
	parent:ForceCollide(ent, false)
	parent:TakeDamage(1, 0, EntityRef(ent), 0)
end

---@param ent Entity
---@param parent EntityPlayer
---@param knockback number
function Land.HandleEntityInteraction(ent, parent, knockback)
	local var = ent.Variant
    local stompBehavior = {
        [EntityType.ENTITY_TEAR] = function()
            local tear = ent:ToTear()
            if not tear then return end
			if Player.IsEdith(parent, true) then return end

			Helpers.BoostTear(tear, 25, 1.5)
        end,
        [EntityType.ENTITY_FIREPLACE] = function()
            if var == 4 then return end
            ent:Die()
        end,
        [EntityType.ENTITY_FAMILIAR] = function()
            if not Helpers.When(var, tables.PhysicsFamiliar, false) then return end
            Helpers.TriggerPush(ent, parent, knockback)

			local fam = ent:ToFamiliar() 
			if not fam then return end

			if fam.Variant == FamiliarVariant.CUBE_BABY then
				fam:Shoot()
			end
        end,
        [EntityType.ENTITY_BOMB] = function()
			if Player.IsEdith(parent, true) then return end
            Helpers.TriggerPush(ent, parent, knockback)
        end,
        -- [EntityType.ENTITY_PICKUP] = function()
            
        -- end,
		[EntityType.ENTITY_SLOT] = function ()

		end,
        [EntityType.ENTITY_SHOPKEEPER] = function()
			if Player.IsEdith(parent, true) then return end
            ent:Kill()
        end,
        [EntityType.ENTITY_MOVABLE_TNT] = function()
            ent:Kill()
        end,
    }
	Helpers.WhenEval(ent.Type, stompBehavior)
end

---@param parent EntityPlayer
---@param isSalted boolean	
local function EdithBirthcake(parent, isSalted)
	if not (BirthcakeRebaked and parent:HasTrinket(BirthcakeRebaked.Birthcake.ID) and isSalted) then return end
	local BCRRNG = parent:GetTrinketRNG(BirthcakeRebaked.Birthcake.ID)
	for _ = 1, BCRRNG:RandomInt(3, 7) do
		parent:FireTear(parent.Position, RandomVector():Resized(15))
	end
end

---@param parent EntityPlayer
---@param ent Entity
---@param isDefStomp boolean
---@param SaltedTime boolean
local function SaltEnemyManager(parent, ent, isDefStomp, SaltedTime)
	if not isDefStomp then return end
	StatusEffect.SetStatusEffect(status.SALTED, ent, SaltedTime, parent)
	data(ent).SaltType = data(parent).HoodLand and enums.SaltTypes.EDITHS_HOOD		
end

---@param parent EntityPlayer
---@param ent Entity
---@param damage number
---@param TerraMult number
---@param knockback number
local function DamageManager(parent, ent, damage, TerraMult, knockback)
	local FrozenMult = ent:HasEntityFlags(EntityFlag.FLAG_FREEZE) and 1.2 or 1 
	damage = (damage * FrozenMult) * TerraMult

	local pushMult = StatusEffect.EntHasStatusEffect(ent, status.SALTED) and 2 or 1
	Land.LandDamage(ent, parent, damage, knockback * pushMult)
end

local function EntityInteractHandler(ent, parent, knockback)
	local isSalted = StatusEffect.EntHasStatusEffect(ent, status.SALTED)
	local knockbackMult = isSalted and 1.5 or 1

	Land.HandleEntityInteraction(ent, parent, knockback * knockbackMult)

	if ent.Type == EntityType.ENTITY_STONEY then
		ent:ToNPC().State = NpcState.STATE_SPECIAL
	end
end

local function VestigeUnlockManager()
	local pgd = Isaac.GetPersistentGameData()
	local VestigeAch = enums.Achievements.ACHIEVEMENT_VESTIGE
	if pgd:Unlocked(VestigeAch) then return end

	local saveManager = mod.SaveManager
	local PersistentData = saveManager.GetPersistentSave()

	if not PersistentData then return end

	PersistentData.StompKills = PersistentData.StompKills or 0
	PersistentData.StompKills = PersistentData.StompKills + 1

	if PersistentData.StompKills >= 15 then
		pgd:TryUnlock(VestigeAch)
		PersistentData.StompKills = 0
	end
end

---Custom Edith stomp Behavior
---@param parent EntityPlayer
---@param params EdithJumpStompParams
---@param breakGrid boolean
function Land.EdithStomp(parent, params, breakGrid)
	local isDefStomp = params.IsDefensiveStomp
	local HasTerra = parent:HasCollectible(CollectibleType.COLLECTIBLE_TERRA)
	local TerraRNG = parent:GetCollectibleRNG(CollectibleType.COLLECTIBLE_TERRA)
	local TerraMult = HasTerra and modRNG.RandomFloat(TerraRNG, 0.5, 2) or 1	
	local capsule = Capsule(parent.Position, Vector.One, 0, params.Radius)
	local PickupCapsule = Capsule(parent.Position, Vector.One, 0, 20)
	local SlotCapsule = Capsule(parent.Position, Vector.One, 0, parent.Size)
	local SaltedTime = Math.Round(Math.Clamp(120 * (Player.GetplayerTears(parent) / 2.73), 60, 360))
	local isSalted

	-- DebugRenderer.Get(1, false):Capsule(capsule)

	params.StompedEntities = Isaac.FindInCapsule(capsule)

	if not isDefStomp then
		Isaac.RunCallback(callbacks.OFFENSIVE_STOMP, parent, params)
	end

	for _, ent in ipairs(Isaac.FindInCapsule(PickupCapsule, EntityPartition.PICKUP)) do
		if ent:ToPickup() then
			PickupLandHandler(parent, ent)
		end
	end

	for _, ent in ipairs(Isaac.FindInCapsule(SlotCapsule)) do
		if ent:ToSlot() then
			SlotLandManager(parent, ent)
		end 
	end

	--- Pendiente de reducir
	for _, ent in ipairs(params.StompedEntities) do
		if GetPtrHash(parent) == GetPtrHash(ent) then goto Break end
		EntityInteractHandler(ent, parent, params.Knockback)
		SaltEnemyManager(parent, ent, isDefStomp, SaltedTime)

		if not Helpers.IsEnemy(ent) then goto Break end

		local volume = Math.exp(Player.GetNumTears(parent), 1, 1.4)

		if not params.IsDefensiveStomp then
			Isaac.RunCallback(callbacks.OFFENSIVE_STOMP_HIT, parent, ent, params)
			sfx:Play(SoundEffect.SOUND_MEATY_DEATHS, volume)
		end

		for _ = 1, Player.GetNumTears(parent) do
			DamageManager(parent, ent, params.Damage, TerraMult, params.Knockback)
		end

		if ent.HitPoints > params.Damage then goto Break end
		Isaac.RunCallback(callbacks.OFFENSIVE_STOMP_KILL, parent, ent, params)

		if StatusEffect.EntHasStatusEffect(ent, enums.EdithStatusEffects.SALTED) then
			VestigeUnlockManager()
		end

		EdithBirthcake(parent, isSalted)
		Land.AddExtraGore(ent, parent)
		::Break::
	end

	if breakGrid then
		Helpers.DestroyGrid(parent, params.Radius)
	end
end

---Tainted Edith hop land behavior
---@param parent EntityPlayer
---@param HopParams TEdithHopParryParams
function Land.TaintedEdithHop(parent, HopParams)
	local capsule = Capsule(parent.Position, Vector.One, 0, HopParams.HopRadius)
	local PickupCapsule = Capsule(parent.Position, Vector.One, 0, 20)
	local SlotCapsule = Capsule(parent.Position, Vector.One, 0, parent.Size)
	local Charge = HopParams.HopMoveCharge / 100
	local BRCharge = HopParams.HopMoveBRCharge / 100
	local burnDamage, burnDuration = BRCharge * parent.Damage / 2, math.ceil(BRCharge * 123)
	local PlayerRef = EntityRef(parent)
	local CinderDuration = Helpers.SecondsToFrames(4 * (Charge + BRCharge))

	for _, ent in ipairs(Isaac.FindInCapsule(PickupCapsule)) do
		if ent:ToPickup() then
			PickupLandHandler(parent, ent)
		end
	end

	for _, ent in ipairs(Isaac.FindInCapsule(SlotCapsule)) do
		if ent:ToSlot() then
			SlotLandManager(parent, ent)
		end
	end

	for _, ent in ipairs(Isaac.FindInCapsule(capsule)) do
		Land.HandleEntityInteraction(ent, parent, HopParams.HopKnockback)
		Land.LandDamage(ent, parent, HopParams.HopDamage, HopParams.HopKnockback)
		
		if Helpers.IsEnemy(ent) then			
			StatusEffect.SetStatusEffect(status.CINDER, ent, CinderDuration, parent)
			if BRCharge > 0 then
				ent:AddBurn(PlayerRef, burnDuration, burnDamage)
			end
		end
	end
end

---Function made to adjust landing volumes
---@param Percent number
---@return number
local function GetVolume(Percent)
	return (Percent / 100) ^ 2
end

---@param sound SoundEffect
---@param volume number
---@param IsChap4 boolean
---@param hasWater boolean
local function SfxFeedbackManager(sound, volume, IsChap4, hasWater)
	if isEdithJump and isVestige then
		sound = enums.SoundEffect.SOUND_EDITH_STOMP
	end

	sfx:Play(sound, volume, 0, false)

	if IsChap4 then
		sfx:Play(SoundEffect.SOUND_MEATY_DEATHS, volume - 0.5, 0, false, 1, 0)
	end

	if hasWater then
		sfx:Play(enums.SoundEffect.SOUND_EDITH_STOMP_WATER, volume, 0, false)
	end	
end

---Function for audiovisual feedback of Edith and Tainted Edith landings.
---@param player EntityPlayer
---@param soundTable table Takes a table with sound IDs.
---@param GibColor Color Takes a color for salt gibs spawned on Landing.
---@param IsParryLand? boolean Is used for Tainted Edith's parry land behavior and can be ignored.
function Land.LandFeedbackManager(player, soundTable, GibColor, IsParryLand)
	local saveManager = mod.SaveManager 
	if not saveManager:IsLoaded() then return end
	local menuData = saveManager:GetSettingsSave()
	if not menuData then return end

	--- Pendiente de reducir
	local room = game:GetRoom()
	local BackDrop = room:GetBackdropType()
	local hasWater = room:HasWater()
	local IsChap4 = Helpers.IsChap4()
	local Variant = hasWater and EffectVariant.BIG_SPLASH or EffectVariant.POOF02
	local SubType = hasWater and 2 or (IsChap4 and 3 or 1)
	local backColor = tables.BackdropColors
	local soundPick 
	local size
	local volume 
	local ScreenShakeIntensity
	local gibAmount = 0
	local gibSpeed = 2
	local IsSoulOfEdith = data(player).IsSoulOfEdithJump 
	local IsEdithsHood = data(player).HoodLand
	local IsMortis = Helpers.IsLJMortis()
	local isEdithJump = Player.IsEdith(player, false) or IsSoulOfEdith or IsEdithsHood

	if isEdithJump then
		local isRocketLaunchStomp = data(player).RocketLaunch
		local isDefensive = Edith.GetJumpStompParams(player).IsDefensiveStomp or IsEdithsHood
		local EdithData = Helpers.GetConfigData(ConfigDataTypes.EDITH) ---@cast EdithData EdithData
		size = (IsSoulOfEdith and 0.8 or (isDefensive and 0.6 or 0.7)) * (isRocketLaunchStomp and 1.25 or 1)
		soundPick = EdithData.StompSound
		volume = GetVolume(EdithData.StompVolume) * (isDefensive and 1.5 or 2)
		ScreenShakeIntensity = isDefensive and 6 or (isRocketLaunchStomp and 14 or 10)
		gibAmount = EdithData.DisableSaltGibs and 0 or (isRocketLaunchStomp and 14 or 10)
		gibSpeed = isDefensive and 2 or 3
	else
		local TEdithData = Helpers.GetConfigData(ConfigDataTypes.TEDITH) ---@cast TEdithData TEdithData
		size = IsParryLand and 0.7 or 0.5
		soundPick = IsParryLand and TEdithData.ParrySound or TEdithData.HopSound 
		volume = GetVolume(TEdithData.Volume) * (IsParryLand and 1.5 or 1)
		ScreenShakeIntensity = IsParryLand and 6 or 3
		gibAmount = not TEdithData.DisableSaltGibs and (IsParryLand and 6 or 2) or 0
	end

	local stompGFX = Isaac.Spawn(
		EntityType.ENTITY_EFFECT, 
		Variant, 
		SubType, 
		player.Position, 
		Vector.Zero, 
		player
	)

	local rng = stompGFX:GetDropRNG()
	local RandSize = { X = modRNG.RandomFloat(rng, 0.8, 1), Y = modRNG.RandomFloat(rng, 0.8, 1) }
	local SizeX, SizeY = size * RandSize.X, size * RandSize.Y
	
	if Helpers.GetConfigData(ConfigDataTypes.MISC).EnableShakescreen then
		game:ShakeScreen(ScreenShakeIntensity)
	end

	local defColor = Color(1, 1, 1)
	local color = defColor
	local switch = {
		[EffectVariant.BIG_SPLASH] = function()
			color = Helpers.When(BackDrop, backColor, Color(0.7, 0.75, 1))
		end,
		[EffectVariant.POOF02] = function()
			color = BackDrop == BackdropType.DROSS and defColor or backColor[BackDrop] 
		end,
	}
	
	Helpers.WhenEval(Variant, switch)
	color = color or defColor

	if IsMortis then
		local Colors = {
			[MortisBackdrop.MORGUE] = Color(0, 0, 0, 1, 0.45, 0.5, 0.575),
			[MortisBackdrop.MOIST] = Color(0, 0.8, 0.76, 1, 0, 0, 0),
			[MortisBackdrop.FLESH] = Color(0, 0, 0, 1, 0.55, 0.5, 0.55),
		}
		local newcolor = Helpers.When(Helpers.GetMortisDrop(), Colors, Color.Default)
		color = newcolor
	end

	stompGFX:GetSprite().PlaybackSpeed = 1.3 * modRNG.RandomFloat(rng, 1, 1.5)
	stompGFX.SpriteScale = Vector(SizeX, SizeY) * player.SpriteScale.X
	stompGFX.Color = color

	GibColor = GibColor or defColor

	if gibAmount > 0 then	
		Helpers.SpawnSaltGib(player, gibAmount, gibSpeed, GibColor)
	end

	local sound = Helpers.When(soundPick, soundTable, 1)

	SfxFeedbackManager(sound, volume, IsChap4, hasWater)
end

---@param player EntityPlayer
---@param enemyTable Entity[]
---@param knockback number
---@param height number
---@param speed number
function Land.TriggerLandenemyJump(player, enemyTable, knockback, height, speed)
	for _, ent in ipairs(enemyTable) do
		if not Helpers.IsEnemy(ent) then goto continue end

		local PushFactor = Helpers.GetPushFactor(ent)

		Helpers.TriggerJumpPush(ent, player, knockback * 1.5, 5)
		JumpLib:TryJump(ent, {
			Height = height * PushFactor,
			Speed = speed * PushFactor,
			Tags = "EdithRebuilt_EnemyJump",
			-- Flags = JumpLib.Flags.
		})
		::continue::
	end
end

---@param player EntityPlayer
function Land.TriggerFlatStoneMiniJumps(player, height, speed)
	if not player:ToPlayer() then return end

	JumpLib:TryJump(player, {
		Height = height,
		Speed = speed,
		Tags = "EdithRebuilt_FlatStoneLand"
	})	
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

---@param ent Entity
---@param HopParams TEdithHopParryParams
local function ParryTearManager(ent, HopParams)
	local tear = ent:ToTear() ---@cast tear EntityTear

	Helpers.BoostTear(tear, 20, 1.5 + ((HopParams.HopStaticCharge + HopParams.HopStaticBRCharge) / 100))

	if hasBirthright then
		tear:AddTearFlags(TearFlags.TEAR_BURN)
	end
end

---@param player EntityPlayer
---@param ent Entity
---@param HopParams TEdithHopParryParams
---@param ImpreciseParryCapsule Capsule
---@param PerfectParryCapsule Capsule
local function ImpreciseParryManager(player, ent, HopParams, ImpreciseParryCapsule, PerfectParryCapsule)
	local PickupCapsule = Capsule(player.Position, Vector.One, 0, 20)
	local SlotCapsule = Capsule(player.Position, Vector.One, 0, player.Size)
	local tearsMult = (Player.GetplayerTears(player) / 2.73) 
	local CinderTime = Math.SecondsToFrames(math.min(4 * tearsMult, 12))

	for _, entity in ipairs(Isaac.FindInCapsule(PickupCapsule)) do
		if entity:ToPickup() then
			PickupLandHandler(player, ent)
		end
	end

	for _, entity in ipairs(Isaac.FindInCapsule(SlotCapsule)) do
		if entity:ToSlot() then
			SlotLandManager(player, ent)
		end
	end

	if ent:ToTear() then return  end
	local pushMult = StatusEffect.EntHasStatusEffect(ent, enums.EdithStatusEffects.CINDER) and 1.5 or 1
	Helpers.TriggerPush(ent, player, 20 * pushMult)

	if not Helpers.IsEnemy(ent) then return end
	if IsEntInTwoCapsules(ent, ImpreciseParryCapsule, PerfectParryCapsule) then return end

	ent:TakeDamage(HopParams.ParryDamage * 0.25, 0, EntityRef(player), 0)
	StatusEffect.SetStatusEffect(enums.EdithStatusEffects.CINDER, ent, CinderTime, player)
	EnemiesInImpreciseParry = true
end

---@param player EntityPlayer
---@param ent Entity
---@param HopParams TEdithHopParryParams
---@param IsTaintedEdith any
local function PerfectParryManager(player, ent, HopParams, IsTaintedEdith)
	if ent:ToTear() then return end
	
	local damageFlag = Player.PlayerHasBirthright(player) and DamageFlag.DAMAGE_FIRE or 0
	local proj = ent:ToProjectile()
	local bomb = ent:ToBomb()
	local shouldTriggerFireJets = IsTaintedEdith and hasBirthright or Player.IsJudasWithBirthright(player)
	local nearestEnemy = Helpers.GetNearestEnemy(player)

	local CinderMult = StatusEffect.EntHasStatusEffect(ent, "Cinder") and 1.25 or 1

	Isaac.RunCallback(enums.Callbacks.PERFECT_PARRY, player, ent, HopParams)

	if proj then
		local spawner = proj.Parent or proj.SpawnerEntity
		local targetEnt = spawner or nearestEnemy or proj

		proj.FallingAccel = -0.1
		proj.FallingSpeed = 0
		proj.Height = -23
		proj:AddProjectileFlags(misc.NewProjectilFlags)
		proj:AddKnockback(EntityRef(player), (targetEnt.Position - player.Position):Resized(25), 5, false)

		if shouldTriggerFireJets then
			proj:AddProjectileFlags(ProjectileFlags.FIRE_SPAWN)
		end
	else
		if Helpers.IsEnemy(ent) then		
			sfx:Play(SoundEffect.SOUND_MEATY_DEATHS)

			for _ = 1, Player.GetNumTears(player) do
				ent:TakeDamage(HopParams.ParryDamage * CinderMult, damageFlag, EntityRef(player), 0)
			end

			if hasBirthright then
				ent:AddBurn(EntityRef(player), 123, 5)
			end

			if ent.HitPoints <= HopParams.ParryDamage then
				Isaac.RunCallback(enums.Callbacks.PERFECT_PARRY_KILL, player, ent)
				Land.AddExtraGore(ent, player)
			end

			if ent.Type == EntityType.ENTITY_FIREPLACE and ent.Variant ~= 4 then
				ent:Kill()
			end
		else
			if ent.Type == EntityType.ENTITY_STONEY then
				ent:ToNPC().State = NpcState.STATE_SPECIAL
			end

			if bomb then
				local vel = (not nearestEnemy and RandomVector() or (nearestEnemy.Position - player.Position)):Resized(15)
				bomb.Velocity = vel
			end
		end
	end
end

--- Misc function used to manage some perfect parry stuff (i made it to be able to return something in the main parry function sorry)
---@param player EntityPlayer
---@param isenemy? boolean
local function PerfectParryMisc(player, isenemy)
	if not isenemy then return end
	game:MakeShockwave(player.Position, 0.035, 0.025, 2)
end

---Helper function used to manage Tainted Edith and Burnt Hood's parry-lands 
---@param player EntityPlayer
---@param HopParams TEdithHopParryParams
---@param IsTaintedEdith? boolean 
---@return boolean PerfectParry Returns a boolean that tells if there was a perfect parry 
---@return boolean EnemiesInImpreciseParry
function Land.ParryLandManager(player, HopParams, IsTaintedEdith)
	local damageBase = 13.5
	local DamageStat = player.Damage 
	local rawFormula = (damageBase + DamageStat) / 1.5 
	local PerfectParry = false
	local EnemiesInImpreciseParry = false
	local ImpreciseParryCapsule = Capsule(player.Position, Vector.One, 0, misc.ImpreciseParryRadius)	
	local PerfectParryCapsule = Capsule(player.Position, Vector.One, 0, misc.PerfectParryRadius)
	local TearParryCapsule = Capsule(player.Position, Vector.One, 0, misc.TearParryRadius)
	local hasBirthright = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)
	local BirthrightMult = hasBirthright and 1.25 or 1
	local hasBirthcake = BirthcakeRebaked and player:HasTrinket(BirthcakeRebaked.Birthcake.ID) or false
	local MultishotMult = Math.Round(Math.exp(Player.GetNumTears(player), 1, 0.5), 2)
	local DamageFormula = (rawFormula * BirthrightMult) * (hasBirthcake and 1.15 or 1) * MultishotMult

	if IsTaintedEdith then
		local damageIncrease = 1 + (HopParams.HopStaticCharge + HopParams.HopStaticBRCharge) / 400
		DamageFormula = DamageFormula * damageIncrease
	end

	HopParams.ParryDamage = DamageFormula
	HopParams.ParriedEnemies = Isaac.FindInCapsule(PerfectParryCapsule, misc.ParryPartitions)
	HopParams.ImpreciseParriedEnemies = Isaac.FindInCapsule(ImpreciseParryCapsule, misc.ParryPartitions)

	for _, ent in pairs(Isaac.FindInCapsule(TearParryCapsule, EntityPartition.TEAR)) do
		ParryTearManager(ent, HopParams)
		PerfectParry = true
	end

	for _, ent in pairs(Isaac.FindInCapsule(ImpreciseParryCapsule, misc.ParryPartitions)) do
		ImpreciseParryManager(player, ent, HopParams, ImpreciseParryCapsule, PerfectParryCapsule)
	end

	for _, ent in pairs(HopParams.ParriedEnemies) do
		PerfectParryManager(player, ent, HopParams, IsTaintedEdith)

		PerfectParry = true
	end

	Land.TriggerLandenemyJump(player, HopParams.ParriedEnemies, HopParams.ParryKnockback, 8, 2)

	local IFrames = (PerfectParry and 30 or 20) + math.ceil((HopParams.HopStaticCharge + HopParams.HopStaticBRCharge * 0.25) / 4)

	player:SetMinDamageCooldown(IFrames)
	PerfectParryMisc(player, PerfectParry)

	local staticChargeCooldownBonus = math.ceil(4 * (HopParams.HopStaticCharge / 100)) 

	if PerfectParry and Helpers.GetConfigData(ConfigDataTypes.TEDITH).EnableParryFlash then
		Helpers.TriggerPerfectParryFlash(player)
	end

	HopParams.ParryCooldown = (
		IsTaintedEdith and 
		(PerfectParry and 
		((hasBirthcake and 10 or 12) - staticChargeCooldownBonus) or 15) or 0
	)

	data(player).MaxParryCooldown = HopParams.ParryCooldown or 0

	HopParams.IsParryJump = false

	GrudgeUnlockManager(PerfectParry)

	HopParams.ParriedEnemies = {}
	return PerfectParry, EnemiesInImpreciseParry
end

return Land