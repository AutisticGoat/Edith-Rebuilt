local game = edithMod.Enums.Utils.Game
local modrng = edithMod.Enums.Utils.RNG
local room = game:GetRoom()

function edithMod:RemoveEdithTarget(player)
	playerData = edithMod:GetData(player)
	
	if player:GetPlayerType() ~= edithMod.Enums.PlayerType.PLAYER_EDITH then return end
	
	if not playerData.EdithTarget then return end
	
	playerData.EdithTarget:Remove()
	playerData.EdithTarget = nil
end

function edithMod:IsEdithTargetMoving(player)
	local k_up = Input.IsActionPressed(ButtonAction.ACTION_UP, player.ControllerIndex)
    local k_down = Input.IsActionPressed(ButtonAction.ACTION_DOWN, player.ControllerIndex)
    local k_left = Input.IsActionPressed(ButtonAction.ACTION_LEFT, player.ControllerIndex)
    local k_right = Input.IsActionPressed(ButtonAction.ACTION_RIGHT, player.ControllerIndex)
	
    return (k_down or k_right or k_left or k_up) or false
end

function edithMod:GetAceleration(entity)
	local normalizedVelocity = entity.Velocity:Normalized()
	local NewVelValue = entity.Velocity * normalizedVelocity
	
	local acel = NewVelValue.X + NewVelValue.Y
	
	return TSIL.Utils.Math.Round(acel, 2)
end

function edithMod.SwitchCase(value, tables)
    local value = tables[value] or tables["_"]
    return type(value) == "function" and value() or value
end

function edithMod:IsKeyStompPressed(player)
	local k_stomp =
		Input.IsButtonPressed(Keyboard.KEY_Z, player.ControllerIndex) or
        Input.IsButtonPressed(Keyboard.KEY_LEFT_SHIFT, player.ControllerIndex) or
        Input.IsButtonPressed(Keyboard.KEY_RIGHT_SHIFT, player.ControllerIndex) or
		Input.IsButtonPressed(Keyboard.KEY_RIGHT_CONTROL, player.ControllerIndex) or
        Input.IsActionPressed(ButtonAction.ACTION_DROP, player.ControllerIndex)
		
	return k_stomp
end

function edithMod:IsKeyStompTriggered(player)
	local k_stomp =
		Input.IsButtonTriggered(Keyboard.KEY_Z, player.ControllerIndex) or
        Input.IsButtonTriggered(Keyboard.KEY_LEFT_SHIFT, player.ControllerIndex) or
        Input.IsButtonTriggered(Keyboard.KEY_RIGHT_SHIFT, player.ControllerIndex) or
		Input.IsButtonTriggered(Keyboard.KEY_RIGHT_CONTROL, player.ControllerIndex) or
        Input.IsActionTriggered(ButtonAction.ACTION_DROP, player.ControllerIndex)
		
	return k_stomp
end

function edithMod.tearsUp(firedelay, val, mult)
	local mult = mult or false
    local currentTears = 30 / (firedelay + 1)
    local newTears = currentTears + val
	
	if mult then
		newTears = currentTears * val
	end
    return math.max((30 / newTears) - 1, -0.75)
end

function edithMod.rangeUp(range, val)
    local currentRange = range / 40.0
    local newRange = currentRange + val
    return math.max(1.0,newRange) * 40.0
end

function edithMod:GetPlayerRange(player)
	return player.TearRange / 40
end

function edithMod:vectorToAngle(x, y)
    if x == 0 then
        return y > 0 and 90 or y < 0 and 270 or 0
    end
    local atan = math.atan(y / x) * 180 / math.pi
    if x < 0 then
        atan = atan + 180
    elseif y < 0 then
        atan = atan + 360
    end
    atan = math.floor((atan + 45) / 90) * 90
    return atan
end

function edithMod:DestroyGrid(entity, radius)
	radius = radius or 10

	local room = game:GetRoom()
	for i = 0, (room:GetGridSize()) do
		local grid = room:GetGridEntity(i)
		if grid then
			local distance = (entity.Position - grid.Position):Length()
			if distance <= radius + 20 then
				local door = grid:ToDoor()
				if door then return end
				grid:Destroy()
			end
		end
	end
end

local LINE_SPRITE = Sprite()
LINE_SPRITE:Load("gfx/1000.021_tiny bug.anm2", true)
LINE_SPRITE:SetFrame("Dead", 0)

local MAX_POINTS = 32
local ANGLE_SEPARATION = 360 / MAX_POINTS

