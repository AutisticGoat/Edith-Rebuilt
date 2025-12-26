local mod = EdithRebuilt
local callbacks = mod.Enums.Callbacks

---@param player EntityPlayer
mod:AddCallback(callbacks.OFFENSIVE_STOMP, function(_, player)
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_JUPITER) then return end		

    local smokeCloud = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.SMOKE_CLOUD, 0, player.Position, Vector.Zero, player):ToEffect() ---@cast smokeCloud EntityEffect
    
    local randomScale = smokeCloud:GetDropRNG():RandomFloat() * 0.3
    smokeCloud.SpriteScale = Vector(0.5 + randomScale, 0.5 + randomScale)
    smokeCloud:SetTimeout(70)

	-- local knifeEntities = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and 8 or 4
	-- local degrees = 360/knifeEntities
	-- local knife

	-- for i = 1, knifeEntities do
	-- 	knife = player:FireKnife(player, degrees * i, true, 0, 0)
	-- 	knife:Shoot(1, player.TearRange / 3)
	-- 	data(knife).StompKnife = true			
	-- end
end)
