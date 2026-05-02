local mod = EdithRebuilt
local enums = mod.Enums
local card = enums.Card
local utils = enums.Utils
local game = utils.Game
local modules = mod.Modules
local Helpers = modules.HELPERS
local ModRNG = modules.RNG 
local JackOfClubs = {}

---@param player EntityPlayer
function JackOfClubs:OnJackOfClubsUse(_, player)
    local rng = player:GetCardRNG(card.CARD_JACK_OF_CLUBS)
    for _, enemy in pairs(Helpers.GetEnemies()) do
        local enemyPos = enemy.Position

        if not ModRNG.RandomBoolean(rng, 0.6) then goto continue end
        game:BombExplosionEffects(
            enemyPos,
            100,
            TearFlags.TEAR_NORMAL,
            Color.Default,
            player,
            0.5,
            true,
            false,
            0
        )
        if not ModRNG.RandomBoolean(rng) then goto continue end
        Isaac.Spawn(
            EntityType.ENTITY_PICKUP,
            PickupVariant.PICKUP_BOMB,
            0,
            enemyPos,
            Vector.Zero,
            nil
        )
        ::continue::
    end
end
mod:AddCallback(ModCallbacks.MC_USE_CARD, JackOfClubs.OnJackOfClubsUse, card.CARD_JACK_OF_CLUBS)