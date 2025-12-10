local mod = EdithRebuilt
local enums = mod.Enums
local game = enums.Utils.Game
local tables = enums.Tables
local ConfigDataTypes = enums.ConfigDataTypes
local saveManager = mod.SaveManager
local floor = require("resources.scripts.functions.Floor")

local Helpers = {}

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
function Helpers.When(value, cases, default)
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
function Helpers.WhenEval(value, cases, default)
    local f = Helpers.When(value, cases)
    local v = (f and f()) or (default and default())
    return v
end

---Helper grid destroyer function
---@param entity Entity
---@param radius number
function Helpers.DestroyGrid(entity, radius)
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

---Makes the tear to receive a boost, increasing its speed and damage
---@param tear EntityTear	
---@param speed number
---@param dmgMult number
function Helpers.BoostTear(tear, speed, dmgMult)
	local player = Helpers.GetPlayerFromTear(tear) ---@cast player EntityPlayer	
	local nearEnemy = Helpers.GetNearestEnemy(player)

	if nearEnemy then
		tear.Velocity = (nearEnemy.Position - tear.Position):Normalized()
	end
	
	tear.CollisionDamage = tear.CollisionDamage * dmgMult
	tear.Velocity = tear.Velocity:Resized(speed)
	tear:AddTearFlags(TearFlags.TEAR_KNOCKBACK)
end

--- returns a `ConfigDataTypes`, used for mod's menu data management
---@param Type ConfigDataTypes
function Helpers.GetConfigData(Type)
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

---Converts seconds to game update frames
---@param seconds number
---@return number
function Helpers:SecondsToFrames(seconds)
	return math.ceil(seconds * 30)
end

---@param player EntityPlayer
function Helpers.GetNearestEnemy(player)
	local closestDistance = math.huge
    local playerPos = player.Position
	local room = game:GetRoom()
	local closestEnemy, enemyPos, distanceToPlayer, checkline

	for _, enemy in ipairs(Helpers.GetEnemies()) do
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

---@param ent Entity
---@return boolean
function Helpers.IsEnemy(ent)
	return (ent:IsActiveEnemy() and ent:IsVulnerableEnemy()) or
	(ent.Type == EntityType.ENTITY_GEMINI and ent.Variant == 12) -- this for blighted ovum little sperm like shit i hate it fuuuck
end

function Helpers.IsVestigeChallenge()
	return Isaac.GetChallenge() == enums.Challenge.CHALLENGE_VESTIGE
end

---The same as `Helpers.TriggerPush` but this accepts a `Vector` for positions instead
---@param pusher Entity
---@param pushed Entity
---@param pushedPos Vector
---@param pusherPos Vector
---@param strength number
---@param duration integer
---@param impactDamage? boolean
function Helpers.TriggerPushPos(pusher, pushed, pushedPos, pusherPos, strength, duration, impactDamage)
	local dir = ((pusherPos - pushedPos) * -1):Resized(strength)
	pushed:AddKnockback(EntityRef(pusher), dir, duration, impactDamage or false)
end

---@param ent Entity
---@return number
function Helpers.GetPushFactor(ent)
	return math.max(0.01, 1 + (5 - ent.Mass) * 1/250)
end	

---Triggers a push to `pushed` from `pusher`
---@param pushed Entity
---@param pusher Entity
---@param strength number
function Helpers.TriggerPush(pushed, pusher, strength)
	local PushFactor = Helpers.GetPushFactor(pushed)
	local dir = ((pusher.Position - pushed.Position) * -1):Resized(strength) * PushFactor
	pushed.Velocity = dir
	pushed:AddKnockback(EntityRef(pusher), dir, 2, false)
end

---Changes `Entity` velocity so now it goes to `Target`'s Position, `strenght` determines how fast it'll go
---@param Entity Entity
---@param Target Entity
---@param strenght number
---@return Vector
function Helpers.ChangeVelToTarget(Entity, Target, strenght)
	return ((Entity.Position - Target.Position) * -1):Normalized():Resized(strenght)
end

--- Helper function that returns a table containing all existing enemies in room
---@return Entity[]
function Helpers.GetEnemies()
    local enemyTable = {}
    for _, ent in ipairs(Isaac.GetRoomEntities()) do
        if not Helpers.IsEnemy(ent) then goto continue end
        table.insert(enemyTable, ent)
		::continue::
    end
    return enemyTable
end 

---@param entity Entity
---@return EntityPlayer?
function Helpers.GetPlayerFromTear(entity)
	local check = entity.Parent or entity.SpawnerEntity

	if not check then return end
	local checkType = check.Type

	local ent = (
		checkType == EntityType.ENTITY_PLAYER and Helpers.GetPtrHashEntity(check) or
		checkType == EntityType.ENTITY_FAMILIAR and check:ToFamiliar().Player
	):ToPlayer() or nil

	return ent
end

