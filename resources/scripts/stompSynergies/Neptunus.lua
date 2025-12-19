local mod = EdithRebuilt
local callbacks = mod.Enums.Callbacks
local Player = mod.Modules.PLAYER

---@param player EntityPlayer
---@param params EdithJumpStompParams
mod:AddCallback(callbacks.OFFENSIVE_STOMP, function(_, player, params)
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_NEPTUNUS) then return end

    local weapon = player:GetWeapon(1)
    if not weapon then return end
    local maxCharge = weapon:GetMaxCharge()
    local charge = weapon:GetCharge()
    local chargePercent = charge / maxCharge
    local hasBirthright = Player.PlayerHasBirthright(player)

    local birthrightMult = {
        Damage = hasBirthright and 2 or 1,
        Duration = 1.5 or 1,
    }

    local water = Isaac.Spawn(
        EntityType.ENTITY_EFFECT, 
        EffectVariant.PLAYER_CREEP_HOLYWATER_TRAIL, 
        0, 
        player.Position, 
        Vector.Zero, 
        player
    ):ToEffect() ---@cast water EntityEffect

    water.CollisionDamage = (15 * birthrightMult) * chargePercent
    water.Size = water.Size * (2.5 * chargePercent)
    water.SpriteScale = water.SpriteScale * water.Size
    water:SetTimeout(math.ceil((150 * birthrightMult.Duration) * chargePercent))
    water:Update()
end)