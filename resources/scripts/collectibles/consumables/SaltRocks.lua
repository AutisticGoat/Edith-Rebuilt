local mod = EdithRebuilt
local enums = mod.Enums
local card = enums.Card
local Helpers = mod.Modules.HELPERS
local StatusEffects = mod.Modules.STATUS_EFFECTS
local SaltRocks = {}

--[[
    On use:
    - Permanently Applies salted status effect to all enemies in room
]]

---@param player EntityPlayer
function SaltRocks:OnSaltRockUse(_, player)
    for _, enemy in pairs(Helpers.GetEnemies()) do
        StatusEffects.SetStatusEffect("Salted", enemy, -1, player)
    end
end
mod:AddCallback(ModCallbacks.MC_USE_CARD, SaltRocks.OnSaltRockUse, card.CARD_SALT_ROCKS)