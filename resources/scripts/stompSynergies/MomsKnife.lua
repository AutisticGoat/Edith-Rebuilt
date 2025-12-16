local mod = EdithRebuilt
local callbacks = mod.Enums.Callbacks
local data = mod.CustomDataWrapper.getData

---@param player EntityPlayer
---@param params EdithJumpStompParams
function mod:KnifeStomp(player, params)
	if params.IsDefensiveStomp then return end
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_KNIFE) then return end		

	local knifeEntities = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and 8 or 4
	local degrees = 360/knifeEntities
	local knife		

	for i = 1, knifeEntities do
		knife = player:FireKnife(player, degrees * i, true, 0, 0)
		knife:Shoot(1, player.TearRange / 3)
		data(knife).StompKnife = true			
	end
end
mod:AddCallback(callbacks.OFFENSIVE_STOMP, mod.KnifeStomp)

---@param knife EntityKnife
function mod:RemoveKnife(knife)	
	if not data(knife).StompKnife then return end
	if knife:IsFlying() then return end 

	knife:Remove()
end
mod:AddCallback(ModCallbacks.MC_POST_KNIFE_UPDATE, mod.RemoveKnife)