function edithMod.RenderAreaOfEffect(entity, AreaSize, AreaColor) -- Took from Melee lib and tweaked a little bit
    local hitboxPosition = entity.Position
    local renderPosition = Isaac.WorldToScreen(hitboxPosition) - Game().ScreenShakeOffset
    local hitboxSize = AreaSize
    local offset = Isaac.WorldToScreen(hitboxPosition + Vector(0, hitboxSize)) - renderPosition + Vector(0, 1)
    local offset2 = offset:Rotated(ANGLE_SEPARATION)
    local segmentSize = offset:Distance(offset2)
    LINE_SPRITE.Scale = Vector(segmentSize * 2 / 3, 0.5)
    for i = 1, MAX_POINTS do
        local angle = ANGLE_SEPARATION * i
        LINE_SPRITE.Rotation = angle
        LINE_SPRITE.Offset = offset:Rotated(angle)
		LINE_SPRITE.Color = AreaColor or Color.Default
        LINE_SPRITE:Render(renderPosition)
    end
end

function edithMod:GetRandomRune(rng)
	local runes = {
		Card.RUNE_HAGALAZ,
		Card.RUNE_JERA,
		Card.RUNE_EHWAZ,
		Card.RUNE_DAGAZ,
		Card.RUNE_ANSUZ,
		Card.RUNE_PERTHRO,
		Card.RUNE_BERKANO,
		Card.RUNE_ALGIZ,
		Card.RUNE_BLANK,
		Card.RUNE_BLACK,
	}

	local runeRandomSelect = edithMod:RandomNumber(rng, 1, #runes)
	
	return runes[runeRandomSelect]
end

local function doEdithTear(tear, IsBlood, isTainted)
	local player = tear.Parent:ToPlayer()
	
	local tearSizeMult = player:HasCollectible(CollectibleType.COLLECTIBLE_SOY_MILK) and 1 or 0.85
	
	tear.Scale = tear.Scale * tearSizeMult
	tear:ChangeVariant(TearVariant.ROCK)
	
	if not player then return end
	
	local tearColor = tear.Color
	local playerColor = player.Color
	
	local colorDif = {
		R = 1,
		G = 1,
		B = 1,
	}
	
	local bloodDif = 1
	
	if IsBlood then
		colorDif.R = colorDif.R + 1
		colorDif.G = colorDif.G - bloodDif
		colorDif.B = colorDif.B - bloodDif
	end
	
	local taintedDif = 1.6	
	if isTainted then
		colorDif.R = colorDif.R - taintedDif
		colorDif.G = colorDif.G - taintedDif
		colorDif.B = colorDif.B - taintedDif
	end
	
	local colorize = playerColor:GetColorize()
	
	tearColor.R = tearColor.R + colorDif.R + (playerColor.R - 1)
	tearColor.G = tearColor.G + colorDif.G + (playerColor.G - 1)
	tearColor.B = tearColor.B + colorDif.B + (playerColor.B - 1)

	local isPlayerColorized = (
		colorize.R +
		colorize.G + 
		colorize.B 
	) ~= 0
	
	if isPlayerColorized then
		local ColAdd = 0.7
		
		local bloodAdd = IsBlood and 2 or 0
		local bloodRem = IsBlood and 3 or 0
		
		tearColor.R = tearColor.R + (colorize.R - ColAdd) + bloodAdd
		tearColor.G = tearColor.G + (colorize.G - ColAdd) - bloodRem
		tearColor.B = tearColor.B + (colorize.B - ColAdd) - bloodRem
	
	end
	
	tear.Color = tearColor 
end

function edithMod.ForceSaltTear(tear, tainted)
    local tearVariants = {
        [TearVariant.BLOOD] = true,
        [TearVariant.GLAUCOMA_BLOOD] = true,
        [TearVariant.CUPID_BLOOD] = true,
        [TearVariant.PUPULA_BLOOD] = true,
        [TearVariant.GODS_FLESH_BLOOD] = true,
	}

	local IsBloodTear = tearVariants[tear.Variant] or false
	
	doEdithTear(tear, IsBloodTear, tainted)
end

function edithMod:SecondsToFrames(seconds)
	return math.ceil(seconds * 30)
end

function edithMod:SpawnBlackPowder(parent, quantity, position, distance)
	quantity = quantity or 20
	distance = distance or 60
		
	local degrees = 360 / quantity
	for i = 1, quantity do
		blackPowder = Isaac.Spawn(
			EntityType.ENTITY_EFFECT,
			EffectVariant.PLAYER_CREEP_BLACKPOWDER, 
			0, 
			position + Vector(0, distance):Rotated(degrees * i), 
			Vector.Zero, 
			parent
		):ToEffect()
		
		local powderData = edithMod:GetData(blackPowder)
		powderData.CustomSpawn = true
	end

	local Pentagram = Isaac.Spawn(
		EntityType.ENTITY_EFFECT,
		EffectVariant.PENTAGRAM_BLACKPOWDER, 
		0, 
		position, 
		Vector.Zero, 
		blackPowder
	):ToEffect()
	
	local entityPosition = blackPowder.Position
	local centerPosition = position
	local radius = (entityPosition - centerPosition):Length()

	Pentagram.Scale = distance + distance / 2	
end

function edithMod:exponentialFunction(number, coeffcient, power)
    return number ~= 0 and coeffcient * number ^ (power - 1) or 0
end

function edithMod:Log(x, base)
    if x <= 0 or base <= 1 then
        return nil
    end

    local logNatural = math.log(x)
    local logBase = math.log(base)
    
    return logNatural / logBase
end


function edithMod:SpawnSaltCreep(parent, position, damage, timeout, gibAmount, spawnType)
	local salt = Isaac.Spawn(
		EntityType.ENTITY_EFFECT, 
		EffectVariant.PLAYER_CREEP_RED, 
		edithMod.Enums.SubTypes.SALT_CREEP,
		position, 
		Vector.Zero,
		parent
	):ToEffect()
	
	salt.CollisionDamage = damage or 0
	
	local timeOutSeconds = edithMod:SecondsToFrames(timeout) or 30
	salt:SetTimeout(timeOutSeconds)
	
	if gibAmount and gibAmount > 0 then
		edithMod:SpawnSaltGib(parent, gibAmount, _, 15, spawnType)
	end
	local saltData = edithMod:GetData(salt)
	
	saltData.SpawnType = spawnType
end

function edithMod:SpawnPepperCreep(parent, position, damage, timeout)
	local pepper = Isaac.Spawn(
		EntityType.ENTITY_EFFECT, 
		EffectVariant.PLAYER_CREEP_RED, 
		edithMod.Enums.SubTypes.PEPPER_CREEP,
		position, 
		Vector.Zero,
		parent
	):ToEffect()
	
	pepper.CollisionDamage = damage or 0
	
	local timeOutSeconds = edithMod:SecondsToFrames(timeout) or 30
	pepper:SetTimeout(timeOutSeconds)
end

function edithMod:hasTrailingZeros(n)
  local str = string.format("%.10f", n)  -- precisión de 10 dígitos decimales
  local lastNonZeroIndex = str:find("%d[^0]+$")
  if lastNonZeroIndex then
    local trailingZeros = str:sub(lastNonZeroIndex + 1)
    return #trailingZeros
  else
    return false
  end

end

function edithMod:contarCifras(n)
    local str = tostring(n)
	return str:gsub("%+", "."):gsub("%.", ""):len()
end

function edithMod:RandomNumber(rng, num1, num2)
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
	
    return result
end

function edithMod.ForceCharacterCostume(player, playertype, costumePath)
	local playerData = edithMod:GetData(player)

	playerData.HasCostume = {}

	if playerData.HasCostume[playertype] then
		playerData.HasCostume[playertype] = nil
	end

	if player:GetPlayerType() == playertype then
		if not playerData.HasCostume[playertype] then
			player:AddNullCostume(costumePath)
			playerData.HasCostume[playertype] = true
		end	
	end

	if player:GetPlayerType() ~= playertype then
		if playerData.HasCostume[playertype] then
			player:TryRemoveNullCostume(costumePath)
			playerData.HasCostume[playertype] = false
		end
	end
end

function edithMod:IsBetweenNumber(num, lower, upper)
  return (lower <= num and num <= upper) or (lower >= num and num >= upper)
end

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
function edithMod:drawLine(from, to, color, linespace)

	linespace = linespace or 16
	
	local diffVector = (to - from)
	local angle = diffVector:GetAngleDegrees()
	local sectionCount = math.floor(diffVector:Length() / linespace)

	targetSprite.Color = color	
	targetSprite.Rotation = angle
	targetSprite:SetFrame("Line", 0)
	targetSprite:Update()
		
	for i = 1, sectionCount do
		targetSprite:Render(Isaac.WorldToScreen(from))
		from = from + Vector.One * linespace * Vector.FromAngle(angle) 
	end

	targetSprite.Rotation = 0
end

function edithMod:SpawnSaltGib(parent, Number, color, timeout,spawnType)
	for i = 1, Number do
		local rng = edithMod.Enums.Utils.RNG
	
		local VelX = edithMod:RandomNumber(rng, -100, 100) / 100
		local VelY = edithMod:RandomNumber(rng, -100, 100) / 100
		
		local saltGib = Isaac.Spawn(
			EntityType.ENTITY_EFFECT,
			EffectVariant.TOOTH_PARTICLE,
			0,
			parent.Position,
			Vector(VelX, VelY):Normalized():Resized(3),
			parent
		):ToEffect()
		if color then 
			saltGib.Color = Color(
				(color.R + p.Color.R - 1), 
				(color.G + p.Color.G - 1), 
				(color.B + p.Color.B - 1), 
				(color.A + p.Color.A - 1),
				(color.RO + p.Color.RO),
				(color.GO + p.Color.GO),
				(color.BO + p.Color.BO)
			)
		else
			saltGib.Color = parent.Color
		end
		
		local timeOutSeconds = edithMod:SecondsToFrames(timeout) or 30
		saltGib:SetTimeout(timeOutSeconds)
		
		local saltGibData = edithMod:GetData(saltGib)
		
		saltGibData.SpawnType = spawnType
	end
end


function edithMod:ShockwaveSprite()
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


function edithMod:isChap4()
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

local function MakeVector(x)
	return Vector(math.cos(math.rad(x)),math.sin(math.rad(x)))
end

function edithMod:GetTPS(p)
    return TSIL.Utils.Math.Round(30 / (p.MaxFireDelay + 1), 2)
end

-- function 

function edithMod:EdithStomp(parent, radius, damage, knockback, breakGrid)
	for i, entity in pairs(Isaac.FindInRadius(parent.Position, radius, 0xFFFFFFFF)) do
		local stompBehavior = {
			[EntityType.ENTITY_PLAYER] = function() 
				-- local player = entity:ToPlayer()
				-- local d = player:GetData()
				-- if player:GetPlayerType() == PlayerType.PLAYER_EDITH then
					-- entity.Velocity = (entity.Position - parent.Position):Resized(knockback) / 4.5
				-- else
					-- entity.Velocity = (entity.Position - parent.Position):Resized(knockback) / 3
				-- end
				-- if d.WasTaintedEdithPush == nil then
					-- d.WasTaintedEdithPush = true
				-- end
			end,
			[EntityType.ENTITY_TEAR] = function()
				local tear = entity:ToTear()
				tear:AddTearFlags(TearFlags.TEAR_QUADSPLIT)
				tear.CollisionDamage = tear.CollisionDamage * 2
				entity.Velocity = (entity.Position - parent.Position):Resized(knockback) * 1.5
			end,
			[EntityType.ENTITY_FIREPLACE] = function()
				if entity.Variant ~= 4 then
					entity:Die()
				end
			end,
			[EntityType.ENTITY_SLOT] = function() 
				if breakslots then
					entity:TakeDamage(damage, DamageFlag.DAMAGE_EXPLOSION | DamageFlag.DAMAGE_CRUSH, EntityRef(parent), 0)
					entity.Velocity = (entity.Position - parent.Position):Resized(knockback)
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
					parent:ForceCollide(pickup)
				end
				
				if entity.Variant == PickupVariant.PICKUP_BOMBCHEST then
					pickup:TryOpenChest(parent)
				end
			end,
			[EntityType.ENTITY_SLOT] = function()	
				local slot = entity:ToSlot()
								
				slot:SetState(2)
				parent:TakeDamage(1, 0, EntityRef(slot), 0)
			end,
			[EntityType.ENTITY_SHOPKEEPER] = function()
				entity:Kill()
			end,
			
		}
	
		if entity:IsActiveEnemy() and entity:IsVulnerableEnemy() then
			if edithMod:IsKeyStompPressed(parent) then
				entity:AddFreeze(EntityRef(parent), 150)
				return
			end
		
			local damageMultiplier = entity:HasEntityFlags(EntityFlag.FLAG_FREEZE) and 1.3 or 1 
			
			local terraMultiplier = parent:HasCollectible(CollectibleType.COLLECTIBLE_TERRA) and edithMod:RandomNumber(_, 500, 1500) / 1000 or 1								
			damage = (damage * damageMultiplier) * terraMultiplier
		
			entity:TakeDamage(damage, DamageFlag.DAMAGE_CRUSH | DamageFlag.DAMAGE_IGNORE_ARMOR, EntityRef(parent), 0)
			
			entity.Velocity = (entity.Position - parent.Position):Resized(knockback)
		else
			edithMod.SwitchCase(entity.Type, stompBehavior)
		end
		if breakGrid then
			edithMod:DestroyGrid(entity, radius, false)
		end
	end
end

function edithMod:TaintedEdithStomp(parent, radius, damage, knockback, breakGrid)
	for i, entity in pairs(Isaac.FindInRadius(parent.Position, radius, 0xFFFFFFFF)) do
		local stompBehavior = {
			[EntityType.ENTITY_FIREPLACE] = function()
				if entity.Variant ~= 4 then
					entity:Die()
				end
			end,
			[EntityType.ENTITY_PICKUP] = function()
				local pickup = entity:ToPickup()
				
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
					parent:ForceCollide(pickup)
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
		else
			edithMod.SwitchCase(entity.Type, stompBehavior)
		end
		if breakGrid then
			edithMod:DestroyGrid(entity, radius, false)
		end
	end
end