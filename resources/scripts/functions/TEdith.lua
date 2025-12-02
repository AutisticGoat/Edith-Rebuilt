---@diagnostic disable: undefined-global
local mod = EdithRebuilt
local enums = mod.Enums
local misc = enums.Misc
local utils = enums.Utils
local game = utils.Game
local sfx = utils.SFX
local data = mod.CustomDataWrapper.getData
local maths = require("resources.scripts.functions.Maths")
local helpers = require("resources.scripts.functions.Helpers")
local Player = require("resources.scripts.functions.Player")
local TEdith = {}

---@class TEdithParryParams
---@field Damage number
---@field Radius number
---@field Knockback number

local DefaultStompParams = {
    Damage = 0,
    Radius = 0,
    Knockback = 0,

} --[[@as TEdithParryParams]]

---@param player EntityPlayer
---@return TEdithParryParams
function TEdith.GetParryParams(player)
    data(player).ParryParams = data(player).ParryParams or DefaultStompParams 
    local params = data(player).ParryParams ---@cast DefaultStompParams TEdithParryParams

    return params
end

---@class TEdithHopParams
---@field Damage number
---@field Knockback number
---@field Radius number
local DefaultHopParams = {
    Damage = 0,
    Knockback = 0,
    Radius = 0,
}

---@generic growth, offset, curve
---@param const number
---@param var number
---@param params { growth: number, offset: number, curve: number }
---@return number
function TEdith.HopHeightCalc(const, var, params)
    -- Validaciones estrictas
    assert(type(var) == "number", "var should be a number")
    assert(var >= 0 and var <= 100, "var should be a number between 0 and 100")

    -- Caso exclusivo cuando variable es exactamente 100
    if var == 100 then return const end

	local limit = 0.999999
    local growth = math.max(0, params.growth or 1) 
    local offset = maths.Clamp(params.offset or 0, -1, 1) 
    local curve = math.max(0.1, math.min(params.curve or 1, 10))
	local formula = (var / 100) ^ curve * growth + offset
    local progresion = math.min(formula, limit)

    -- Resultado final garantizado que nunca iguala la constante
    return const * maths.Clamp(progresion, 0, limit)
end

---@param player EntityPlayer
---@param charge number
---@param BRMult number
function TEdith.AddHopDashCharge(player, charge, BRMult)
	local playerData = data(player)
	local shouldAddToBrCharge = mod.PlayerHasBirthright(player) and playerData.ImpulseCharge >= 100

	playerData.ImpulseCharge = maths.Clamp(playerData.ImpulseCharge + charge, 0, 100)
	
	if not shouldAddToBrCharge then return end
	playerData.BirthrightCharge = shouldAddToBrCharge and maths.Clamp(playerData.BirthrightCharge + (charge * BRMult), 0, 100)
end

--- Misc function used to manage some perfect parry stuff (i made it to be able to return something in the main parry function sorry)
---@param player EntityPlayer
---@param IsTaintedEdith? boolean
---@param isenemy? boolean
local function PerfectParryMisc(player, IsTaintedEdith, isenemy)
	if not isenemy then return end
	game:MakeShockwave(player.Position, 0.035, 0.025, 2)

	if not IsTaintedEdith then return end

    local playerData = data(player)
    local hasBirthright = Player.PlayerHasBirthright(player)
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
function TEdith.ParryLandManager(player, IsTaintedEdith)
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
		helpers.TriggerPush(ent, player, 20 * pushMult, 5, false)

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
				helpers.BoostTear(tear, 20, 1.5)
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
	PerfectParryMisc(player, IsTaintedEdith, PerfectParry)

	playerData.ParryCounter = IsTaintedEdith and (PerfectParry and (hasBirthcake and 8 or 10) or 15)
	playerData.IsParryJump = false

	return PerfectParry, EnemiesInImpreciseParry
end

return TEdith