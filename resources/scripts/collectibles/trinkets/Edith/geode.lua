local mod = EdithRebuilt
local enums = mod.Enums
local trinkets = enums.TrinketType
local modules = mod.Modules
local ModRNG = modules.RNG
local Geode = {}
local NonDestroyFlags = DamageFlag.DAMAGE_INVINCIBLE | DamageFlag.DAMAGE_NO_PENALTIES | DamageFlag.DAMAGE_CURSED_DOOR

---@param npc EntityNPC
---@param source EntityRef
function Geode:SpawnOnKill(npc, source)
	if source.Type == 0 then return end

	local player = mod.GetPlayerFromRef(source)

	if not player then return end
	if not player:HasTrinket(trinkets.TRINKET_GEODE) then return end

	local rng = player:GetTrinketRNG(trinkets.TRINKET_GEODE)

	if not ModRNG.RandomBoolean(rng, 0.025 * mod.exp(player:GetTrinketMultiplier(trinkets.TRINKET_GEODE), 1, 1.75)) then return end

	Isaac.Spawn(
		EntityType.ENTITY_PICKUP,
		PickupVariant.PICKUP_TAROTCARD,
		ModRNG.GetRandomRune(rng),
		npc.Position,
		Vector.Zero,
		player
	)
end
mod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, Geode.SpawnOnKill)

---@param player EntityPlayer
---@param flags DamageFlag
function Geode:DestroyGeode(player, _, flags)
	if not player:HasTrinket(trinkets.TRINKET_GEODE) then return end
	if mod.HasBitFlags(flags, NonDestroyFlags) then return end

	local rng = player:GetTrinketRNG(trinkets.TRINKET_GEODE)
	local trinketMult = player:GetTrinketMultiplier(trinkets.TRINKET_GEODE)
	local totalRunes = 3 + (trinketMult - 1)
	local spawnDegree = 360 / totalRunes
	
	if not ModRNG.RandomBoolean(rng, 0.25) then return end
	player:TryRemoveTrinket(trinkets.TRINKET_GEODE)

	for i = 1, totalRunes do
		Isaac.Spawn(
			EntityType.ENTITY_PICKUP,
			PickupVariant.PICKUP_TAROTCARD,
			ModRNG.GetRandomRune(rng),
			player.Position,
			Vector.One:Rotated(spawnDegree * i) * 1.3,
			player
		)
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, Geode.DestroyGeode)