---@diagnostic disable: missing-return
local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local modules = mod.Modules
local ModRNG = modules.RNG
local Helpers = modules.HELPERS
local Maths = modules.MATHS

local RockRewards = {
    { weight = 40, Variant = PickupVariant.PICKUP_COIN, SubType = CoinSubType.COIN_PENNY },
    { weight = 25, Variant = PickupVariant.PICKUP_COIN, SubType = CoinSubType.COIN_DOUBLEPACK },
    { weight = 15, Variant = PickupVariant.PICKUP_COIN, SubType = CoinSubType.COIN_NICKEL },
    { weight = 10, Variant = PickupVariant.PICKUP_COIN, SubType = CoinSubType.COIN_DIME },
    { weight = 5, Variant = PickupVariant.PICKUP_COIN, SubType = CoinSubType.COIN_LUCKYPENNY },
    { weight = 4, Variant = PickupVariant.PICKUP_COLLECTIBLE, SubType = CollectibleType.COLLECTIBLE_QUARTER },
    { weight = 1, Variant = PickupVariant.PICKUP_COLLECTIBLE, SubType = CollectibleType.COLLECTIBLE_DOLLAR },
}

---@param player EntityPlayer
local function GetChanceToShootRock(player)
    local luck = player.Luck
    local coins = player:GetNumCoins()
    local formula = ((coins + math.max(luck * 5, 0)) + 10) / 100

    return Maths.Clamp(formula, 0, 0.75)
end

---@param player EntityPlayer
---@return number
local function GetRockRewardChance(player)
    local luck = player.Luck
    local coins = player:GetNumCoins()
    local formula = (((coins * 2.5) + math.max(luck * 0.5, 0)) - 3) / 100

    return Maths.Clamp(formula, 0, 0.5)
end

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
    if not ModRNG.RandomBoolean(rng, GetChanceToShootRock(player)) then return end

    Helpers.TurnTearToTerraTear(tear, rng)
end)

---@param rock GridEntityRock
---@param source EntityRef
mod:AddCallback(ModCallbacks.MC_POST_GRID_ROCK_DESTROY, function(_, rock, _, _, source)
	local player = Helpers.GetPlayerFromRef(source)

    if not player then return end
    if not player:HasCollectible(items.COLLECTIBLE_GILDED_STONE) then return end

    local rng = player:GetCollectibleRNG(items.COLLECTIBLE_GILDED_STONE)

    if not ModRNG.RandomBoolean(rng, GetRockRewardChance(player)) then return end

    local reward = GetRandomReward(rng)
    local Velocity = GetRewardVelocity(reward, rng)

    Isaac.Spawn(EntityType.ENTITY_PICKUP, reward.Variant, reward.SubType, rock.Position, Velocity, nil)
end)