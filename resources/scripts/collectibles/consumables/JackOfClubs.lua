local mod = edithMod
local enums = mod.Enums
local card = enums.Card
local utils = enums.Utils
local rng = utils.RNG
local game = utils.Game
local JackOfClubs = {}

---@param player EntityPlayer
function JackOfClubs:myFunction2(_, player)
    for _, enemy in pairs(mod.GetEnemies()) do
        local explosionRoll = rng:RandomFloat()
        local enemyPos = enemy.Position

        if explosionRoll > 0.4 then goto Break end
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

        local SpawnBombRoll = rng:RandomFloat()

        if SpawnBombRoll > 0.5 then goto Break end
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