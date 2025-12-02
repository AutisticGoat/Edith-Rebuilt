---@diagnostic disable: undefined-global, param-type-mismatch
local mod = EdithRebuilt
local enums = mod.Enums
local effectVariant = enums.EffectVariant
local utils = enums.Utils
local game = utils.Game
local level = utils.Level
local sfx = utils.SFX
local ConfigDataTypes = enums.ConfigDataTypes
local tables = enums.Tables
local jumpTags = tables.JumpTags
local jumpFlags = tables.JumpFlags
local misc = enums.Misc
local players = enums.PlayerType
local sounds = enums.SoundEffect
local data = mod.CustomDataWrapper.getData
local saveManager = mod.SaveManager

local Math = mod.Modules.MATHS

local MortisBackdrop = {
	FLESH = 1,
	MOIST = 2,
	MORGUE = 3
}

---Checks if player is Edith
---@param player EntityPlayer
---@param tainted boolean set it to `true` to check if player is Tainted Edith
---@return boolean
function EdithRebuilt.IsEdith(player, tainted)
	return player:GetPlayerType() == (tainted and players.PLAYER_EDITH_B or players.PLAYER_EDITH)
end

---Checks if any player is Edith
---@param player EntityPlayer
---@return boolean
function EdithRebuilt:IsAnyEdith(player)
	return mod.IsEdith(player, true) or mod.IsEdith(player, false)
end

---Checks if Edith's target is moving
---@param player EntityPlayer
---@return boolean
function EdithRebuilt.IsEdithTargetMoving(player)
	local k_up = Input.IsActionPressed(ButtonAction.ACTION_UP, player.ControllerIndex)
    local k_down = Input.IsActionPressed(ButtonAction.ACTION_DOWN, player.ControllerIndex)
    local k_left = Input.IsActionPressed(ButtonAction.ACTION_LEFT, player.ControllerIndex)
    local k_right = Input.IsActionPressed(ButtonAction.ACTION_RIGHT, player.ControllerIndex)
	
    return (k_down or k_right or k_left or k_up) or false
end

