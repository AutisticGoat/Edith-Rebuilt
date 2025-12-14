local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local utils = enums.Utils
local game = utils.Game
local MoltenCore = {}
local Helpers = mod.Modules.HELPERS
local data = mod.CustomDataWrapper.getData

function MoltenCore:MoltenCoreStats(player)
	local MoltenCoreCount = player:GetCollectibleNum(items.COLLECTIBLE_MOLTEN_CORE)
	if MoltenCoreCount < 1 then return end
	player.Damage = player.Damage + (1 * MoltenCoreCount)
end
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, MoltenCore.MoltenCoreStats, CacheFlag.CACHE_DAMAGE)

---@param player EntityPlayer
function MoltenCore:MoltenCoreUpdate(player)
	if not player:HasCollectible(items.COLLECTIBLE_MOLTEN_CORE) then return end

	for _, enemy in ipairs(Isaac.FindInRadius(player.Position, 60, EntityPartition.ENEMY)) do
		if not Helpers.IsEnemy(enemy) then goto continue end
		data(enemy).IsInCoreRadius = true

		local CoreCount = data(enemy).CoreCount
		local Formula = math.min(player.Damage * (CoreCount / 50), player.Damage * 2)
		
		if Formula < player.Damage * 2 then
			local Red = 0.5 * CoreCount / 125
			local Green = 0.125 * CoreCount / 125 
			enemy.Color = Color(1, 1, 1, 1, Red, Green)
		end

		if CoreCount % 15 ~= 0 then goto continue end

		enemy:TakeDamage(Formula, DamageFlag.DAMAGE_FIRE, EntityRef(player), 0)
		::continue::
	end 
end	
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, MoltenCore.MoltenCoreUpdate)

---@param npc EntityNPC
function MoltenCore:NPCUpdate(npc)
	local npcData = data(npc)

	if not npcData.IsInCoreRadius then 
		npcData.CoreCount = 0 
		npc.Color = Color.Default
		return
	end

	npcData.CoreCount = npcData.CoreCount or 0
	npcData.CoreCount = npcData.CoreCount + 1
	npcData.IsInCoreRadius = false
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, MoltenCore.NPCUpdate)

---@param entity Entity
---@param source EntityRef
function MoltenCore:KillingSalEnemy(entity, source)
	local player = Helpers.GetPlayerFromRef(source)
	local entData = data(entity)

	if not player then return end
	if not player:HasCollectible(items.COLLECTIBLE_MOLTEN_CORE) then return end
	if not Helpers.IsEnemy(entity) then return end
	if not entData.IsInCoreRadius then return end

	Helpers.SpawnFireJet(player, entity.Position, player.Damage * 2.5, 1, 1)
end
mod:AddCallback(PRE_NPC_KILL.ID, MoltenCore.KillingSalEnemy)
