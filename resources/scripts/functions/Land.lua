---@diagnostic disable: undefined-global, param-type-mismatch
local mod = EdithRebuilt
local enums = mod.Enums
local utils = enums.Utils
local game = utils.Game
local sfx = utils.SFX
local misc = enums.Misc
local ConfigDataTypes = enums.ConfigDataTypes
local tables = enums.Tables
local MortisBackdrop = tables.MortisBackdrop
local sounds = enums.SoundEffect
local callbacks = enums.Callbacks
local status = enums.EdithStatusEffects
local data = mod.DataHolder.GetEntityData
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
	local Helpers = mod.Modules.HELPERS
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
	local Helpers = mod.Modules.HELPERS

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
	return mod.Modules.HELPERS.When(pickup.Variant, KeyRequiredChests, false)
end

---@param pickup EntityPickup
---@return boolean
local function IsChest(pickup)
	return mod.Modules.HELPERS.When(pickup.Variant, Chests, false)
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
	local IsStopAnimPickup = mod.Modules.HELPERS.When(pickup.Variant, NonTriggerAnimPickupVar, false)
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

	local room = game:GetRoom()
	local IsPickedUp = pickup:GetSprite():IsPlaying("Collect")

	if mod.Modules.HELPERS.IsVestigeChallenge() then
		Land.PickupManager(parent, pickup)
	end

	if IsPickedUp then return end

	data(pickup).HopLandedPlayer = parent

	if not Player.IsEdith(parent, false) then return end

	if not (var == PickupVariant.PICKUP_BOMBCHEST and Player.IsEdith(parent, false)) then return end
	pickup:TryOpenChest(parent)

	if room:GetType() == RoomType.ROOM_CHALLENGE then
		Ambush.StartChallenge()
	end
end

mod:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, function (_, pickup)
	local player = data(pickup).HopLandedPlayer ---@cast player EntityPlayer

	if not player then return end

	player:ForceCollide(pickup, true)
	data(pickup).HopLandedPlayer = nil
end)

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
	if not mod.Modules.HELPERS.When(var, TriggerDamageSlots, false) then return end
	parent:ForceCollide(ent, false)
	parent:TakeDamage(1, 0, EntityRef(ent), 0)
end

---@param ent Entity
---@param parent EntityPlayer
---@param knockback number
function Land.HandleEntityInteraction(ent, parent, knockback)
	local var = ent.Variant
	local Helpers = mod.Modules.HELPERS
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
            Helpers.TriggerPush(ent, parent, knockback * 1.3)

			local fam = ent:ToFamiliar() 
			if not fam then return end

			if var == FamiliarVariant.CUBE_BABY then
				fam:TryThrow(EntityRef(parent), fam.Velocity, 0)
			end
        end,
        [EntityType.ENTITY_BOMB] = function()
			if Player.IsEdith(parent, true) then return end
            Helpers.TriggerPush(ent, parent, knockback)
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

---@param parent EntityPlayer
---@param ent Entity
---@param params EdithJumpStompParams
---@param saltedTime number
---@param terraMult number
---@param numTears number
---@param maths table
local function HandleStompedEnemy(parent, ent, params, saltedTime, terraMult, numTears, maths)
	EntityInteractHandler(ent, parent, params.Knockback)
	SaltEnemyManager(parent, ent, params.IsDefensiveStomp, saltedTime)

	if not mod.Modules.HELPERS.IsEnemy(ent) then return end

	if not params.IsDefensiveStomp then
		local volume = maths.exp(numTears, 1, 1.4)
		Isaac.RunCallback(callbacks.OFFENSIVE_STOMP_HIT, parent, ent, params)
		sfx:Play(SoundEffect.SOUND_MEATY_DEATHS, volume)
	end

	for _ = 1, numTears do
		DamageManager(parent, ent, params.Damage, terraMult, params.Knockback)
	end

	if ent.HitPoints > params.Damage then return end

	Isaac.RunCallback(callbacks.OFFENSIVE_STOMP_KILL, parent, ent, params)

	local isSalted = StatusEffect.EntHasStatusEffect(ent, enums.EdithStatusEffects.SALTED)
	if isSalted then VestigeUnlockManager() end

	EdithBirthcake(parent, isSalted)
	Land.AddExtraGore(ent, parent)