--[[Perform a Switch/Case-like selection.  
    `value` is used to index `cases`.  
    When `value` is `nil`, returns `default`.  
    **Note:** Type inference on this function is decent, but not perfect.
    You might want to use things such as [casting](https://luals.github.io/wiki/annotations/#as)
    the returned value.
    ]]
---@generic In, Out, Default
---@param value?    In
---@param cases     { [In]: Out }
---@param default?  Default
---@return Out|Default
function EdithRebuilt.When(value, cases, default)
    return value and cases[value] or default
end

--[[Perform a Switch/Case-like selection, like @{EdithRebuilt.When}, but takes a
    table of functions and runs the found matching case to return its result.  
    `value` is used to index `cases`.
    When `value` is `nil`, returns `default`, or runs it and returns its value if
    it is a function.  
    **Note:** Type inference on this function is decent, but not perfect.
    You might want to use things such as [casting](https://luals.github.io/wiki/annotations/#as)
    the returned value.
    ]]
---@generic In, Out, Default
---@param value? In
---@param cases { [In]: fun(): Out }
---@param default?  fun(): Default
---@return Out|Default
function EdithRebuilt.WhenEval(value, cases, default)
    local f = mod.When(value, cases)
    local v = (f and f()) or (default and default())
    return v
end

---@param player EntityPlayer
function EdithRebuilt.PlayerHasBirthright(player)
	return player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)
end

---Helper function for Edith's cooldown color manager
---@param player EntityPlayer
---@param intensity number
---@param duration integer
function EdithRebuilt.SetColorCooldown(player, intensity, duration)
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

---Used to add some interactions to Judas' Birthright effect
---@param player EntityPlayer
function EdithRebuilt.IsJudasWithBirthright(player)
	return player:GetPlayerType() == PlayerType.PLAYER_JUDAS and mod.PlayerHasBirthright(player)
end

---Checks if player is pressing Edith's jump button
---@param player EntityPlayer
---@return boolean
function EdithRebuilt.IsKeyStompPressed(player)
	local k_stomp =
		Input.IsButtonPressed(Keyboard.KEY_Z, player.ControllerIndex) or
        Input.IsButtonPressed(Keyboard.KEY_LEFT_SHIFT, player.ControllerIndex) or
        Input.IsButtonPressed(Keyboard.KEY_RIGHT_SHIFT, player.ControllerIndex) or
		Input.IsButtonPressed(Keyboard.KEY_RIGHT_CONTROL, player.ControllerIndex) or
        Input.IsActionPressed(ButtonAction.ACTION_DROP, player.ControllerIndex)
		
	return k_stomp
end

---Checks if player triggered Edith's jump action
---@param player EntityPlayer
---@return boolean
function EdithRebuilt:IsKeyStompTriggered(player)
	local k_stomp =
		Input.IsButtonTriggered(Keyboard.KEY_Z, player.ControllerIndex) or
        Input.IsButtonTriggered(Keyboard.KEY_LEFT_SHIFT, player.ControllerIndex) or
        Input.IsButtonTriggered(Keyboard.KEY_RIGHT_SHIFT, player.ControllerIndex) or
		Input.IsButtonTriggered(Keyboard.KEY_RIGHT_CONTROL, player.ControllerIndex) or
        Input.IsActionTriggered(ButtonAction.ACTION_DROP, player.ControllerIndex)
		
	return k_stomp
end

---@param player EntityPlayer
---@return boolean
function EdithRebuilt.IsDefensiveStomp(player)
	if not mod.IsEdith(player, false) then return false end
	return data(player).IsDefensiveStomp 
end

---Helper range stat manager function
---@param range number
---@param val number
---@return number
function EdithRebuilt.rangeUp(range, val)
    local currentRange = range / 40.0
    local newRange = currentRange + val
    return math.max(1.0, newRange) * 40.0
end

---Returns player's range stat as portrayed in Game's stat HUD
---@param player EntityPlayer
---@return number
function EdithRebuilt.GetPlayerRange(player)
	return player.TearRange / 40
end

---Helper function to directly change `entity`'s color
---@param entity Entity
---@param red? number
---@param green? number
---@param blue? number
---@param alpha? number
function EdithRebuilt:ChangeColor(entity, red, green, blue, alpha)
	local color = entity.Color
	local Red = red or color.R
	local Green = green or color.G
	local Blue = blue or color.B
	local Alpha = alpha or color.A

	color:SetTint(Red, Green, Blue, Alpha)

	entity.Color = color
end

---Helper grid destroyer function
---@param entity Entity
---@param radius number
function EdithRebuilt:DestroyGrid(entity, radius)
	radius = radius or 10
	local room = game:GetRoom()

	for i = 0, room:GetGridSize() do
		local grid = room:GetGridEntity(i)
		if not grid then goto Break end  
		if entity.Position:Distance(grid.Position) > radius then goto Break end
		grid:Destroy(false)
		::Break::
	end
end

local LINE_SPRITE = Sprite("gfx/TinyBug.anm2", true)
local MAX_POINTS = 360
local ANGLE_SEPARATION = 360 / MAX_POINTS

LINE_SPRITE:SetFrame("Dead", 0)

---@param pos Vector
---@param AreaSize number
---@param AreaColor Color
function EdithRebuilt.RenderAreaOfEffect(pos, AreaSize, AreaColor) -- Took from Melee lib, tweaked a little bit
	if game:GetRoom():GetRenderMode() == RenderMode.RENDER_WATER_REFLECT then return end

    local renderPosition = Isaac.WorldToScreen(pos) - game.ScreenShakeOffset
    local hitboxSize = AreaSize
    local offset = Isaac.WorldToScreen(pos + Vector(0, hitboxSize)) - renderPosition + Vector(0, 1)
    local offset2 = offset:Rotated(ANGLE_SEPARATION)
    local segmentSize = offset:Distance(offset2)
    LINE_SPRITE.Scale = Vector(segmentSize * (2 / 3), 0.5)
    for i = 1, MAX_POINTS do
        local angle = ANGLE_SEPARATION * i
        LINE_SPRITE.Rotation = angle
        LINE_SPRITE.Offset = offset:Rotated(angle)
		LINE_SPRITE.Color = AreaColor or misc.ColorDefault
        LINE_SPRITE:Render(renderPosition)
    end
end

---Manages Edith's Target and Tainted Edith's arrow behavior when going trough doors
---@param effect EntityEffect
---@param player EntityPlayer
---@param triggerDistance number
function EdithRebuilt:TargetDoorManager(effect, player, triggerDistance)
	local room = game:GetRoom()
	local effectPos = effect.Position
	local roomName = level:GetCurrentRoomDesc().Data.Name
	local isTainted = mod.IsEdith(player, true) or false
	local MirrorRoomCheck = roomName == "Mirror Room" and player:HasInstantDeathCurse()
	local playerHasPhoto = (player:HasCollectible(CollectibleType.COLLECTIBLE_POLAROID) or player:HasCollectible(CollectibleType.COLLECTIBLE_NEGATIVE))

	for i = 0, 7 do
		local door = room:GetDoor(i)
		if not door then goto Break end
		local sprite = door:GetSprite()
		local doorSpritePath = sprite:GetLayer(0):GetSpritesheetPath()
		local MausoleumRoomCheck = string.find(doorSpritePath, "mausoleum") ~= nil
		local StrangeDoorCheck = string.find(doorSpritePath, "mausoleum_alt") ~= nil
		local ShouldMoveToStrangeDoorPos = StrangeDoorCheck and sprite:WasEventTriggered("FX")
		local doorPos = room:GetDoorSlotPosition(i)

		if not (doorPos and effectPos:Distance(doorPos) <= triggerDistance) then 	
			if player.Color.A < 1 then
				mod:ChangeColor(player, _, _, _, 1)
			end
			goto Break 
		end

		if door:IsOpen() or MirrorRoomCheck or ShouldMoveToStrangeDoorPos then
			player.Position = doorPos
			mod.RemoveEdithTarget(player, isTainted)
		elseif StrangeDoorCheck then
			if not playerHasPhoto then goto Break end
			door:TryUnlock(player)
		elseif MausoleumRoomCheck then
			if not sprite:IsPlaying("KeyOpen") then
				sprite:Play("KeyOpen")
			end

			if sprite:IsFinished("KeyOpen") then
				door:TryUnlock(player, true)
			end
		else
			mod:ChangeColor(player, 1, 1, 1, 1)
			door:TryUnlock(player)
		end
		::Break::
	end
end

---@param Type ConfigDataTypes
function EdithRebuilt.GetConfigData(Type)
	if not saveManager:IsLoaded() then return end
	local config = saveManager:GetSettingsSave()

	if not config then return end

	local switch = {
		[ConfigDataTypes.EDITH] = config.EdithData --[[@as EdithData]], 
		[ConfigDataTypes.TEDITH] = config.TEdithData --[[@as TEdithData]], 
		[ConfigDataTypes.MISC] = config.MiscData --[[@as MiscData]], 
	}

	return mod.When(Type, switch)
end

local backdropColors = tables.BackdropColors

---@param player EntityPlayer
function EdithRebuilt.InitVestigeJump(player)
	local jumpSpeed = 3.75 + (player.MoveSpeed - 1)
	local jumpHeight = 40
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
		Tags = jumpTags.EdithJump,
		Flags = jumpFlags.EdithJump,
	}

	JumpLib:Jump(player, config)
