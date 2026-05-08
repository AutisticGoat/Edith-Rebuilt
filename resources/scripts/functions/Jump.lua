local mod = EdithRebuilt
local enums = mod.Enums
local utils = enums.Utils
local tables = enums.Tables
local jumpTags = tables.JumpTags
local jumpFlags = tables.JumpFlags
local sfx = utils.SFX
local game = utils.Game
local data = mod.DataHolder.GetEntityData
local Jump = {}

---@param entity Entity
---@return boolean
function Jump.IsJumping(entity)
	return JumpLib:GetData(entity).Jumping
end

---@param entity Entity
---@return integer
function Jump.GetJumpFrame(entity)
    return Jump.IsJumping(entity) and JumpLib.Internal:GetData(entity).UpdateFrame or 0
end

---@param player EntityPlayer
---@param hasWater boolean
---@param isChap4 boolean
local function SpawnJumpDustCloud(player, hasWater, isChap4)
	local effectConfig = hasWater and {
		variant = EffectVariant.BIG_SPLASH,
		subType = 1,
		speed   = 1.3,
	} or isChap4 and {
		variant = EffectVariant.POOF02,
		subType = 66,
		speed   = 2,
	} or {
		variant = EffectVariant.POOF01,
		subType = 1,
		speed   = 2,
	}

	local dustCloud = Isaac.Spawn(
		EntityType.ENTITY_EFFECT,
		effectConfig.variant,
		effectConfig.subType,
		player.Position,
		Vector.Zero,
		player
	):ToEffect() ---@cast dustCloud EntityEffect

	mod.Modules.HELPERS.SetBloodEffectColor(dustCloud)
	dustCloud.SpriteScale = dustCloud.SpriteScale * player.SpriteScale.X
	dustCloud.DepthOffset = -100
	dustCloud:GetSprite().PlaybackSpeed = effectConfig.speed
end

---@param jumpData JumpData
---@param tag string
function Jump.IsSpecificJump(jumpData, tag)
	return jumpData.Tags[tag] ~= nil
end	

---@param player EntityPlayer
---@param params EdithJumpStompParams|TEdithHopParryParams
function Jump.SetBombJump(player, params)
	if not Input.IsActionTriggered(ButtonAction.ACTION_BOMB, player.ControllerIndex) then return end
	if not mod.Modules.PLAYER.CanTriggerBombStomp(player) then return end

	local isStomp = params.BombStomp ~= nil
	local isParry = params.ParryBomb ~= nil

	if isStomp then
		local hasRocketInAJar = player:HasCollectible(CollectibleType.COLLECTIBLE_ROCKET_IN_A_JAR)
		params.BombStomp = not hasRocketInAJar
		params.RocketLaunch = hasRocketInAJar
	elseif isParry then
		params.ParryBomb = true
	end
end	

---Function used to trigger Tainted Edith and Burnt Hood's parry-jump
---@param player EntityPlayer
---@param tag string
function Jump.InitTaintedEdithParryJump(player, tag)
	local room = game:GetRoom()

	sfx:Play(SoundEffect.SOUND_SHELLGAME)
	SpawnJumpDustCloud(player, room:HasWater(), mod.Modules.HELPERS.IsChap4())

	JumpLib:Jump(player, {
		Height = 8,
		Speed  = 5.5,
		Tags   = tag,
		Flags  = jumpFlags.TEdithJump,
	})

	data(player).IsParryJump = true
end

---@param player EntityPlayer
---@param jumpTag? string
---@param vestige? boolean
function Jump.InitEdithJump(player, jumpTag, vestige)
	vestige = vestige or false
	jumpTag = jumpTag or jumpTags.EdithJump

	local canFly = player.CanFly
	local room = game:GetRoom()
	local modules = mod.Modules
	local jumpSpeed = vestige and (4 + (player.MoveSpeed - 1)) or canFly and 1.3 or 1.85
	local soundEffect = canFly and SoundEffect.SOUND_ANGEL_WING or SoundEffect.SOUND_SHELLGAME
	local div = vestige and 1 or (canFly and 25 or 15)
	local base = vestige and 40 or (canFly and 15 or 13)
	local epicFetusMult = player:HasCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS) and 3 or 1
	local jumpHeight = not vestige and ((base + (modules.TARGET_ARROW.GetEdithTargetDistance(player) / 40) / div) * epicFetusMult) or base

	sfx:Play(soundEffect)
	SpawnJumpDustCloud(player, room:HasWater(), modules.HELPERS.IsChap4())

	JumpLib:TryJump(player, {
		Height = jumpHeight,
		Speed  = jumpSpeed,
		Tags   = jumpTag,
		Flags  = jumpFlags.EdithJump,
	})
end

local JumpHeightParams = {
	growth = 0.35, 
	offset = 0.65, 
	curve = 1
}

---@param player EntityPlayer
function Jump.InitTaintedEdithHop(player)
	local charge = mod.Modules.TEDITH.GetHopDashCharge(player, false, false)

	if not charge or charge <= 0 then return end

	local Maths = mod.Modules.MATHS
	local jumpHeight = Maths.HopHeightCalc(6, charge, JumpHeightParams)
	local jumpSpeed = 3 * Maths.Log(charge, 100)
	local config = {
		Height = jumpHeight,
		Speed = jumpSpeed,
		Tags = jumpTags.TEdithHop,
		Flags = jumpFlags.TEdithHop
	}
	JumpLib:Jump(player, config) 
end

return Jump