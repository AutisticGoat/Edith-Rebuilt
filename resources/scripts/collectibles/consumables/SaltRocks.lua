local mod = EdithRebuilt
local enums = mod.Enums
local game = enums.Utils.Game
local card = enums.Card
local sfx = enums.Utils.SFX
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
        StatusEffects.SetStatusEffect("Salt", enemy, -1, player)
        Helpers.SpawnSaltGib(enemy, 5, 3, nil, true)
    end
    sfx:Play(SoundEffect.SOUND_ROCK_CRUMBLE)
    game:ShakeScreen(8)
end
mod:AddCallback(ModCallbacks.MC_USE_CARD, SaltRocks.OnSaltRockUse, card.CARD_SALT_ROCKS)