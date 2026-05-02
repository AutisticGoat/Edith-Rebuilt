---@diagnostic disable: undefined-field
local mod = EdithRebuilt
local enums = mod.Enums
local utils = enums.Utils
local tables = enums.Tables
local game = utils.Game
local JumpParams = tables.JumpParams
local modules = mod.Modules
local EdithMod = modules.EDITH
local Land = modules.LAND
local TargetArrow = modules.TARGET_ARROW
local effects = modules.STATUS_EFFECTS
local helpers = modules.HELPERS
local Player = modules.PLAYER
local ModRNG = modules.RNG
local VecDir = modules.VEC_DIR
local Jump = modules.JUMP
local data = mod.DataHolder.GetEntityData
local params = EdithMod.GetJumpStompParams

---@class EdithUpdateState 
---@field isMoving boolean
---@field isKeyStompPressed boolean
---@field hasMarked boolean
---@field isShooting boolean
---@field jumpData JumpData
---@field isPitfall boolean
---@field isJumping boolean
---@field isVestige boolean
---@field jumpParams EdithJumpStompParams

---@param player EntityPlayer
local function EdithTeleportManager(player)
	if not player:GetSprite():IsPlaying("TeleportDown") then return end
	JumpLib:QuitJump(player)
	TargetArrow.RemoveEdithTarget(player, false)
end

local function HandleEdithInit(player)
	if player.FrameCount ~= 0 then return end
	Player.SetCustomSprite(player, false)
	if helpers.GetConfigData(enums.ConfigDataTypes.EDITH).SaltShakerSlot == 1 then
		player:RemoveCollectible(enums.CollectibleType.COLLECTIBLE_SALTSHAKER)
		player:SetPocketActiveItem(enums.CollectibleType.COLLECTIBLE_SALTSHAKER, ActiveSlot.SLOT_POCKET, false)
	end
end

---@param player EntityPlayer
---@param state EdithUpdateState
local function HandleTargetSpawn(player, state)
	if player.FrameCount == 0 then return end
	local shouldSpawn = state.isMoving or state.isKeyStompPressed or (state.hasMarked and state.isShooting)
	if shouldSpawn and not state.isPitfall and not state.jumpData.Tags.EdithRebuilt_FlatStoneLand then
		TargetArrow.SpawnEdithTarget(player)
	end
end

---@param player EntityPlayer
---@param target EntityEffect?
---@param state EdithUpdateState
local function HandleTargetManagers(player, target, state)
	if not target then return end
	EdithMod.TargetMovementManager(player, target, state.isMoving)
	EdithMod.JumpTriggerManager(player, state.jumpParams, state.isKeyStompPressed, state.isJumping, state.isVestige)
	EdithMod.HeadDirectionManager(player, state.isJumping, state.isShooting, state.isKeyStompPressed)
end

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function(_, player)
	if not Player.IsEdith(player, false) then return end

	if player:IsDead() or helpers.IsDSSMenuOpen() then
		TargetArrow.RemoveEdithTarget(player)
		return
	end

	local state = {
		isMoving = TargetArrow.IsEdithTargetMoving(player),
		isKeyStompPressed = helpers.IsKeyStompPressed(player),
		hasMarked  = player:HasCollectible(CollectibleType.COLLECTIBLE_MARKED),
		isShooting = Player.IsPlayerShooting(player),
		jumpData = JumpLib:GetData(player),
		isPitfall = JumpLib:IsPitfalling(player),
		isJumping = Jump.IsJumping(player),
		isVestige = helpers.IsVestigeChallenge(),
		jumpParams = params(player),
	} ---@cast state EdithUpdateState

	HandleEdithInit(player)
	HandleTargetSpawn(player, state)

	EdithTeleportManager(player)
	EdithMod.CustomDropBehavior(player, state.jumpParams)
	Player.ManageEdithWeapons(player)
	EdithMod.DashItemBehavior(player)

	HandleTargetManagers(player, TargetArrow.GetEdithTarget(player), state)
end)

---@param player EntityPlayer
---@return boolean
local function IsInTrapdoor(player)
	local grid = game:GetRoom():GetGridEntityFromPos(player.Position)
	return grid and grid:GetType() == GridEntityType.GRID_TRAPDOOR or false
end

---@param pos Vector
---@return boolean
local function IsFleshTrapdoorAtPos(pos)
	local grid = game:GetRoom():GetGridEntityFromPos(pos)
	if not grid then return false end
	local trapdoor = grid:ToTrapDoor()
	if not trapdoor then return false end
	local path = trapdoor:GetSprite():GetLayer(0):GetSpritesheetPath()
	return string.find(path, "womb") ~= nil
		or (string.find(path, "corpse") ~= nil
			and not string.find(path, "corpse_big"))
end

---@param player EntityPlayer
mod:AddCallback(JumpLib.Callbacks.POST_ENTITY_JUMP, function(_, player)
	local jumpParams = params(player)

	jumpParams.JumpStartPos = player.Position
	jumpParams.JumpStartDist = TargetArrow.GetEdithTargetDistance(player)

	if not player:HasCollectible(CollectibleType.COLLECTIBLE_LUMP_OF_COAL) then return end

	local rng = player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_LUMP_OF_COAL)
	jumpParams.CoalBonus = ModRNG.RandomFloat(rng, 0.5, 0.6) * jumpParams.JumpStartDist / 40
end, JumpParams.EdithJump)

---@param player EntityPlayer
local function ManageFeedback(player)
    if IsInTrapdoor(player) then return end
    Land.LandFeedbackManager(player, Land.GetLandSoundTable(false), player.Color, false)
