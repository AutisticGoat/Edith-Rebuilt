local mod = EdithRebuilt
local callbacks = mod.Enums.Callbacks

-- Pending to rework

-- ---@param player EntityPlayer
-- ---@param params EdithJumpStompParams
-- mod:AddCallback(callbacks.PERFECT_PARRY, function(_, player, params)
--     if not player:HasCollectible(CollectibleType.COLLECTIBLE_NEPTUNUS) then return end

--     local weapon = player:GetWeapon(1)
--     if not weapon then return end
--     local maxCharge = weapon:GetMaxCharge()
--     local charge = weapon:GetCharge()
--     local chargePercent = charge / maxCharge

--     local water = Isaac.Spawn(
--         EntityType.ENTITY_EFFECT, 
--         EffectVariant.PLAYER_CREEP_HOLYWATER_TRAIL, 
--         0, 
--         player.Position, 
--         Vector.Zero, 
--         player
--     ):ToEffect() ---@cast water EntityEffect

--     water.CollisionDamage = 15 * chargePercent
--     water.Size = water.Size * (2.5 * chargePercent)
--     water.SpriteScale = water.SpriteScale * water.Size
--     water:SetTimeout(math.ceil(150 * chargePercent))
--     water:Update()
-- end)