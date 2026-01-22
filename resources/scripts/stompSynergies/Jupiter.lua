local mod = EdithRebuilt
local callbacks = mod.Enums.Callbacks
local Player = mod.Modules.PLAYER
---@param player EntityPlayer
mod:AddCallback(callbacks.OFFENSIVE_STOMP, function(_, player)
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_JUPITER) then return end		

    local smokeCloud = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.SMOKE_CLOUD, 0, player.Position, Vector.Zero, player):ToEffect() ---@cast smokeCloud EntityEffect

    local baseScale = Player.PlayerHasBirthright(player) and 0.8 or 0.5
    local timeOut = Player.PlayerHasBirthright(player) and 140 or 70

    local randomScale = smokeCloud:GetDropRNG():RandomFloat() * 0.3
    smokeCloud.SpriteScale = Vector(baseScale + randomScale, baseScale + randomScale)
    smokeCloud:SetTimeout(70)
end)
