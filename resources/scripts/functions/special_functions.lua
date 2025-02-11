local mod = edithMod
local enums = mod.Enums
local utils = enums.Utils
local game = utils.Game
local tables = enums.Tables
local misc = enums.Misc

---Function to remove Edith's target
---@param player EntityPlayer
function edithMod.RemoveEdithTarget(player)
	local playerData = edithMod.GetData(player)
	if not edithMod.IsEdith(player, false) then return end
	if not playerData.EdithTarget then return end
	
	playerData.EdithTarget:Remove()
	playerData.EdithTarget = nil
end

--[[Checks if player is Edith.
	Boolean argument checks for Tainted Edith
]]
---@param player EntityPlayer
---@param tainted boolean
---@return boolean
function edithMod.IsEdith(player, tainted)
	return player:GetPlayerType() == (tainted and edithMod.Enums.PlayerType.PLAYER_EDITH_B or edithMod.Enums.PlayerType.PLAYER_EDITH)
end

---Checks if any player is Edith
---@param player EntityPlayer
---@return boolean
function edithMod:IsAnyEdith(player)
	return edithMod.IsEdith(player, true) or edithMod.IsEdith(player, false)
end
	
---Function to remove Tainted Edith's arrow 
---@param player EntityPlayer
function edithMod:RemoveTaintedEdithTargetArrow(player)
	local playerData = edithMod.GetData(player)
	
	if not edithMod.IsEdith(player, true) then return end
	
	if not playerData.TaintedEdithTarget then return end
	
	playerData.TaintedEdithTarget:Remove()
	playerData.TaintedEdithTarget = nil
end

