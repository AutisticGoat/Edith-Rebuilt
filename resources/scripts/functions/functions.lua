---@diagnostic disable: undefined-global
local mod = EdithRebuilt
local enums = mod.Enums
local effectVariant = enums.EffectVariant
local utils = enums.Utils
local game = utils.Game
local level = utils.Level
local sfx = utils.SFX
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

---Checks if player is Edith. Boolean argument checks for Tainted Edith
---@param player EntityPlayer
---@param tainted boolean
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
		grid:Destroy()
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
	return mod.When(rng:RandomInt(1, #tables.Runes), tables.Runes, 32)
end

---Reset both Tainted Edith's Move charge and Birthright charge
---@param player any
function EdithRebuilt.resetCharges(player)
	local playerData = data(player)
	playerData.ImpulseCharge = 0
	playerData.BirthrightCharge = 0
end

---Helper function to stop Tainted Edith's hop-dash
---@param player EntityPlayer
---@param cooldown integer
---@param useQuitJump boolean
---@param resetChrg boolean
function EdithRebuilt.stopTEdithHops(player, cooldown, useQuitJump, resetChrg)
	if not mod.IsEdith(player, true) then return end

	local playerData = data(player)
	playerData.IsHoping = false
	playerData.HopVector = Vector.Zero
	player:MultiplyFriction(0.5)

	cooldown = cooldown or 0
	useQuitJump = useQuitJump or false

	if useQuitJump then
		JumpLib:QuitJump(player)
	end

	if resetChrg then
		mod.resetCharges(player)
	end

	player:SetMinDamageCooldown(cooldown)
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
	rng = rng or utils.RNG

	if not max then
		max = min
		min = 0
	end

	min = min * 1000
	max = max * 1000

	return rng:RandomInt(min, max) / 1000
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
	local override = mod.When(weapon:GetWeaponType(), tables.OverrideWeapons, false)

	if not override then return end
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
	local direction = mod.GetEdithTargetDirection(player, false)
	local distance = mod.GetEdithTargetDistance(player)

	if hasMarsEffect then
		mod.EdithDash(player, direction, distance, 50)
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

---@param player EntityPlayer
---@param jumpdata JumpConfig
function EdithRebuilt.BombFall(player, jumpdata)	
	if mod.IsDefensiveStomp(player) then return end
	if not Input.IsActionTriggered(ButtonAction.ACTION_BOMB, player.ControllerIndex) then return end
	if player:GetNumBombs() <= 0 and not player:HasGoldenBomb() then return end

	data(player).BombStomp = true
	JumpLib:SetSpeed(player, 8 + (jumpdata.Height / 10))
end

local backdropColors = tables.BackdropColors
---@param player EntityPlayer
function EdithRebuilt.InitEdithJump(player)	
	local canFly = player.CanFly
	local jumpSpeed = canFly and 1.3 or 1.85
	local soundeffect = canFly and SoundEffect.SOUND_ANGEL_WING or SoundEffect.SOUND_SHELLGAME
	local div = canFly and 25 or 15
	local base = canFly and 15 or 13
	local IsMortis = mod.IsLGMortis()
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
		Tags = jumpTags.EdithJump,
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

	local var 
	local sprite 
	local Path

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
	tainted = tainted or false
	local IsBloodTear = mod.When(tear.Variant, tables.BloodytearVariants, false) 
	
	doEdithTear(tear, IsBloodTear, tainted)
end

---Converts seconds to game update frames
---@param seconds number
---@return number
function EdithRebuilt:SecondsToFrames(seconds)
	return math.ceil(seconds * 30)
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
	):ToEffect()

	if not Pentagram then return end
	Pentagram.Scale = distance + distance / 2	
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
---@param spawnType string
---@param inheritParentColor? boolean
---@param inheritParentVel? boolean
function EdithRebuilt:SpawnSaltCreep(parent, position, damage, timeout, gibAmount, gibSpeed, spawnType, inheritParentColor, inheritParentVel)
	inheritParentColor = inheritParentColor or false
	inheritParentVel = inheritParentVel or false
	gibAmount = gibAmount or 0

	local salt = Isaac.Spawn(
		EntityType.ENTITY_EFFECT, 
		EffectVariant.PLAYER_CREEP_RED, 
		enums.SubTypes.SALT_CREEP,
		position, 
		Vector.Zero,
		parent
	):ToEffect()
	
	if not salt then return end

	local saltColor = inheritParentColor and parent.Color or Color.Default

	salt.CollisionDamage = damage or 0
	salt.Color = saltColor

	local timeOutSeconds = mod:SecondsToFrames(timeout) or 30
	salt:SetTimeout(timeOutSeconds)
	
	if gibAmount > 0 then
		local gibColor = inheritParentColor and Color.Default or nil
		mod:SpawnSaltGib(parent, gibAmount, gibSpeed, gibColor, inheritParentVel)
	end
	data(salt).SpawnType = spawnType
end

---Returns distance between Edith and her target
---@param player EntityPlayer
---@return number
function EdithRebuilt.GetEdithTargetDistance(player)
	local target = mod.GetEdithTarget(player, false)
	return player.Position:Distance(target.Position)
end

---Returns a normalized vector that represents direction regarding Edith and her Target, set `tainted` to true to check for Tainted Edith's arrow instead
---@param player EntityPlayer
---@param tainted boolean
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
	):ToEffect()
	
	if not pepper then return end
	pepper.CollisionDamage = damage or 0
	pepper:SetTimeout(mod:SecondsToFrames(timeout) or 30)