end

---Custom Edith stomp behavior
---@param parent EntityPlayer
---@param params EdithJumpStompParams
---@param breakGrid boolean
function Land.EdithStomp(parent, params, breakGrid)
	local maths = mod.Modules.MATHS
	local Helpers = mod.Modules.HELPERS
	local hasTerra = parent:HasCollectible(CollectibleType.COLLECTIBLE_TERRA)
	local terraMult = hasTerra and modRNG.RandomFloat(parent:GetCollectibleRNG(CollectibleType.COLLECTIBLE_TERRA), 0.5, 2) or 1
	local saltedTime = maths.Round(maths.Clamp(120 * (Player.GetplayerTears(parent) / 2.73), 60, 360))
	local numTears = Player.GetNumTears(parent)

	local Capsules = {
		Stomp = Capsule(parent.Position, Vector.One, 0, params.Radius),
		Pickup = Capsule(parent.Position, Vector.One, 0, 30),
		Slot = Capsule(parent.Position, Vector.One, 0, parent.Size),
	}

	params.StompedEntities = Isaac.FindInCapsule(Capsules.Stomp)

	if not params.IsDefensiveStomp then
		Isaac.RunCallback(callbacks.OFFENSIVE_STOMP, parent, params)
	end

	for _, ent in ipairs(Isaac.FindInCapsule(Capsules.Pickup, EntityPartition.PICKUP)) do
		if ent:ToPickup() then PickupLandHandler(parent, ent) end
	end

	for _, ent in ipairs(Isaac.FindInCapsule(Capsules.Slot)) do
		if ent:ToSlot() then SlotLandManager(parent, ent) end
	end

	for _, ent in ipairs(params.StompedEntities) do
		if GetPtrHash(parent) == GetPtrHash(ent) then goto continue end
		HandleStompedEnemy(parent, ent, params, saltedTime, terraMult, numTears, maths)
		::continue::
	end

	if breakGrid then
		Helpers.DestroyGrid(parent, params.Radius)
	end
end

---@param player EntityPlayer
---@param params EdithJumpStompParams|TEdithHopParryParams
local function TriggerBombExplosion(player, params)
    if params.RocketLaunch then return end
    game:BombExplosionEffects(player.Position, 100, player:GetBombFlags(), misc.ColorDefault, player, 1, false, false, 0)
    if mod.Modules.PLAYER.ShouldConsumeBomb(player) then
        player:AddBombs(-1)
    end
end

---@param player EntityPlayer
---@param params EdithJumpStompParams|TEdithHopParryParams
---@param isEdith boolean
---@param isTEdith boolean
local function UpdateBombState(player, params, isEdith, isTEdith)
    if isEdith then
        if player:HasCollectible(CollectibleType.COLLECTIBLE_FAST_BOMBS) then
            params.Cooldown = 3
        end
        params.BombStomp = false
    elseif isTEdith then
        params.ParryBomb = false
    end
end

---@param player EntityPlayer
---@param params EdithJumpStompParams|TEdithHopParryParams
function Land.BombLandManager(player, params)
	local modules = mod.Modules

	local isEdith = modules.PLAYER.IsEdith(player, false)
	local isTEdith = modules.PLAYER.IsEdith(player, true)

	local isBombLand = isEdith and params.BombStomp or isTEdith and params.ParryBomb or false

	if not isBombLand then return end

	TriggerBombExplosion(player, params)
    UpdateBombState(player, params, isEdith, isTEdith)
end

