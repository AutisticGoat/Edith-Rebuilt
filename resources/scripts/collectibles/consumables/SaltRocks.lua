local mod = edithMod
local enums = mod.Enums
local card = enums.Card
local utils = enums.Utils
local rng = utils.RNG
local SaltRocks = {}

---@param player EntityPlayer
function SaltRocks:OnSaltRockUse(_, player)
    for _, enemy in pairs(mod.GetEnemies()) do
        local enemyData = mod.GetData(enemy)
        enemyData.Salted = true
        enemy:AddSlowing(EntityRef(player), 10000, 0.7, Color(1, 1, 1, 1, 0.2, 0.2, 0.2))
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
    local enemyData = mod.GetData(NPC)
    local IsInAttackState = mod.When(NPC.State, AttackState, false)
    local Projectiles = Isaac.FindByType(EntityType.ENTITY_PROJECTILE)

    if not enemyData.Salted then return end
    if not IsInAttackState then enemyData.CancelRoll = nil return end
        
    enemyData.CancelRoll = enemyData.CancelRoll or rng:RandomFloat()

    if enemyData.CancelRoll > 0.5 then return end
    for _, proj in ipairs(Projectiles) do
        if GetPtrHash(proj.SpawnerEntity) ~= GetPtrHash(NPC) then goto Break end
        proj.Visible = false
        proj:Kill()
        ::Break::
    end 
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

    if flag == true then return end
    flag = true
    entity:TakeDamage(amount * 1.2, flags, source, Cooldown)
    flag = false
    return false
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, SaltRocks.OnSaltedEnemyTakingDamage)