---@param entity Entity|EntityRef
---@return Entity?
function Helpers.GetPtrHashEntity(entity)
	if not entity then return end
	entity = entity.Entity or entity

	for _, matchEntity in pairs(Isaac.FindByType(entity.Type, entity.Variant, entity.SubType, false, false)) do
		if GetPtrHash(entity) == GetPtrHash(matchEntity) then
			return matchEntity
		end
	end
	return nil
end

---Returns `true` if Dogma's appear cutscene is playing
---@return boolean
function Helpers.IsDogmaAppearCutscene()
	local TV = Isaac.FindByType(EntityType.ENTITY_GENERIC_PROP, 4)[1]
	local Dogma = Isaac.FindByType(EntityType.ENTITY_DOGMA)[1]

	if not TV then return false end
	return TV:GetSprite():IsPlaying("Idle2") and Dogma ~= nil
end

---Helper function that returns `EntityPlayer` from `EntityRef`
---@param EntityRef EntityRef
---@return EntityPlayer?
function Helpers.GetPlayerFromRef(EntityRef)
	local ent = EntityRef.Entity

	if not ent then return nil end
	local familiar = ent:ToFamiliar()
	return ent:ToPlayer() or Helpers.GetPlayerFromTear(ent) or familiar and familiar.Player 
end

---Helper function to directly change `entity`'s color
---@param entity Entity
---@param red? number
---@param green? number
---@param blue? number
---@param alpha? number
function Helpers.ChangeColor(entity, red, green, blue, alpha)
	local color = entity.Color
	local Red = red or color.R
	local Green = green or color.G
	local Blue = blue or color.B
	local Alpha = alpha or color.A

	color:SetTint(Red, Green, Blue, Alpha)

	entity.Color = color
end

local backdropColors = tables.BackdropColors
local MortisBackdrop = tables.MortisBackdrop

---@param effect EntityEffect
function Helpers.SetBloodEffectColor(effect)
    local room = game:GetRoom()
    local IsMortis = floor.IsLJMortis()
	local BackDrop = room:GetBackdropType()
	local hasWater = room:HasWater()
	local color = Color(1, 1, 1)
	local switch = {
		[EffectVariant.BIG_SPLASH] = function()
			color = backdropColors[BackDrop] or Color(0.7, 0.75, 1)
			if IsMortis then
				color = Color(0, 0.8, 0.76, 1, 0, 0, 0)
			end
		end,
		[EffectVariant.POOF02] = function()
			if IsMortis then
				local Colors = {
					[MortisBackdrop.MORGUE] = Color(0, 0, 0, 1, 0.45, 0.5, 0.575),
					[MortisBackdrop.MOIST] = Color(0, 0.8, 0.76, 1, 0, 0, 0),
					[MortisBackdrop.FLESH] = Color(0, 0, 0, 1, 0.55, 0.5, 0.55),
				}
				color = mod.When(floor.GetMortisDrop(), Colors, Color.Default)
            else
                color = backdropColors[BackDrop] or Color(1, 0, 0)
			end
		end,
		[EffectVariant.POOF01] = function()
			if hasWater then
				color = backdropColors[BackDrop]
			end
		end
	}
	mod.WhenEval(effect.Variant, switch)
    effect:SetColor(color, -1, 100, false, false)
end

---@param player EntityPlayer
function Helpers.IsInTrapdoor(player)
	local room = game:GetRoom()
	local grid = room:GetGridEntityFromPos(player.Position)

	return grid and grid:GetType() == GridEntityType.GRID_TRAPDOOR or false
end	

---Function used to spawn Tainted Edith's birthright fire jets
---@param player EntityPlayer
---@param position Vector
---@param damage number
---@param mult number
---@param scale number
function Helpers.SpawnFireJet(player, position, damage, mult, scale)
	local Fire = Isaac.Spawn(
		EntityType.ENTITY_EFFECT,
		EffectVariant.FIRE_JET,
		0,
		position,
		Vector.Zero,
		player
	)
	Fire.SpriteScale = Fire.SpriteScale * (scale or 1)
	Fire.CollisionDamage = damage * mult
end

--Checks if player is pressing Edith's jump button
---@param player EntityPlayer
---@return boolean
function Helpers.IsKeyStompPressed(player)
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
function Helpers.IsKeyStompTriggered(player)
	local k_stomp =
		Input.IsButtonTriggered(Keyboard.KEY_Z, player.ControllerIndex) or
        Input.IsButtonTriggered(Keyboard.KEY_LEFT_SHIFT, player.ControllerIndex) or
        Input.IsButtonTriggered(Keyboard.KEY_RIGHT_SHIFT, player.ControllerIndex) or
		Input.IsButtonTriggered(Keyboard.KEY_RIGHT_CONTROL, player.ControllerIndex) or
        Input.IsActionTriggered(ButtonAction.ACTION_DROP, player.ControllerIndex)
		
	return k_stomp
end

---@param parent Entity
---@param Number number
---@param speed number?
---@param color Color?
---@param inheritParentVel boolean?
function Helpers.SpawnSaltGib(parent, Number, speed, color, inheritParentVel)
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

return Helpers