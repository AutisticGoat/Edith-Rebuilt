local mod = EdithRebuilt
local callbacks = mod.Enums.Callbacks
local Player = mod.Modules.PLAYER

---@param player EntityPlayer
---@param isStomp boolean
local function SpawnWaterCreep(player, isStomp)
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_NEPTUNUS) then return end

    local weapon = player:GetWeapon(1)
    if not weapon then return end

    local chargePercent = weapon:GetCharge() / weapon:GetMaxCharge()
    local hasBirthright = isStomp and Player.PlayerHasBirthright(player)
    local damageMult = hasBirthright and 2 or 1
    local durationMult = hasBirthright and 1.5 or 1

    local water = Isaac.Spawn(
        EntityType.ENTITY_EFFECT,
        EffectVariant.PLAYER_CREEP_HOLYWATER_TRAIL,
        0,
        player.Position,
        Vector.Zero,
        player
    ):ToEffect() ---@cast water EntityEffect

    water.CollisionDamage = (15 * damageMult) * chargePercent
    water.Size = water.Size * (2.5 * chargePercent)
    water.SpriteScale = water.SpriteScale * water.Size
    water:SetTimeout(math.ceil((150 * durationMult) * chargePercent))
    water:Update()
end

mod:AddCallback(callbacks.PERFECT_PARRY, function(_, player) SpawnWaterCreep(player, false) end)
mod:AddCallback(callbacks.OFFENSIVE_STOMP, function(_, player) SpawnWaterCreep(player, true)  end)
