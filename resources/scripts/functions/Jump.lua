local mod = EdithRebuilt
local enums = mod.Enums
local utils = enums.Utils
local game = utils.Game
local sfx = utils.SFX
local tables = enums.Tables
local jumpTags = tables.JumpTags
local jumpFlags = tables.JumpFlags
local helpers = include("resources.scripts.functions.Helpers")
local data = helpers.getData
local jump = {}

---Checks if player is pressing Edith's jump button
---@param player EntityPlayer
---@return boolean
function jump.IsKeyStompPressed(player)
	local k_stomp =
		Input.IsButtonPressed(Keyboard.KEY_Z, player.ControllerIndex) or
        Input.IsButtonPressed(Keyboard.KEY_LEFT_SHIFT, player.ControllerIndex) or
        Input.IsButtonPressed(Keyboard.KEY_RIGHT_SHIFT, player.ControllerIndex) or
		Input.IsButtonPressed(Keyboard.KEY_RIGHT_CONTROL, player.ControllerIndex) or
        Input.IsActionPressed(ButtonAction.ACTION_DROP, player.ControllerIndex)
		
	return k_stomp
end

---Checks if player triggered Edith's jump button
---@param player EntityPlayer
---@return boolean
function jump:IsKeyStompTriggered(player)
	local k_stomp =
		Input.IsButtonTriggered(Keyboard.KEY_Z, player.ControllerIndex) or
        Input.IsButtonTriggered(Keyboard.KEY_LEFT_SHIFT, player.ControllerIndex) or
        Input.IsButtonTriggered(Keyboard.KEY_RIGHT_SHIFT, player.ControllerIndex) or
		Input.IsButtonTriggered(Keyboard.KEY_RIGHT_CONTROL, player.ControllerIndex) or
        Input.IsActionTriggered(ButtonAction.ACTION_DROP, player.ControllerIndex)
		
	return k_stomp
end

---@param player EntityPlayer
---@param jumpTag? string
---@param vestige? boolean
function jump.InitEdithJump(player, jumpTag, vestige)	
	vestige = vestige or false
    jumpTag = jumpTag or jumpTags.EdithJump

	local canFly = player.CanFly
	local jumpSpeed = vestige and (3.75 + (player.MoveSpeed - 1)) or canFly and 1.3 or 1.85
	local soundeffect = canFly and SoundEffect.SOUND_ANGEL_WING or SoundEffect.SOUND_SHELLGAME
	local div = canFly and 25 or 15
	local base = canFly and 15 or 13
	local epicFetusMult = player:HasCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS) and 3 or 1
	local jumpHeight = (base + (mod.GetEdithTargetDistance(player) / 40) / div) * epicFetusMult
	local room = game:GetRoom()
	local isChap4 = mod:isChap4()
	local hasWater = room:HasWater()
	local variant = hasWater and EffectVariant.BIG_SPLASH or (isChap4 and EffectVariant.POOF02 or EffectVariant.POOF01)
	local subType = (isChap4 and 66 or 1)
	local DustCloud = Isaac.Spawn(
		EntityType.ENTITY_EFFECT, 
		variant, 
		subType, 
		player.Position, 
		Vector.Zero, 
		player
	):ToEffect() ---@cast DustCloud EntityEffect 
	sfx:Play(soundeffect)

    helpers.SetBloodEffectColor(DustCloud)

	DustCloud.SpriteScale = DustCloud.SpriteScale * player.SpriteScale.X
	DustCloud.DepthOffset = -100
	DustCloud:GetSprite().PlaybackSpeed = hasWater and 1.3 or 2	

	local config = {
		Height = jumpHeight,
		Speed = jumpSpeed,
		Tags = jumpTag,
		Flags = jumpFlags.EdithJump,
	}

	JumpLib:Jump(player, config)
end

---Function used to trigger Tainted Edith and Burnt Hood's parry-jump
---@param player EntityPlayer
---@param tag string
function jump.InitTaintedEdithParryJump(player, tag)
	local jumpHeight = 8
	local jumpSpeed = 2.5
	local room = game:GetRoom()
	local RoomWater = room:HasWater()
	local isChap4 = mod:isChap4()
	local variant = RoomWater and EffectVariant.BIG_SPLASH or (isChap4 and EffectVariant.POOF02 or EffectVariant.POOF01)
	local subType = RoomWater and 1 or (isChap4 and 66 or 1)
	
	sfx:Play(SoundEffect.SOUND_SHELLGAME)
	
	local DustCloud = Isaac.Spawn(
		EntityType.ENTITY_EFFECT, 
		variant, 
		subType, 
		player.Position, 
		Vector.Zero, 
		player
	) ---@cast DustCloud EntityEffect 

    helpers.SetBloodEffectColor(DustCloud)

	DustCloud.SpriteScale = DustCloud.SpriteScale * player.SpriteScale.X
	DustCloud.DepthOffset = -100
	DustCloud:GetSprite().PlaybackSpeed = RoomWater and 1.3 or 2	

	local config = {
		Height = jumpHeight,
		Speed = jumpSpeed,
		Tags = tag,
		Flags = jumpFlags.TEdithJump
	}
	JumpLib:Jump(player, config)
	data(player).IsParryJump = true
end

return jump