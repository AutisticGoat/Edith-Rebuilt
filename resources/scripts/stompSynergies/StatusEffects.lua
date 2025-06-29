local mod = EdithRebuilt
local funcs = require("resources.scripts.stompSynergies.Funcs")
local EdithJump = require("resources.scripts.stompSynergies.JumpData")

---@param player EntityPlayer
function mod:OnStatusEffectLand(player)
    -- print(player.TearFlags)
    -- print(player.TearFlags & TearFlags.TEAR_POISON == TearFlags.TEAR_POISON)

end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, mod.OnStatusEffectLand, EdithJump)