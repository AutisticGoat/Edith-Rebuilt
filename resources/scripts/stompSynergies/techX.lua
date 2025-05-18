local mod = EdithRebuilt
local funcs = require("resources.scripts.stompSynergies.Funcs")
local EdithJump = require("resources.scripts.stompSynergies.JumpData")

---@param player EntityPlayer
function mod:TechXStomp(player)
	if funcs.KeyStompPressed(player) then return end
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_TECH_X) then return end
	local techXDistance = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and 65 or 50
	local LaserDamage = (techXDistance/100) + 0.25
	local techX = player:FireTechXLaser(player.Position, Vector.Zero, techXDistance, player, LaserDamage)

	techX.DisableFollowParent = true
---@diagnostic disable-next-line: param-type-mismatch
	techX:SetTimeout(17) 
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, mod.TechXStomp, EdithJump)