end

---@param player EntityPlayer
---@param jumpTag? string
function EdithRebuilt.InitEdithJump(player, jumpTag)	
	jumpTag = jumpTag or jumpTags.EdithJump

	local canFly = player.CanFly
	local jumpSpeed = canFly and 1.3 or 1.85
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
		Tags = jumpTag,
		Flags = jumpFlags.EdithJump,
	}

	JumpLib:Jump(player, config)
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
function EdithRebuilt:GetLandSoundTable(tainted, isParryLand)
	local TEdithSounds = LandSounds.TEdith
	return tainted and (isParryLand and TEdithSounds.Parry or TEdithSounds.Hop) or LandSounds.Edith
end

---Returns `true` if Dogma's appear cutscene is playing
---@return boolean
function EdithRebuilt.IsDogmaAppearCutscene()
	local TV = Isaac.FindByType(EntityType.ENTITY_GENERIC_PROP, 4)[1]
	local Dogma = Isaac.FindByType(EntityType.ENTITY_DOGMA)[1]

	if not TV then return false end
	return TV:GetSprite():IsPlaying("Idle2") and Dogma ~= nil
end

---@param tear EntityTear
local function tearCol(_, tear)
	local tearData = data(tear)
	if not tearData.IsEdithRebuiltSaltTear then return end

	local var, sprite, Path

	for _, ent in ipairs(Isaac.FindByType(EntityType.ENTITY_EFFECT)) do
		var = ent.Variant
		sprite = ent:GetSprite()
		
		if not (var == EffectVariant.ROCK_POOF or var == EffectVariant.TOOTH_PARTICLE) then goto Break end
		if ent.Position:Distance(tear.Position) > 10 then goto Break end

		Path = var == EffectVariant.ROCK_POOF and tearData.ShatterSprite or tearData.SaltGibsSprite

		if var == EffectVariant.TOOTH_PARTICLE then
			if ent.SpawnerEntity then goto Break end
			ent.Color = tear.Color
		end

		sprite:ReplaceSpritesheet(0, misc.TearPath .. Path .. ".png", true)
		::Break::
	end
end
mod:AddCallback(ModCallbacks.MC_POST_TEAR_DEATH, tearCol)

