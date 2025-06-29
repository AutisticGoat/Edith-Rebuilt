local mod = EdithRebuilt
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
	
	if not mod.RandomBoolean(rng, player:GetNumCoins()  / 100) then return end
	local tearDamageChange = rng:RandomInt(500, 2500) / 100
	tear.CollisionDamage = tear.CollisionDamage * tearDamageChange
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

---comment
---@param rng RNG
---@return table
local function getRandomReward(rng)
    local totalWeight = 0
    for weight in pairs(RockRewards) do
        totalWeight = totalWeight + weight
    end

    local randomValue = rng:RandomFloat() * totalWeight
    local cumulativeWeight = 0

    for weight, reward in pairs(RockRewards) do
        cumulativeWeight = cumulativeWeight + weight
        if randomValue <= cumulativeWeight then
            return reward
        end
---@diagnostic disable-next-line: missing-return
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
	local GeneralSpawnFormula = ((CoinCount / 2) + (math.min(collectiveLuck, 1) - 1)) / 100

	if not mod.RandomBoolean(rng, GeneralSpawnFormula) then return end

	local reward = getRandomReward(rng)
	local vel = reward.Variant == 20 and rng:RandomVector():Resized(3) or Vector.Zero

	Isaac.Spawn(EntityType.ENTITY_PICKUP, reward.Variant, reward.SubType, rock.Position, vel, nil)
end
mod:AddCallback(ModCallbacks.MC_POST_GRID_ROCK_DESTROY, GildedStone.OnDestroyingRockReward)