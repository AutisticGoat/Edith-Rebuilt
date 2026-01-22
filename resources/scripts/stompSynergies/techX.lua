local mod = EdithRebuilt
local callbacks = mod.Enums.Callbacks

---@param player EntityPlayer
mod:AddCallback(callbacks.OFFENSIVE_STOMP, function (_, player)
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_TECH_X) then return end
	local techXDistance = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and 65 or 50
	local LaserDamage = (techXDistance/100) + 0.25
	local techX = player:FireTechXLaser(player.Position, Vector.Zero, techXDistance, player, LaserDamage)

	techX.DisableFollowParent = true
	techX:SetTimeout(17) 
end)