---@param tear EntityTear
---@param IsBlood boolean
---@param isTainted boolean
local function doEdithTear(tear, IsBlood, isTainted)
	local player = mod:GetPlayerFromTear(tear)

	if not player then return end

	local tearSizeMult = player:HasCollectible(CollectibleType.COLLECTIBLE_SOY_MILK) and 1 or 0.85
	local tearData = data(tear)
	local path = (isTainted and (IsBlood and "burnt_blood_salt_tears" or "burnt_salt_tears") or (IsBlood and "blood_salt_tears" or "salt_tears"))
	local newSprite = misc.TearPath .. path .. ".png"

	tear.Scale = tear.Scale * tearSizeMult

	tear:ChangeVariant(TearVariant.ROCK)
	
	tearData.ShatterSprite = (isTainted and (IsBlood and "burnt_blood_salt_shatter" or "burnt_salt_shatter") or (IsBlood and "blood_salt_shatter" or "salt_shatter"))
	tearData.SaltGibsSprite = (isTainted and (IsBlood and "burnt_blood_salt_gibs" or "burnt_salt_gibs") or (IsBlood and "blood_salt_gibs" or "salt_gibs"))
	
	tear:GetSprite():ReplaceSpritesheet(0, newSprite, true)
	tear.Color = player.Color
	tearData.IsEdithRebuiltSaltTear = true
end

---Forces tears to look like salt tears. `tainted` argument sets tears for Tainted Edith
---@param tear EntityTear
---@param tainted? boolean
function EdithRebuilt.ForceSaltTear(tear, tainted)
	local IsBloodTear = mod.When(tear.Variant, tables.BloodytearVariants, false)
	doEdithTear(tear, IsBloodTear, tainted)
end

---Converts seconds to game update frames
---@param seconds number
---@return number
function EdithRebuilt:SecondsToFrames(seconds)
	return math.ceil(seconds * 30)
end

function EdithRebuilt.PepperEnemy(ent, player, frames)
	ent:AddSlowing(EntityRef(player), frames, 0.5, Color(0.5, 0.5, 0.5))
	data(ent).PepperFrames = frames
end

