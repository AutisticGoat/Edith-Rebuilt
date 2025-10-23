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
local data = mod.CustomDataWrapper.getData
local saveManager = mod.SaveManager

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
	
---Changes `Entity` velocity so now it goes to `Target`'s Position, `strenght` determines how fast it'll go
---@param Entity Entity
---@param Target Entity
---@param strenght number
---@return Vector
function EdithRebuilt.ChangeVelToTarget(Entity, Target, strenght)
	return ((Entity.Position - Target.Position) * -1):Normalized():Resized(strenght)
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

---Helper tears stat manager function
---@param firedelay number
---@param val number
---@param mult? boolean
---@return number
function EdithRebuilt.tearsUp(firedelay, val, mult)
    local currentTears = 30 / (firedelay + 1)
    local newTears = mult and (currentTears * val) or currentTears + val
    return math.max((30 / newTears) - 1, -0.75)
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

---Returns a random rune (Used for Geode trinket)
---@param rng RNG
---@return integer
function EdithRebuilt.GetRandomRune(rng)
	return mod.When(rng:RandomInt(1, #tables.Runes), tables.Runes)
end

---Returns a chance based boolean
---@param rng? RNG -- if `nil`, the function will use Mod's `RNG` object instead
---@param chance? number if `nil`, default chance will be 0.5 (50%)
function EdithRebuilt.RandomBoolean(rng, chance)
	return (rng or utils.RNG):RandomFloat() <= (chance or 0.5)
end

---Helper function for a better management of random floats, allowing to use min and max values, like `math.random()` and `RNG:RandomInt()`
---@param rng? RNG if `nil`, the function will use Mod's `RNG` object instead
---@param min number
---@param max? number if `nil`, returned number will be one between 0 and `min`
function EdithRebuilt.RandomFloat(rng, min, max)
	if not max then
		max = min
		min = 0
	end

	min = min * 1000
	max = max * 1000

	return (rng or utils.RNG):RandomInt(min, max) / 1000
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

---@param player EntityPlayer
function EdithRebuilt.ManageEdithWeapons(player)
	local weapon = player:GetWeapon(1)

	if not weapon then return end
	if not mod.When(weapon:GetWeaponType(), tables.OverrideWeapons, false) then return end
	local newWeapon = Isaac.CreateWeapon(WeaponType.WEAPON_TEARS, player)
	Isaac.DestroyWeapon(weapon)
	player:EnableWeaponType(WeaponType.WEAPON_TEARS, true)
	player:SetWeapon(newWeapon, 1)	
end

---@param player EntityPlayer
---@param jumpData JumpData
function EdithRebuilt.CustomDropBehavior(player, jumpData)
	if not mod.IsEdith(player, false) then return end
	local playerData = data(player)
	playerData.ShouldDrop = playerData.ShouldDrop or false

	if playerData.ShouldDrop == false then
	---@diagnostic disable-next-line: undefined-field
		player:SetActionHoldDrop(0)
	end

	if not jumpData.Jumping then playerData.ShouldDrop = false return end
	if not Input.IsActionTriggered(ButtonAction.ACTION_DROP, player.ControllerIndex) then return end
	if not (jumpData.Height > 10 and not JumpLib:IsFalling(player)) then return end
	playerData.ShouldDrop = true
	---@diagnostic disable-next-line: undefined-field
	player:SetActionHoldDrop(119)
end

---@param player EntityPlayer
function EdithRebuilt.DashItemBehavior(player)
	local edithTarget = mod.GetEdithTarget(player)

	if not edithTarget then return end
	local effects = player:GetEffects()
	local hasMarsEffect = effects:HasCollectibleEffect(CollectibleType.COLLECTIBLE_MARS)
	local hasAnyPonyEffect = effects:HasCollectibleEffect(CollectibleType.COLLECTIBLE_PONY) or effects:HasCollectibleEffect(CollectibleType.COLLECTIBLE_WHITE_PONY)
	local direction = mod.GetEdithTargetDirection(player, false)
	local distance = mod.GetEdithTargetDistance(player)

	if hasMarsEffect or hasAnyPonyEffect then
		mod.EdithDash(player, direction, distance, 50)
	end

	if player.Velocity:Length() <= 3 then
		effects:RemoveCollectibleEffect(CollectibleType.COLLECTIBLE_PONY, -1)
		effects:RemoveCollectibleEffect(CollectibleType.COLLECTIBLE_WHITE_PONY, -1)
	end

	local primaryActiveSlot = player:GetActiveItemDesc(ActiveSlot.SLOT_PRIMARY)
	local activeItem = primaryActiveSlot.Item

	if activeItem == 0 then return end

	local isMoveBasedActive = tables.MovementBasedActives[activeItem] or false
	local itemConfig = Isaac.GetItemConfig():GetCollectible(activeItem)
	local maxItemCharge = itemConfig.MaxCharges
	local currentItemCharge = primaryActiveSlot.Charge
	local itemBatteryCharge = primaryActiveSlot.BatteryCharge
	local totalItemCharge = currentItemCharge + itemBatteryCharge
	local usedCharge = totalItemCharge - maxItemCharge

	if not isMoveBasedActive or totalItemCharge < maxItemCharge then return end
	if not Input.IsActionTriggered(ButtonAction.ACTION_ITEM, player.ControllerIndex) then return end

	mod.EdithDash(player, direction, distance, 50)
	player:UseActiveItem(activeItem)
	player:SetActiveCharge(usedCharge, ActiveSlot.SLOT_PRIMARY)
end

---@param player EntityPlayer
function EdithRebuilt.FallBehavior(player)
	local distance = mod.GetEdithTargetDistance(player)
	local jumpdata = JumpLib:GetData(player)

	if mod.IsDefensiveStomp(player) then return end
	if not (player.CanFly and ((mod.IsEdithTargetMoving(player) and distance <= 50) or distance <= 5)) then return end

	player:MultiplyFriction(isMovingTarget and 1 or 0.2)

	if not (jumpdata.Fallspeed < 8.5 and JumpLib:IsFalling(player)) then return end
	sfx:Play(SoundEffect.SOUND_SHELLGAME)
	JumpLib:SetSpeed(player, 10 + (jumpdata.Height / 10))
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

---@param player EntityPlayer
---@param bomb? EntityBomb
function EdithRebuilt.ExplosionRecoil(player, bomb)
	JumpLib:Jump(player, {
		Height = 10,
		Speed = 1.5,
		Tags = jumpTags.EdithJump,
		Flags = jumpFlags.EdithJump,
	})

	local velTarget = (
		bomb and (player.Position - bomb.Position) or 
		-player.Velocity
	):Normalized()

	player.Velocity = velTarget:Resized(15)
	data(player).RocketLaunch = true
end

---@param player EntityPlayer
---@param jumpdata JumpConfig
function EdithRebuilt.BombFall(player, jumpdata)	
	if mod.IsDefensiveStomp(player) then return end
	if not Input.IsActionTriggered(ButtonAction.ACTION_BOMB, player.ControllerIndex) then return end

	local HasDrFetus = player:HasCollectible(CollectibleType.COLLECTIBLE_DR_FETUS)

	if not (HasDrFetus or player:GetNumBombs() > 0 or player:HasGoldenBomb()) then return end

	local playerData = data(player) 

	playerData.BombStomp = true

	if player:HasCollectible(CollectibleType.COLLECTIBLE_ROCKET_IN_A_JAR) then 
		local TargetAnglev = mod.GetEdithTargetDirection(player, false):GetAngleDegrees()
		local bomb = Isaac.Spawn(EntityType.ENTITY_BOMB, BombVariant.BOMB_ROCKET, 0, player.Position, Vector.Zero, player):ToBomb() ---@cast bomb EntityBomb
		bomb:SetRocketAngle(TargetAnglev)
		bomb:SetRocketSpeed(40)
		local ShouldKeepBomb = HasDrFetus or player:HasGoldenBomb()

		if not ShouldKeepBomb then
			player:AddBombs(-1)
		end

		sfx:Play(SoundEffect.SOUND_ROCKET_LAUNCH)
		
		mod.ExplosionRecoil(player)

		playerData.RocketLaunch = true
		data(bomb).IsEdithRocket = true
		return
	end

	if playerData.RocketLaunch then return end
	JumpLib:SetSpeed(player, 8 + (jumpdata.Height / 10))
end

---@param bomb EntityBomb
function mod:BombUpdate(bomb)
	if not data(bomb).IsEdithRocket then return end
	local rocketHeight = JumpLib:GetData(bomb).Height

	if rocketHeight <= 15 then
		JumpLib:QuitJump(bomb)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_BOMB_RENDER, mod.BombUpdate)

local backdropColors = tables.BackdropColors
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

---@param player EntityPlayer
function EdithRebuilt.GetNearestEnemy(player)
	local closestDistance = math.huge
    local playerPos = player.Position
	local room = game:GetRoom()
	local closestEnemy, enemyPos, distanceToPlayer, checkline

	for _, enemy in ipairs(mod.GetEnemies()) do
		if enemy:HasEntityFlags(EntityFlag.FLAG_CHARM) then goto Break end
		enemyPos = enemy.Position
		distanceToPlayer = enemyPos:Distance(playerPos)
		checkline = room:CheckLine(playerPos, enemyPos, LineCheckMode.PROJECTILE, 0, false, false)
		if not checkline then goto Break end
        if distanceToPlayer >= closestDistance then goto Break end
        closestEnemy = enemy
        closestDistance = distanceToPlayer
        ::Break::
	end
    return closestEnemy
end

---Expontential function
---@param number number
---@param coeffcient number
---@param power number
---@return integer
function EdithRebuilt.exp(number, coeffcient, power)
    return number ~= 0 and coeffcient * number ^ (power - 1) or 0
end

---Logaritmic function
---@param x number
---@param base number
---@return number?
function EdithRebuilt.Log(x, base)
    if x <= 0 or base <= 1 then
        return nil
    end

    local logNatural = math.log(x)
    local logBase = math.log(base)
    
    return logNatural / logBase
end

---Changes `player`'s ANM2 file
---@param player EntityPlayer
---@param FilePath string
function EdithRebuilt.SetNewANM2(player, FilePath)
	local playerSprite = player:GetSprite()

	if not (playerSprite:GetFilename() ~= FilePath and not player:IsCoopGhost()) then return end
	playerSprite:Load(FilePath, true)
	playerSprite:Update()
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

---Forcefully adds a costume for a character
---@param player EntityPlayer
---@param playertype PlayerType
---@param costume integer
function EdithRebuilt.ForceCharacterCostume(player, playertype, costume)
	local playerData = data(player)

	playerData.HasCostume = {}

	local hasCostume = playerData.HasCostume[playertype] or false
	local isCurrentPlayerType = player:GetPlayerType() == playertype

	if isCurrentPlayerType then
		if not hasCostume then
			player:AddNullCostume(costume)
			playerData.HasCostume[playertype] = true
		end
	else
		if hasCostume then
			player:TryRemoveNullCostume(costume)
			playerData.HasCostume[playertype] = false
		end
	end
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
    return mod.Round(30 / (p.MaxFireDelay + 1), 2)
end

---@param ent Entity
---@param parent EntityPlayer
---@param knockback number
function EdithRebuilt.HandleEntityInteraction(ent, parent, knockback)
	local var = ent.Variant
    local stompBehavior = {
        [EntityType.ENTITY_TEAR] = function()
            local tear = ent:ToTear()
            if not tear then return end
			if mod.IsEdith(parent, true) then return end

			mod.BoostTear(tear, 25, 1.5)
        end,
        [EntityType.ENTITY_FIREPLACE] = function()
            if var == 4 then return end
            ent:Die()
        end,
        [EntityType.ENTITY_FAMILIAR] = function()
            if not mod.When(var, tables.PhysicsFamiliar, false) then return end
            mod.TriggerPush(ent, parent, knockback, 3, false)
        end,
        [EntityType.ENTITY_BOMB] = function()
			if mod.IsEdith(parent, true) then return end
            mod.TriggerPush(ent, parent, knockback, 3, false)
        end,
        [EntityType.ENTITY_PICKUP] = function()
            local pickup = ent:ToPickup() ---@cast pickup EntityPickup
            local isFlavorTextPickup = mod.When(var, tables.BlacklistedPickupVariants, false)
            local IsLuckyPenny = var == PickupVariant.PICKUP_COIN and ent.SubType == CoinSubType.COIN_LUCKYPENNY

            if isFlavorTextPickup or IsLuckyPenny then return end
			parent:ForceCollide(pickup, true)

            if not (var == PickupVariant.PICKUP_BOMBCHEST and mod.IsEdith(parent, false)) then return end
			pickup:TryOpenChest(parent)
        end,
        [EntityType.ENTITY_SHOPKEEPER] = function()
			if mod.IsEdith(parent, true) then return end
            ent:Kill()
        end,
    }

	mod.WhenEval(ent.Type, stompBehavior)
end

local damageFlags = DamageFlag.DAMAGE_CRUSH | DamageFlag.DAMAGE_IGNORE_ARMOR

---comment
---@param ent Entity
---@param dealEnt Entity
---@param damage number
---@param knockback number
function EdithRebuilt.LandDamage(ent, dealEnt, damage, knockback)	
	if not mod.IsEnemy(ent) then return end

	ent:TakeDamage(damage, damageFlags, EntityRef(dealEnt), 0)
	mod.TriggerPush(ent, dealEnt, knockback, 5, false)
end

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

---Custom Edith stomp Behavior
---@param parent EntityPlayer
---@param radius number
---@param damage number
---@param knockback number
---@param breakGrid boolean
function EdithRebuilt:EdithStomp(parent, radius, damage, knockback, breakGrid)
	local isDefStomp = mod.IsDefensiveStomp(parent) or data(parent).HoodLand
	local HasTerra = parent:HasCollectible(CollectibleType.COLLECTIBLE_TERRA)
	local TerraRNG = parent:GetCollectibleRNG(CollectibleType.COLLECTIBLE_TERRA)
	local TerraMult = HasTerra and mod.RandomFloat(TerraRNG, 0.5, 2) or 1	
	local playerData = data(parent)
	local FrozenMult, BCRRNG
	local capsule = Capsule(parent.Position, Vector.One, 0, radius)
	local SaltedTime = mod.Round(mod.Clamp(120 * (mod.GetTPS(parent) / 2.73), 60, 360))
	local isSalted

	playerData.StompedEntities = Isaac.FindInCapsule(capsule)

	for _, ent in ipairs(playerData.StompedEntities) do
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

---@param player EntityPlayer
function mod:Peffect(player)
	player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
	player:EvaluateItems()	
end
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, mod.Peffect)

