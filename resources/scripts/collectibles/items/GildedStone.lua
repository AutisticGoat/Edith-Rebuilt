local mod = edithMod
local utils = edithMod.Enums.Utils
local room = utils.Room

function mod:GildedStoneStats(player, flags)
	local MoltenCoreCount = player:GetCollectibleNum(edithMod.Enums.CollectibleType.COLLECTIBLE_GILDED_STONE)
	if MoltenCoreCount < 1 then return end

	local cacheActions = {
		[CacheFlag.CACHE_DAMAGE] = function()
			player.Damage = player.Damage * 1.2
		end,
		[CacheFlag.CACHE_SPEED] = function()
			player.MoveSpeed = player.MoveSpeed - 0.175
		end,
	}
	edithMod.SwitchCase(flags, cacheActions)
end
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.GildedStoneStats)

-- function mod:ReplaceRocks()
	-- local gridSize = room:GetGridSize()
	
	-- for i = 0, gridSize do
		-- local gent = room:GetGridEntity(i)
		
		-- if gent then
			-- if gent:GetType() == GridEntityType.GRID_ROCK then
				-- local rock = gent:ToRock()
				-- print("piedra")
			-- end
		-- end
	-- end
-- end
-- mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.ReplaceRocks)