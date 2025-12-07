---@diagnostic disable: undefined-global, param-type-mismatch
local mod = EdithRebuilt
local enums = mod.Enums
local utils = enums.Utils
local game = utils.Game
local sfx = utils.SFX
local ConfigDataTypes = enums.ConfigDataTypes
local tables = enums.Tables
local callbacks = enums.Callbacks
local data = mod.CustomDataWrapper.getData
local Math = require("resources.scripts.functions.Maths")
local Helpers = require("resources.scripts.functions.Helpers")
local modRNG = require("resources.scripts.functions.RNG")
local Player = require("resources.scripts.functions.Player")
local Edith  = require("resources.scripts.functions.Edith")
local Land = {}

local damageFlags = DamageFlag.DAMAGE_CRUSH | DamageFlag.DAMAGE_IGNORE_ARMOR

---@param ent Entity
---@param dealEnt Entity
---@param damage number
---@param knockback number
function Land.LandDamage(ent, dealEnt, damage, knockback)	
	if not mod.IsEnemy(ent) then return end

	ent:TakeDamage(damage, damageFlags, EntityRef(dealEnt), 0)
	Helpers.TriggerPush(ent, dealEnt, knockback)
end

---@param ent Entity
---@param player EntityPlayer
function AddExtraGore(ent, player)
	local enabledExtraGore

	if Player.IsEdith(player, false) then
		enabledExtraGore = mod.GetConfigData(ConfigDataTypes.EDITH).EnableExtraGore
	elseif Player.IsEdith(player, true) then
		enabledExtraGore = mod.GetConfigData(ConfigDataTypes.TEDITH).EnableExtraGore
	end

	if not enabledExtraGore then return end
	if not ent:ToNPC() then return end

	ent:AddEntityFlags(EntityFlag.FLAG_EXTRA_GORE)
	ent:MakeBloodPoof(ent.Position, nil, 0.5)
	sfx:Play(SoundEffect.SOUND_DEATH_BURST_LARGE)
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

			mod.BoostTear(tear, 25, 1.5)
        end,
        [EntityType.ENTITY_FIREPLACE] = function()
            if var == 4 then return end
            ent:Die()
        end,
        [EntityType.ENTITY_FAMILIAR] = function()
            if not Helpers.When(var, tables.PhysicsFamiliar, false) then return end
            Helpers.TriggerPush(ent, parent, knockback)
        end,
        [EntityType.ENTITY_BOMB] = function()
			if Player.IsEdith(parent, true) then return end
            Helpers.TriggerPush(ent, parent, knockback)
        end,
        [EntityType.ENTITY_PICKUP] = function()
            local pickup = ent:ToPickup() ---@cast pickup EntityPickup
            local isFlavorTextPickup = mod.When(var, tables.BlacklistedPickupVariants, false)
            local IsLuckyPenny = var == PickupVariant.PICKUP_COIN and ent.SubType == CoinSubType.COIN_LUCKYPENNY

            if isFlavorTextPickup or IsLuckyPenny then return end
			parent:ForceCollide(pickup, true)

			if not Player.IsEdith(parent, false) then return end

			if IsKeyRequiredChest(pickup) then
				if var == PickupVariant.PICKUP_MEGACHEST then
					local rng = pickup:GetDropRNG()
					local piData = data(pickup)

					piData.OpenAttempts = 0
					piData.OpenAttempts = piData.OpenAttempts + 1

					local attempt = piData.OpenAttempts
					local openRoll = rng:RandomInt(attempt, 7)

					if openRoll == 7 then
						pickup:TryOpenChest(parent)
					else
						pickup:GetSprite():Play("UseKey")
					end
				else
					pickup:TryOpenChest(parent)
				end

				if ShouldConsumeKeys(parent) then
					parent:AddKeys(-1)
				end
			end

            if not (var == PickupVariant.PICKUP_BOMBCHEST and Player.IsEdith(parent, false)) then return end
			pickup:TryOpenChest(parent)
        end,
        [EntityType.ENTITY_SHOPKEEPER] = function()
			if Player.IsEdith(parent, true) then return end
            ent:Kill()
        end,
    }
	mod.WhenEval(ent.Type, stompBehavior)
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
	EdithRebuilt.SetSalted(ent, SaltedTime, parent)
	data(ent).SaltType = data(parent).HoodLand and enums.SaltTypes.EDITHS_HOOD		
end

---@param parent EntityPlayer
---@param ent Entity
---@param damage number
---@param TerraMult number
---@param knockback number
local function DamageManager(parent, ent, damage, TerraMult, knockback)
	sfx:Play(SoundEffect.SOUND_MEATY_DEATHS)

	local FrozenMult = ent:HasEntityFlags(EntityFlag.FLAG_FREEZE) and 1.2 or 1 
	damage = (damage * FrozenMult) * TerraMult
	
	Land.LandDamage(ent, parent, damage, knockback)
end

local function EntityInteractHandler(ent, parent, knockback)
	local isSalted = mod.IsSalted(ent)
	local knockbackMult = isSalted and 1.5 or 1

	Land.HandleEntityInteraction(ent, parent, knockback * knockbackMult)

	if ent.Type == EntityType.ENTITY_STONEY then
		ent:ToNPC().State = NpcState.STATE_SPECIAL
	end
end

