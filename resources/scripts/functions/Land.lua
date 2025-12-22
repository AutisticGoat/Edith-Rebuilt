---@diagnostic disable: undefined-global, param-type-mismatch
local mod = EdithRebuilt
local enums = mod.Enums
local utils = enums.Utils
local game = utils.Game
local sfx = utils.SFX
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
	ent:MakeBloodPoof(ent.Position, nil, 0.5)
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
local function ShouldConsumeKeys(player)
	return (player:GetNumKeys() > 0 and not player:HasGoldenKey())
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
        [EntityType.ENTITY_PICKUP] = function()
            local pickup = ent:ToPickup() ---@cast pickup EntityPickup
            local isFlavorTextPickup = Helpers.When(var, tables.BlacklistedPickupVariants, false)
            local IsLuckyPenny = var == PickupVariant.PICKUP_COIN and ent.SubType == CoinSubType.COIN_LUCKYPENNY

			if Helpers.IsVestigeChallenge() then
				Land.PickupManager(parent, pickup)
			end

            if isFlavorTextPickup or IsLuckyPenny then return end
			parent:ForceCollide(pickup, true)

			if not Player.IsEdith(parent, false) then return end

            if not (var == PickupVariant.PICKUP_BOMBCHEST and Player.IsEdith(parent, false)) then return end
			pickup:TryOpenChest(parent)
        end,
		[EntityType.ENTITY_SLOT] = function ()
			-- parent:ForceCollide(ent, false)
			local TriggerDamageSlots = {
				[SlotVariant.BLOOD_DONATION_MACHINE] = true,
				[SlotVariant.DEVIL_BEGGAR] = true,
				[SlotVariant.CONFESSIONAL] = true,
			}

			if not Helpers.When(var, TriggerDamageSlots, false) then return end
			parent:ForceCollide(ent, false)
			parent:TakeDamage(1, 0, EntityRef(ent), 0)
		end,
        [EntityType.ENTITY_SHOPKEEPER] = function()
			if Player.IsEdith(parent, true) then return end
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
	
	Land.LandDamage(ent, parent, damage, knockback)
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
	local SaltedTime = Math.Round(Math.Clamp(120 * (Player.GetplayerTears(parent) / 2.73), 60, 360))
	local isSalted

	params.StompedEntities = Isaac.FindInCapsule(capsule)

	if not isDefStomp then
		Isaac.RunCallback(callbacks.OFFENSIVE_STOMP, parent, params)
	end

	--- Pendiente de reducir
	for _, ent in ipairs(params.StompedEntities) do
		if GetPtrHash(parent) == GetPtrHash(ent) then goto Break end
		EntityInteractHandler(ent, parent, params.Knockback)
		SaltEnemyManager(parent, ent, isDefStomp, SaltedTime)

		if not Helpers.IsEnemy(ent) then goto Break end
		
		if not params.IsDefensiveStomp then
			Isaac.RunCallback(callbacks.OFFENSIVE_STOMP_HIT, parent, ent, params)
			sfx:Play(SoundEffect.SOUND_MEATY_DEATHS)
		end

		DamageManager(parent, ent, params.Damage, TerraMult, params.Knockback)

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
		Helpers.DestroyGrid(parent)
	end
end

---Tainted Edith hop land behavior
---@param parent EntityPlayer
---@param HopParams TEdithHopParryParams
function Land.TaintedEdithHop(parent, HopParams)
	local capsule = Capsule(parent.Position, Vector.One, 0, HopParams.HopRadius)
	local BRCharge = HopParams.HopMoveBRCharge / 100
	local burnDamage, burnDuration = BRCharge * parent.Damage / 2, math.ceil(BRCharge * 123)
	local PlayerRef = EntityRef(parent)

	for _, ent in ipairs(Isaac.FindInCapsule(capsule)) do
		Land.HandleEntityInteraction(ent, parent, HopParams.HopKnockback)
		Land.LandDamage(ent, parent, HopParams.HopDamage, HopParams.HopKnockback)
	
		if BRCharge > 0 then
			ent:AddBurn(PlayerRef, burnDuration, burnDamage)
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
	local isVestige = Helpers.IsVestigeChallenge()

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

---@param params EdithJumpStompParams
---@param height number
---@param speed number
function Land.TriggerLandenemyJump(params, height, speed)
	for _, ent in ipairs(params.StompedEntities) do
		local PushFactor = Helpers.GetPushFactor(ent)

		if Helpers.IsEnemy(ent) then
			JumpLib:TryJump(ent, {
			Height = height * PushFactor,
			Speed = speed * PushFactor,
			Tags = "EdithRebuilt_EnemyJump",
			-- Flags = JumpLib.Flags.
		})	
		end
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

return Land