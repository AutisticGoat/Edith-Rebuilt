local mod = EdithRebuilt
local callbacks = mod.Enums.Callbacks
local data = mod.DataHolder.GetEntityData

---@param player EntityPlayer
local function FireBrimstoneRays(player)
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE) then return end

	local totalRays = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and 6 or 4
	local shootDegrees = 360 / totalRays

	for i = 1, totalRays do
		local laser = player:FireDelayedBrimstone(shootDegrees * i, player)
		laser:SetMaxDistance(player.TearRange / 5)
		laser:AddTearFlags(player.TearFlags)
		data(laser).SynergyBrimstone = true
	end
end

mod:AddCallback(callbacks.PERFECT_PARRY, function(_, player) FireBrimstoneRays(player) end)
mod:AddCallback(callbacks.OFFENSIVE_STOMP, function(_, player) FireBrimstoneRays(player) end)

---@param laser EntityLaser
mod:AddCallback(ModCallbacks.MC_POST_LASER_UPDATE, function(_, laser)
	if not data(laser).SynergyBrimstone then return end
	laser.Angle = laser.Angle + 10
end)
