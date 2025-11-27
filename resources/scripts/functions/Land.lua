---@diagnostic disable: undefined-global, param-type-mismatch
local mod = EdithRebuilt
local enums = mod.Enums
local utils = enums.Utils
local game = utils.Game
local sfx = utils.SFX
local ConfigDataTypes = enums.ConfigDataTypes
local tables = enums.Tables
local data = mod.CustomDataWrapper.getData
local Math = include("resources.scripts.functions.Maths")
local Land = {}

---Custom Edith stomp Behavior
---@param parent EntityPlayer
---@param params EdithJumpStompParams
---@param breakGrid boolean
function Land.EdithStomp(parent, params, breakGrid)
	local isDefStomp = params.IsDefensiveStomp or data(parent).HoodLand
	local damage, knockback, radius = params.Damage, params.Knockback, params.Radius
	local HasTerra = parent:HasCollectible(CollectibleType.COLLECTIBLE_TERRA)
	local TerraRNG = parent:GetCollectibleRNG(CollectibleType.COLLECTIBLE_TERRA)
	local TerraMult = HasTerra and mod.RandomFloat(TerraRNG, 0.5, 2) or 1	
	local FrozenMult, BCRRNG
	local capsule = Capsule(parent.Position, Vector.One, 0, radius)
	local SaltedTime = Math.Round(Math.Clamp(120 * (mod.GetTPS(parent) / 2.73), 60, 360))
	local isSalted

	params.StompedEntities = Isaac.FindInCapsule(capsule)

	--- Pendiente de reducir
	for _, ent in ipairs(params.StompedEntities) do
		if GetPtrHash(parent) == GetPtrHash(ent) then goto Break end

		isSalted = mod.IsSalted(ent)
		local knockbackMult = isSalted and 1.5 or 1

		mod.HandleEntityInteraction(ent, parent, knockback * knockbackMult)

		if ent.Type == EntityType.ENTITY_STONEY then
			ent:ToNPC().State = NpcState.STATE_SPECIAL
		end

		Isaac.RunCallback(mod.Enums.Callbacks.OFFENSIVE_STOMP, parent, ent)	

		if isDefStomp then
			EdithRebuilt.SetSalted(ent, SaltedTime, parent)
			if data(parent).HoodLand then
				data(ent).SaltType = enums.SaltTypes.EDITHS_HOOD
			end
			goto Break
		end

		if not mod.IsEnemy(ent) then goto Break end

		FrozenMult = ent:HasEntityFlags(EntityFlag.FLAG_FREEZE) and 1.2 or 1 
		damage = (damage * FrozenMult) * TerraMult

		mod.LandDamage(ent, parent, damage, knockback)
		sfx:Play(SoundEffect.SOUND_MEATY_DEATHS)

		if ent.HitPoints > damage then goto Break end

		if BirthcakeRebaked and parent:HasTrinket(BirthcakeRebaked.Birthcake.ID) and isSalted then
			BCRRNG = parent:GetTrinketRNG(BirthcakeRebaked.Birthcake.ID)
			for _ = 1, BCRRNG:RandomInt(3, 7) do
				parent:FireTear(parent.Position, RandomVector():Resized(15))
			end
		end
		mod.AddExtraGore(ent, parent)
		::Break::
	end

	if breakGrid then
		mod:DestroyGrid(parent, radius)
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
	local isEdithJump = mod.IsEdith(player, false) or IsSoulOfEdith or IsEdithsHood
	local isVestige = mod.IsVestigeChallenge()

	if isEdithJump then
		local isRocketLaunchStomp = data(player).RocketLaunch
		local isDefensive = mod.IsDefensiveStomp(player) or IsEdithsHood
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
	local RandSize = { X = mod.RandomFloat(rng, 0.8, 1), Y = mod.RandomFloat(rng, 0.8, 1) }
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

	stompGFX:GetSprite().PlaybackSpeed = 1.3 * mod.RandomFloat(rng, 1, 1.5)
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