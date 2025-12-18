local mod = EdithRebuilt
local callbacks = mod.Enums.Callbacks
local Creeps = mod.Modules.CREEPS

---@param player EntityPlayer
mod:AddCallback(callbacks.OFFENSIVE_STOMP, function(_, player)
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_BLACK_POWDER) then return end	
	if player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_BLACK_POWDER):RandomInt(1, 3) ~= 1 then return end
	local distance = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and 90 or 70
	Creeps.SpawnBlackPowder(player, 20, player.Position, distance)
end)