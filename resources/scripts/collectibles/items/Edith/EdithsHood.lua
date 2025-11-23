local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local saltTypes = enums.SaltTypes
local sounds = enums.SoundEffect
local tables = enums.Tables
local jumpTags = tables.JumpTags
local jumpFlags = tables.JumpFlags
local jumpParams = tables.JumpParams
local game = enums.Utils.Game
local sfx = enums.Utils.SFX
local data = mod.CustomDataWrapper.getData
local EdithsHood = {}
local backdropColors = tables.BackdropColors
local saveManager = mod.SaveManager

local MortisBackdrop = {
	FLESH = 1,
	MOIST = 2,
	MORGUE = 3
}

---Helper function for Edith's cooldown color manager
---@param player EntityPlayer
---@param intensity number
---@param duration integer
function EdithsHood:ColorCooldown(player, intensity, duration)
	local pcolor = player.Color
	local col = pcolor:GetColorize()
	local tint = pcolor:GetTint()
	local off = pcolor:GetOffset()
	local Red = off.R + (intensity + ((col.R + tint.R) * 0.2))
	local Green = off.G + (intensity + ((col.G + tint.G) * 0.2))
	local Blue = off.B + (intensity + ((col.B + tint.B) * 0.2))
		
	pcolor:SetOffset(Red, Green, Blue)
	player:SetColor(pcolor, duration, 100, true, false)
end

---@param player EntityPlayer
local function InitEdithsHoodJump(player)	
	local canFly = player.CanFly
	local jumpSpeed = 1.85
	local soundeffect = canFly and SoundEffect.SOUND_ANGEL_WING or SoundEffect.SOUND_SHELLGAME
	local div = canFly and 25 or 15
	local base = canFly and 15 or 13
	local IsMortis = mod.IsLJMortis()
	local epicFetusMult = player:HasCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS) and 3 or 1
	local jumpHeight = (base + (mod.GetEdithTargetDistance(player) / 40) / div) * epicFetusMult
	local room = game:GetRoom()
	local isChap4 = mod:isChap4()
	local BackDrop = room:GetBackdropType()
	local hasWater = room:HasWater()
	local variant = hasWater and EffectVariant.BIG_SPLASH or (isChap4 and EffectVariant.POOF02 or EffectVariant.POOF01)
	local subType = hasWater and 1 or (isChap4 and 66 or 1)
	local DustCloud = Isaac.Spawn(
		EntityType.ENTITY_EFFECT, 
		variant, 
		subType, 
		player.Position, 
		Vector.Zero, 
		player
	)
	sfx:Play(soundeffect)

	local color = Color(1, 1, 1)
	local switch = {
		[EffectVariant.BIG_SPLASH] = function()
			color = backdropColors[BackDrop] or Color(0.7, 0.75, 1)
			if IsMortis then
				color = Color(0, 0.8, 0.76, 1, 0, 0, 0)
			end
		end,
		[EffectVariant.POOF02] = function()
			color = backdropColors[BackDrop] or Color(1, 0, 0)

			if IsMortis then
				local Colors = {
					[MortisBackdrop.MORGUE] = Color(0, 0, 0, 1, 0.45, 0.5, 0.575),
					[MortisBackdrop.MOIST] = Color(0, 0.8, 0.76, 1, 0, 0, 0),
					[MortisBackdrop.FLESH] = Color(0, 0, 0, 1, 0.55, 0.5, 0.55),
				}
				local newcolor = mod.When(EdithRebuilt.GetMortisDrop(), Colors, Color.Default)
				color = newcolor
			end
		end,
		[EffectVariant.POOF01] = function()
			if hasWater then
				color = backdropColors[BackDrop]
			end
		end
	}
	mod.WhenEval(variant, switch)

	DustCloud.SpriteScale = DustCloud.SpriteScale * player.SpriteScale.X
	DustCloud.DepthOffset = -100
	DustCloud:SetColor(color, -1, 100, false, false)
	DustCloud:GetSprite().PlaybackSpeed = hasWater and 1.3 or 2	

	local config = {
		Height = jumpHeight,
		Speed = jumpSpeed,
		Tags = jumpTags.EdithsHoodJump,
		Flags = jumpFlags.EdithJump,
	}

	JumpLib:Jump(player, config)
