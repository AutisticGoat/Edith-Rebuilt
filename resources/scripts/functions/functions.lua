local mod = edithMod
local enums = mod.Enums
local effectVariant = enums.EffectVariant
local utils = enums.Utils
local game = utils.Game
local sfx = utils.SFX
local tables = enums.Tables
local jumpTags = tables.JumpTags
local jumpFlags = tables.JumpFlags
local misc = enums.Misc
local players = enums.PlayerType

---Checks if player is Edith. Boolean argument checks for Tainted Edith
---@param player EntityPlayer
---@param tainted boolean
---@return boolean
function edithMod.IsEdith(player, tainted)
	return player:GetPlayerType() == (tainted and players.PLAYER_EDITH_B or players.PLAYER_EDITH)
end

---Checks if any player is Edith
---@param player EntityPlayer
---@return boolean
function edithMod:IsAnyEdith(player)
	return edithMod.IsEdith(player, true) or edithMod.IsEdith(player, false)
end
	
---Changes `Entity` velocity so now it goes to `Target`'s Position, `strenght` determines how fast it'll go
---@param Entity Entity
---@param Target Entity
---@param strenght number
---@return Vector
function edithMod.ChangeVelToTarget(Entity, Target, strenght)
	local EntPos = Entity.Position
	local TarPos = Target.Position

	return ((EntPos - TarPos) * -1):Normalized():Resized(strenght)
end

---Checks if Edith's target is moving
---@param player EntityPlayer
---@return boolean
function edithMod.IsEdithTargetMoving(player)
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
function edithMod.When(value, cases, default)
    return value and cases[value] or default
end

