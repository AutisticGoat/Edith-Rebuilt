local mod = edithMod

function edithMod:MoltenCoreStats(player)
	local MoltenCoreCount = player:GetCollectibleNum(edithMod.Enums.CollectibleType.COLLECTIBLE_MOLTEN_CORE)
	if MoltenCoreCount < 1 then return end
	player.Damage = player.Damage + (2.5 * MoltenCoreCount)
end
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, edithMod.MoltenCoreStats, CacheFlag.CACHE_DAMAGE)

function edithMod:MoltenCoreTear(tear)


end
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, edithMod.MoltenCoreTear)