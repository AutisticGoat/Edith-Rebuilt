---@diagnostic disable: undefined-global
local mod = EdithRebuilt
local enums = mod.Enums
local game = enums.Utils.Game
local misc = enums.Misc
local tables = enums.Tables
local ConfigDataTypes = enums.ConfigDataTypes
local saveManager = mod.SaveManager
local data = mod.DataHolder.GetEntityData

local Helpers = {}

function Helpers.GetScreenCenter()
	local room = game:GetRoom()
	local pos = room:WorldToScreenPosition(Vector(0,0)) - room:GetRenderScrollOffset() - game.ScreenShakeOffset	
	local rx = pos.X + 60 * 26 / 40
	local ry = pos.Y + 140 * (26 / 40)
	return Vector(rx * 2 + 13 * 26, ry * 2 + 7 * 26) / 2
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
    local room = game:GetRoom()
    radius = radius or 10
    for i = 0, (room:GetGridSize()) do
		local grid = room:GetGridEntity(i)

		if not grid then goto continue end
		if (entity.Position - grid.Position):Length() > radius then goto continue end
		if grid:GetType() == GridEntityType.GRID_DOOR then goto continue end

		grid:Destroy()

		::continue::
    end
end

---Makes the tear to receive a boost, increasing its speed and damage
---@param tear EntityTear	
---@param speed number
---@param dmgMult number
function Helpers.BoostTear(tear, speed, dmgMult)
	local player = Helpers.GetPlayerFromTear(tear) ---@cast player EntityPlayer	

	if not player then return end

	local nearEnemy = Helpers.GetNearestEnemy(player)

	if nearEnemy then
		tear.Velocity = (nearEnemy.Position - tear.Position)
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

	return Helpers.When(Type, switch)
end

---Converts seconds to game update frames
---@param seconds number
function Helpers.SecondsToFrames(seconds)
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

function Helpers.IsGrudgeChallenge()
	return Isaac.GetChallenge() == enums.Challenge.CHALLENGE_GRUDGE
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
	local dir = ((pusher.Position - pushed.Position) * -1):Resized(strength)
	pushed.Velocity = dir
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

	local ent = nil

	if checkType == EntityType.ENTITY_PLAYER then
		ent = Helpers.GetPtrHashEntity(check):ToPlayer()
	elseif checkType == EntityType.ENTITY_FAMILIAR then
		ent = check:ToFamiliar().Player
	end

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

---@param pushed Entity
---@param pusher Entity
---@param strength number
---@param duration integer
function Helpers.TriggerJumpPush(pushed, pusher, strength, duration)
	local dir = ((pusher.Position - pushed.Position) * -1):Resized(strength)-- * PushFactor
	pushed:AddKnockback(EntityRef(pusher), dir, duration, false)
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
    local IsMortis = Helpers.IsLJMortis()
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
				color = Helpers.When(Helpers.GetMortisDrop(), Colors, Color.Default)
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
	Helpers.WhenEval(effect.Variant, switch)
    effect:SetColor(color, -1, 100, false, false)
end

---@param player EntityPlayer
function Helpers.IsInTrapdoor(player)
	local room = game:GetRoom()
	local grid = room:GetGridEntityFromPos(player.Position)

	return grid and grid:GetType() == GridEntityType.GRID_TRAPDOOR or false
end	

---Function used to spawn Tainted Edith's birthright fire jets
---@param position Vector
---@param damage number
---@param mult? number
---@param scale? number
function Helpers.SpawnFireJet(position, damage, mult, scale)
	local Fire = Isaac.Spawn(
		EntityType.ENTITY_EFFECT,
		EffectVariant.FIRE_JET,
		0,
		position,
		Vector.Zero,
		nil
	)
	Fire.SpriteScale = Fire.SpriteScale * (scale or 1)
	Fire.CollisionDamage = damage * (mult or 1)

	return Fire
end

--Checks if player is pressing Edith's jump button
---@param player EntityPlayer
---@return boolean
function Helpers.IsKeyStompPressed(player)
	local customButtom = Helpers.GetConfigData(ConfigDataTypes.MISC).CustomActionKey

	local k_stomp =
		Input.IsButtonPressed(customButtom, player.ControllerIndex) or
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
	local customButtom = Helpers.GetConfigData(ConfigDataTypes.MISC).CustomActionKey

	local k_stomp =
		Input.IsButtonTriggered(customButtom, player.ControllerIndex) or
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

---Helper function to find out how large a bomb explosion is based on the damage inflicted.
---@param damage number
---@return number
function Helpers.GetBombRadiusFromDamage(damage)
    if damage > 175 then
        return 105
    elseif damage <= 140 then
        return 75
    else
        return 90
    end
end

---Checks if player is in Last Judgement's Mortis 
---@return boolean
function Helpers.IsLJMortis()
	if not StageAPI then return false end
	if not LastJudgement then return false end

	local stage = LastJudgement.STAGE
	local IsMortis = StageAPI and (stage.Mortis:IsStage() or stage.MortisTwo:IsStage() or stage.MortisXL:IsStage())

	return IsMortis
