local mod = EdithRebuilt
local callbacks = mod.Enums.Callbacks
local data = mod.DataHolder.GetEntityData

---@param player EntityPlayer
mod:AddCallback(callbacks.PERFECT_PARRY, function(_, player)
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE) then return end

	local totalRays = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and 6 or 4
	local shootDegrees = 360 / totalRays
	local laser
	
	for	i = 1, totalRays do
		laser = player:FireDelayedBrimstone(shootDegrees * i, player)
		laser:SetMaxDistance(player.TearRange / 5)
		laser:AddTearFlags(player.TearFlags)
		data(laser).ParryBrimstone = true
	end
end)

mod:AddCallback(ModCallbacks.MC_POST_LASER_UPDATE, function (_, laser)
	if not data(laser).ParryBrimstone then return end	
	laser.Angle = laser.Angle + 10
end)