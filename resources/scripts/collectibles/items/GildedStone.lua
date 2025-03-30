local mod = edithMod
local enums = mod.Enums
local items = enums.CollectibleType
local plyMan = PlayerManager
local GildedStone = {}

---@param tear EntityTear
function GildedStone:ShootingRockTears(tear)
	local player = mod:GetPlayerFromTear(tear) 
	if not player then return end
	if not player:HasCollectible(items.COLLECTIBLE_GILDED_STONE) then return end

	local rng = player:GetCollectibleRNG(items.COLLECTIBLE_GILDED_STONE)
	local coins = player:GetNumCoins() 
	local RockTearRoll = rng:RandomFloat() * 100

	print(coins)

	if RockTearRoll > coins then return end
	tear:AddTearFlags(TearFlags.TEAR_ROCK)
	tear:ChangeVariant(TearVariant.ROCK)
end
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, GildedStone.ShootingRockTears)

local RockRewards = {
    [75] = {Variant = PickupVariant.PICKUP_COIN, SubType = CoinSubType.COIN_PENNY},
    [15] = {Variant = PickupVariant.PICKUP_COIN, SubType = CoinSubType.COIN_NICKEL},
    [5] = {Variant = PickupVariant.PICKUP_COIN, SubType = CoinSubType.COIN_DIME},
    [4] = {Variant = PickupVariant.PICKUP_COLLECTIBLE, SubType = CollectibleType.COLLECTIBLE_QUARTER},
    [1] = {Variant = PickupVariant.PICKUP_COLLECTIBLE, SubType = CollectibleType.COLLECTIBLE_DOLLAR},
}

local function getRandomReward()
    local totalWeight = 0
    for weight in pairs(RockRewards) do
        totalWeight = totalWeight + weight
    end

    local randomValue = math.random() * totalWeight
    local cumulativeWeight = 0

	print(totalWeight)

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
		rng = player:GetCollectibleRNG(items.COLLECTIBLE_GILDED_STONE)
		CoinCount = player:GetNumCoins()
	end
	local GeneralSpawnFormula = (CoinCount / 2) + (math.min(collectiveLuck, 1) - 1)

	GeneralSpawnRoll = rng:RandomFloat() * 100

	if GeneralSpawnRoll > GeneralSpawnFormula then return end
	RewardRoll = rng:RandomFloat() * 100

	local reward = getRandomReward()
	local vel = reward.Variant == 20 and RandomVector():Resized(3) or Vector.Zero

	Isaac.Spawn(EntityType.ENTITY_PICKUP, reward.Variant, reward.SubType, rock.Position, vel, nil)
end
mod:AddCallback(ModCallbacks.MC_POST_GRID_ROCK_DESTROY, GildedStone.OnDestroyingRockReward)
