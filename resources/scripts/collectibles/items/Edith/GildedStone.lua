---@diagnostic disable: missing-return
local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local modules = mod.Modules
local ModRNG = modules.RNG
local Helpers = modules.HELPERS
local plyMan = PlayerManager

local RockRewards = {
    { weight = 70, Variant = PickupVariant.PICKUP_COIN, SubType = CoinSubType.COIN_PENNY },
    { weight = 15, Variant = PickupVariant.PICKUP_COIN, SubType = CoinSubType.COIN_NICKEL },
    { weight = 10, Variant = PickupVariant.PICKUP_COIN, SubType = CoinSubType.COIN_DIME },
    { weight = 4, Variant = PickupVariant.PICKUP_COLLECTIBLE, SubType = CollectibleType.COLLECTIBLE_QUARTER },
    { weight = 1, Variant = PickupVariant.PICKUP_COLLECTIBLE, SubType = CollectibleType.COLLECTIBLE_DOLLAR },
}

local function BuildCumulativeTable(rewards)
    local sorted = {}
    for _, entry in ipairs(rewards) do
        sorted[#sorted + 1] = entry
    end
    table.sort(sorted, function(a, b) return a.weight < b.weight end)

    local cumulative = {}
    local total = 0
    for _, entry in ipairs(sorted) do
        total = total + entry.weight
        cumulative[#cumulative + 1] = { threshold = total, reward = entry }
    end
    return cumulative, total
end

local CumulativeRewards, TotalWeight = BuildCumulativeTable(RockRewards)

---@param rng RNG
---@return table
local function GetRandomReward(rng)
    local roll = rng:RandomFloat() * TotalWeight
    for _, entry in ipairs(CumulativeRewards) do
        if roll <= entry.threshold then return entry.reward end
    end
end

---@return { luck: number, coins: number, rng: RNG }
local function GetCollectivePlayerStats()
    local stats = { luck = 0, coins = 0, rng = nil }
    for _, player in ipairs(plyMan.GetPlayers()) do
        stats.luck  = stats.luck + player.Luck
        stats.coins = stats.coins + player:GetNumCoins()
        stats.rng   = stats.rng or player:GetCollectibleRNG(items.COLLECTIBLE_GILDED_STONE)
    end
    return stats
end

---@param coins number
---@param luck number
---@return number
local function GetRockRewardChance(coins, luck)
    return ((coins / 2) + (math.min(luck, 1) - 1)) / 100
end

---@param reward table
---@param rng RNG
---@return Vector
local function GetRewardVelocity(reward, rng)
    return reward.Variant == PickupVariant.PICKUP_COIN and rng:RandomVector():Resized(3) or Vector.Zero
end

---@param tear EntityTear
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, function(_, tear)
	local player = Helpers.GetPlayerFromTear(tear)
    if not player then return end
    if not player:HasCollectible(items.COLLECTIBLE_GILDED_STONE) then return end

    local rng = player:GetCollectibleRNG(items.COLLECTIBLE_GILDED_STONE)
    if not ModRNG.RandomBoolean(rng, player:GetNumCoins() / 100) then return end

    Helpers.TurnTearToTerraTear(tear, rng)
end)

---@param rock GridEntityRock
mod:AddCallback(ModCallbacks.MC_POST_GRID_ROCK_DESTROY, function(_, rock)
	if not plyMan.AnyoneHasCollectible(items.COLLECTIBLE_GILDED_STONE) then return end

    local stats = GetCollectivePlayerStats()
    if not stats.rng then return end
    if not ModRNG.RandomBoolean(stats.rng, GetRockRewardChance(stats.coins, stats.luck)) then return end

    local reward = GetRandomReward(stats.rng)
    Isaac.Spawn(EntityType.ENTITY_PICKUP, reward.Variant, reward.SubType, rock.Position, GetRewardVelocity(reward, stats.rng), nil)
end)