---Custom Edith stomp Behavior
---@param parent EntityPlayer
---@param params EdithJumpStompParams
---@param breakGrid boolean
function Land.EdithStomp(parent, params, breakGrid)
	local isDefStomp = params.IsDefensiveStomp
	local damage, knockback, radius = params.Damage, params.Knockback, params.Radius
	local HasTerra = parent:HasCollectible(CollectibleType.COLLECTIBLE_TERRA)
	local TerraRNG = parent:GetCollectibleRNG(CollectibleType.COLLECTIBLE_TERRA)
	local TerraMult = HasTerra and mod.RandomFloat(TerraRNG, 0.5, 2) or 1	
	local capsule = Capsule(parent.Position, Vector.One, 0, radius)
	local SaltedTime = Math.Round(Math.Clamp(120 * (mod.GetTPS(parent) / 2.73), 60, 360))
	local isSalted

	params.StompedEntities = Isaac.FindInCapsule(capsule)

	Isaac.RunCallback(callbacks.OFFENSIVE_STOMP, parent, params)

	--- Pendiente de reducir
	for _, ent in ipairs(params.StompedEntities) do
		if GetPtrHash(parent) == GetPtrHash(ent) then goto Break end
		EntityInteractHandler(ent, parent, knockback)
		SaltEnemyManager(parent, ent, isDefStomp, SaltedTime)

		if not mod.IsEnemy(ent) then goto Break end
		Isaac.RunCallback(callbacks.OFFENSIVE_STOMP_HIT, parent, ent, params)
		DamageManager(parent, ent, damage, TerraMult, knockback)

		if ent.HitPoints > damage then goto Break end
		EdithBirthcake(parent, isSalted)
		AddExtraGore(ent, parent)
		::Break::
	end

	if breakGrid then
		mod:DestroyGrid(parent, radius)
	end
end

-- local function NPCUpdate(npc)
	
-- end
-- mod:AddCallback(ModCallbacks.)

---Tainted Edith parry land behavior
---@param parent EntityPlayer
---@param radius number
---@param damage number
---@param knockback number
function Land.TaintedEdithHop(parent, radius, damage, knockback)
	local capsule = Capsule(parent.Position, Vector.One, 0, radius)
	
	for _, ent in ipairs(Isaac.FindInCapsule(capsule)) do
		Land.HandleEntityInteraction(ent, parent, knockback)
		Land.LandDamage(ent, parent, damage, knockback)
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
	local IsChap4 = mod:isChap4()
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
	local IsMortis = EdithRebuilt.IsLJMortis()
	local isEdithJump = Player.IsEdith(player, false) or IsSoulOfEdith or IsEdithsHood
	local isVestige = mod.IsVestigeChallenge()

	if isEdithJump then
		local isRocketLaunchStomp = data(player).RocketLaunch
		local isDefensive = Edith.GetJumpStompParams(player).IsDefensiveStomp or IsEdithsHood
		local EdithData = mod.GetConfigData(ConfigDataTypes.EDITH) ---@cast EdithData EdithData
		size = (IsSoulOfEdith and 0.8 or (isDefensive and 0.6 or 0.7)) * (isRocketLaunchStomp and 1.25 or 1)
		soundPick = EdithData.StompSound
		volume = GetVolume(EdithData.StompVolume) * (isDefensive and 1.5 or 2)
		ScreenShakeIntensity = isDefensive and 6 or (isRocketLaunchStomp and 14 or 10)
		gibAmount = EdithData.DisableSaltGibs and 0 or (isRocketLaunchStomp and 14 or 10)
		gibSpeed = isDefensive and 2 or 3
	else
		local TEdithData = mod.GetConfigData(ConfigDataTypes.TEDITH) ---@cast TEdithData TEdithData
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
	
	if mod.GetConfigData(ConfigDataTypes.MISC).EnableShakescreen then
		game:ShakeScreen(ScreenShakeIntensity)
	end

	local defColor = Color(1, 1, 1)
	local color = defColor
	local switch = {
		[EffectVariant.BIG_SPLASH] = function()
			color = mod.When(BackDrop, backColor, Color(0.7, 0.75, 1))
		end,
		[EffectVariant.POOF02] = function()
			color = BackDrop == BackdropType.DROSS and defColor or backColor[BackDrop] 
		end,
	}
	
	mod.WhenEval(Variant, switch)
	color = color or defColor

	if IsMortis then
		local Colors = {
			[MortisBackdrop.MORGUE] = Color(0, 0, 0, 1, 0.45, 0.5, 0.575),
			[MortisBackdrop.MOIST] = Color(0, 0.8, 0.76, 1, 0, 0, 0),
			[MortisBackdrop.FLESH] = Color(0, 0, 0, 1, 0.55, 0.5, 0.55),
		}
		local newcolor = mod.When(EdithRebuilt.GetMortisDrop(), Colors, Color.Default)
		color = newcolor
	end

	stompGFX:GetSprite().PlaybackSpeed = 1.3 * modRNG.RandomFloat(rng, 1, 1.5)
	stompGFX.SpriteScale = Vector(SizeX, SizeY) * player.SpriteScale.X
	stompGFX.Color = color

	GibColor = GibColor or defColor

	if gibAmount > 0 then	
		mod:SpawnSaltGib(player, gibAmount, gibSpeed, GibColor)
	end

	local sound = mod.When(soundPick, soundTable, 1)

	SfxFeedbackManager(sound, volume, IsChap4, hasWater)
end

return Land