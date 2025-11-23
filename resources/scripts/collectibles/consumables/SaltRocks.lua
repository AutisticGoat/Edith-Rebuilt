local mod = EdithRebuilt
local enums = mod.Enums
local card = enums.Card
local SaltRocks = {}
local getData = mod.CustomDataWrapper.getData

---@param player EntityPlayer
function SaltRocks:OnSaltRockUse(_, player)
    for _, enemy in pairs(mod.GetEnemies()) do
        mod.SetSalted(enemy, -1, player)
    end
end
mod:AddCallback(ModCallbacks.MC_USE_CARD, SaltRocks.OnSaltRockUse, card.CARD_SALT_ROCKS)

function SaltRocks:OnReplacingSaltRocks(RNG, CardID)
    print("a[oodjaopjdop]")
end
mod:AddCallback(ModCallbacks.MC_GET_CARD, SaltRocks.OnReplacingSaltRocks)