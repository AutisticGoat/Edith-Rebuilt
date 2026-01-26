local mod = EdithRebuilt
local callbacks = mod.Enums.Callbacks
local ModRNG = mod.Modules.RNG
local Player = mod.Modules.PLAYER

---@param player EntityPlayer
---@param direction Vector
local function RedCandle(player, direction)
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_BIRDS_EYE) then return end
    player:ShootRedCandle(direction)
end

---@param player EntityPlayer
---@param direction Vector
local function BlueCandle(player, direction)
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_GHOST_PEPPER) then return end
    player:ShootBlueCandle(direction)
end

local function HasBothPeppers(player)
    return player:HasCollectible(CollectibleType.COLLECTIBLE_GHOST_PEPPER) and player:HasCollectible(CollectibleType.COLLECTIBLE_BIRDS_EYE)
end

---@param player EntityPlayer
mod:AddCallback(callbacks.OFFENSIVE_STOMP, function(_, player)
    local rng = player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_GHOST_PEPPER) or player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_BIRDS_EYE)

    if not rng then return end

    local fires = Player.PlayerHasBirthright(player) and 8 or 4
    local degrees = 360 / fires

    local chance = (
        (not HasBothPeppers(player) and 1 / math.max((12 - player.Luck), 2)) or
        (1 / math.max((8 - player.Luck), 1))
    )

    if not ModRNG.RandomBoolean(rng, chance) then return end

    for i = 1, fires do
        local dir = Vector(0, 1):Rotated(degrees * i)

        if HasBothPeppers(player) then  
            if ModRNG.RandomBoolean(rng) then
                RedCandle(player, dir)
            else
                BlueCandle(player, dir)
            end
        else
            RedCandle(player, dir)
            BlueCandle(player, dir)
        end
    end
end)

