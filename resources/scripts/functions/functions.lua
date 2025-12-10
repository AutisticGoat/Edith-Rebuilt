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
local Helpers = mod.Modules.HELPERS
local Math = mod.Modules.MATHS

local MortisBackdrop = {
	FLESH = 1,
	MOIST = 2,
	MORGUE = 3
}

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
	local player = Helpers.GetPlayerFromTear(tear)

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
	local timeOutSeconds = Math.SecondsToFrames(timeout) or 30

	salt.CollisionDamage = damage or 0
	salt.Color = color or saltColor
	salt:SetTimeout(timeOutSeconds)

	if gibAmount > 0 then
		local gibColor = color or (inheritParentColor and Color.Default or nil)
		Helpers.SpawnSaltGib(parent, gibAmount, gibSpeed, gibColor, inheritParentVel)
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

---Function to get Edith's Target, setting `tainted` to `true` will return Tainted Edith's Arrow
---@param player EntityPlayer
---@param tainted boolean?
---@return EntityEffect
function EdithRebuilt.GetEdithTarget(player, tainted)
	local playerData = data(player)
	return tainted and playerData.TaintedEdithTarget or playerData.EdithTarget
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
	return ent:ToPlayer() or Helpers.GetPlayerFromTear(ent) or familiar and familiar.Player 
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

local CinderHopRNG = RNG()
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function()
	CinderHopRNG:SetSeed(game:GetSeeds():GetStartSeed())
end)