end

---Forcefully adds a costume for a character
---@param player EntityPlayer
---@param playertype PlayerType
---@param costumePath integer
function EdithRebuilt.ForceCharacterCostume(player, playertype, costumePath)
	local playerData = data(player)

	playerData.HasCostume = {}

	local hasCostume = playerData.HasCostume[playertype] or false
	local isCurrentPlayerType = player:GetPlayerType() == playertype

	if isCurrentPlayerType then
		if not hasCostume then
			player:AddNullCostume(costumePath)
			playerData.HasCostume[playertype] = true
		end
	else
		if hasCostume then
			player:TryRemoveNullCostume(costumePath)
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
---@param isObscure boolean
function EdithRebuilt.drawLine(from, to, color, isObscure)
	isObscure = isObscure or false
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

function EdithRebuilt:SpawnSaltGib(parent, Number, speed, color, inheritParentVel)
    local parentColor = parent.Color
    local parentPos = parent.Position
    local finalColor = Color(1, 1, 1) or parent.Color

    if color then
        local CTint = color:GetTint()
        local PTint = parentColor:GetTint()
        local COff = color:GetOffset()
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
            RandomVector():Resized(speed),
            parent
        ):ToEffect()

        if not saltGib then return end

        if inheritParentVel then
            saltGib.Velocity = saltGib.Velocity + parent.Velocity
        end

        saltGib.Color = finalColor
        saltGib.Timeout = 5
    end
end

---Function to spawn Edith's Target, setting `tainted` to `true` will Spawn Tainted Edith's Arrow
---@param player EntityPlayer
---@param tainted? boolean
function EdithRebuilt.SpawnEdithTarget(player, tainted)
	tainted = tainted or false
	local playerData = data(player)

	local TargetVariant = tainted and effectVariant.EFFECT_EDITH_B_TARGET or effectVariant.EFFECT_EDITH_TARGET

	local TargetData = tainted and playerData.TaintedEdithTarget or playerData.EdithTarget

	if mod.IsDogmaAppearCutscene() then return end
	if TargetData then return end 

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
---@param tainted boolean?
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

