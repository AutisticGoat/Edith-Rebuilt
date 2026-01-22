local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local modules = mod.Modules
local ModRNG = modules.RNG
local Helpers = modules.HELPERS
local plyMan = PlayerManager
local GildedStone = {}

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function (_, player)
	local gildedCount = player:GetCollectibleNum(items.COLLECTIBLE_GILDED_STONE)
	if gildedCount < 1 then return end
	player.Luck = player.Luck + (1 * gildedCount)
end, CacheFlag.CACHE_LUCK)

---@param tear EntityTear
function GildedStone:ShootingRockTears(tear)
	local player = Helpers.GetPlayerFromTear(tear)
	if not player then return end
	if not player:HasCollectible(items.COLLECTIBLE_GILDED_STONE) then return end
	local rng = player:GetCollectibleRNG(items.COLLECTIBLE_GILDED_STONE)
	
	if not ModRNG.RandomBoolean(rng, player:GetNumCoins() / 100) then return end
	tear:AddTearFlags(TearFlags.TEAR_ROCK)
	tear:ChangeVariant(TearVariant.ROCK)
	tear.CollisionDamage = tear.CollisionDamage * ModRNG.RandomFloat(rng, 0.5, 2)
end
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, GildedStone.ShootingRockTears)

local RockRewards = {
    [70] = {Variant = PickupVariant.PICKUP_COIN, SubType = CoinSubType.COIN_PENNY},
    [15] = {Variant = PickupVariant.PICKUP_COIN, SubType = CoinSubType.COIN_NICKEL},
    [10] = {Variant = PickupVariant.PICKUP_COIN, SubType = CoinSubType.COIN_DIME},
    [4] = {Variant = PickupVariant.PICKUP_COLLECTIBLE, SubType = CollectibleType.COLLECTIBLE_QUARTER},
    [1] = {Variant = PickupVariant.PICKUP_COLLECTIBLE, SubType = CollectibleType.COLLECTIBLE_DOLLAR},
}

---@param rng RNG
---@return table?
local function getRandomReward(rng)
    local randomValue = math.max(1, rng:RandomFloat() * 100)
    local cumulativeWeight = 0

    for weight, reward in pairs(RockRewards) do
        cumulativeWeight = cumulativeWeight + weight
        if randomValue <= cumulativeWeight then
            return reward
        end
	end
end

---@param rock GridEntityRock
function GildedStone:OnDestroyingRockReward(rock)
	if not plyMan.AnyoneHasCollectible(items.COLLECTIBLE_GILDED_STONE) then return end

	local collectiveLuck = 0
	local CoinCount = 0
	local rng

	for _, player in ipairs(plyMan.GetPlayers()) do
		collectiveLuck = collectiveLuck + player.Luck
		CoinCount = player:GetNumCoins()
		rng = player:GetCollectibleRNG(items.COLLECTIBLE_GILDED_STONE)
	end
	local GeneralSpawnFormula = ((CoinCount / 2) + (math.min(collectiveLuck, 1) - 1)) / 100

	if not ModRNG.RandomBoolean(rng, GeneralSpawnFormula) then return end

	local reward = getRandomReward(rng) ---@cast reward table
	local vel = reward.Variant == 20 and rng:RandomVector():Resized(3) or Vector.Zero

	Isaac.Spawn(EntityType.ENTITY_PICKUP, reward.Variant, reward.SubType, rock.Position, vel, nil)
end
mod:AddCallback(ModCallbacks.MC_POST_GRID_ROCK_DESTROY, GildedStone.OnDestroyingRockReward)