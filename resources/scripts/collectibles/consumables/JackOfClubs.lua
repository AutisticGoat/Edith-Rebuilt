local mod = EdithRebuilt
local enums = mod.Enums
local card = enums.Card
local utils = enums.Utils
local game = utils.Game
local JackOfClubs = {}

---@param player EntityPlayer
function JackOfClubs:myFunction2(_, player)
    local rng = player:GetCardRNG(card.CARD_JACK_OF_CLUBS)
    local enemyPos
    for _, enemy in pairs(mod.GetEnemies()) do
        enemyPos = enemy.Position

        if not mod.RandomBoolean(rng, 0.4) then goto Break end
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
        if not mod.RandomBoolean(rng) then goto Break end
        Isaac.Spawn(
            EntityType.ENTITY_PICKUP,
            PickupVariant.PICKUP_BOMB,
            0,
            enemyPos,
            Vector.Zero,
            nil
        )
        ::Break::
    end
end
mod:AddCallback(ModCallbacks.MC_USE_CARD, JackOfClubs.myFunction2, card.CARD_JACK_OF_CLUBS)