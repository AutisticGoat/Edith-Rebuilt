local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local saltTypes = enums.SaltTypes
local Player = mod.Modules.PLAYER
local tables = enums.Tables
local jumpTags = tables.JumpTags
local jumpParams = tables.JumpParams
local modules = mod.Modules
local Math = modules.MATHS
local helpers = modules.HELPERS
local RNGMod = modules.RNG
local Edith = modules.EDITH
local Land = modules.LAND
local Creeps = modules.CREEPS
local sfx = enums.Utils.SFX
local data = mod.DataHolder.GetEntityData
local EdithsHood = {}

---@param tear EntityTear
function EdithsHood:ShootSaltTears(tear)
	local player = helpers.GetPlayerFromTear(tear)
	
	if not player then return end
	if Player.IsAnyEdith(player) then return end
	if not player:HasCollectible(items.COLLECTIBLE_EDITHS_HOOD) then return end
	
	helpers.ForceSaltTear(tear, false)
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
	playerData.StompedEntities = nil
	playerData.IsDefensiveStomp = false
end
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, EdithsHood.JumpCooldown)

function EdithsHood:TriggerJump(player)
	local data = data(player)

	if not player:HasCollectible(items.COLLECTIBLE_EDITHS_HOOD) then return end
	if not data.HoodJumpTimer or data.HoodJumpTimer ~= 0 then return end
	if not Input.IsActionTriggered(ButtonAction.ACTION_DROP, player.ControllerIndex) then return end
	
	data.HoodJumpTimer = 90

	Edith.InitEdithJump(player, jumpTags.EdithsHoodJump)
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, EdithsHood.TriggerJump)

function EdithsHood:OnHoodJumpLand(player)
	local params = Edith.GetJumpStompParams(player)

	params.Damage = (player.Damage * 0.75) * 3
	params.Radius = 30
	params.Knockback = 5

	Land.LandFeedbackManager(player, Land.GetLandSoundTable(false), Color.Default, false)
	Land.EdithStomp(player, params, false)
	Land.TriggerLandenemyJump(player, params, 10, 1.8)

	for i = 1, maxCreep do
		Creeps.SpawnSaltCreep(player, player.Position + Vector(0, 30):Rotated(saltDegrees*i), 0.1, 5, 1, 3, saltTypes.EDITHS_HOOD)
	end
	player:SetMinDamageCooldown(20)
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, EdithsHood.OnHoodJumpLand, jumpParams.EdithsHoodJump)

---@param npc EntityNPC
---@param source EntityRef
function EdithsHood:OnSaltedDeath(npc, source)
    local saltedType = data(npc).SaltType ---@cast saltedType SaltTypes
    local player = helpers.GetPlayerFromRef(source)

    if not player then return end
    if saltedType ~= saltTypes.EDITHS_HOOD then return end

	local rng = player:GetCollectibleRNG(items.COLLECTIBLE_EDITHS_HOOD)
	local randomTears = rng:RandomInt(4, 8)
	local tear

	for _ = 1, randomTears do
		tear = player:FireTear(npc.Position, rng:RandomVector():Resized(player.ShotSpeed * 10), false, false, false, player, 1.2)

		tear:AddTearFlags(player.TearFlags)
	end
end 
mod:AddCallback(PRE_NPC_KILL.ID, EdithsHood.OnSaltedDeath)