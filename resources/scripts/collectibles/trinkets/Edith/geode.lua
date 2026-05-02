local mod = EdithRebuilt
local enums = mod.Enums
local trinkets = enums.TrinketType
local NonDestroyFlags = DamageFlag.DAMAGE_INVINCIBLE | DamageFlag.DAMAGE_NO_PENALTIES | DamageFlag.DAMAGE_CURSED_DOOR
local modules = mod.Modules
local ModRNG = modules.RNG
local Helpers = modules.HELPERS
local Maths = modules.MATHS
local BitMask = modules.BIT_MASK

local GEODE = {
    CHANCE_DESTROY = 0.25,
    CHANCE_KILL_BASE = 0.025,
    CHANCE_KILL_EXP = 1.75,
    BASE_RUNES = 2,
    SPAWN_RADIUS = 1.3,
}

---@param position Vector
---@param velocity Vector
---@param rng RNG
---@param player EntityPlayer
local function SpawnRune(position, velocity, rng, player)
    Isaac.Spawn(
        EntityType.ENTITY_PICKUP,
        PickupVariant.PICKUP_TAROTCARD,
        ModRNG.GetRandomRune(rng),
        position,
        velocity,
        player
    )
end

---@param player EntityPlayer
---@param npc EntityNPC
local function TryDropRuneOnKill(player, npc)
    local rng = player:GetTrinketRNG(trinkets.TRINKET_GEODE)
	local geodeMult = player:GetTrinketMultiplier(trinkets.TRINKET_GEODE)
    local chance = GEODE.CHANCE_KILL_BASE * Maths.exp(geodeMult, 1, GEODE.CHANCE_KILL_EXP)

    if not ModRNG.RandomBoolean(rng, chance) then return end
    SpawnRune(npc.Position, Vector.Zero, rng, player)
end

---@param player EntityPlayer
local function TryShatterGeode(player)
    local rng = player:GetTrinketRNG(trinkets.TRINKET_GEODE)
    if not ModRNG.RandomBoolean(rng, GEODE.CHANCE_DESTROY) then return end

    player:TryRemoveTrinket(trinkets.TRINKET_GEODE)

    local totalRunes = GEODE.BASE_RUNES + player:GetTrinketMultiplier(trinkets.TRINKET_GEODE)
    local spawnDegree = 360 / totalRunes

    for i = 1, totalRunes do
        local velocity = Vector.One:Rotated(spawnDegree * i) * GEODE.SPAWN_RADIUS
        SpawnRune(player.Position, velocity, rng, player)
    end
end

---@param npc EntityNPC
---@param source EntityRef
mod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, function(_, npc, source)
    if source.Type == 0 then return end

    local player = Helpers.GetPlayerFromRef(source)
    if not player then return end
    if not player:HasTrinket(trinkets.TRINKET_GEODE) then return end

    TryDropRuneOnKill(player, npc)
end)

---@param player EntityPlayer
---@param flags DamageFlag
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, function(_, player, _, flags)
    if not player:HasTrinket(trinkets.TRINKET_GEODE) then return end
    if player:GetDamageCooldown() > 0 then return end
    if BitMask.HasAnyBitFlags(flags, NonDestroyFlags) then return end

    TryShatterGeode(player)
end)