---Custom black powder spawn (Used for Edith's black powder stomp synergy)
---@param parent Entity
---@param quantity number
---@param position Vector
---@param distance number
function EdithRebuilt:SpawnBlackPowder(parent, quantity, position, distance)
	quantity = quantity or 20
	local degrees = 360 / quantity
	local blackPowder
	for i = 1, quantity do
		blackPowder = Isaac.Spawn(
			EntityType.ENTITY_EFFECT,
			EffectVariant.PLAYER_CREEP_BLACKPOWDER, 
			0, 
			position + Vector(0, distance or 60):Rotated(degrees * i),
			Vector.Zero, 
			parent
		)
		if not blackPowder then return end
		data(blackPowder).CustomSpawn = true
	end

	local Pentagram = Isaac.Spawn(
		EntityType.ENTITY_EFFECT,
		EffectVariant.PENTAGRAM_BLACKPOWDER, 
		0, 
		position, 
		Vector.Zero, 
		nil
	):ToEffect() ---@cast Pentagram EntityEffect

	Pentagram.Scale = distance + distance / 2	
end

---Spawns Salt Creep
---@param parent Entity
---@param position Vector
---@param damage number
---@param timeout number
---@param gibAmount integer
---@param gibSpeed number
---@param spawnType SaltTypes
---@param inheritParentColor? boolean
---@param inheritParentVel? boolean
---@param color Color? Use this param to override salt's color
function EdithRebuilt:SpawnSaltCreep(parent, position, damage, timeout, gibAmount, gibSpeed, spawnType, inheritParentColor, inheritParentVel, color)
	gibAmount = gibAmount or 0

	local salt = Isaac.Spawn(
		EntityType.ENTITY_EFFECT, 
		EffectVariant.PLAYER_CREEP_RED, 
		enums.SubTypes.SALT_CREEP,
		position, 
		Vector.Zero,
		parent
	):ToEffect() ---@cast salt EntityEffect

	local saltColor = inheritParentColor and parent.Color or Color.Default
	local timeOutSeconds = mod:SecondsToFrames(timeout) or 30

	salt.CollisionDamage = damage or 0
	salt.Color = color or saltColor
	salt:SetTimeout(timeOutSeconds)

	if gibAmount > 0 then
		local gibColor = color or (inheritParentColor and Color.Default or nil)
		mod:SpawnSaltGib(parent, gibAmount, gibSpeed, gibColor, inheritParentVel)
	end
	data(salt).SpawnType = spawnType
end

---Returns distance between Edith and her target
---@param player EntityPlayer
---@return number
function EdithRebuilt.GetEdithTargetDistance(player)
	local target = mod.GetEdithTarget(player, false)
	if not target then return 0 end
	return player.Position:Distance(target.Position)
end

---Returns a normalized vector that represents direction regarding Edith and her Target, set `tainted` to true to check for Tainted Edith's arrow instead
---@param player EntityPlayer
---@param tainted boolean?
---@return Vector
function EdithRebuilt.GetEdithTargetDirection(player, tainted)
	local target = mod.GetEdithTarget(player, tainted or false)
	return (target.Position - player.Position):Normalized()
end

---Spawns Pepper creep, used for Pepper Grinder
---@param parent Entity
---@param position Vector
---@param damage number
---@param timeout number
function EdithRebuilt:SpawnPepperCreep(parent, position, damage, timeout)
	local pepper = Isaac.Spawn(
		EntityType.ENTITY_EFFECT, 
		EffectVariant.PLAYER_CREEP_RED, 
		enums.SubTypes.PEPPER_CREEP,
		position,
		Vector.Zero,
		parent
	):ToEffect() ---@cast pepper EntityEffect

	pepper.CollisionDamage = damage or 0
	pepper:SetTimeout(mod:SecondsToFrames(timeout) or 30)
end

---Checks if player is shooting by checking if shoot inputs are being pressed
---@param player EntityPlayer
---@return boolean
function EdithRebuilt:IsPlayerShooting(player)
	local shoot = {
        l = Input.IsActionPressed(ButtonAction.ACTION_SHOOTLEFT, player.ControllerIndex),
        r = Input.IsActionPressed(ButtonAction.ACTION_SHOOTRIGHT, player.ControllerIndex),
        u = Input.IsActionPressed(ButtonAction.ACTION_SHOOTUP, player.ControllerIndex),
        d = Input.IsActionPressed(ButtonAction.ACTION_SHOOTDOWN, player.ControllerIndex)
    }
	return (shoot.l or shoot.r or shoot.u or shoot.d)
end

local targetSprite = Sprite("gfx/edith rebuilt target.anm2", true)

---Draws a line between from `from` position to `to` position
---@param from Vector
---@param to Vector
---@param color Color
---@param isObscure? boolean
function EdithRebuilt.drawLine(from, to, color, isObscure)
	local diffVector = to - from
	local angle = diffVector:GetAngleDegrees()
	local sectionCount = math.floor(diffVector:Length() / 16) - 1
	local direction = Vector.FromAngle(angle)

	targetSprite:SetFrame("Line", isObscure and 1 or 0)
	targetSprite.Color = color
	targetSprite.Rotation = angle

	local currentPos
	for i = 0, sectionCount do
		currentPos = from + direction * (i * 16)
		targetSprite:Render(Isaac.WorldToScreen(currentPos))
	end
end

---@param parent Entity
---@param Number number
---@param speed number?
---@param color Color?
---@param inheritParentVel boolean?
function EdithRebuilt:SpawnSaltGib(parent, Number, speed, color, inheritParentVel)
    local parentColor = parent.Color
    local parentPos = parent.Position
    local finalColor = Color(1, 1, 1) or parent.Color

    if color then
        local CTint = color:GetTint()
        local COff = color:GetOffset()
		local PTint = parentColor:GetTint()
        local POff = parentColor:GetOffset()
        local PCol = parentColor:GetColorize()

        finalColor:SetTint(CTint.R + PTint.R - 1, CTint.G + PTint.G - 1, CTint.B + PTint.B - 1, 1)
        finalColor:SetOffset(COff.R + POff.R, COff.G + POff.G, COff.B + POff.B)
        finalColor:SetColorize(PCol.R, PCol.G, PCol.B, PCol.A)
    end

    local saltGib

    for _ = 1, Number do    
        saltGib = Isaac.Spawn(
            EntityType.ENTITY_EFFECT,
            EffectVariant.TOOTH_PARTICLE,
            0,
            parentPos,
            RandomVector():Resized(speed or 3),
            parent
        ):ToEffect() ---@cast saltGib EntityEffect

        saltGib.Color = finalColor
        saltGib.Timeout = 5

		if inheritParentVel then
            saltGib.Velocity = saltGib.Velocity + parent.Velocity
        end
    end
end

---Function to spawn Edith's Target, setting `tainted` to `true` will Spawn Tainted Edith's Arrow
---@param player EntityPlayer
---@param tainted? boolean
function EdithRebuilt.SpawnEdithTarget(player, tainted)
	if mod.IsDogmaAppearCutscene() then return end
	if mod.GetEdithTarget(player, tainted or false) then return end 

	local playerData = data(player)
	local TargetVariant = tainted and effectVariant.EFFECT_EDITH_B_TARGET or effectVariant.EFFECT_EDITH_TARGET
	local target = Isaac.Spawn(	
		EntityType.ENTITY_EFFECT,
		TargetVariant,
		0,
		player.Position,
		Vector.Zero,
		player
	):ToEffect()
	target.DepthOffset = -100
	target.SortingLayer = SortingLayer.SORTING_NORMAL
	
	if tainted then
		playerData.TaintedEdithTarget = target
	else
		target.GridCollisionClass = GridCollisionClass.COLLISION_SOLID
		playerData.EdithTarget = target
	end
end

---Function to get Edith's Target, setting `tainted` to `true` will return Tainted Edith's Arrow
---@param player EntityPlayer
---@param tainted boolean?
---@return EntityEffect
function EdithRebuilt.GetEdithTarget(player, tainted)
	local playerData = data(player)
	return tainted and playerData.TaintedEdithTarget or playerData.EdithTarget
end

---Function to remove Edith's target
---@param player EntityPlayer
---@param tainted? boolean
function EdithRebuilt.RemoveEdithTarget(player, tainted)
	local target = mod.GetEdithTarget(player, tainted)

	if not target then return end
	target:Remove()

	local playerData = data(player)
	if tainted then
		playerData.TaintedEdithTarget = nil
	else
		playerData.EdithTarget = nil
	end
end

function EdithRebuilt.HasBitFlags(flags, checkFlag)
	return flags & checkFlag == checkFlag
end

---Checks if player is in Last Judgement's Mortis 
---@return boolean
function EdithRebuilt.IsLJMortis()
	if not StageAPI then return false end
	if not LastJudgement then return false end

	local stage = LastJudgement.STAGE
	local IsMortis = StageAPI and (stage.Mortis:IsStage() or stage.MortisTwo:IsStage() or stage.MortisXL:IsStage())

	return IsMortis
end

---@param ent Entity
---@return boolean
function EdithRebuilt.IsEnemy(ent)
	return (ent:IsActiveEnemy() and ent:IsVulnerableEnemy()) or
	(ent.Type == EntityType.ENTITY_GEMINI and ent.Variant == 12) -- this for blighted ovum little sperm like shit i hate it fuuuck
end

---Helper function to find out how large a bomb explosion is based on the damage inflicted.
---@param damage number
---@return number
function EdithRebuilt.GetBombRadiusFromDamage(damage)
    if damage > 175 then
        return 105
    elseif damage <= 140 then
        return 75
    else
        return 90
    end
end

---Checks if are in Chapter 4 (Womb, Utero, Scarred Womb, Corpse)
---@return boolean
function EdithRebuilt:isChap4()
	local backdrop = game:GetRoom():GetBackdropType()
	
	if EdithRebuilt.IsLJMortis() then return true end
	return mod.When(backdrop, tables.Chap4Backdrops, false)
end

---Returns player's tears stat as portrayed in game's stats HUD
---@param p EntityPlayer
---@return number
function EdithRebuilt.GetTPS(p)
    return Math.Round(30 / (p.MaxFireDelay + 1), 2)
end

local KeyRequiredChests = {
	[PickupVariant.PICKUP_LOCKEDCHEST] = true,
	[PickupVariant.PICKUP_ETERNALCHEST] = true,
	[PickupVariant.PICKUP_OLDCHEST] = true,
	[PickupVariant.PICKUP_MEGACHEST] = true,
}

---@param pickup EntityPickup
---@return boolean
function IsKeyRequiredChest(pickup)
	return mod.When(pickup.Variant, KeyRequiredChests, false)
end

---@param player EntityPlayer
---@return unknown
local function ShouldConsumeKeys(player)
	return (player:GetNumKeys() > 0 and not player:HasGoldenKey())
end

local damageFlags = DamageFlag.DAMAGE_CRUSH | DamageFlag.DAMAGE_IGNORE_ARMOR

---@param ent Entity
---@param player EntityPlayer
function EdithRebuilt.AddExtraGore(ent, player)
	local enabledExtraGore

	if mod.IsEdith(player, false) then
		enabledExtraGore = mod.GetConfigData(ConfigDataTypes.EDITH).EnableExtraGore
	elseif mod.IsEdith(player, true) then
		enabledExtraGore = mod.GetConfigData(ConfigDataTypes.TEDITH).EnableExtraGore
	end

	if not enabledExtraGore then return end
	if not ent:ToNPC() then return end

	ent:AddEntityFlags(EntityFlag.FLAG_EXTRA_GORE)
	ent:MakeBloodPoof(ent.Position, nil, 0.5)
	sfx:Play(SoundEffect.SOUND_DEATH_BURST_LARGE)
end

function EdithRebuilt.IsVestigeChallenge()
	return Isaac.GetChallenge() == enums.Challenge.CHALLENGE_VESTIGE
end

---Helper function that returns `EntityPlayer` from `EntityRef`
---@param EntityRef EntityRef
---@return EntityPlayer?
function EdithRebuilt.GetPlayerFromRef(EntityRef)
	local ent = EntityRef.Entity

	if not ent then return nil end
	local familiar = ent:ToFamiliar()
	return ent:ToPlayer() or mod:GetPlayerFromTear(ent) or familiar and familiar.Player 
end

---@param player EntityPlayer
---@return Entity[]
function EdithRebuilt.GetStompedEnemies(player)
	local enemyTable = {}
    for _, ent in ipairs(data(player).StompedEntities) do
        if not mod.IsEnemy(ent) then goto continue end
        table.insert(enemyTable, ent)
		::continue::
    end
    return enemyTable
end

---Method used for Edith's dash behavior (Like A Pony/White Pony or Mars usage)
---@param player EntityPlayer
---@param dir Vector
---@param dist number
---@param div number
function EdithRebuilt.EdithDash(player, dir, dist, div)
	player.Velocity = player.Velocity + dir * dist / div
end

--- Helper function that returns a table containing all existing enemies in room
---@return Entity[]
function EdithRebuilt.GetEnemies()
    local enemyTable = {}
    for _, ent in ipairs(Isaac.GetRoomEntities()) do
        if not mod.IsEnemy(ent) then goto continue end
        table.insert(enemyTable, ent)
		::continue::
    end
    return enemyTable
end 

---Function used to trigger Tainted Edith and Burnt Hood's parry-jump
---@param player EntityPlayer
---@param tag string
function EdithRebuilt:InitTaintedEdithParryJump(player, tag)
	local backdropColors = tables.BackdropColors
	local jumpHeight = 8
	local jumpSpeed = 2.5
	local room = game:GetRoom()
	local RoomWater = room:HasWater()
	local isChap4 = mod:isChap4()
	local BackDrop = room:GetBackdropType()
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
	) 

	local color = DustCloud.Color
	local switch = {
		[EffectVariant.BIG_SPLASH] = function()
			color = backdropColors[BackDrop] or Color(0.7, 0.75, 1)
		end,
		[EffectVariant.POOF02] = function()
			color = backdropColors[BackDrop] or Color(1, 0, 0)
		end,
		[EffectVariant.POOF01] = function()
			if RoomWater then
				color = backdropColors[BackDrop]
			end
		end
	}

	mod.WhenEval(variant, switch)

	DustCloud.SpriteScale = DustCloud.SpriteScale * player.SpriteScale.X
	DustCloud.DepthOffset = -100
	DustCloud:SetColor(color, -1, 100, false, false)
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