end

---@param tear EntityTear
function EdithsHood:ShootSaltTears(tear)
	local player = mod:GetPlayerFromTear(tear)
	
	if not player then return end
	if mod:IsAnyEdith(player) then return end
	if not player:HasCollectible(items.COLLECTIBLE_EDITHS_HOOD) then return end
	
	mod.ForceSaltTear(tear)
end
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, EdithsHood.ShootSaltTears)

---@param player EntityPlayer
function EdithsHood:Stats(player)
	if not player:HasCollectible(items.COLLECTIBLE_EDITHS_HOOD) then return end
	player.Damage = player.Damage * 1.35
end
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, EdithsHood.Stats, CacheFlag.CACHE_DAMAGE)

local maxCreep = 10
local saltDegrees = 360 / maxCreep

function EdithsHood:JumpCooldown(player)
	if not player:HasCollectible(items.COLLECTIBLE_EDITHS_HOOD) then return end
	local playerData = data(player)
	playerData.HoodJumpTimer = playerData.HoodJumpTimer or 90
	playerData.HoodJumpTimer = mod.Clamp(playerData.HoodJumpTimer - 1, 0, 90)

	if playerData.HoodJumpTimer == 1 then
		EdithsHood:ColorCooldown(player, 0.6, 5)
		local EdithSave = saveManager.GetSettingsSave().EdithData
		local soundTab = tables.CooldownSounds[EdithSave.CooldownSound or 1]
		local pitch = soundTab.Pitch == 1.2 and (soundTab.Pitch * mod.RandomFloat(player:GetDropRNG(), 1, 1.1)) or soundTab.Pitch
		sfx:Play(soundTab.SoundID, 2, 0, false, pitch)
		playerData.StompedEntities = nil
		playerData.IsDefensiveStomp = false
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, EdithsHood.JumpCooldown)

function EdithsHood:TriggerJump(player)
	if not player:HasCollectible(items.COLLECTIBLE_EDITHS_HOOD) then return end
	if data(player).HoodJumpTimer ~= 0 then return end
	if not Input.IsActionTriggered(ButtonAction.ACTION_DROP, player.ControllerIndex) then return end
	
	data(player).HoodJumpTimer = 90
	InitEdithsHoodJump(player)	
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, EdithsHood.TriggerJump)

local SoundPick = {
	[1] = SoundEffect.SOUND_STONE_IMPACT, 
	[2] = sounds.SOUND_EDITH_STOMP,
	[3] = sounds.SOUND_FART_REVERB,
	[4] = sounds.SOUND_VINE_BOOM,
}

function EdithsHood:OnHoodJumpLand(player)
	mod.LandFeedbackManager(player, SoundPick, Color.Default, false)
	mod:EdithStomp(player, 30, (player.Damage / 2) * 3, 30, false)
	for i = 1, maxCreep do
		mod:SpawnSaltCreep(player, player.Position + Vector(0, 30):Rotated(saltDegrees*i), 0.1, 5, 1, 3, saltTypes.EDITHS_HOOD)
	end
	
	player:SetMinDamageCooldown(20)
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, EdithsHood.OnHoodJumpLand, jumpParams.EdithsHoodJump)

---@param npc EntityNPC
---@param source EntityRef
function EdithsHood:OnSaltedDeath(npc, source)
    local saltedType = data(npc).SaltType ---@cast saltedType SaltTypes
    local player = mod.GetPlayerFromRef(source)

    if not player then return end
    if saltedType ~= saltTypes.EDITHS_HOOD then return end

	local rng = player:GetCollectibleRNG(items.COLLECTIBLE_EDITHS_HOOD)
	local randomTears = rng:RandomInt(4, 8)
	local tear

	for i = 1, randomTears do
		tear = player:FireTear(npc.Position, rng:RandomVector():Resized(player.ShotSpeed * 10), false, false, false, player, 1.2)

		tear:AddTearFlags(player.TearFlags)
	end
end 
mod:AddCallback(PRE_NPC_KILL.ID, EdithsHood.OnSaltedDeath)