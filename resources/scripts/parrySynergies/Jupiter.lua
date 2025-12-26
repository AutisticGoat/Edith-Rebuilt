local mod = EdithRebuilt
local callbacks = mod.Enums.Callbacks

---@param player EntityPlayer
mod:AddCallback(callbacks.PERFECT_PARRY, function(_, player)
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_JUPITER) then return end		

    local smokeCloud = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.SMOKE_CLOUD, 0, player.Position, Vector.Zero, player):ToEffect() ---@cast smokeCloud EntityEffect

    local randomScale = smokeCloud:GetDropRNG():RandomFloat() * 0.3
    smokeCloud.SpriteScale = Vector(0.5 + randomScale, 0.5 + randomScale)
    smokeCloud:SetTimeout(70)
end)