---Changes `Entity` velocity so now it goes to `Target`'s Position, `strenght` determines how fast it'll go
---@param Entity Entity
---@param Target Entity
---@param strenght number`
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

---
---@param entity Entity
---@return number
function edithMod:GetAceleration(entity)
	return entity.Velocity:Length()
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

---Changes `Vec` components (works the same as setting them manually)
---@param Vec Vector
---@param x number
---@param y number
function edithMod.SetVector(Vec, x, y)
	Vec.X = x
	Vec.Y = y
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
    local newTears = currentTears + val
	
	if mult then
		newTears = currentTears * val
	end
    return math.max((30 / newTears) - 1, -0.75)
end

---Helper range stat manager function
---@param range number
---@param val number
---@return number
function edithMod.rangeUp(range, val)
    local currentRange = range / 40.0
    local newRange = currentRange + val
    return math.max(1.0,newRange) * 40.0
end

---Returns player's range stat as portrayed in Game's stat HUD
---@param player EntityPlayer
---@return number
function edithMod:GetPlayerRange(player)
	return player.TearRange / 40
end

---Converts a vector to an angle
---@param vector Vector
---@return integer
function edithMod.vectorToAngle(vector)
	local x = vector.X 
	local y = vector.Y

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
---@param entity Entity
---@param red number
---@param green number
---@param blue number
---@param alpha? number
---@param redOff? number
---@param greenOff? number
---@param blueOff? number
function edithMod:ChangeColor(entity, red, green, blue, alpha, redOff, greenOff, blueOff)
	local color = entity.Color
	color.R = red or entity.Color.R
	color.G = green or entity.Color.G
	color.B = blue or entity.Color.B
	color.A = alpha or entity.Color.A
	color.RO = redOff or entity.Color.RO
	color.GO = greenOff or entity.Color.GO
	color.BO = blueOff or entity.Color.BO
	
	entity.Color = color
end

---Helper grid destroyer function
---@param entity Entity
---@param radius number
function edithMod:DestroyGrid(entity, radius)
	radius = radius or 10
	local room = game:GetRoom()
	local roomSize = room:GetGridSize()

	for i = 0, roomSize do
		local grid = room:GetGridEntity(i)
		if grid then
			local distance = (entity.Position - grid.Position):Length()
			if distance <= radius then
				grid:Destroy()
			end
		end
	end
end

local LINE_SPRITE = Sprite()
LINE_SPRITE:Load("gfx/TinyBug.anm2", true)
LINE_SPRITE:SetFrame("Dead", 0)

local MAX_POINTS = 360
local ANGLE_SEPARATION = 360 / MAX_POINTS

---
---@param entity Entity
---@param AreaSize number
---@param AreaColor Color
function edithMod.RenderAreaOfEffect(entity, AreaSize, AreaColor) -- Took from Melee lib, tweaked a little bit
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
		LINE_SPRITE.Color = AreaColor or Color.Default
        LINE_SPRITE:Render(renderPosition)
    end
end

---Returns a random rune (Used for Geode trinket)
---@param rng RNG
---@return integer
function edithMod:GetRandomRune(rng)
	local runes = #tables.Runes
	
	local runeRandomSelect = edithMod.RandomNumber(1, runes)
	return tables.Runes[runeRandomSelect]
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

	for i = 0, 7 do
		local door = room:GetDoor(i)
		if door then
			local doorPos = room:GetDoorSlotPosition(i)
			if doorPos and effectPos:Distance(doorPos) <= triggerDistance then
				if door:IsOpen() or (roomName == "Mirror Room" and player:GetEffects():HasNullEffect(NullItemID.ID_LOST_CURSE)) then
					player.Position = doorPos
					edithMod.RemoveEdithTarget(player)
					edithMod:RemoveTaintedEdithTargetArrow(player)
					edithMod:ChangeColor(player, 1, 1, 1, 0)
				else
					door:TryUnlock(player)
				end
				break
			end
		end
	end
end

---@param tear EntityTear
local function tearCol(_, tear)
	if not tear.Parent then return end

	local player = tear.Parent:ToPlayer()
	
	if not player then return end
	if not edithMod:IsAnyEdith(player) then return end	
	local tearData = edithMod.GetData(tear)
	
	if not tearData.ShatterSprite then return end

	local isBloody = string.find(tearData.ShatterSprite, "blood") ~= nil
	local isBurnt = string.find(tearData.ShatterSprite, "burnt") ~= nil
	local tableColor = tables.TearShatterColor
	local shatterColor = tableColor[isBurnt][isBloody]
		
	for _, ent in ipairs(Isaac.GetRoomEntities()) do
		if ent.Type == 1000 and (ent.Variant == 145 or ent.Variant == 35) then
			local dist = tear.Position:Distance(ent.Position)
			if dist <= 10 then
				if ent.Variant == 35 then		
					ent.Color = tear.Color
					edithMod:ChangeColor(ent, shatterColor[1], shatterColor[2], shatterColor[3])
				end
				if ent.Variant == 145 then
					local sprite = ent:GetSprite()
					sprite:ReplaceSpritesheet(0, misc.TearPath .. tearData.ShatterSprite .. ".png", true)
					edithMod:ChangeColor(ent, shatterColor[1], shatterColor[2], shatterColor[3])
				end
			end
		end
	end
end
edithMod:AddCallback(ModCallbacks.MC_POST_TEAR_DEATH, tearCol)

---@param tear EntityTear
---@param IsBlood boolean
---@param isTainted boolean
local function doEdithTear(tear, IsBlood, isTainted)
	local player = tear.Parent:ToPlayer()	

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

---Forces tears to look like salt tears. Boolean argument sets tears for Tainted Edith
---@param tear EntityTear
---@param tainted? boolean
function edithMod.ForceSaltTear(tear, tainted)
	tainted = tainted or false
	local IsBloodTear = tables.BloodytearVariants[tear.Variant] or false
	
	doEdithTear(tear, IsBloodTear, tainted)
end

---Converts seconds to game update frames
---@param seconds number
---@return integer
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
function edithMod:exponentialFunction(number, coeffcient, power)
    return number ~= 0 and coeffcient * number ^ (power - 1) or 0
end

---Logaritmic function
---@param x number
---@param base number
---@return number?
function edithMod:Log(x, base)
    if x <= 0 or base <= 1 then
        return nil
    end

    local logNatural = math.log(x)
    local logBase = math.log(base)
    
    return logNatural / logBase
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
		edithMod:SpawnSaltGib(parent, gibAmount, Color.Default, 15, spawnType)
	end
	local saltData = edithMod.GetData(salt)
	
	saltData.SpawnType = spawnType
end

---Returns distance between Edith and her target
---@param player EntityPlayer
---@return number
function edithMod.GetEdithTargetDistance(player)
	if not edithMod.IsEdith(player, false) then return end
	local playerData = edithMod.GetData(player)
	local target = playerData.EdithTarget ---@type EntityEffect

	return player.Position:Distance(target.Position)
end

---Returns a normalize vector that represents direction regarding Edith and her Target
---@param player EntityPlayer
---@return Vector
function edithMod.GetEdithTargetDirection(player)
	if not edithMod.IsEdith(player, false) then return end
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

local red = 255
local green = 0
local blue = 0
local state = 1

local RGBCyclingColor = Color(1, 1, 1, 1)
function edithMod:RGBCycle(step)
    step = step or 1 
		
    if state == 1 then
        green = math.min(255, green + step)
        if green == 255 then
            state = 2
        end
    elseif state == 2 then
        red = math.max(0, red - step)
        if red == 0 then
            state = 3
        end
    elseif state == 3 then
        blue = math.min(255, blue + step)
        if blue == 255 then
            state = 4
        end
    elseif state == 4 then
        green = math.max(0, green - step)
        if green == 0 then
            state = 5
        end
    elseif state == 5 then
        red = math.min(255, red + step)
        if red == 255 then
            state = 6
        end
    elseif state == 6 then
        blue = math.max(0, blue - step)
        if blue == 0 then
            state = 1
        end
    end

	RGBCyclingColor.R = red / 255
	RGBCyclingColor.G = green / 255
	RGBCyclingColor.B = blue / 255

	return RGBCyclingColor
end

---comment
---@param n number
---@return integer
function edithMod:contarCifras(n)
    local str = tostring(n)
	return str:gsub("%+", "."):gsub("%.", ""):len()
end

---Returns a random number, it usually take Mod's RNG object but you can pass any other RNG object you'd like to use
---@param num1 number
---@param num2? number
---@param rng? RNG
---@return (integer|number)
function edithMod.RandomNumber(num1, num2, rng)
    rng = rng or edithMod.Enums.Utils.RNG

    local isFloat = (num2 and math.type(num1 + num2) == "float") or math.type(num1) == "float"

    local cifrasNum1 = edithMod:contarCifras(num1)
    local cifrasNum2 = num2 and edithMod:contarCifras(num2) or 0

    local longerNumber = math.max(cifrasNum1, cifrasNum2)

    local power = isFloat and (num2 and 10 ^ (longerNumber - 1) or 10 ^ (cifrasNum1 - 1)) or 1

	if num1 then
		num1 = math.ceil(num1 * power)
	end
	if num2 then
        num2 = math.ceil(num2 * power)
    end

    local result
	if num1 then
		if num2 then
			result = rng:RandomInt(num1, num2) * (1 / power)
		else
			result = (rng:RandomInt(num1) + 1) * (1 / power)
		end
	else
		result = rng:RandomFloat()
	end
	
	if result % 1 == 0 then
		result = math.tointeger(result)
	end
	
---@diagnostic disable-next-line: return-type-mismatch
    return result
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

---comment Checks if a number is between other two numbers
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

local targetSprite = Sprite()
targetSprite:Load("gfx/edith target.anm2", true)

---Draws a line between From position to To position
---@param from Vector
---@param to Vector
---@param color Color
---@param linespace integer
function edithMod:drawLine(from, to, color, linespace)

	linespace = linespace or 16
	
	local diffVector = (to - from)
	local angle = diffVector:GetAngleDegrees()
	local sectionCount = math.floor(diffVector:Length() / linespace)

	targetSprite.Color = color
	targetSprite.Rotation = angle
	targetSprite:SetFrame("Line", 0)
	targetSprite:Update()
		
	for _ = 1, sectionCount do
		targetSprite:Render(Isaac.WorldToScreen(from))
		from = from + Vector.One * linespace * Vector.FromAngle(angle) 
	end

	targetSprite.Rotation = 0
end

---Spawns Salt gibs (Used as a visual feedback effect for edith stomps)
---@param parent Entity
---@param Number integer
---@param color? Color
---@param timeout? number
---@param spawnType? string
function edithMod:SpawnSaltGib(parent, Number, color, timeout, spawnType)
	for _ = 1, Number do	
		local saltGib = Isaac.Spawn(
			EntityType.ENTITY_EFFECT,
			EffectVariant.TOOTH_PARTICLE,
			0,
			parent.Position,
			RandomVector():Resized(3),
			parent
		):ToEffect() 

		if not saltGib then return end

		if color then 
			saltGib.Color = Color(
				(color.R + parent.Color.R - 1), 
				(color.G + parent.Color.G - 1), 
				(color.B + parent.Color.B - 1), 
				(color.A + parent.Color.A - 1),
				(color.RO + parent.Color.RO),
				(color.GO + parent.Color.GO),
				(color.BO + parent.Color.BO)
			)
		else
			saltGib.Color = parent.Color
		end

	---@diagnostic disable-next-line: param-type-mismatch
		local timeOutSeconds = edithMod:SecondsToFrames(timeout) or 30
		local saltGibData = edithMod.GetData(saltGib)
		saltGib:SetTimeout(timeOutSeconds)
		saltGibData.SpawnType = spawnType
	end
end

---Spawns Edith Target and returns it
---@param player EntityPlayer
---@return EntityEffect
function edithMod:SpawnEdithTarget(player)
	local playerData = edithMod.GetData(player)

	if not playerData.EdithTarget then 
		local target = Isaac.Spawn(	
			EntityType.ENTITY_EFFECT,
			edithMod.Enums.EffectVariant.EFFECT_EDITH_TARGET,
			0,
			player.Position,
			Vector.Zero,
			player
		):ToEffect()
		playerData.EdithTarget = target

		target.DepthOffset = -100
	end

	return playerData.EdithTarget
end

---Returns the closest enemy to player
---@param player EntityPlayer
---@return EntityNPC|nil
function edithMod.GetClosestEnemy(player)
	local closestDistance, closestEnemy
	local room = game:GetRoom()
    for _, enemy in ipairs(Isaac.GetRoomEntities()) do
        if enemy:IsActiveEnemy() and enemy:IsVulnerableEnemy() then
            local distanceToPlayer = enemy.Position:Distance(player.Position)
            if not closestDistance or closestDistance > distanceToPlayer then
                closestEnemy = enemy:ToNPC()
                closestDistance = distanceToPlayer
            end
        end
    end

	if closestEnemy then
		local checkline = room:CheckLine(player.Position, closestEnemy.Position, 0, 1000)
		if checkline == false then return nil end
	end
	return closestEnemy
end

---Spawns Tainted Edith Arrow and returns it
---@param player EntityPlayer
---@return EntityEffect
function edithMod:SpawnTaintedArrow(player)
	local playerData = edithMod.GetData(player)

	if not playerData.TaintedEdithTarget then 
		local arrow = Isaac.Spawn(	
			EntityType.ENTITY_EFFECT,
			edithMod.Enums.EffectVariant.EFFECT_EDITH_B_TARGET,
			0,
			player.Position,
			Vector.Zero,
			player
		):ToEffect()
		playerData.TaintedEdithTarget = arrow

		arrow.DepthOffset = -100
	end

	return playerData.TaintedEdithTarget
end

---Function used to manage and change Shockwave sprites from `TSIL` Library
---@return string
function edithMod:ShockwaveSprite()
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

---Checks if are in Chapter 4 (Womb, Utero, Scarred Womb, Corpse)
---@return boolean
function edithMod:isChap4()
	local room = game:GetRoom()
	local bdType = room:GetBackdropType()

	local chap4bdType = {}

	chap4bdType[10] = true
	chap4bdType[11] = true
	chap4bdType[12] = true
	chap4bdType[13] = true
	chap4bdType[34] = true
	chap4bdType[43] = true
	chap4bdType[44] = true
	
	return chap4bdType[bdType] or false
end

---Returns player's tears stat as portrayed in game's stats HUD
---@param p EntityPlayer
---@return number
function edithMod.GetTPS(p)
    return TSIL.Utils.Math.Round(30 / (p.MaxFireDelay + 1), 2)
end

---Custom Edith stomp Behavior
---@param parent EntityPlayer
---@param radius number
---@param damage number
---@param knockback number
---@param breakGrid boolean
function edithMod:EdithStomp(parent, radius, damage, knockback, breakGrid)
	for i, entity in pairs(Isaac.FindInRadius(parent.Position, radius, 0xFFFFFFFF)) do
		local stompBehavior = {
			[EntityType.ENTITY_TEAR] = function()
				local tear = entity:ToTear()
				if not tear then return end
				tear:AddTearFlags(TearFlags.TEAR_QUADSPLIT)
				tear.CollisionDamage = tear.CollisionDamage * 2
				entity.Velocity = (entity.Position - parent.Position):Resized(knockback) * 1.5
			end,
			[EntityType.ENTITY_FIREPLACE] = function()
				if entity.Variant ~= 4 then
					entity:Die()
				end
			end,
			[EntityType.ENTITY_FAMILIAR] = function()
				local familiars = {
					[FamiliarVariant.SAMSONS_CHAINS] = true,
					[FamiliarVariant.PUNCHING_BAG] = true,
					[FamiliarVariant.CUBE_BABY] = true,
				}
				
				local isphysicFamiliar = familiars[entity.Variant]
				
			
				if isphysicFamiliar then
					entity.Velocity = (entity.Position - parent.Position):Resized(knockback)
				end
			end,
			[EntityType.ENTITY_BOMB] = function()
				entity.Velocity = (entity.Position - parent.Position):Resized(knockback)
			end,
			[EntityType.ENTITY_PICKUP] = function()
				local pickup = entity:ToPickup()
				
				if not pickup then return end

				local FlavorTextPikcupVariants = {
					[PickupVariant.PICKUP_PILL] = true,
					[PickupVariant.PICKUP_TAROTCARD] = true,
					[PickupVariant.PICKUP_TRINKET] = true,
					[PickupVariant.PICKUP_COLLECTIBLE] = true,
					[PickupVariant.PICKUP_BROKEN_SHOVEL] = true,
				}
				
				local isCoinPenny = (
					pickup.Variant == PickupVariant.PICKUP_COIN and
					pickup.SubType == CoinSubType.COIN_LUCKYPENNY
				)
				
				local isFlavorTextPickup = edithMod.SwitchCase(pickup.Variant, FlavorTextPikcupVariants) or isCoinPenny
				
				if not isFlavorTextPickup then
					parent:ForceCollide(pickup, true)
				end
				
				if entity.Variant == PickupVariant.PICKUP_BOMBCHEST then
					pickup:TryOpenChest(parent)
				end
			end,
			[EntityType.ENTITY_SLOT] = function()	
			end,
			[EntityType.ENTITY_SHOPKEEPER] = function()
				entity:Kill()
			end,
			
		}
	
		if entity:IsActiveEnemy() and entity:IsVulnerableEnemy() then
			if edithMod.IsKeyStompPressed(parent) then
				entity:AddFreeze(EntityRef(parent), 150)
				return
			end
		
			local damageMultiplier = entity:HasEntityFlags(EntityFlag.FLAG_FREEZE) and 1.3 or 1 
			
			local terraMultiplier = parent:HasCollectible(CollectibleType.COLLECTIBLE_TERRA) and edithMod.RandomNumber(500, 1500) / 1000 or 1								
			damage = (damage * damageMultiplier) * terraMultiplier
		
			entity:TakeDamage(damage, DamageFlag.DAMAGE_CRUSH | DamageFlag.DAMAGE_IGNORE_ARMOR, EntityRef(parent), 0)
			
			entity.Velocity = (entity.Position - parent.Position):Resized(knockback)
		else
			edithMod.When(entity.Type, stompBehavior)
		end
		if breakGrid then
			edithMod:DestroyGrid(entity, radius)
		end
	end
end

---@param player EntityPlayer
---@return EntityEffect
function edithMod.GetEdithTarget(player)
	local playerData = edithMod.GetData(player)
	local edithTarget = playerData.EdithTarget

	return edithTarget
end


---Method used for Edith's dash behavior (Like A Pony/White Pony or Mars usage)
---@param player EntityPlayer
---@param dir Vector
---@param dist number
---@param div number
function edithMod.EdithDash(player, dir, dist, div)
	player.Velocity = player.Velocity + dir * dist / div
end

---Tainted Edith parry land behavior
---@param parent EntityPlayer
---@param radius number
---@param damage number
---@param knockback number
---@param isParry boolean
function edithMod:TaintedEdithStomp(parent, radius, damage, knockback, isParry)
	for _, entity in ipairs(Isaac.FindInRadius(parent.Position, radius, 0xFFFFFFFF)) do
		local stompBehavior = {
			[EntityType.ENTITY_FIREPLACE] = function()
				if entity.Variant ~= 4 then
					entity:Die()
				end
			end,
			[EntityType.ENTITY_PICKUP] = function()
				local pickup = entity:ToPickup()
				
				if not pickup then return end

				local FlavorTextPikcupVariants = {
					[PickupVariant.PICKUP_PILL] = true,
					[PickupVariant.PICKUP_TAROTCARD] = true,
					[PickupVariant.PICKUP_TRINKET] = true,
					[PickupVariant.PICKUP_COLLECTIBLE] = true,
					[PickupVariant.PICKUP_BROKEN_SHOVEL] = true,
				}
				
				local isCoinPenny = (
					pickup.Variant == PickupVariant.PICKUP_COIN and
					pickup.SubType == CoinSubType.COIN_LUCKYPENNY
				)
				
				local isFlavorTextPickup = edithMod.SwitchCase(pickup.Variant, FlavorTextPikcupVariants) or isCoinPenny
				
				if not isFlavorTextPickup then
					parent:ForceCollide(pickup, true)
				end
				
				if entity.Variant == PickupVariant.PICKUP_BOMBCHEST then
					pickup:TryOpenChest(parent)
				end
			end,
			[EntityType.ENTITY_PROJECTILE] = function()
				entity.Velocity = (entity.Position - parent.Position):Resized(knockback)
			end,
		}
	
		if entity:IsActiveEnemy() and entity:IsVulnerableEnemy() then
		
			entity:TakeDamage(damage, DamageFlag.DAMAGE_CRUSH | DamageFlag.DAMAGE_IGNORE_ARMOR, EntityRef(parent), 0)
			
			entity.Velocity = (entity.Position - parent.Position):Resized(knockback)

			if isParry then
				parent:SetMinDamageCooldown(30)
			end
		else
			edithMod.SwitchCase(entity.Type, stompBehavior)
		end
	end
end

local sfx = utils.SFX

--[[Function for audiovisual feedback of Edith and Tainted Edith landings.
	`soundTable` Takes a table with sound IDs.
	`GibColor` Takes a color for salt gibs spawned on Landing.
	`IsParryLand` Is used for Tainted Edith's parry land behavior and can be ignored.]]	
---@param player EntityPlayer
---@param soundTable table
---@param GibColor Color
---@param IsParryLand? boolean
function edithMod.LandFeedbackManager(player, soundTable, GibColor, IsParryLand)
	local room = game:GetRoom()
	local BackDrop = room:GetBackdropType()
	local hasWater = room:HasWater()
	local Variant = hasWater and EffectVariant.BIG_SPLASH or EffectVariant.POOF02
	local SubType = hasWater and 2 or (edithMod:isChap4() and 3 or 1)
	local backColor = tables.BackdropColors

	local saveManager = edithMod.SaveManager 
	if not saveManager:IsLoaded() then return end
	local menuData = saveManager:GetDeadSeaScrollsSave()
	if not menuData then return end

	local miscData = menuData.miscData

	local soundPick ---@type number
	local SizeX ---@type number
	local SizeY ---@type number
	local volume ---@type number
	local ScreenShakeIntensity ---@type number
	local gibAmount ---@type number

	if edithMod.IsEdith(player, false) then 
		local isStomping = edithMod.IsKeyStompPressed(player)
		local EdithData = menuData.EdithData

		soundPick = EdithData.stompsound ---@type number
		volume = (isStomping and 1.5 or 2) * ((EdithData.stompVolume / 100) ^ 2) ---@type number

		SizeX = isStomping and 0.6 or 0.7 * player.SpriteScale.X
		SizeY = isStomping and 0.6 or 0.8 * player.SpriteScale.X

		ScreenShakeIntensity = isStomping and 6 or 10

		gibAmount = isStomping and 6 or 10
	elseif edithMod.IsEdith(player, true) then
		local TEdithData = menuData.TEdithData

		soundPick = TEdithData.TaintedHopSound ---@type number
		volume = (IsParryLand and 1.5 or 1) * ((TEdithData.taintedStompVolume / 100) ^ 2) ---@type number
		ScreenShakeIntensity = 6
		gibAmount = IsParryLand and 6 or 1
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

	edithMod.SetVector(stompGFX.SpriteScale, SizeX, SizeY)

	local color = Color.Default
	local switch = {
		[EffectVariant.BIG_SPLASH] = function()
			color = edithMod.When(BackDrop, backColor, Color(0.7, 0.75, 1))
		end,
		[EffectVariant.POOF02] = function()
			color = BackDrop == BackdropType.DROSS and Color.Default or backColor[BackDrop] 
		end,
	}
	
	edithMod.WhenEval(Variant, switch)
	color = color or Color.Default

	stompGFX.Color = color
	GibColor = GibColor or Color.Default
	edithMod:SpawnSaltGib(player, gibAmount, GibColor, 5, "StompGib")
end