---Tainted Edith hop land behavior
---@param parent EntityPlayer
---@param HopParams TEdithHopParryParams
function Land.TaintedEdithHop(parent, HopParams)
	local capsule = Capsule(parent.Position, Vector.One, 0, HopParams.HopRadius)
	local PickupCapsule = Capsule(parent.Position, Vector.One, 0, 30)
	local SlotCapsule = Capsule(parent.Position, Vector.One, 0, parent.Size)
	local Charge = HopParams.HopMoveCharge / 100
	local BRCharge = HopParams.HopMoveBRCharge / 100
	local burnDamage, burnDuration = BRCharge * parent.Damage / 2, math.ceil(BRCharge * 123)
	local PlayerRef = EntityRef(parent)
	local CinderDuration = mod.Modules.MATHS.SecondsToFrames(4 * (Charge + BRCharge))

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

		if mod.Modules.HELPERS.IsEnemy(ent) then
			local npc = ent:ToNPC()

			if npc then
				npc:ApplyTearflagEffects(ent.Position, parent.TearFlags, parent, parent.Damage)
			end

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

    local sounds = {
        { sound = sound, volume = volume, pitch = 0, loop = false },
        IsChap4  and { sound = SoundEffect.SOUND_MEATY_DEATHS, volume = volume - 0.5, pitch = 0, loop = false, a = 1, b = 0 },
        hasWater and { sound = enums.SoundEffect.SOUND_EDITH_STOMP_WATER, volume = volume,       pitch = 0, loop = false },
    }

    for _, s in ipairs(sounds) do
        if s then
            sfx:Play(s.sound, s.volume, s.pitch, s.loop, s.a, s.b)
        end
    end
end

local EFFECT = {
    PLAYBACK_BASE     = 1.3,
    PLAYBACK_VARIANCE = 1.5,
    RAND_SIZE_MIN     = 0.8,
    RAND_SIZE_MAX     = 1.0,
}

---@param hasWater boolean
---@param IsChap4 boolean
---@return EffectVariant, number
local function GetEffectVariantAndSubType(hasWater, IsChap4)
    if hasWater then return EffectVariant.BIG_SPLASH, 2 end
    return EffectVariant.POOF02, (IsChap4 and 3 or 1)
end

---@param player EntityPlayer
---@return boolean
local function IsEdithJump(player)
    local d = data(player)
    return Player.IsEdith(player, false) or d.IsSoulOfEdithJump or d.HoodLand
end

---@class FeedbackLandParams
---@field Size number
---@field SoundPick number
---@field Volume number
---@field ScreenShakeIntensity number
---@field GibAmount number
---@field GibSpeed number

---@param player EntityPlayer
---@return FeedbackLandParams
local function GetEdithLandParams(player)
    local Helpers  = mod.Modules.HELPERS
    local d = data(player)
    local IsSoulOfEdith = d.IsSoulOfEdithJump
    local IsEdithsHood = d.HoodLand
    local isRocketLaunch = d.RocketLaunch
    local isDefensive = Edith.GetJumpStompParams(player).IsDefensiveStomp or IsEdithsHood
    local EdithData = Helpers.GetConfigData(ConfigDataTypes.EDITH) ---@cast EdithData EdithData

    local sizeBase = IsSoulOfEdith and 0.8 or (isDefensive and 0.6 or 0.7)
    return {
        Size = sizeBase * (isRocketLaunch and 1.25 or 1),
        SoundPick = EdithData.StompSound,
        Volume = GetVolume(EdithData.StompVolume) * (isDefensive and 1.5 or 2),
        ScreenShakeIntensity = isDefensive and 6 or (isRocketLaunch and 14 or 10),
        GibAmount = EdithData.DisableSaltGibs and 0 or (isRocketLaunch and 14 or 10),
        GibSpeed = isDefensive and 2 or 3,
    }
end

---@param IsParryLand boolean
---@return FeedbackLandParams
local function GetTEdithLandParams(IsParryLand)
    local TEdithData = mod.Modules.HELPERS.GetConfigData(ConfigDataTypes.TEDITH) ---@cast TEdithData TEdithData
    return {
        Size = IsParryLand and 0.7 or 0.5,
        SoundPick = IsParryLand and TEdithData.ParrySound or TEdithData.HopSound,
        Volume = GetVolume(TEdithData.Volume) * (IsParryLand and 1.5 or 1),
        ScreenShakeIntensity = IsParryLand and 6 or 3,
        GibAmount = not TEdithData.DisableSaltGibs and (IsParryLand and 6 or 2) or 0,
        GibSpeed = 2,
    }
end

