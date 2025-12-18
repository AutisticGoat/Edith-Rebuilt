local mod = EdithRebuilt
local callbacks = mod.Enums.Callbacks

---@param player EntityPlayer
function mod:RockStomp(player)
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_TERRA) then return end
	local hasBirthright = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)
	local totalrocks = hasBirthright and 8 or 6
	local totalrings = hasBirthright and 2 or 1
	local shockwaveDamage = (hasBirthright and player.Damage * 1.4 or player.Damage) / 2

	for ring = 1, totalrings do
		local dist = ring == 1 and 40 or 20
		for rocks = 1, totalrocks do
			CustomShockwaveAPI:SpawnCustomCrackwave(
				player.Position, -- Position
				player, -- Spawner
				dist, -- Steps
				rocks * (360 / totalrocks), -- Angle
				1, -- Delay
				ring, -- Limit
				shockwaveDamage -- Damage
			)
		end
	end
end
mod:AddCallback(callbacks.OFFENSIVE_STOMP, mod.RockStomp)