local mod = edithMod
local enums = mod.Enums
local card = enums.Card
local utils = enums.Utils
local rng = utils.RNG
local SaltRocks = {}

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
function SaltRocks:OnSaltRockUse(_, player)
    local enemies = GetEnemies()

    for _, enemy in pairs(enemies) do
        local enemyData = mod.GetData(enemy)

        enemyData.Salted = true

        -- local explosionRoll = rng:RandomFloat()

        -- if explosionRoll > 0.4 then goto Break end
        -- game:BombExplosionEffects(
        --     enemy.Position,
        --     100,
        --     TearFlags.TEAR_NORMAL,
        --     Color.Default,
        --     player,
        --     0.5,
        --     true,
        --     false,
        --     0
        -- )

        -- local SpawnBombRoll = rng:RandomFloat()

        -- if SpawnBombRoll > 0.5 then goto Break end
        -- Isaac.Spawn(
        --     EntityType.ENTITY_PICKUP,
        --     PickupVariant.PICKUP_BOMB,
        --     0,
        --     enemy.Position,
        --     Vector.Zero,
        --     nil
        -- )
        -- ::Break::
    end
end
mod:AddCallback(ModCallbacks.MC_USE_CARD, SaltRocks.OnSaltRockUse, card.CARD_SALT_ROCKS)


local AttackState = {
    [NpcState.STATE_ATTACK] = true,
    [NpcState.STATE_ATTACK2] = true,
    [NpcState.STATE_ATTACK3] = true,
    [NpcState.STATE_ATTACK4] = true,
    [NpcState.STATE_ATTACK5] = true,
}


---@param NPC EntityNPC
function SaltRocks:OnSaltedEnemiesUpdate(NPC)
    local state = NPC.State
    local enemyData = mod.GetData(NPC)
    -- print(state, NPC.State, state == NPC.State)

    local IsInAttackState = mod.When(NPC.State, AttackState, false)
    local Projectiles = Isaac.FindByType(EntityType.ENTITY_PROJECTILE)

    if not enemyData.Salted then return end
    if IsInAttackState then
        enemyData.CancelRoll = enemyData.CancelRoll or rng:RandomFloat()

        if enemyData.CancelRoll < 0.5 then
            for _, proj in ipairs(Projectiles) do
                proj.Visible = false
                proj:Kill()
            end 
        end
    else
        enemyData.CancelRoll = nil  
    end

    NPC:AddSlowing(EntityRef(NPC), 10000, 0.7, Color(1, 1, 1, 1, 0.2, 0.2, 0.2))
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, SaltRocks.OnSaltedEnemiesUpdate)

local flag = false

---@param entity Entity
---@param amount number
---@param flags DamageFlag
---@param source EntityRef
---@param Cooldown integer
function SaltRocks:OnSaltedEnemyTakingDamage(entity, amount, flags, source, Cooldown)    
    local enemyData = mod.GetData(entity)

    if not enemyData.Salted then return end
    if not amount == (amount * 1.2) then return end

    if flag == false then
        flag = true
        entity:TakeDamage(amount * 1.2, flags, source, Cooldown)
        
        return false
    end
    flag = false
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, SaltRocks.OnSaltedEnemyTakingDamage)