local mod = EdithRebuilt
local funcs = require("resources.scripts.stompSynergies.Funcs")
local EdithJump = require("resources.scripts.stompSynergies.JumpData")

---@param player EntityPlayer
function mod:BlackPowderStomp(player)
	if funcs.DefensiveStomp(player) then return end
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_BLACK_POWDER) then return end	
	if player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_BLACK_POWDER):RandomInt(1, 3) ~= 1 then return end
	local distance = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and 90 or 70
	mod:SpawnBlackPowder(player, 20, player.Position, distance)
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, mod.BlackPowderStomp, EdithJump)

function mod:Stuff(effect)
	if funcs.GetData(effect).CustomSpawn == true then return end
	effect.Visible = false
	effect:Remove()
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.Stuff, EffectVariant.PLAYER_CREEP_BLACKPOWDER)