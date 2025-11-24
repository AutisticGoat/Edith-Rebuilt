local mod = EdithRebuilt
local enums = mod.Enums
local Callbacks = enums.Callbacks

---@param player EntityPlayer
---@param entity Entity
mod:AddCallback(Callbacks.OFFENSIVE_STOMP, function(_, player, entity)
    local playerRef = EntityRef(player)
    local tearEffects = {
        [TearFlags.TEAR_SLOW] = function()
            local SlowColor = Color(0.5, 0.5, 0.5, 1)
            entity:AddSlowing(playerRef, 90, 0.6, SlowColor)
        end,
        [TearFlags.TEAR_POISON] = function()
            entity:AddPoison(playerRef, 90, player.Damage)
        end,
        [TearFlags.TEAR_FREEZE] = function()
            entity:AddFreeze(playerRef, 90)
        end,
        [TearFlags.TEAR_CHARM] = function()
            entity:AddCharmed(playerRef, 90)
        end,
        [TearFlags.TEAR_CONFUSION] = function()
            entity:AddConfusion(playerRef, 90, false)
        end,
        [TearFlags.TEAR_FEAR] = function()
            entity:AddFear(playerRef, 90)
        end,
        [TearFlags.TEAR_SHRINK] = function()
            entity:AddShrink(playerRef, 90)
        end,
        [TearFlags.TEAR_KNOCKBACK] = function()
            entity.Velocity = entity.Velocity * 1.025
        end,
        [TearFlags.TEAR_ICE] = function()
            entity:AddEntityFlags(EntityFlag.FLAG_ICE)
        end,
        [TearFlags.TEAR_MAGNETIZE] = function()
            entity:AddKnockback(playerRef, entity.Position, 15, false)
        end,
        [TearFlags.TEAR_BAIT] = function()
            entity:AddBaited(playerRef, 90)
        end,
        [TearFlags.TEAR_BACKSTAB] = function()
            entity:AddBleeding(playerRef, 150)
        end,
        [TearFlags.TEAR_BURN] = function()
            entity:AddBurn(playerRef, 120, player.Damage)
        end
    }

    for flag, func in pairs(tearEffects) do
        if mod.HasBitFlags(player.TearFlags, flag) then
            func()
        end
    end
end)