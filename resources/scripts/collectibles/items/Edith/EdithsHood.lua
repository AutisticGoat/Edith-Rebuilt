local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local saltTypes = enums.SaltTypes
local tables = enums.Tables
local jumpTags = tables.JumpTags
local jumpParams = tables.JumpParams
local modules = mod.Modules
local Player = modules.PLAYER
local Math = modules.MATHS
local helpers = modules.HELPERS
local RNGMod = modules.RNG
local Edith = modules.EDITH
local Land = modules.LAND
local Creeps = modules.CREEPS
local sfx = enums.Utils.SFX
local data = mod.DataHolder.GetEntityData
local maxCreep = 10
local saltDegrees = 360 / maxCreep

---@param tear EntityTear
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, function(_, tear)
	local player = helpers.GetPlayerFromTear(tear)

	if not player then return end
	if Player.IsAnyEdith(player) then return end
	if not player:HasCollectible(items.COLLECTIBLE_EDITHS_HOOD) then return end

	helpers.ForceSaltTear(tear, false)
end)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
	if not player:HasCollectible(items.COLLECTIBLE_EDITHS_HOOD) then return end
	if JumpLib:GetData(player).Jumping then return end

	local playerData = data(player)
	playerData.HoodJumpTimer = playerData.HoodJumpTimer or 0
	playerData.HoodJumpTimer = Math.Clamp(playerData.HoodJumpTimer - 1, 0, 90) or 0

	if playerData.HoodJumpTimer ~= 1 then return end
	local EdithSave = helpers.GetConfigData("EdithData") --[[@as EdithData]]
	local soundTab = tables.CooldownSounds[EdithSave.JumpCooldownSound or 1]
	local pitch = soundTab.Pitch == 1.2 and (soundTab.Pitch * RNGMod.RandomFloat(player:GetDropRNG(), 1, 1.1)) or soundTab.Pitch
	sfx:Play(soundTab.SoundID, 2, 0, false, pitch)
	Player.SetColorCooldown(player, 0.6, 5)	
end)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function(_, player)
	local playerData = data(player)

	if Player.IsAnyEdith(player) then return end
	if not player:HasCollectible(items.COLLECTIBLE_EDITHS_HOOD) then return end
	if not playerData.HoodJumpTimer or playerData.HoodJumpTimer ~= 0 then return end
	if not Input.IsActionTriggered(ButtonAction.ACTION_DROP, player.ControllerIndex) then return end

	playerData.HoodJumpTimer = 60

	Edith.InitEdithJump(player, jumpTags.EdithsHoodJump)
end)

---@param player EntityPlayer
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, function (_, player)
	if Player.IsAnyEdith(player) then return end

	local params = Edith.GetJumpStompParams(player)
	local playerData = data(player)

	params.Damage = (player.Damage * 1.5) * 3
	params.Radius = 40
	params.Knockback = 15

	playerData.HoodLand = true
	Land.LandFeedbackManager(player, Land.GetLandSoundTable(false), Color.Default, false)
	playerData.HoodLand = false
	Land.EdithStomp(player, params, false)
	Land.TriggerLandenemyJump(player, params.StompedEntities, params.Knockback, 10, 1.8)

	for i = 1, maxCreep do
		Creeps.SpawnSaltCreep(player, player.Position + Vector(0, 30):Rotated(saltDegrees*i), 0.1, 5, 1, 3, saltTypes.EDITHS_HOOD)
	end
	player:SetMinDamageCooldown(30)
end, jumpParams.EdithsHoodJump)

---@param npc EntityNPC
---@param source EntityRef
mod:AddCallback(PRE_NPC_KILL.ID, function(_, npc, source)
	local saltedType = data(npc).SaltType ---@cast saltedType SaltTypes
    local player = helpers.GetPlayerFromRef(source)

    if not player then return end
    if saltedType ~= saltTypes.EDITHS_HOOD then return end

	local rng = player:GetCollectibleRNG(items.COLLECTIBLE_EDITHS_HOOD)
	local randomTears = rng:RandomInt(4, 8)

	for _ = 1, randomTears do
		local tear = player:FireTear(npc.Position, rng:RandomVector():Resized(player.ShotSpeed * 10), false, false, false, player, 1.2)
		tear:AddTearFlags(player.TearFlags)
	end
end)