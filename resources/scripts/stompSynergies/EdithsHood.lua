local mod = EdithRebuilt
local enums = mod.Enums
local callbacks = enums.Callbacks
local saltTypes = enums.SaltTypes
local Creeps = mod.Modules.CREEPS
local EdithHood = enums.CollectibleType.COLLECTIBLE_EDITHS_HOOD

local maxCreep = 10
local saltDegrees = 360 / maxCreep

---@param player EntityPlayer
mod:AddCallback(callbacks.OFFENSIVE_STOMP, function(_, player)
    if not player:HasCollectible(EdithHood) then return end	
	if player:GetCollectibleRNG(EdithHood):RandomInt(1, 3) ~= 1 then return end
    for i = 1, maxCreep do
		Creeps.SpawnSaltCreep(player, player.Position + Vector(0, 30):Rotated(saltDegrees*i), 0.1, 5, 1, 3, saltTypes.EDITHS_HOOD)
	end
end)