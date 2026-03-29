local mod = EdithRebuilt
local Helpers = mod.Modules.HELPERS
local Callbacks = mod.Enums.Callbacks

-- La lógica es idéntica entre parry y stomp; solo difiere el nombre del campo
-- de daño en params. Se normaliza igual que Damage.lua.

---@param params TEdithHopParryParams|EdithJumpStompParams
local function GetDamage(params)
    return params.Damage or params.ParryDamage
end

---@param params TEdithHopParryParams|EdithJumpStompParams
local function SetDamage(params, value)
    if params.Damage ~= nil then
        params.Damage = value
    else
        params.ParryDamage = value
    end
end

---@param player EntityPlayer
---@param ent Entity
---@param params TEdithHopParryParams|EdithJumpStompParams
local function ApplyPlaydoughEffect(player, ent, params)
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_PLAYDOUGH_COOKIE) then return end

    local itemRNG = player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_PLAYDOUGH_COOKIE)
    local effects = {
        [1] = function() end,
        [2] = function()
            local subEffects = {
                [1] = function() SetDamage(params, GetDamage(params) * 2) end,
                [2] = function() ent:AddBurn(EntityRef(player), 150, player.Damage) end,
                [3] = function() ent:AddFreeze(EntityRef(player), 120) end,
            }
            Helpers.WhenEval(itemRNG:RandomInt(1, 3), subEffects)
        end,
        [3] = function() ent:AddCharmed(EntityRef(player), 120) end,
        [4] = function() ent:AddSlowing(EntityRef(player), 120, 120, Color(0.2, 0.2, 1)) end,
        [5] = function() ent:AddPoison(EntityRef(player), 120, player.Damage) end,
        [6] = function()
            ent:AddFear(EntityRef(player), 120)
            ent:AddEntityFlags(EntityFlag.FLAG_ICE)
        end,
        [7] = function() ent:AddBaited(EntityRef(player), 120) end,
    }

    Helpers.WhenEval(itemRNG:RandomInt(1, 7), effects)
end

mod:AddCallback(Callbacks.PERFECT_PARRY, function(_, player, ent, params) ApplyPlaydoughEffect(player, ent, params) end)
mod:AddCallback(Callbacks.OFFENSIVE_STOMP_HIT, function(_, player, ent, params) ApplyPlaydoughEffect(player, ent, params) end)