local CinderHopRNG = RNG()
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function()
	CinderHopRNG:SetSeed(game:GetSeeds():GetStartSeed())
end)

---@return integer
function EdithRebuilt.GetMortisDrop()
	if not EdithRebuilt.IsLJMortis() then return 0 end

	if LastJudgement.UsingMorgueisBackdrop then
		return MortisBackdrop.MORGUE
	elseif LastJudgement.UsingMoistisBackdrop then 
		return MortisBackdrop.MOIST
	else
		return MortisBackdrop.FLESH
	end
end

---Function used to spawn Tainted Edith's birthright fire jets
---@param player EntityPlayer
---@param position Vector
---@param damage number
---@param useDefaultMult? boolean
---@param scale number
function EdithRebuilt.SpawnFireJet(player, position, damage, useDefaultMult, scale)
	useDefaultMult = useDefaultMult or false
	local playerData = data(player)
	local Fire = Isaac.Spawn(
		EntityType.ENTITY_EFFECT,
		EffectVariant.FIRE_JET,
		0,
		position,
		Vector.Zero,
		player
	)
	Fire.SpriteScale = Fire.SpriteScale * (scale or 1)
	Fire.CollisionDamage = damage * (useDefaultMult and 1 or (playerData.MoveBrCharge / 100))