---@param player EntityPlayer
---@param flag CacheFlag
function mod:EvaluateCache(player, flag)
	if flag ~= CacheFlag.CACHE_DAMAGE then return end
	local damagemult = player:GetBoneHearts() * 0.75

	player.Damage = player.Damage + damagemult
end
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.EvaluateCache)

---Triggers a push to `pushed` from `pusher`
---@param pushed Entity
---@param pusher Entity
---@param strength number
---@param duration integer
---@param impactDamage? boolean
function EdithRebuilt.TriggerPush(pushed, pusher, strength, duration, impactDamage)
	local dir = ((pusher.Position - pushed.Position) * -1):Resized(strength)
	pushed:AddKnockback(EntityRef(pusher), dir, duration, impactDamage or false)
end

---The same as `EdithRebuilt.TriggerPush` but this accepts a `Vector` for positions instead
---@param pusher Entity
---@param pushed Entity
---@param pushedPos Vector
---@param pusherPos Vector
---@param strength number
---@param duration integer
---@param impactDamage? boolean
function EdithRebuilt.TriggerPushPos(pusher, pushed, pushedPos, pusherPos, strength, duration, impactDamage)
	local dir = ((pusherPos - pushedPos) * -1):Resized(strength)
	pushed:AddKnockback(EntityRef(pusher), dir, duration, impactDamage or false)
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

