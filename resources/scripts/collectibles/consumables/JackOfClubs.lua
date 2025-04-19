local mod = edithMod
local enums = mod.Enums
local card = enums.Card
local utils = enums.Utils
local rng = utils.RNG
local game = utils.Game
local JackOfClubs = {}

---@return Entity[]
local function GetEnemies()
    local roomEnt = Isaac.GetRoomEntities()
    local enemyTable = {}

    for _, ent in ipairs(roomEnt) do
        if not (ent:IsActiveEnemy() and ent:IsVulnerableEnemy()) then goto Break end
        table.insert(enemyTable, ent)
        ::Break::
    end

    return enemyTable
end 

---@param player EntityPlayer
function JackOfClubs:myFunction2(_, player)
    local enemies = GetEnemies()

    for _, enemy in pairs(enemies) do
        local explosionRoll = rng:RandomFloat()

        if explosionRoll > 0.4 then goto Break end
        game:BombExplosionEffects(
            enemy.Position,
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
            enemy.Position,
            Vector.Zero,
            nil
        )
        ::Break::
    end
end
mod:AddCallback(ModCallbacks.MC_USE_CARD, JackOfClubs.myFunction2, card.CARD_JACK_OF_CLUBS)