--[[Perform a Switch/Case-like selection, like @{edithMod.When}, but takes a
    table of functions and runs the found matching case to return its result.  
    `value` is used to index `cases`.
    When `value` is `nil`, returns `default`, or runs it and returns its value if
    it is a function.  
    **Note:** Type inference on this function is decent, but not perfect.
    You might want to use things such as [casting](https://luals.github.io/wiki/annotations/#as)
    the returned value.
    ]]
---@generic In, Out, Default
---@param value?    In
---@param cases     { [In]: fun(): Out }
---@param default?  fun(): Default
---@return Out|Default
function edithMod.WhenEval(value, cases, default)
    local f = edithMod.When(value, cases)
    local v = (f and f()) or (default and default())
    return v
end

---Checks if player is pressing Edith's jump button
---@param player EntityPlayer
---@return boolean
function edithMod.IsKeyStompPressed(player)
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
function edithMod:IsKeyStompTriggered(player)
	local k_stomp =
		Input.IsButtonTriggered(Keyboard.KEY_Z, player.ControllerIndex) or
        Input.IsButtonTriggered(Keyboard.KEY_LEFT_SHIFT, player.ControllerIndex) or
        Input.IsButtonTriggered(Keyboard.KEY_RIGHT_SHIFT, player.ControllerIndex) or
		Input.IsButtonTriggered(Keyboard.KEY_RIGHT_CONTROL, player.ControllerIndex) or
        Input.IsActionTriggered(ButtonAction.ACTION_DROP, player.ControllerIndex)
		
	return k_stomp
end

---Helper tears stat manager function
---@param firedelay number
---@param val number
---@param mult? boolean
---@return number
function edithMod.tearsUp(firedelay, val, mult)
	mult = mult or false
    local currentTears = 30 / (firedelay + 1)
    local newTears = mult and (currentTears * val) or currentTears + val
    return math.max((30 / newTears) - 1, -0.75)
end

---Helper range stat manager function
---@param range number
---@param val number
---@return number
function edithMod.rangeUp(range, val)
    local currentRange = range / 40.0
    local newRange = currentRange + val
    return math.max(1.0, newRange) * 40.0
end

---Returns player's range stat as portrayed in Game's stat HUD
---@param player EntityPlayer
---@return number
function edithMod.GetPlayerRange(player)
	return player.TearRange / 40
end

---Converts a vector to an angle
---@param vector Vector
---@return integer
function edithMod.vectorToAngle(vector)
	local x, y = vector.X, vector.Y

	if x == 0 then
		return y > 0 and 90 or y < 0 and 270 or 0
	end

	local angle = math.deg(math.atan(y / x))
	if x < 0 then
		angle = angle + 180
	elseif y < 0 then
		angle = angle + 360
	end

	return math.floor((angle + 45) / 90) * 90
end

---
---@param color Color
---@param red number
---@param green number
---@param blue number
---@param alpha? number
---@param redOff? number
---@param greenOff? number
---@param blueOff? number
function edithMod:ChangeColor(color, red, green, blue, alpha, redOff, greenOff, blueOff)
	local newcolor = color
	color.R = red or newcolor.R
	color.G = green or newcolor.G
	color.B = blue or newcolor.B
	color.A = alpha or newcolor.A
	color.RO = redOff or newcolor.RO
	color.GO = greenOff or newcolor.GO
	color.BO = blueOff or newcolor.BO
	
	color = newcolor
end

---Helper grid destroyer function
---@param entity Entity
---@param radius number
function edithMod:DestroyGrid(entity, radius)
	radius = radius or 10
	local room = game:GetRoom()
	local roomSize = room:GetGridSize()
	local entPos = entity.Position

	for i = 0, roomSize do
		local grid = room:GetGridEntity(i)
		if not grid then goto Break end
		local gridPos = grid.Position
		local distance = entPos:Distance(gridPos) 
		if distance > radius then goto Break end
		grid:Destroy()
		::Break::
	end
end

local LINE_SPRITE = Sprite("gfx/TinyBug.anm2", true)
local MAX_POINTS = 360
local ANGLE_SEPARATION = 360 / MAX_POINTS

LINE_SPRITE:SetFrame("Dead", 0)

---@param entity Entity
---@param AreaSize number
---@param AreaColor Color
function edithMod.RenderAreaOfEffect(entity, AreaSize, AreaColor) -- Took from Melee lib, tweaked a little bit
	local room = game:GetRoom()

	if room:GetRenderMode() == RenderMode.RENDER_WATER_REFLECT then return end

    local hitboxPosition = entity.Position
    local renderPosition = Isaac.WorldToScreen(hitboxPosition) - game.ScreenShakeOffset
    local hitboxSize = AreaSize
    local offset = Isaac.WorldToScreen(hitboxPosition + Vector(0, hitboxSize)) - renderPosition + Vector(0, 1)
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
function edithMod.GetRandomRune(rng)
	return edithMod.When(rng:RandomInt(1, #tables.Runes), tables.Runes, 32)
end

---Reset both Tainted Edith's Move charge and Birthright charge
---@param player any
function edithMod.resetCharges(player)
	local playerData = mod.GetData(player)
	playerData.ImpulseCharge = 0
	playerData.BirthrightCharge = 0
end

---Helper function to stop Tainted Edith's hop-dash
---@param player EntityPlayer
---@param cooldown integer
---@param useQuitJump boolean
---@param resetChrg boolean
function edithMod.stopTEdithHops(player, cooldown, useQuitJump, resetChrg)
	if not mod.IsEdith(player, true) then return end

	local playerData = mod.GetData(player)
	playerData.IsHoping = false
	player:MultiplyFriction(0.5)
	playerData.HopVector = Vector.Zero

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

---Manages Edith's Target and Tainted Edith's arrow behavior when going trough doors
---@param effect EntityEffect
---@param player EntityPlayer
---@param triggerDistance number
function edithMod:TargetDoorManager(effect, player, triggerDistance)
	local room = game:GetRoom()
	local level = game:GetLevel()
	local effectPos = effect.Position
	local roomName = level:GetCurrentRoomDesc().Data.Name
	local isTainted = mod.IsEdith(player, true) or false
	local MirrorRoomCheck = roomName == "Mirror Room" and player:HasInstantDeathCurse()

	for i = 0, 7 do
		local door = room:GetDoor(i)
		if not door then goto Break end
		local sprite = door:GetSprite()
		local MausoleumRoomCheck = string.find(sprite:GetLayer(0):GetSpritesheetPath(), "mausoleum") ~= nil
		local doorPos = room:GetDoorSlotPosition(i)
		if not (doorPos and effectPos:Distance(doorPos) <= triggerDistance) then 			
			if player.Color.A < 1 then
				mod:ChangeColor(player.Color, 1, 1, 1, 1)
			end
			goto Break 
		end
		if door:IsOpen() or MirrorRoomCheck then
			mod:ChangeColor(player.Color, 1, 1, 1, 0)
			player.Position = doorPos
			mod.RemoveEdithTarget(player, isTainted)
			
		elseif MausoleumRoomCheck then
			if not sprite:IsPlaying("KeyOpen") then
				sprite:Play("KeyOpen")
			end

			if sprite:IsFinished("KeyOpen") then
				door:TryUnlock(player, true)
			end
		else
			mod:ChangeColor(player.Color, 1, 1, 1, 1)
			door:TryUnlock(player)
		end
		::Break::
	end
end

---@param player EntityPlayer
function edithMod.ManageEdithWeapons(player)
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
function edithMod.CustomDropBehavior(player, jumpData)
	local playerData = mod.GetData(player)
	local height = jumpData.Height
	local isJumping = jumpData.Jumping

	playerData.ShouldDrop = playerData.ShouldDrop or false
	
	if playerData.ShouldDrop == false then
	---@diagnostic disable-next-line: undefined-field
		player:SetActionHoldDrop(0)
	end

	if not isJumping then playerData.ShouldDrop = false return end
	if not Input.IsActionTriggered(ButtonAction.ACTION_DROP, player.ControllerIndex) then return end
	local IsFalling = JumpLib:IsFalling(player)
	if not (height > 10 and not IsFalling) then return end
	playerData.ShouldDrop = true
	---@diagnostic disable-next-line: undefined-field
	player:SetActionHoldDrop(119)
end

---@param player EntityPlayer
function edithMod.DashItemBehavior(player)
	local edithTarget = mod.GetEdithTarget(player)

	if not edithTarget then return end
	local effects = player:GetEffects()
	local hasMarsEffect = effects:HasCollectibleEffect(CollectibleType.COLLECTIBLE_MARS)
	local direction = mod.GetEdithTargetDirection(player)
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
function edithMod.InitEdithJump(player)	
	local distance = mod.GetEdithTargetDistance(player)
	local jumpSpeed = player.CanFly and 1 or 1.5
	local soundeffect = player.CanFly and SoundEffect.SOUND_ANGEL_WING or SoundEffect.SOUND_SHELLGAME
	local div = player.CanFly and 15 or 25

	sfx:Play(soundeffect)

	local epicFetusMult = player:HasCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS) and 3 or 1
	local jumpHeight = (10 + (distance / 40) / div) * epicFetusMult
	local DustCloud = Isaac.Spawn(
		EntityType.ENTITY_EFFECT,
		EffectVariant.POOF01,
		1,
		player.Position,
		Vector.Zero,
		player
	)
	DustCloud.DepthOffset = -100

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
function edithMod.IsDogmaAppearCutscene()
	local TV = Isaac.FindByType(EntityType.ENTITY_GENERIC_PROP, 4)[1] -- Im sure there's only one TV, if needed i'll improve this function with more checks and stuff
	local Dogma = Isaac.FindByType(EntityType.ENTITY_DOGMA)[1] -- Again, there's only One Dogma, but who knows maybe i'll add more checks in the future 

	if not TV then return false end
	TVSprite = TV:GetSprite()

	return TVSprite:GetAnimation() == "Idle2" and Dogma ~= nil
end

---@param tear EntityTear
local function tearCol(_, tear)
	if not tear.Parent then return end

	local player = tear.Parent:ToPlayer()
	if not player or not edithMod:IsAnyEdith(player) then return end

	local tearData = edithMod.GetData(tear)
	if not tearData.ShatterSprite then return end

	local isBloody = string.find(tearData.ShatterSprite, "blood") ~= nil
	local isBurnt = string.find(tearData.ShatterSprite, "burnt") ~= nil
	local shatterColor = tables.TearShatterColor[isBurnt][isBloody]

	for _, ent in ipairs(Isaac.GetRoomEntities()) do
		if not (ent.Type == 1000 and (ent.Variant == 145 or ent.Variant == 35)) then goto Break end
		if tear.Position:Distance(ent.Position) > 15 then goto Break end
		if ent.Variant == 35 then
			ent.Color = ent.Color * misc.BurnedSaltColor
			print(ent.Color)
		elseif ent.Variant == 145 then
			-- print("asdk[asdjop]")
			-- print(misc.TearPath .. tearData.ShatterSprite .. ".png")
			ent:GetSprite():ReplaceSpritesheet(0, misc.TearPath .. tearData.ShatterSprite .. ".png", true)
		end
		ent.Color:SetTint(shatterColor[1], shatterColor[2], shatterColor[3], 1)
		print(ent.Variant, ent.Color)
		-- edithMod:ChangeColor(ent.Color, shatterColor[1], shatterColor[2], shatterColor[3])
		::Break::
	end
end
edithMod:AddCallback(ModCallbacks.MC_POST_TEAR_DEATH, tearCol)

---@param tear EntityTear
---@param IsBlood boolean
---@param isTainted boolean
local function doEdithTear(tear, IsBlood, isTainted)
	local player = edithMod:GetPlayerFromTear(tear)

	if not player then return end

	local tearSizeMult = player:HasCollectible(CollectibleType.COLLECTIBLE_SOY_MILK) and 1 or 0.85
	local tearData = edithMod.GetData(tear)

	tear.Scale = tear.Scale * tearSizeMult
	tear:ChangeVariant(TearVariant.ROCK)
	local tearSprite = tear:GetSprite()
		
	local path = (isTainted and (IsBlood and "burnt_blood_salt_tears" or "burnt_salt_tears") or (IsBlood and "blood_salt_tears" or "salt_tears"))
	
	tearData.ShatterSprite = (isTainted and (IsBlood and "burnt_blood_salt_shatter" or "burnt_salt_shatter") or (IsBlood and "blood_salt_shatter" or "salt_shatter"))
				
	local newSprite = misc.TearPath .. path .. ".png"
	tearSprite:ReplaceSpritesheet(0, newSprite, true)
	tear.Color = player.Color
end

---Forces tears to look like salt tears. `tainted` argument sets tears for Tainted Edith
---@param tear EntityTear
---@param tainted? boolean
function edithMod.ForceSaltTear(tear, tainted)
	tainted = tainted or false
	local IsBloodTear = edithMod.When(tear.Variant, tables.BloodytearVariants, false) 
	
	doEdithTear(tear, IsBloodTear, tainted)
end

---Converts seconds to game update frames
---@param seconds number
---@return number
function edithMod:SecondsToFrames(seconds)
	return math.ceil(seconds * 30)
end

---Custom black powder spawn (Used for Edith's black powder stomp synergy)
---@param parent Entity
---@param quantity number
---@param position Vector
---@param distance number
function edithMod:SpawnBlackPowder(parent, quantity, position, distance)
	quantity = quantity or 20
	distance = distance or 60
		
	local degrees = 360 / quantity
	for i = 1, quantity do
		local blackPowder = Isaac.Spawn(
			EntityType.ENTITY_EFFECT,
			EffectVariant.PLAYER_CREEP_BLACKPOWDER, 
			0, 
			position + Vector(0, distance):Rotated(degrees * i), 
			Vector.Zero, 
			parent
		):ToEffect()
		if not blackPowder then return end
		local powderData = edithMod.GetData(blackPowder)
		powderData.CustomSpawn = true
	end

	local Pentagram = Isaac.Spawn(
		EntityType.ENTITY_EFFECT,
		EffectVariant.PENTAGRAM_BLACKPOWDER, 
		0, 
		position, 
		Vector.Zero, 
		nil
	):ToEffect()

	Pentagram.Scale = distance + distance / 2	
end

---Expontential function
---@param number number
---@param coeffcient number
---@param power number
---@return integer
function edithMod.exp(number, coeffcient, power)
    return number ~= 0 and coeffcient * number ^ (power - 1) or 0
end

---Logaritmic function
---@param x number
---@param base number
---@return number?
function edithMod.Log(x, base)
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
function edithMod.SetNewANM2(player, FilePath)
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
---@param spawnType string
function edithMod:SpawnSaltCreep(parent, position, damage, timeout, gibAmount, spawnType)
	local salt = Isaac.Spawn(
		EntityType.ENTITY_EFFECT, 
		EffectVariant.PLAYER_CREEP_RED, 
		edithMod.Enums.SubTypes.SALT_CREEP,
		position, 
		Vector.Zero,
		parent
	):ToEffect()
	
	if not salt then return end

	salt.CollisionDamage = damage or 0
	
	local timeOutSeconds = edithMod:SecondsToFrames(timeout) or 30
	salt:SetTimeout(timeOutSeconds)
	
	if gibAmount and gibAmount > 0 then
		edithMod:SpawnSaltGib(parent, gibAmount, Color.Default)
	end
	local saltData = edithMod.GetData(salt)
	saltData.SpawnType = spawnType
end

---Returns distance between Edith and her target
---@param player EntityPlayer
---@return number
function edithMod.GetEdithTargetDistance(player)
	local playerData = edithMod.GetData(player)
	local target = playerData.EdithTarget---@type EntityEffect

	return player.Position:Distance(target.Position)
end

---Returns a normalized vector that represents direction regarding Edith and her Target
---@param player EntityPlayer
---@return Vector
function edithMod.GetEdithTargetDirection(player)
	local playerData = edithMod.GetData(player)
	local target = playerData.EdithTarget ---@type EntityEffect
	local dif = target.Position - player.Position

	return dif:Normalized()
end

---Spawns Pepper creep, used for Pepper Grinder
---@param parent Entity
---@param position Vector
---@param damage number
---@param timeout number
function edithMod:SpawnPepperCreep(parent, position, damage, timeout)
	local pepper = Isaac.Spawn(
		EntityType.ENTITY_EFFECT, 
		EffectVariant.PLAYER_CREEP_RED, 
		edithMod.Enums.SubTypes.PEPPER_CREEP,
		position, 
		Vector.Zero,
		parent
	):ToEffect()
	
	if not pepper then return end
	pepper.CollisionDamage = damage or 0
	local timeOutSeconds = edithMod:SecondsToFrames(timeout) or 30
	pepper:SetTimeout(timeOutSeconds)
end

---Forcefully adds a costume for a character
---@param player EntityPlayer
---@param playertype PlayerType
---@param costumePath integer
function edithMod.ForceCharacterCostume(player, playertype, costumePath)
	local playerData = edithMod.GetData(player)

	playerData.HasCostume = playerData.HasCostume or {}

	local hasCostume = playerData.HasCostume[playertype] or false
	local isCurrentPlayerType = (player:GetPlayerType() == playertype)

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

---Checks if a number is between other two numbers
---@param num number
---@param lower number
---@param upper number
---@return boolean
function edithMod:IsBetweenNumber(num, lower, upper)
	return (lower <= num and num <= upper) or (lower >= num and num >= upper)
end

---Checks if player is shooting by checking if shoot inputs are being pressed
---@param player EntityPlayer
---@return boolean
function edithMod:IsPlayerShooting(player)
	local shoot = {
        l = Input.IsActionPressed(ButtonAction.ACTION_SHOOTLEFT, player.ControllerIndex),
        r = Input.IsActionPressed(ButtonAction.ACTION_SHOOTRIGHT, player.ControllerIndex),
        u = Input.IsActionPressed(ButtonAction.ACTION_SHOOTUP, player.ControllerIndex),
        d = Input.IsActionPressed(ButtonAction.ACTION_SHOOTDOWN, player.ControllerIndex)
    }
	return (shoot.l or shoot.r or shoot.u or shoot.d)
end

local targetSprite = Sprite("gfx/edith target.anm2", true)

---Draws a line between From position to To position
---@param from Vector
---@param to Vector
---@param color Color
function edithMod.drawLine(from, to, color)
	local diffVector = to - from
	local angle = diffVector:GetAngleDegrees()
	local sectionCount = math.floor(diffVector:Length() / 16)
	local direction = Vector.FromAngle(angle)

	targetSprite.Color = color
	targetSprite.Rotation = angle
	targetSprite:SetFrame("Line", 0)

	for i = 0, sectionCount - 1 do
		local currentPos = from + direction * (i * 16)
		targetSprite:Render(Isaac.WorldToScreen(currentPos))
	end
end

---Spawns Salt gibs (Used as a visual feedback effect for edith stomps and salt related items)
---@param parent Entity
---@param Number integer
---@param color? Color
function edithMod:SpawnSaltGib(parent, Number, color)
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
		finalColor:SetOffset(COff.R + (POff.R), COff.G + (POff.G), COff.B + (POff.B))
		finalColor:SetColorize(PCol.R, PCol.G, PCol.B, PCol.A)
	end

    for _ = 1, Number do    
        local saltGib = Isaac.Spawn(
            EntityType.ENTITY_EFFECT,
            EffectVariant.TOOTH_PARTICLE,
            0,
            parentPos,
            RandomVector():Resized(3),
            parent
		):ToEffect()

		if not saltGib then return end

        saltGib.Color = finalColor
		saltGib.Timeout = 5
    end
end

---Function to spawn Edith's Target, setting `tainted` to `true` will Spawn Tainted Edith's Arrow
---@param player EntityPlayer
---@param tainted? boolean
function edithMod.SpawnEdithTarget(player, tainted)
	tainted = tainted or false
	local playerData = edithMod.GetData(player)

	local TargetVariant = tainted and effectVariant.EFFECT_EDITH_B_TARGET or effectVariant.EFFECT_EDITH_TARGET

	local TargetData = (tainted and playerData.TaintedEdithTarget) or playerData.EdithTarget

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
	
	if tainted then
		playerData.TaintedEdithTarget = target
	else
		target.GridCollisionClass = GridCollisionClass.COLLISION_SOLID
		playerData.EdithTarget = target
	end
end

---Function to get Edith's Target, setting `tainted` to `true` will return Tainted Edith's Arrow
---@param player EntityPlayer
---@return EntityEffect
function edithMod.GetEdithTarget(player, tainted)
	tainted = tainted or false
	local playerData = edithMod.GetData(player)
	local target = (tainted and playerData.TaintedEdithTarget) or playerData.EdithTarget

	return target
end

---Function to remove Edith's target
---@param player EntityPlayer
---@param tainted? boolean
function edithMod.RemoveEdithTarget(player, tainted)
	tainted = tainted or false
	local target = mod.GetEdithTarget(player, tainted)

	if not target then return end
	target:Remove()

	local playerData = edithMod.GetData(player)
	if tainted then
		playerData.TaintedEdithTarget = nil
	else
		playerData.EdithTarget = nil
	end
end

---Function used to manage and change Shockwave sprites from `TSIL` Library
---@return string
function edithMod.ShockwaveSprite()
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

function edithMod.HasBitFlags(flags, checkFlag)
	return flags & checkFlag == checkFlag
end

---Checks if are in Chapter 4 (Womb, Utero, Scarred Womb, Corpse)
---@return boolean
function edithMod:isChap4()
	local level = game:GetLevel()
	local stage = level:GetStage()
	local Chap4Stages = tables.Chap4Stages

	return mod.When(stage, Chap4Stages, false)
end

---Returns player's tears stat as portrayed in game's stats HUD
---@param p EntityPlayer
---@return number
function edithMod.GetTPS(p)
    return TSIL.Utils.Math.Round(30 / (p.MaxFireDelay + 1), 2)
end

function edithMod.HandleEntityInteraction(ent, parent, knockback)
    local posDif = ent.Position - parent.Position
    local stompBehavior = {
        [EntityType.ENTITY_TEAR] = function()
            local tear = ent:ToTear()
            if not tear then return end
			if mod.IsEdith(parent, true) then return end

            tear:AddTearFlags(TearFlags.TEAR_QUADSPLIT)
            tear.CollisionDamage = tear.CollisionDamage * 2
            ent.Velocity = (posDif):Resized(knockback) * 1.5
        end,
        [EntityType.ENTITY_FIREPLACE] = function()
            if ent.Variant == 4 then return end
            ent:Die()
        end,
        [EntityType.ENTITY_FAMILIAR] = function()
            local familiars = {
                [FamiliarVariant.SAMSONS_CHAINS] = true,
                [FamiliarVariant.PUNCHING_BAG] = true,
                [FamiliarVariant.CUBE_BABY] = true,
            }
            
            local isphysicFamiliar = mod.When(ent.Variant, familiars, false)
            
            if not isphysicFamiliar then return end
            ent.Velocity = (posDif):Resized(knockback)
        end,
        [EntityType.ENTITY_BOMB] = function()
			local playerData = mod.GetData(parent)
			if mod.IsEdith(parent, true) and playerData.MoveCharge < 80 then
				return
			end

            ent.Velocity = (posDif):Resized(knockback)
        end,
        [EntityType.ENTITY_PICKUP] = function()
            local pickup = ent:ToPickup()
            
            if not pickup then return end

            local BlacklisVariants = {
                [PickupVariant.PICKUP_PILL] = true,
                [PickupVariant.PICKUP_TAROTCARD] = true,
                [PickupVariant.PICKUP_TRINKET] = true,
                [PickupVariant.PICKUP_COLLECTIBLE] = true,
                [PickupVariant.PICKUP_BROKEN_SHOVEL] = true,
            }

            local isFlavorTextPickup = mod.When(pickup.Variant, BlacklisVariants, false)
            local IsLuckyPenny = ent.Variant == PickupVariant.PICKUP_COIN and ent.SubType == CoinSubType.COIN_LUCKYPENNY

            if not isFlavorTextPickup and not IsLuckyPenny then
                parent:ForceCollide(pickup, true)
            end
            
            if ent.Variant == PickupVariant.PICKUP_BOMBCHEST then
                pickup:TryOpenChest(parent)
            end
        end,
        [EntityType.ENTITY_SLOT] = function()    
        end,
        [EntityType.ENTITY_SHOPKEEPER] = function()
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
function edithMod.LandDamage(ent, dealEnt, damage, knockback)
	if not (ent:IsActiveEnemy() and ent:IsVulnerableEnemy()) then return end

	ent:TakeDamage(damage, damageFlags, EntityRef(dealEnt), 0)
	edithMod.TriggerPush(ent, dealEnt, knockback, 5, false)
end

---Custom Edith stomp Behavior
---@param parent EntityPlayer
---@param radius number
---@param damage number
---@param knockback number
---@param breakGrid boolean
function edithMod:EdithStomp(parent, radius, damage, knockback, breakGrid)
	local StompCapsule = Capsule(parent.Position, Vector.One, 0, radius)
	local HasTerra = parent:HasCollectible(CollectibleType.COLLECTIBLE_TERRA)
	local rng = utils.RNG

	if breakGrid then
		mod:DestroyGrid(parent, radius)
	end

	for _, ent in ipairs(Isaac.FindInCapsule(StompCapsule)) do
		mod.HandleEntityInteraction(ent, parent, knockback)

		if not (ent:IsActiveEnemy() and ent:IsVulnerableEnemy()) then goto Break end
		if mod.IsKeyStompPressed(parent) then
			ent:AddFreeze(EntityRef(parent), 150)
			goto Break
		end
	
		local FrozenEnt = ent:HasEntityFlags(EntityFlag.FLAG_FREEZE)
		local damageMult = FrozenEnt and 1.3 or 1 
		local terraMult = HasTerra and rng:RandomInt(500, 2500) / 1000 or 1							
		damage = (damage * damageMult) * terraMult
	
		mod.LandDamage(ent, parent, damage, knockback)
		::Break::
	end
end

---Triggers a push to `pushed` from `pusher`
---@param pushed Entity
---@param pusher Entity
---@param strength number
---@param duration integer
---@param impactDamage boolean
function edithMod.TriggerPush(pushed, pusher, strength, duration, impactDamage)
	local dir = ((pusher.Position - pushed.Position) * -1):Resized(strength)
	pushed:AddKnockback(EntityRef(pusher), dir, duration, impactDamage)
end

---Method used for Edith's dash behavior (Like A Pony/White Pony or Mars usage)
---@param player EntityPlayer
---@param dir Vector
---@param dist number
---@param div number
function edithMod.EdithDash(player, dir, dist, div)
	player.Velocity = player.Velocity + dir * dist / div
end

--- Helper function that returns a table containing all existing enemies
---@return Entity[]
function edithMod.GetEnemies()
    local roomEnt = Isaac.GetRoomEntities()
    local enemyTable = {}

    for _, ent in ipairs(roomEnt) do
        if not (ent:IsActiveEnemy() and ent:IsVulnerableEnemy()) then goto Break end
        table.insert(enemyTable, ent)
        ::Break::
    end

    return enemyTable
end 

local AllPartitions = EntityPartition.BULLET | EntityPartition.EFFECT | EntityPartition.ENEMY | EntityPartition.FAMILIAR | EntityPartition.PICKUP | EntityPartition.TEAR

---Tainted Edith parry land behavior
---@param parent EntityPlayer
---@param radius number
---@param damage number
---@param knockback number
function edithMod:TaintedEdithHop(parent, radius, damage, knockback)
	local HopCapsule = Capsule(parent.Position, Vector.One, 0, radius)
	local CapsulEnts = Isaac.FindInCapsule(HopCapsule)

	for _, ent in ipairs(CapsulEnts) do
		mod.HandleEntityInteraction(ent, parent, knockback)
		mod.LandDamage(ent, parent, damage, knockback)
	end
end

--[[Function for audiovisual feedback of Edith and Tainted Edith landings.
	`soundTable` Takes a table with sound IDs.
	`GibColor` Takes a color for salt gibs spawned on Landing.
	`IsParryLand` Is used for Tainted Edith's parry land behavior and can be ignored.]]	
---@param player EntityPlayer
---@param soundTable table
---@param GibColor Color
---@param IsParryLand? boolean
function edithMod.LandFeedbackManager(player, soundTable, GibColor, IsParryLand)
	local saveManager = edithMod.SaveManager 
	if not saveManager:IsLoaded() then return end
	local menuData = saveManager:GetSettingsSave()
	if not menuData then return end

	local room = game:GetRoom()
	local BackDrop = room:GetBackdropType()
	local hasWater = room:HasWater()
	local Variant = hasWater and EffectVariant.BIG_SPLASH or EffectVariant.POOF02
	local SubType = hasWater and 2 or (edithMod:isChap4() and 3 or 1)
	local backColor = tables.BackdropColors
	local miscData = menuData.miscData
	local soundPick ---@type number
	local SizeX ---@type number
	local SizeY ---@type number
	local volume ---@type number
	local ScreenShakeIntensity ---@type number
	local gibAmount ---@type number

	local playerData = mod.GetData(player)
	local IsSoulOfEdith = playerData.IsSoulOfEdithJump 
	-- return tags["edithMod_TaintedEdithJump"] or false

	if edithMod.IsEdith(player, false) or IsSoulOfEdith then
		local isStomping = edithMod.IsKeyStompPressed(player)
		local EdithData = menuData.EdithData

		soundPick = EdithData.stompsound ---@type number
		volume = (isStomping and 1.5 or 2) * ((EdithData.stompVolume / 100) ^ 2) ---@type number
		SizeX = (IsSoulOfEdith and 0.8 or (isStomping and 0.6 or 0.7)) * player.SpriteScale.X
		SizeY = (IsSoulOfEdith and 0.8 or (isStomping and 0.6 or 0.8)) * player.SpriteScale.X
		ScreenShakeIntensity = isStomping and 6 or 10
		gibAmount = not EdithData.DisableGibs and 10 or 0
	else 
		local TEdithData = menuData.TEdithData
		SizeX = IsParryLand and 0.8 or 0.5
		SizeY = IsParryLand and 0.7 or 0.5
		soundPick = IsParryLand and TEdithData.TaintedParrySound or TEdithData.TaintedHopSound ---@type number
		volume = (IsParryLand and 1.5 or 1) * ((TEdithData.taintedStompVolume / 100) ^ 2) ---@type number
		ScreenShakeIntensity = IsParryLand and 6 or 3
		gibAmount = not TEdithData.DisableGibs and (IsParryLand and 6 or 2) or 0
	end

	local sound = edithMod.When(soundPick, soundTable, 1)
	sfx:Play(sound, volume, 0, false, 1, 0)

	if miscData.shakescreen then
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
			color = edithMod.When(BackDrop, backColor, Color(0.7, 0.75, 1))
		end,
		[EffectVariant.POOF02] = function()
			color = BackDrop == BackdropType.DROSS and defColor or backColor[BackDrop] 
		end,
	}
	
	edithMod.WhenEval(Variant, switch)
	color = color or defColor

	stompGFX.SpriteScale = Vector(SizeX, SizeY) * player.SpriteScale.X
	stompGFX.Color = color
	GibColor = GibColor or defColor
	edithMod:SpawnSaltGib(player, gibAmount, GibColor)
end

---@param entity Entity
---@return EntityPlayer?
function edithMod:GetPlayerFromTear(entity)
	for i=1, 3 do
		local check = nil
		if i == 1 then
			check = entity.Parent
		elseif i == 2 then
			check = entity.SpawnerEntity
		end
		if check then
			if check.Type == EntityType.ENTITY_PLAYER then
				return edithMod:GetPtrHashEntity(check):ToPlayer()
			elseif check.Type == EntityType.ENTITY_FAMILIAR then
				return check:ToFamiliar().Player:ToPlayer()
			end
		end
	end
	return nil
end

---comment
---@param entity Entity
---@return table
function edithMod.GetData(entity)
	local data = entity:GetData()
	data.edithMod = data.edithMod or {}
	return data.edithMod
end

function edithMod:GetPtrHashEntity(entity)
	if entity then
		if entity.Entity then
			entity = entity.Entity
		end
		for _, matchEntity in pairs(Isaac.FindByType(entity.Type, entity.Variant, entity.SubType, false, false)) do
			if GetPtrHash(entity) == GetPtrHash(matchEntity) then
				return matchEntity
			end
		end
	end
	return nil
end