end

--- Misc function used to manage some perfect parry stuff (i made it to be able to return something in the main parry function sorry)
---@param IsTaintedEdith boolean
---@param isenemy? boolean
local function PerfectParryMisc(player, IsTaintedEdith, isenemy)
	if not isenemy then return end
	game:MakeShockwave(player.Position, 0.035, 0.025, 2)

	if not IsTaintedEdith then return end

	playerData.ImpulseCharge = playerData.ImpulseCharge + 20

	if playerData.ImpulseCharge >= 100 and hasBirthright then
		playerData.BirthrightCharge = playerData.BirthrightCharge + 15
	end
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

---Helper function used to manage Tainted Edith and Burnt Hood's parry-lands 
---@param player EntityPlayer
---@param IsTaintedEdith? boolean 
---@return boolean PerfectParry Returns a boolean that tells if there was a perfect parry 
---@return boolean EnemiesInImpreciseParry
function EdithRebuilt.ParryLandManager(player, IsTaintedEdith)
	local damageBase = 13.5
	local DamageStat = player.Damage 
	local rawFormula = (damageBase + DamageStat) / 1.5 
	local PerfectParry = false
	local EnemiesInImpreciseParry = false
	local playerPos = player.Position
	local playerData = data(player)
	local ImpreciseParryCapsule = Capsule(player.Position, Vector.One, 0, misc.ImpreciseParryRadius)	
	local PerfectParryCapsule = Capsule(player.Position, Vector.One, 0, misc.PerfectParryRadius)
	local hasBirthright = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)
	local BirthrightMult = hasBirthright and 1.25 or 1
	local hasBirthcake = BirthcakeRebaked and player:HasTrinket(BirthcakeRebaked.Birthcake.ID) or false
	local DamageFormula = (rawFormula * BirthrightMult) * (hasBirthcake and 1.15 or 1)
	local shouldTriggerFireJets = IsTaintedEdith and hasBirthright or mod.IsJudasWithBirthright(player)
	local spawner, targetEnt, proj

	if IsTaintedEdith then
		local damageIncrease = 1 + (playerData.ImpulseCharge + playerData.BirthrightCharge) / 400
		DamageFormula = DamageFormula * damageIncrease
	end

	local tearsMult = (mod.GetTPS(player) / 2.73) 
	local CinderTime = mod:SecondsToFrames((4 * tearsMult))

	for _, ent in pairs(Isaac.FindInCapsule(ImpreciseParryCapsule, misc.ParryPartitions)) do
		if ent:ToTear() then goto continue end
		local pushMult = mod.IsCinder(ent) and 1.5 or 1
		mod.TriggerPush(ent, player, 20 * pushMult, 5, false)

		if not mod.IsEnemy(ent) then goto continue end
		if IsEntInTwoCapsules(ent, ImpreciseParryCapsule, PerfectParryCapsule) then goto continue end		
		mod.SetCinder(ent, CinderTime, player)
		EnemiesInImpreciseParry = true
		::continue::
	end

	for _, ent in pairs(Isaac.FindInCapsule(PerfectParryCapsule, misc.ParryPartitions)) do
		Isaac.RunCallback(enums.Callbacks.PERFECT_PARRY, player, ent)
		proj = ent:ToProjectile()
		 
		if proj then
			spawner = proj.Parent or proj.SpawnerEntity
			targetEnt = spawner or mod.GetNearestEnemy(player) or proj

			proj.FallingAccel = -0.1
			proj.FallingSpeed = 0
			proj.Height = -23
			proj:AddProjectileFlags(misc.NewProjectilFlags)
			proj:AddKnockback(EntityRef(player), (targetEnt.Position - player.Position):Resized(25), 5, false)

			if shouldTriggerFireJets then
				proj:AddProjectileFlags(ProjectileFlags.FIRE_SPAWN)
			end
		else
			local tear = ent:ToTear()
			if shouldTriggerFireJets then
				local jets = 6
				local ndegree = 360 / jets

				for i = 1, jets do
					local jetPos = playerPos + Vector(35, 0):Rotated(ndegree*i)
					mod.SpawnFireJet(player, jetPos, DamageFormula / 1.5, true, 1)				
				end
			end
		
			if ent.Type == EntityType.ENTITY_STONEY then
				ent:ToNPC().State = NpcState.STATE_SPECIAL
			end

			if tear then
				mod.BoostTear(tear, 20, 1.5)
			end

			ent:TakeDamage(DamageFormula, 0, EntityRef(player), 0)
			sfx:Play(SoundEffect.SOUND_MEATY_DEATHS)

			if ent.Type == EntityType.ENTITY_FIREPLACE and ent.Variant ~= 4 then
				ent:Kill()
			end

			if ent.HitPoints <= DamageFormula then
				Isaac.RunCallback(enums.Callbacks.PERFECT_PARRY_KILL, player, ent)
				mod.AddExtraGore(ent, player)
			end
		end
		PerfectParry = true		
	end

	player:SetMinDamageCooldown(PerfectParry and 30 or 15)
	PerfectParryMisc(IsTaintedEdith, PerfectParry)

	playerData.ParryCounter = IsTaintedEdith and (PerfectParry and (hasBirthcake and 8 or 10) or 15)
	playerData.IsParryJump = false

	return PerfectParry, EnemiesInImpreciseParry
end

---@param entity Entity
---@return EntityPlayer?
function EdithRebuilt:GetPlayerFromTear(entity)
	local check = entity.Parent or entity.SpawnerEntity

	if not check then return end
	local checkType = check.Type

	if checkType == EntityType.ENTITY_PLAYER then
		return mod:GetPtrHashEntity(check):ToPlayer()
	elseif checkType == EntityType.ENTITY_FAMILIAR then
		return check:ToFamiliar().Player:ToPlayer()
	end

	return nil
end

---@param entity Entity|EntityRef
---@return Entity?
function EdithRebuilt:GetPtrHashEntity(entity)
	if not entity then return end
	entity = entity.Entity or entity

	for _, matchEntity in pairs(Isaac.FindByType(entity.Type, entity.Variant, entity.SubType, false, false)) do
		if GetPtrHash(entity) == GetPtrHash(matchEntity) then
			return matchEntity
		end
	end
	return nil
end