end

---@return integer
function Helpers.GetMortisDrop()
	if not Helpers.IsLJMortis() then return 0 end

	if LastJudgement.UsingMorgueisBackdrop then
		return tables.MortisBackdrop.MORGUE
	elseif LastJudgement.UsingMoistisBackdrop then 
		return tables.MortisBackdrop.MOIST
	else
		return tables.MortisBackdrop.FLESH
	end
end

---Checks if player run is in Chapter 4 (Womb, Utero, Scarred Womb, Corpse)
---@return boolean
function Helpers.IsChap4()
	local backdrop = game:GetRoom():GetBackdropType()
	
	if Helpers.IsLJMortis() then return true end
	return Helpers.When(backdrop, tables.Chap4Backdrops, false)
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
---@param tainted boolean
function Helpers.ForceSaltTear(tear, tainted)
	local IsBloodTear = Helpers.When(tear.Variant, tables.BloodytearVariants, false)
	doEdithTear(tear, IsBloodTear, tainted)
end

local LINE_SPRITE = Sprite("gfx/TinyBug.anm2", true)
local MAX_POINTS = 360
local ANGLE_SEPARATION = 360 / MAX_POINTS

LINE_SPRITE:SetFrame("Dead", 0)

---@param pos Vector
---@param AreaSize number
---@param AreaColor Color
function Helpers.RenderAreaOfEffect(pos, AreaSize, AreaColor) -- Took from Melee lib, tweaked a little bit
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

---@param wisp Entity
---@param ID CollectibleType
function Helpers.IsModItemWisp(wisp, ID)
	if not wisp:ToFamiliar() then return false end
	return wisp.Variant == FamiliarVariant.WISP and wisp.SubType == ID
end

function Helpers.TriggerPerfectParryFlash(player)
	ItemOverlay.Show(enums.Giantbook.PERFECT_PARRY, 3, player)
	ItemOverlay.GetSprite().Color = Color(0, 0, 0, 0)
end

mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
	local overlaySprite = ItemOverlay.GetSprite()
	local frame = overlaySprite:GetFrame()

	if ItemOverlay.GetOverlayID() ~= enums.Giantbook.PERFECT_PARRY then return end

	local tEdithConfig = Helpers.GetConfigData(ConfigDataTypes.TEDITH) --[[@as TEdithData]]
	local color = tEdithConfig.ParryFlashColor
	local contrast = tEdithConfig.ParryFlashContrast
	local brightness = tEdithConfig.ParryFlashBrightness

	if frame == 0 then
		game:SetColorModifier(ColorModifier(color.r, color.g, color.b, color.a, brightness, contrast), true, 1)
		Isaac.CreateTimer(function ()
			game:GetRoom():UpdateColorModifier(true, true, 0.15)
		end, 1, 1, false)
	elseif frame == 5 then
		overlaySprite:Stop(true)
		overlaySprite:Reset()
	end
end)

function Helpers.IsModChallenge()
	return Helpers.IsVestigeChallenge() or Helpers.IsGrudgeChallenge()
end

--- From HudHelper by Benny 🐐: https://github.com/BenevolusGoat/hud-helper
	function Helpers.ShouldHideHUD()
		return ModConfigMenu and ModConfigMenu.IsVisible
			or not game:GetHUD():IsVisible() and not (TheFuture or {}).HiddenHUD
			or game:GetSeeds():HasSeedEffect(SeedEffect.SEED_NO_HUD)
	end

	---@param HUDSprite Sprite
	---@param charge number
	---@param maxCharge number
	---@param position Vector
	---@function
	function Helpers.RenderChargeBar(HUDSprite, charge, maxCharge, position)
		if Helpers.ShouldHideHUD() or not Options.ChargeBars then return end
		if game:GetRoom():GetRenderMode() == RenderMode.RENDER_WATER_REFLECT then return end

		local chargePercent = math.min(charge / maxCharge, 1)

		if chargePercent == 1 then
			-- ChargedHUD:IsPlaying("StartCharged") and not
			if HUDSprite:IsFinished("Charged") or HUDSprite:IsFinished("StartCharged") then
				if not HUDSprite:IsPlaying("Charged") then
					HUDSprite:Play("Charged", true)
				end
			elseif not HUDSprite:IsPlaying("Charged") then
				if not HUDSprite:IsPlaying("StartCharged") then
					HUDSprite:Play("StartCharged", true)
				end
			end
		elseif chargePercent > 0 and chargePercent < 1 then
			if not HUDSprite:IsPlaying("Charging") then
				HUDSprite:Play("Charging")
			end
			local frame = math.floor(chargePercent * 100)
			HUDSprite:SetFrame("Charging", frame)
		elseif chargePercent == 0 and not HUDSprite:IsPlaying("Disappear") and not HUDSprite:IsFinished("Disappear") then
			HUDSprite:Play("Disappear", true)
		end

		HUDSprite:Render(position)
		if Isaac.GetFrameCount() % 2 == 0 and not game:IsPaused() then
			HUDSprite:Update()
		end
	end
---

return Helpers