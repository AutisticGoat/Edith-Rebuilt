local mod = EdithRebuilt
local enums = mod.Enums
local Callbacks = enums.Callbacks
local funcs = require("resources.scripts.stompSynergies.Funcs")
local EdithJump = require("resources.scripts.stompSynergies.JumpData")

mod:AddCallback(Callbacks.OFFENSIVE_STOMP, function(_, player, entity)
    local tearEffects = {
        [TearFlags.TEAR_SLOW] = function()
            local SlowColor = Color(0.5, 0.5, 0.5, 1)
            entity:AddSlowing(EntityRef(player), 90, 0.6, SlowColor)
        end,
        [TearFlags.TEAR_POISON] = function()
            entity:AddPoison(EntityRef(player), 90, player.Damage)
        end,
        [TearFlags.TEAR_FREEZE] = function()
            entity:AddFreeze(EntityRef(player), 90)
        end,
        [TearFlags.TEAR_CHARM] = function()
            entity:AddCharmed(EntityRef(player), 90)
        end,
        [TearFlags.TEAR_CONFUSION] = function()
            entity:AddConfusion(EntityRef(player), 90, false)
        end,
        [TearFlags.TEAR_FEAR] = function()
            entity:AddFear(EntityRef(player), 90)
        end,
        [TearFlags.TEAR_SHRINK] = function()
            entity:AddShrink(EntityRef(player), 90)
        end,
        [TearFlags.TEAR_KNOCKBACK] = function()
            entity.Velocity = entity.Velocity * 1.025
        end,
        [TearFlags.TEAR_ICE] = function()
            entity:AddEntityFlags(EntityFlag.FLAG_ICE)
        end,
        [TearFlags.TEAR_MAGNETIZE] = function()
            entity:AddKnockback(EntityRef(player), entity.Position, 15, false)
        end,
        [TearFlags.TEAR_BAIT] = function()
            entity:AddBaited(EntityRef(player), 90)
        end,
        [TearFlags.TEAR_BACKSTAB] = function()
            entity:AddBleeding(EntityRef(player), 150)
        end,
    }

    for flag, func in pairs(tearEffects) do
        if mod.HasBitFlags(player.TearFlags, flag) then
            func()
        end
    end
end)