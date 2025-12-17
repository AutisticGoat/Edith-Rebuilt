local mod = EdithRebuilt
local callbacks = mod.Enums.Callbacks

---@param player EntityPlayer
function mod:RockParry(player)
	-- if params.IsDefensiveStomp then return end
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_TERRA) then return end
	-- local totalrocks = hasBirthright and 8 or 6
	-- local totalrings = hasBirthright and 2 or 1
	-- local shockwaveDamage = (hasBirthright and player.Damage * 1.4 or player.Damage) / 2

	-- for ring = 1, totalrings do
		-- local dist = ring == 1 and 40 or 20
		for rocks = 1, 6 do
			CustomShockwaveAPI:SpawnCustomCrackwave(
				player.Position, -- Position
				player, -- Spawner
				20, -- Steps
				rocks * (360 / 6), -- Angle
				1, -- Delay
				1, -- Limit
				15 -- Damage
			)
		end
	-- end
end
mod:AddCallback(callbacks.PERFECT_PARRY, mod.RockParry)