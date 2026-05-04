local mod = EdithRebuilt
local enums = mod.Enums
local Callbacks = enums.Callbacks

---@param player EntityPlayer
---@param isBombLand boolean
local function TriggerBombEffects(player, isBombLand)
    if not isBombLand then return end

    local bombMods = {
        [CollectibleType.COLLECTIBLE_GHOST_BOMBS] = function ()
            
        end
    } 
end 

---@param player EntityPlayer
---@param jumpParams EdithJumpStompParams
mod:AddCallback(Callbacks.OFFENSIVE_STOMP, function (_, player, jumpParams)
    TriggerBombEffects(player, jumpParams.BombStomp)
end)

---@param player EntityPlayer
---@param hopParryParams TEdithHopParryParams
mod:AddCallback(Callbacks.PERFECT_PARRY, function (_, player, _, hopParryParams)
    
end)