---Function used to manage and change Shockwave sprites from `TSIL` Library
---@return string
function EdithRebuilt.ShockwaveSprite()
	local room = game:GetRoom()
    local bdType = room:GetBackdropType()
    local effectPath = "resources/gfx/effects/effect_062_"

    local shockwaveSprites = {
        [BackdropType.CAVES] = "groundbreakcaves.png",
        [BackdropType.CATACOMBS] = "groundbreakcaves.png",
        [BackdropType.FLOODED_CAVES] = "groundbreak.png",
        [BackdropType.DEPTHS] = "groundbreakdepths.png",
        [BackdropType.WOMB] = "groundbreakwomb.png",
        [BackdropType.UTERO] = "groundbreakwomb.png",
        [BackdropType.SCARRED_WOMB] = "groundbreakwomb.png",
        [BackdropType.BLUE_WOMB] = "groundbreakbluewomb.png",
        [BackdropType.MINES] = room:HasLava() and "groundbreakmineslava.png" or "groundbreakmines.png",
        [BackdropType.MAUSOLEUM] = "groundbreakmausoleum.png",
        [BackdropType.CORPSE] = "groundbreakcorpse.png",
        [BackdropType.MAUSOLEUM2] = "groundbreakmausoleum.png",
        [BackdropType.MAUSOLEUM3] = "groundbreakmausoleum.png",
        [BackdropType.MAUSOLEUM4] = "groundbreakmausoleum.png",
        [BackdropType.CORPSE2] = "groundbreakcorpse2.png",
        [BackdropType.CORPSE3] = "groundbreakwomb.png",
        [BackdropType.ASHPIT] = "groundbreakmineslava.png",
        [BackdropType.GEHENNA] = "groundbreak.png",
    }

    return effectPath .. (shockwaveSprites[bdType] or "groundbreak.png")
end

function EdithRebuilt.HasBitFlags(flags, checkFlag)
	return flags & checkFlag == checkFlag
end

---Checks if player is in Last Judgement's Mortis 
---@return boolean
function EdithRebuilt.IsLGMortis()
	if not StageAPI then return false end
	if not LastJudgement then return false end

	local stage = LastJudgement.STAGE
	local IsMortis = StageAPI and (stage.Mortis:IsStage() or stage.MortisTwo:IsStage() or stage.MortisXL:IsStage())

	return IsMortis
end

---@param ent Entity
---@return boolean
function EdithRebuilt.IsEnemy(ent)
	return ent:IsActiveEnemy() and ent:IsVulnerableEnemy() 
end

---Checks if are in Chapter 4 (Womb, Utero, Scarred Womb, Corpse)
---@return boolean
function EdithRebuilt:isChap4()
	local stage = level:GetStage()
	local Chap4Stages = tables.Chap4Stages
	
	if EdithRebuilt.IsLGMortis() then return true end
	return mod.When(stage, Chap4Stages, false)
end

---Returns player's tears stat as portrayed in game's stats HUD
---@param p EntityPlayer
---@return number
function EdithRebuilt.GetTPS(p)
    return TSIL.Utils.Math.Round(30 / (p.MaxFireDelay + 1), 2)
end

