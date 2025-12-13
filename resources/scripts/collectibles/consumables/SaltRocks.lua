local mod = EdithRebuilt
local enums = mod.Enums
local card = enums.Card
local Helpers = mod.Modules.HELPERS
local SaltRocks = {}

---@param player EntityPlayer
function SaltRocks:OnSaltRockUse(_, player)
    for _, enemy in pairs(Helpers.GetEnemies()) do
        mod.SetSalted(enemy, -1, player)
    end
end
mod:AddCallback(ModCallbacks.MC_USE_CARD, SaltRocks.OnSaltRockUse, card.CARD_SALT_ROCKS)