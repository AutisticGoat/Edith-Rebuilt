local mod = EdithRebuilt
local callbacks = mod.Enums.Callbacks
local data = mod.CustomDataWrapper.getData

-- I need to think about something different

---@param player EntityPlayer
mod:AddCallback(callbacks.PERFECT_PARRY, function(_, player)
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_KNIFE) then return end		

	local knifeEntities = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and 8 or 4
	local degrees = 360/knifeEntities
	local knife

	for i = 1, knifeEntities do
		knife = player:FireKnife(player, degrees * i, true, 0, 0)
		knife:Shoot(1, player.TearRange / 3)
		data(knife).ParryKnife = true			
	end
end)

---@param knife EntityKnife
function mod:RemoveKnife(knife)	
	if not data(knife).ParryKnife then return end
	if knife:IsFlying() then return end 

	knife:Remove()
end
mod:AddCallback(ModCallbacks.MC_POST_KNIFE_UPDATE, mod.RemoveKnife)