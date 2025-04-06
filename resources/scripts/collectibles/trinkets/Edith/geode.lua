local mod = edithMod
local enums = mod.Enums
local trinkets = enums.TrinketType
local Geode = {}
local baseDestroyChance = 0.35
local spawnChance = 0.025
local baseRunes = 3
local NonDestroyFlags = DamageFlag.DAMAGE_INVINCIBLE | DamageFlag.DAMAGE_NO_PENALTIES | DamageFlag.DAMAGE_CURSED_DOOR

---@param entity Entity
---@param damage number
---@param source EntityRef
function Geode:SpawnOnKill(entity, damage, _, source)
	if source.Type == 0 then return end

	local playerEntity = source.Entity:ToPlayer()
	local familiarEntity = source.Entity:ToFamiliar()
	local tearEntity = source.Entity:ToTear()
	local player = (
		playerEntity or
		familiarEntity and familiarEntity.Player or
		tearEntity and mod:GetPlayerFromTear(tearEntity) 
	)

	if not player then return end
	if not player:HasTrinket(trinkets.TRINKET_GEODE) then return end
	if not (entity:IsActiveEnemy() and entity:IsVulnerableEnemy()) then return end
	if entity.HitPoints > damage then return end

	local trinketMult = player:GetTrinketMultiplier(trinkets.TRINKET_GEODE)
	local rng = player:GetTrinketRNG(trinkets.TRINKET_GEODE)
	local spawnRuneRoll = rng:RandomFloat()
	local KillSpawnChance = spawnChance * mod.exp(trinketMult, 1, 1.75)

	if spawnRuneRoll > KillSpawnChance then return end
	local ChosenRune = mod.GetRandomRune(rng)

	Isaac.Spawn(
		EntityType.ENTITY_PICKUP,
		PickupVariant.PICKUP_TAROTCARD,
		ChosenRune,
		entity.Position,
		Vector.Zero,
		player
	)
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, Geode.SpawnOnKill)

---@param player EntityPlayer
---@param flags DamageFlag
function Geode:DestroyGeode(player, _, flags)
	if not player:HasTrinket(trinkets.TRINKET_GEODE) then return end
	if mod.HasBitFlags(flags, NonDestroyFlags) then return end

	local rng = player:GetTrinketRNG(trinkets.TRINKET_GEODE)
	local trinketMult = player:GetTrinketMultiplier(trinkets.TRINKET_GEODE)
	local breakGeodeRoll = rng:RandomFloat()
	local totalRune = baseRunes + (trinketMult - 1)
	local spawnDegree = 360 / totalRune
	
	if breakGeodeRoll > baseDestroyChance then return end
	
	for i = 1, totalRune do
		local randomRune = mod.GetRandomRune(rng)		
		Isaac.Spawn(
			EntityType.ENTITY_PICKUP,
			PickupVariant.PICKUP_TAROTCARD,
			randomRune,
			player.Position,
			Vector.One:Rotated(spawnDegree * i) * 1.3,
			player
		)
	end
	
	player:TryRemoveTrinket(trinkets.TRINKET_GEODE)
end
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, Geode.DestroyGeode)