---@param Variant EffectVariant
---@param BackDrop BackdropType
---@param IsMortis boolean
---@return Color
local function GetLandEffectColor(Variant, BackDrop, IsMortis)
    local Helpers = mod.Modules.HELPERS
    local backColor = tables.BackdropColors
    local defColor = Color(1, 1, 1)
    local color

    if Variant == EffectVariant.BIG_SPLASH then
        color = Helpers.When(BackDrop, backColor, Color(0.7, 0.75, 1))
    elseif Variant == EffectVariant.POOF02 then
        color = BackDrop == BackdropType.DROSS and defColor or backColor[BackDrop]
    end

    if IsMortis then
        local MortisColors = {
            [MortisBackdrop.MORGUE] = Color(0, 0, 0, 1, 0.45, 0.5, 0.575),
            [MortisBackdrop.MOIST] = Color(0, 0.8, 0.76, 1, 0, 0, 0),
            [MortisBackdrop.FLESH] = Color(0, 0, 0, 1, 0.55, 0.5, 0.55),
        }
        color = Helpers.When(Helpers.GetMortisDrop(), MortisColors, Color.Default)
    end

    return color or defColor
end

---@param player EntityPlayer
---@param stompGFX Entity
---@param size number
---@param color Color
local function ApplyEffectVisuals(player, stompGFX, size, color)
    local rng = stompGFX:GetDropRNG()
    local randX = modRNG.RandomFloat(rng, EFFECT.RAND_SIZE_MIN, EFFECT.RAND_SIZE_MAX)
    local randY = modRNG.RandomFloat(rng, EFFECT.RAND_SIZE_MIN, EFFECT.RAND_SIZE_MAX)

    stompGFX:GetSprite().PlaybackSpeed = EFFECT.PLAYBACK_BASE * modRNG.RandomFloat(rng, 1, EFFECT.PLAYBACK_VARIANCE)
    stompGFX.SpriteScale = Vector(size * randX, size * randY) * player.SpriteScale.X
    stompGFX.Color = color
end

---@param player EntityPlayer
---@param landParams FeedbackLandParams
---@param IsChap4 boolean
local function SpawnLandGFX(player, landParams, IsChap4)
	local room = game:GetRoom()
    local hasWater = room:HasWater()
	local Variant, SubType = GetEffectVariantAndSubType(hasWater, IsChap4)
	local BackDrop = room:GetBackdropType()
	local IsMortis = mod.Modules.HELPERS.IsLJMortis()
	local stompGFX = Isaac.Spawn(
        EntityType.ENTITY_EFFECT,
        Variant, SubType,
        player.Position, Vector.Zero, player
    )

	ApplyEffectVisuals(player, stompGFX, landParams.Size, GetLandEffectColor(Variant, BackDrop, IsMortis))
end

---@param player EntityPlayer
---@param soundTable table
---@param GibColor Color
---@param IsParryLand? boolean
function Land.LandFeedbackManager(player, soundTable, GibColor, IsParryLand)
    local saveManager = mod.SaveManager
    if not saveManager:IsLoaded() then return end
    if not saveManager:GetSettingsSave() then return end

    local Helpers = mod.Modules.HELPERS
    local IsChap4 = Helpers.IsChap4()

    local landParams = IsEdithJump(player)
        and GetEdithLandParams(player)
        or GetTEdithLandParams(IsParryLand)

    SpawnLandGFX(player, landParams, IsChap4)

    if Helpers.GetConfigData(ConfigDataTypes.MISC).EnableShakescreen then
        game:ShakeScreen(landParams.ScreenShakeIntensity)
    end

    if landParams.GibAmount > 0 then
        Helpers.SpawnSaltGib(player, landParams.GibSpeed, landParams.GibSpeed, GibColor or Color(1, 1, 1))
    end

    SfxFeedbackManager(Helpers.When(landParams.SoundPick, soundTable, 1), landParams.Volume, IsChap4, hasWater)
end

