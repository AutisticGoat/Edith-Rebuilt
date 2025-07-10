local mod = EdithRebuilt
local funcs = require("resources.scripts.stompSynergies.Funcs")
local EdithJump = require("resources.scripts.stompSynergies.JumpData")

function mod:KnifeStomp(player)
	if funcs.DefensiveStomp(player) then return end
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_KNIFE) then return end		
	
	local knifeEntities = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and 8 or 4
	local degrees = 360/knifeEntities
	local knife		

	for i = 1, knifeEntities do
		knife = player:FireKnife(player, degrees * i, true, 0, 0)
		
		funcs.GetData(knife).StompKnife = true			
		knife:Shoot(1, player.TearRange / 3)
	end
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, mod.KnifeStomp, EdithJump)

---@param knife EntityKnife
function mod:RemoveKnife(knife)	
	if funcs.GetData(knife).StompKnife ~= true then return end
	if knife:IsFlying() then return end 
	
	knife:Remove()
end
mod:AddCallback(ModCallbacks.MC_POST_KNIFE_UPDATE, mod.RemoveKnife)