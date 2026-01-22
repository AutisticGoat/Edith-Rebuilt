local mod = EdithRebuilt
local enums = mod.Enums
local Helpers = mod.Modules.HELPERS
local Callbacks = enums.Callbacks

---@param player EntityPlayer
---@param ent Entity
---@param params EdithJumpStompParams
mod:AddCallback(Callbacks.OFFENSIVE_STOMP_HIT, function(_, player, ent, params)
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_PLAYDOUGH_COOKIE) then return end
    local Itemrng = player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_PLAYDOUGH_COOKIE)
    local Effects = {
        [1] = function(rng) 
            return 
        end,
        [2] = function() 
            local SubEffects = {
                [1] = function() params.Damage = params.Damage * 2 end,
                [2] = function() ent:AddBurn(EntityRef(player), 150, player.Damage) end,
                [3] = function() ent:AddFreeze(EntityRef(player), 120) end,
            }

            Helpers.WhenEval(Itemrng:RandomInt(1, 3), SubEffects)
        end,
        [3] = function() 
            ent:AddCharmed(EntityRef(player), 120)
        end,
        [4] = function() 
            ent:AddSlowing(EntityRef(player), 120, 120, Color(0.2, 0.2, 1))
        end,
        [5] = function()
            ent:AddPoison(EntityRef(player), 120, player.Damage)
        end,
        [6] = function() 
            ent:AddFear(EntityRef(player), 120)
            ent:AddEntityFlags(EntityFlag.FLAG_ICE)    
        end,
        [7] = function() 
            ent:AddBaited(EntityRef(player), 120)
        end,
    }

    Helpers.WhenEval(Itemrng:RandomInt(1, 7), Effects)
end)