---Tainted Edith parry land behavior
---@param parent EntityPlayer
---@param radius number
---@param damage number
---@param knockback number
function EdithRebuilt:TaintedEdithHop(parent, radius, damage, knockback)
	local capsule = Capsule(parent.Position, Vector.One, 0, radius)
	
	for _, ent in ipairs(Isaac.FindInCapsule(capsule)) do
		mod.HandleEntityInteraction(ent, parent, knockback)
		mod.LandDamage(ent, parent, damage, knockback)
	end
end

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

--- Rounds a number to the closest number of decimal places given.
--- Defaults to rounding to the nearest integer. 
--- (from Library of Isaac)
---@param n number
---@param decimalPlaces integer? @Default: 0
---@return number
function EdithRebuilt.Round(n, decimalPlaces)
	decimalPlaces = decimalPlaces or 0
	local mult = 10^(decimalPlaces or 0)
	return math.floor(n * mult + 0.5) / mult
end

--- Helper function to clamp a number into a range (from Library of Isaac).
---@param a number
---@param min number
---@param max number
---@return number
function EdithRebuilt.Clamp(a, min, max)
	if min > max then
		local temp = min
		min = max
		max = temp
	end

	return math.max(min, math.min(a, max))
end

--- Helper function to convert a given amount of angle degrees into the corresponding `Direction` enum (From Library of Isaac, tweaked a bit)
---@param angleDegrees number
---@return Direction
function EdithRebuilt.AngleToDirection(angleDegrees)
    local normalizedDegrees = angleDegrees % 360
    if normalizedDegrees < 45 or normalizedDegrees >= 315 then
        return Direction.RIGHT
    elseif normalizedDegrees < 135 then
        return Direction.DOWN
    elseif normalizedDegrees < 225 then
        return Direction.LEFT
    else
        return Direction.UP
    end
