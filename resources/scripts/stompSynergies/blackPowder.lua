local mod = EdithRebuilt
local callbacks = mod.Enums.Callbacks
local data = mod.DataHolder.GetEntityData
local Creeps = mod.Modules.CREEPS

---@param player EntityPlayer
function mod:BlackPowderStomp(player)
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_BLACK_POWDER) then return end	
	if player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_BLACK_POWDER):RandomInt(1, 3) ~= 1 then return end
	local distance = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and 90 or 70
	Creeps.SpawnBlackPowder(player, 20, player.Position, distance)
end
mod:AddCallback(callbacks.OFFENSIVE_STOMP, mod.BlackPowderStomp)

function mod:Stuff(effect)
	if data(effect).CustomSpawn == true then return end
	effect.Visible = false
	effect:Remove()
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.Stuff, EffectVariant.PLAYER_CREEP_BLACKPOWDER)