---@param player EntityPlayer
---@param enemyTable Entity[]
---@param knockback number
---@param height number
---@param speed number
function Land.TriggerLandenemyJump(player, enemyTable, knockback, height, speed)
	local Helpers = mod.Modules.HELPERS

	for _, ent in ipairs(enemyTable) do
		if not Helpers.IsEnemy(ent) then goto continue end

		local PushFactor = Helpers.GetPushFactor(ent)

		Helpers.TriggerJumpPush(ent, player, knockback * 1.5, 5)
		JumpLib:TryJump(ent, {
			Height = height * PushFactor,
			Speed = speed * PushFactor,
			Tags = "EdithRebuilt_EnemyJump",
			Flags = JumpLib.Flags.COLLISION_GRID
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
	local tear = ent:ToTear()

	if not tear then return end

	mod.Modules.HELPERS.BoostTear(tear, 20, 1.5 + ((HopParams.HopStaticCharge + HopParams.HopStaticBRCharge) / 100))

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
	local CinderTime = mod.Modules.MATHS.SecondsToFrames(math.min(4 * tearsMult, 12))

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
	local Helpers = mod.Modules.HELPERS
	Helpers.TriggerPush(ent, player, 20 * pushMult)

	if not Helpers.IsEnemy(ent) then return end
	if IsEntInTwoCapsules(ent, ImpreciseParryCapsule, PerfectParryCapsule) then return end

	ent:TakeDamage(HopParams.ParryDamage * 0.25, 0, EntityRef(player), 0)
	StatusEffect.SetStatusEffect(enums.EdithStatusEffects.CINDER, ent, CinderTime, player)
	EnemiesInImpreciseParry = true
end

local function ProjectilePerfectParry(player, proj, shouldTriggerFireJets)
	local spawner = proj.Parent or proj.SpawnerEntity
	local targetEnt = spawner or Helpers.GetNearestEnemy(player) or proj
	local flags = misc.NewProjectilFlags | (shouldTriggerFireJets and ProjectileFlags.FIRE_SPAWN or 0)

	proj.FallingAccel = -0.1
	proj.FallingSpeed = 0
	proj.Height = -23
	proj:AddProjectileFlags(flags)
	proj:AddKnockback(EntityRef(player), (targetEnt.Position - player.Position):Resized(25), 5, false)
end

---@param player EntityPlayer
---@param ent Entity
---@param HopParams TEdithHopParryParams
---@param IsTaintedEdith any
local function PerfectParryManager(player, ent, HopParams, IsTaintedEdith)
	if ent:ToTear() then return end

	local hasBirthright = Player.PlayerHasBirthright(player) 
	local damageFlag = hasBirthright and DamageFlag.DAMAGE_FIRE or 0
	local proj = ent:ToProjectile()
	local bomb = ent:ToBomb()
	local shouldTriggerFireJets = IsTaintedEdith and hasBirthright or Player.IsJudasWithBirthright(player)
	local PlayerRef = EntityRef(player)

	local CinderMult = StatusEffect.EntHasStatusEffect(ent, "Cinder") and 1.25 or 1

	Isaac.RunCallback(enums.Callbacks.PERFECT_PARRY, player, ent, HopParams)

	if proj then
		ProjectilePerfectParry(player, proj, shouldTriggerFireJets)
	elseif mod.Modules.HELPERS.IsEnemy(ent) then
		sfx:Play(SoundEffect.SOUND_MEATY_DEATHS)

		for _ = 1, Player.GetNumTears(player) do
			ent:TakeDamage(HopParams.ParryDamage * CinderMult, damageFlag, PlayerRef, 0)
		end

		if hasBirthright then
			ent:AddBurn(PlayerRef, 123, 5)
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

		if ent.Type == EntityType.ENTITY_SHOPKEEPER then
			ent:Kill()
		end

		if bomb then
			bomb:SetExplosionCountdown(0)
			bomb.ExplosionDamage = bomb.ExplosionDamage * 1.25
		end
	end
end

---@param player EntityPlayer
---@param isenemy? boolean
local function TriggerParryShockwave(player, isenemy)
	if not isenemy then return end
	game:MakeShockwave(player.Position, 0.035, 0.025, 2)
end

local function CalcParryDamage(player, hopParams, isTaintedEdith)
    local damageBase = 13.5
    local rawFormula = (damageBase + player.Damage) / 1.5
    local birthrightMult = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and 1.25 or 1
    local hasBirthcake = BirthcakeRebaked and player:HasTrinket(BirthcakeRebaked.Birthcake.ID) or false
	local Maths = mod.Modules.MATHS
    local multishotMult = Maths.Round(Maths.exp(Player.GetNumTears(player), 1, 0.5), 2)
    local damageFormula = (rawFormula * birthrightMult) * (hasBirthcake and 1.15 or 1) * multishotMult

    if isTaintedEdith then
        local damageIncrease = 1 + (hopParams.HopStaticCharge + hopParams.HopStaticBRCharge) / 400
        damageFormula = damageFormula * damageIncrease
    end
    return damageFormula, hasBirthcake
end

local function CalcParryCooldown(isTaintedEdith, perfectParry, hasBirthcake, staticChargeCooldownBonus)
    if not isTaintedEdith then return 0 end
    if not perfectParry then return 15 end
    local base = hasBirthcake and 10 or 12
    return base - staticChargeCooldownBonus
end

local function ProcessParryHits(player, hopParams, isTaintedEdith, capsules)
    local perfectParry = false
    local enemiesInImpreciseParry = false

    for _, ent in pairs(Isaac.FindInCapsule(capsules.tear, EntityPartition.TEAR)) do
        ParryTearManager(ent, hopParams)
        perfectParry = true
    end

    enemiesInImpreciseParry = #Isaac.FindInCapsule(capsules.imprecise, misc.ParryPartitions) > 0

    for _, ent in pairs(Isaac.FindInCapsule(capsules.imprecise, misc.ParryPartitions)) do
        ImpreciseParryManager(player, ent, hopParams, capsules.imprecise, capsules.perfect)
    end

    for _, ent in pairs(hopParams.ParriedEnemies) do
        PerfectParryManager(player, ent, hopParams, isTaintedEdith)
        perfectParry = true
    end

    return perfectParry, enemiesInImpreciseParry
end

local function TriggerParryKnockback(player, enemies, knockback)
    Land.TriggerLandenemyJump(player, enemies, knockback, 8, 2)
end

---Helper function used to manage Tainted Edith and Burnt Hood's parry-lands
---@param player EntityPlayer
---@param hopParams TEdithHopParryParams
---@param isTaintedEdith? boolean
---@return boolean perfectParry
---@return boolean enemiesInImpreciseParry
function Land.ParryLandManager(player, hopParams, isTaintedEdith)
    local capsules = {
        imprecise = Capsule(player.Position, Vector.One, 0, misc.ImpreciseParryRadius),
        perfect = Capsule(player.Position, Vector.One, 0, misc.PerfectParryRadius),
        tear = Capsule(player.Position, Vector.One, 0, misc.TearParryRadius),
    }

    local damageFormula, hasBirthcake = CalcParryDamage(player, hopParams, isTaintedEdith)
    hopParams.ParryDamage = damageFormula
    hopParams.ParriedEnemies = Isaac.FindInCapsule(capsules.perfect, misc.ParryPartitions)
    hopParams.ImpreciseParriedEnemies = Isaac.FindInCapsule(capsules.imprecise, misc.ParryPartitions)

    local perfectParry, enemiesInImpreciseParry = ProcessParryHits(player, hopParams, isTaintedEdith, capsules)

    TriggerParryKnockback(player, hopParams.ImpreciseParriedEnemies, hopParams.ParryKnockback)
    TriggerParryKnockback(player, hopParams.ParriedEnemies, hopParams.ParryKnockback)

    local staticChargeCooldownBonus = math.ceil(4 * (hopParams.HopStaticCharge / 100))
    local iFrames = (perfectParry and 30 or 25) + math.ceil((hopParams.HopStaticCharge + hopParams.HopStaticBRCharge * 0.25) / 4)

    player:SetMinDamageCooldown(iFrames)
    TriggerParryShockwave(player, perfectParry)

	local Helpers = mod.Modules.HELPERS

    if perfectParry and Helpers.GetConfigData(ConfigDataTypes.TEDITH).EnableParryFlash then
        Helpers.TriggerPerfectParryFlash(player)
    end

    hopParams.ParryCooldown = CalcParryCooldown(isTaintedEdith, perfectParry, hasBirthcake, staticChargeCooldownBonus)
    data(player).MaxParryCooldown = hopParams.ParryCooldown or 0
    hopParams.IsParryJump = false

    GrudgeUnlockManager(perfectParry)

    hopParams.ParriedEnemies = {}
    hopParams.ImpreciseParriedEnemies = {}
    return perfectParry, enemiesInImpreciseParry
end
return Land