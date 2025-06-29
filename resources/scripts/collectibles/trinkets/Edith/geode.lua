local mod = EdithRebuilt
local enums = mod.Enums
local trinkets = enums.TrinketType
local Geode = {}
local baseDestroyChance = 0.25
local spawnChance = 0.025
local baseRunes = 3
local NonDestroyFlags = DamageFlag.DAMAGE_INVINCIBLE | DamageFlag.DAMAGE_NO_PENALTIES | DamageFlag.DAMAGE_CURSED_DOOR

---@param npc EntityNPC
---@param source EntityRef
function Geode:SpawnOnKill(npc, source)
	if source.Type == 0 then return end

	local player = mod.GetPlayerFromRef(source)

	if not player then return end
	if not player:HasTrinket(trinkets.TRINKET_GEODE) then return end

	local trinketMult = player:GetTrinketMultiplier(trinkets.TRINKET_GEODE)
	local rng = player:GetTrinketRNG(trinkets.TRINKET_GEODE)
	local KillSpawnChance = spawnChance * mod.exp(trinketMult, 1, 1.75)

	if not mod.RandomBoolean(rng, KillSpawnChance) then return end
	local ChosenRune = mod.GetRandomRune(rng)

	Isaac.Spawn(
		EntityType.ENTITY_PICKUP,
		PickupVariant.PICKUP_TAROTCARD,
		ChosenRune,
		npc.Position,
		Vector.Zero,
		player
	)
end
mod:AddCallback(PRE_NPC_KILL.ID, Geode.SpawnOnKill)

---@param player EntityPlayer
---@param flags DamageFlag
function Geode:DestroyGeode(player, _, flags)
	if not player:HasTrinket(trinkets.TRINKET_GEODE) then return end
	if mod.HasBitFlags(flags, NonDestroyFlags) then return end

	local rng = player:GetTrinketRNG(trinkets.TRINKET_GEODE)
	local trinketMult = player:GetTrinketMultiplier(trinkets.TRINKET_GEODE)
	local totalRune = baseRunes + (trinketMult - 1)
	local spawnDegree = 360 / totalRune
	
	if not mod.RandomBoolean(rng, baseDestroyChance) then return end
	player:TryRemoveTrinket(trinkets.TRINKET_GEODE)

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
end
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, Geode.DestroyGeode)