end

---@param player EntityPlayer
local function ManageVestigeLandAnim(player)
    if not helpers.IsVestigeChallenge() then return end
    player:PlayExtraAnimation("BigJumpFinish")
end

---@param player EntityPlayer
---@param jumpParams EdithJumpStompParams
local function ExecuteStompSequence(player, jumpParams)
    EdithMod.StompKnockbackManager(player, jumpParams)
    EdithMod.StompCooldownManager(player, jumpParams)
    EdithMod.StompDamageManager(player, jumpParams)
    EdithMod.StompRadiusManager(player, jumpParams)

    Land.EdithStomp(player, jumpParams, true)
    Land.TriggerLandenemyJump(player, jumpParams.StompedEntities, jumpParams.Knockback, 8, 2)
    Land.BombLandManager(player, jumpParams)
end

---@param player EntityPlayer
---@param edithTarget EntityEffect
local function ApplyLandingState(player, edithTarget)
    edithTarget:GetSprite():Play("Idle")
    player:SetMinDamageCooldown(25)
    player:MultiplyFriction(0.1)
end

---@param player EntityPlayer
local function ResetPropulsionState(player)
	local playerData = data(player)

    params(player).RocketLaunch = false
    playerData.RocketPropulsion = false
    playerData.BombPropulsion = false
end

mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, function(_, player, _, pitfall)
    local edithTarget = TargetArrow.GetEdithTarget(player)
    if not edithTarget then return end

    if pitfall then
        TargetArrow.RemoveEdithTarget(player)
        return
    end

    local jumpParams = params(player)

    ManageFeedback(player)
    ManageVestigeLandAnim(player)
    ExecuteStompSequence(player, jumpParams)
    ApplyLandingState(player, edithTarget)
    ResetPropulsionState(player)

    EdithMod.StompTargetRemover(player)
end, JumpParams.EdithJump)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
	if not Player.IsEdith(player, false) then return end

	local jumpParams = params(player)
	Player.WaterCurrentManager(player)

	if jumpParams.RocketLaunch then return end
	EdithMod.CooldownUpdate(player, jumpParams)
end)

---@param ent Entity
mod:AddCallback(enums.Callbacks.OFFENSIVE_STOMP_KILL, function(_, _, ent)
	data(ent).KilledByStomp = true
end)

---@param npc EntityNPC
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, function (_, npc)
	if npc:IsBoss() then return end
	if not effects.EntHasStatusEffect(npc, "Salt") then return end
	if not data(npc).KilledByStomp then return end

	return true
end)

---@param player EntityPlayer
---@param jumpdata JumpData
mod:AddCallback(JumpLib.Callbacks.ENTITY_UPDATE_60, function (_, player, jumpdata)
	if not Player.IsEdith(player, false) then return end

	local jumpIntData = JumpLib.Internal:GetData(player)
	local jumpParams = params(player)

	EdithMod.JumpMovement(player, helpers.IsVestigeChallenge())
	EdithMod.DefensiveStompManager(player, jumpIntData, jumpParams)
	EdithMod.FlightFallBehavior(player, jumpdata, jumpParams)
	Jump.SetBombJump(player, jumpParams)
	EdithMod.BombFall(player, jumpdata, jumpParams)
end, JumpParams.EdithJump)

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function ()
	Player.ForEachPlayerType(function(player)
		helpers.ChangeColor(player, nil, nil, nil, 1)
		TargetArrow.RemoveEdithTarget(player)
		params(player).CanJump = false
	end, enums.PlayerType.PLAYER_EDITH)
end)

---@param damage number
---@param source EntityRef
---@return boolean?
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function (_, _, damage, _, source)
	if source.Type == 0 then return end

	local ent = source.Entity
	local familiar = ent:ToFamiliar()
	local player = helpers.GetPlayerFromRef(source)

	if not player then return end
	if not Player.IsEdith(player, false) then return end
	if not Jump.IsJumping(player) then return end

	local HasHeels = player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_HEELS)

	if not (familiar or (HasHeels and damage == 12)) then return end
	return false
end)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_RENDER, function(_, player)
	if not Player.IsEdith(player, false) then return end

	local sprite = player:GetSprite()

	if not sprite:IsPlaying("Trapdoor") then return end
	if sprite:GetFrame() ~= 4 then return end
	if not IsFleshTrapdoorAtPos(player.Position) then return end
	game:StartStageTransition(false, 0, player)
end)

---@param ID CollectibleType
---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, function(_, ID, _, player)
    if helpers.When(ID, tables.RemoveTargetItems, false) then
        TargetArrow.RemoveEdithTarget(player)
    end

    if ID == CollectibleType.COLLECTIBLE_KAMIKAZE then
        if not Player.IsEdith(player, false) then return end
        if not Jump.IsJumping(player) then return end
        return true
    end
end)

---@param bomb EntityBomb
mod:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, function(_, bomb)
	if not bomb:GetSprite():IsPlaying("Explode") then return end
	local player
	for _, ent in ipairs(Isaac.FindInRadius(bomb.Position, helpers.GetBombRadiusFromDamage(bomb.ExplosionDamage), EntityPartition.PLAYER)) do
		player = ent:ToPlayer() ---@cast player EntityPlayer
		if not Player.IsEdith(player, false) then goto continue end
		data(player).BombPropulsion = true
		EdithMod.ExplosionRecoil(player, params(player), bomb)
		::continue::
	end
end)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_POCKET_ITEMS_SWAP, function(_, player)
	if not Player.IsEdith(player, false) then return end
	if Jump.IsJumping(player) then return end
	return true
end)