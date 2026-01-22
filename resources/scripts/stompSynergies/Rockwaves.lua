local mod = EdithRebuilt
local callbacks = mod.Enums.Callbacks

---@param player EntityPlayer
mod:AddCallback(callbacks.OFFENSIVE_STOMP, function(_, player)
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_TERRA) then return end
	local hasBirthright = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)
	local totalrings = hasBirthright and 2 or 1
	local damageMult = hasBirthright and 1.5 or 1.25
	local shockwaveDamage = (player.Damage * damageMult) / 2

	for ring = 1, totalrings do
		local totalRocks = ring == 1 and 6 or 12
		local dist = ring == 1 and 40 or 70
		for rocks = 1, totalRocks do
			CustomShockwaveAPI:SpawnCustomCrackwave(
				player.Position, -- Position
				player, -- Spawner
				dist, -- Steps
				rocks * (360 / totalRocks), -- Angle
				1, -- Delay
				ring, -- Limit
				shockwaveDamage -- Damage
			)
		end
	end
end)