end

--- Returns a direction corresponding to the direction the provided vector is pointing (from Library of Isaac)
---@param vector Vector
---@return Direction
function EdithRebuilt.VectorToDirection(vector)
	return mod.AngleToDirection(vector:GetAngleDegrees())
end

---Helper function to check if two vectors are exactly equal (from Library).
---@param v1 Vector
---@param v2 Vector
---@return boolean
function EdithRebuilt.VectorEquals(v1, v2)
    return v1.X == v2.X and v1.Y == v1.Y
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

---Makes the tear to receive a boost, increasing its speed and damage
---@param tear EntityTear	
---@param speed number
---@param dmgMult number
function EdithRebuilt.BoostTear(tear, speed, dmgMult)
	local player = mod:GetPlayerFromTear(tear) ----@cast player EntityPlayer	
	local nearEnemy = mod.GetNearestEnemy(player)

	if nearEnemy then
		tear.Velocity = (nearEnemy.Position - tear.Position):Normalized()
	end
	
	tear.CollisionDamage = tear.CollisionDamage * dmgMult
	tear.Velocity = tear.Velocity:Resized(speed)
	tear:AddTearFlags(TearFlags.TEAR_KNOCKBACK)
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

---Function made to adjust landing volumes
---@param Percent number
---@return number
local function GetVolume(Percent)
	return (Percent / 100) ^ 2
end

---Function for audiovisual feedback of Edith and Tainted Edith landings.
---@param player EntityPlayer
---@param soundTable table Takes a table with sound IDs.
---@param GibColor Color Takes a color for salt gibs spawned on Landing.
---@param IsParryLand? boolean Is used for Tainted Edith's parry land behavior and can be ignored.
function EdithRebuilt.LandFeedbackManager(player, soundTable, GibColor, IsParryLand)
	local saveManager = mod.SaveManager 
	if not saveManager:IsLoaded() then return end
	local menuData = saveManager:GetSettingsSave()
	if not menuData then return end

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
	sfx:Play(sound, volume, 0, false)

	if IsChap4 then
		sfx:Play(SoundEffect.SOUND_MEATY_DEATHS, volume - 0.5, 0, false, 1, 0)
	end

	if hasWater then
		sfx:Play(enums.SoundEffect.SOUND_EDITH_STOMP_WATER, volume, 0, false)
	end	
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