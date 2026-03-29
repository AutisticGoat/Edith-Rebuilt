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
    return player:HasCollectible(CollectibleType.COLLECTIBLE_GHOST_PEPPER)
       and player:HasCollectible(CollectibleType.COLLECTIBLE_BIRDS_EYE)
end

---@param player EntityPlayer
---@param isStomp boolean
local function ShootPeppers(player, isStomp)
    local rng = ( 
        player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_GHOST_PEPPER) or
        player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_BIRDS_EYE)
    )

    if not rng then return end

    local fires = (isStomp and Player.PlayerHasBirthright(player)) and 8 or 4
    local degrees = 360 / fires
    local HasBothPeppers = HasBothPeppers(player)

    local luckMod = HasBothPeppers and 8 or 12
    local maxDiv = HasBothPeppers and 1 or 2

    local chance = 1 / math.max((luckMod - player.Luck), maxDiv)

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
end

mod:AddCallback(callbacks.PERFECT_PARRY,   function(_, player) ShootPeppers(player, false) end)
mod:AddCallback(callbacks.OFFENSIVE_STOMP, function(_, player) ShootPeppers(player, true)  end)