---@param ent Entity
---@param parent EntityPlayer
---@param knockback number
function EdithRebuilt.HandleEntityInteraction(ent, parent, knockback)
	local var = ent.Variant
	local sub = ent.SubType
    local stompBehavior = {
        [EntityType.ENTITY_TEAR] = function()
            local tear = ent:ToTear()
            if not tear then return end
			if mod.IsEdith(parent, true) then return end

			mod.TriggerPush(ent, parent, knockback * 1.5, 3, false)
            tear:AddTearFlags(TearFlags.TEAR_QUADSPLIT)
            tear.CollisionDamage = tear.CollisionDamage * 2
        end,
        [EntityType.ENTITY_FIREPLACE] = function()
            if var == 4 then return end
            ent:Die()
        end,
        [EntityType.ENTITY_FAMILIAR] = function()
            local isphysicFamiliar = mod.When(var, tables.PhysicsFamiliar, false)
            if not isphysicFamiliar then return end
            mod.TriggerPush(ent, parent, knockback, 3, false)
        end,
        [EntityType.ENTITY_BOMB] = function()
			if mod.IsEdith(parent, true) then return end
            mod.TriggerPush(ent, parent, knockback, 3, false)
        end,
        [EntityType.ENTITY_PICKUP] = function()
            local pickup = ent:ToPickup()
            
            if not pickup then return end
            local isFlavorTextPickup = mod.When(var, tables.BlacklistedPickupVariants, false)
            local IsLuckyPenny = var == PickupVariant.PICKUP_COIN and sub == CoinSubType.COIN_LUCKYPENNY

            if isFlavorTextPickup or IsLuckyPenny then return end
			parent:ForceCollide(pickup, true)

            if not (var == PickupVariant.PICKUP_BOMBCHEST and mod.IsEdith(player, false)) then return end
			pickup:TryOpenChest(parent)
        end,
        [EntityType.ENTITY_SLOT] = function()    
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

---
---@param ent Entity
function EdithRebuilt.AddExtraGore(ent)
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
	if breakGrid then
		mod:DestroyGrid(parent, radius)
	end

	if not saveManager:IsLoaded() then return end
	local saveData = saveManager.GetSettingsSave()
	if not saveData then return end

	local isDefStomp = mod.IsDefensiveStomp(parent)
	local HasTerra = parent:HasCollectible(CollectibleType.COLLECTIBLE_TERRA)
	local TerraRNG = parent:GetCollectibleRNG(CollectibleType.COLLECTIBLE_TERRA)
	local TerraMult = HasTerra and mod.RandomFloat(TerraRNG, 0.5, 2) or 1	
	local FrozenEnt 
	local FrozenMult 
	local BCRRNG

	for _, ent in ipairs(Isaac.FindInCapsule(Capsule(parent.Position, Vector.One, 0, radius))) do
		mod.HandleEntityInteraction(ent, parent, knockback)

		if ent.Type == EntityType.ENTITY_STONEY then
			local stoneyData = data(ent)

			if not isDefStomp and stoneyData.IsFragile then
				ent:Die()
			end

			stoneyData.IsFragile = isDefStomp
		end

		if not mod.IsEnemy(ent) then goto Break end

		if isDefStomp then
			ent:AddFreeze(EntityRef(parent), 150)
			goto Break
		end

		FrozenEnt = ent:HasEntityFlags(EntityFlag.FLAG_FREEZE)
		FrozenMult = FrozenEnt and 1.4 or 1 
		damage = (damage * FrozenMult) * TerraMult

		mod.LandDamage(ent, parent, damage, knockback)
		sfx:Play(SoundEffect.SOUND_MEATY_DEATHS)

		if ent.HitPoints > damage then goto Break end

		if BirthcakeRebaked and parent:HasTrinket(BirthcakeRebaked.Birthcake.ID) and FrozenEnt then
			BCRRNG = parent:GetTrinketRNG(BirthcakeRebaked.Birthcake.ID)
			for _ = 1, BCRRNG:RandomInt(3, 7) do
				parent:FireTear(parent.Position, RandomVector():Resized(15))
			end
		end

		if saveData.EdithData.EnableGore then
			mod.AddExtraGore(ent)
		end

		::Break::
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

---Triggers a push to `pushed` from `pusher`
---@param pushed Entity
---@param pusher Entity
---@param strength number
---@param duration integer
---@param impactDamage boolean
function EdithRebuilt.TriggerPush(pushed, pusher, strength, duration, impactDamage)
	local dir = ((pusher.Position - pushed.Position) * -1):Resized(strength)
	pushed:AddKnockback(EntityRef(pusher), dir, duration, impactDamage)
end

---Method used for Edith's dash behavior (Like A Pony/White Pony or Mars usage)
---@param player EntityPlayer
---@param dir Vector
---@param dist number
---@param div number
function EdithRebuilt.EdithDash(player, dir, dist, div)
	player.Velocity = player.Velocity + dir * dist / div
end

--- Helper function that returns a table containing all existing enemies
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

---Tainted Edith parry land behavior
---@param parent EntityPlayer
---@param radius number
---@param damage number
---@param knockback number
function EdithRebuilt:TaintedEdithHop(parent, radius, damage, knockback)
	local mult
	for _, ent in ipairs(Isaac.FindInCapsule(Capsule(parent.Position, Vector.One, 0, radius))) do
		mult = ent:HasEntityFlags(EntityFlag.FLAG_CONFUSION) and 1.5 or 1
		mod.HandleEntityInteraction(ent, parent, knockback)
		mod.LandDamage(ent, parent, damage * mult, knockback)
	end
end

---@return integer
function EdithRebuilt.GetMortisDrop()
	if not EdithRebuilt.IsLGMortis() then return 0 end

	local mod = LastJudgement

	if mod.UsingMorgueisBackdrop then
		return MortisBackdrop.MORGUE
	elseif mod.UsingMoistisBackdrop then 
		return MortisBackdrop.MOIST
	else
		return MortisBackdrop.FLESH
	end
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
	local soundPick ---@type number
	local SizeX ---@type number
	local SizeY ---@type number
	local volume ---@type number
	local ScreenShakeIntensity ---@type number
	local gibAmount ---@type number
	local gibSpeed = 2
	local IsSoulOfEdith = data(player).IsSoulOfEdithJump 
	local IsMortis = EdithRebuilt.IsLGMortis()

	if mod.IsEdith(player, false) or IsSoulOfEdith then
		local isDefensive = mod.IsDefensiveStomp(player)
		local EdithData = menuData.EdithData
		local size = (IsSoulOfEdith and 0.8 or (isDefensive and 0.6 or 0.7)) * player.SpriteScale.X
		SizeX = size; SizeY = size
		soundPick = EdithData.stompsound ---@type number
		volume = (isDefensive and 1.5 or 2) * ((EdithData.stompVolume / 100) ^ 2) ---@type number
		ScreenShakeIntensity = isDefensive and 6 or 10
		gibAmount = EdithData.DisableGibs and 0 or 10
		gibSpeed = isDefensive and 2 or 3
	else
		local TEdithData = menuData.TEdithData
		SizeX = IsParryLand and 0.8 or 0.5
		SizeY = IsParryLand and 0.7 or 0.5
		soundPick = IsParryLand and TEdithData.TaintedParrySound or TEdithData.TaintedHopSound ---@type number
		volume = (IsParryLand and 1.5 or 1) * ((TEdithData.taintedStompVolume / 100) ^ 2) ---@type number
		ScreenShakeIntensity = IsParryLand and 6 or 3
		gibAmount = not TEdithData.DisableGibs and (IsParryLand and 6 or 2) or 0
	end

	local sound = mod.When(soundPick, soundTable, 1)
	sfx:Play(sound, volume, 0, false, 1, 0)

	if IsChap4 then
		sfx:Play(SoundEffect.SOUND_MEATY_DEATHS, volume - 0.5, 0, false, 1, 0)
	end

	if menuData.miscData.shakescreen then
		game:ShakeScreen(ScreenShakeIntensity)
	end

	local stompGFX = Isaac.Spawn(
		EntityType.ENTITY_EFFECT, 
		Variant, 
		SubType, 
		player.Position, 
		Vector.Zero, 
		player
	)

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

	stompGFX:GetSprite().PlaybackSpeed = 1.3
	stompGFX.SpriteScale = Vector(SizeX, SizeY) * player.SpriteScale.X
	stompGFX.Color = color

	GibColor = GibColor or defColor
	if gibAmount > 0 then	
		mod:SpawnSaltGib(player, gibAmount, gibSpeed, GibColor)
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
	elseif check.Type == EntityType.ENTITY_FAMILIAR then
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