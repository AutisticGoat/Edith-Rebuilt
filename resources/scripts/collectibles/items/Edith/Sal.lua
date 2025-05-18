local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local Sal = {}

---@param player EntityPlayer
function Sal:SalSpawnSaltCreep(player)
	if not player:HasCollectible(items.COLLECTIBLE_SAL) then return end
	if player.FrameCount % 15 ~= 0 then return end

	mod:SpawnSaltCreep(player, player.Position, 0, 3, 2, "Sal")
end
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, Sal.SalSpawnSaltCreep)

---@param entity Entity
---@param amount number
---@param source EntityRef
function Sal:KillingSalEnemy(entity, amount, _, source)
	local entityData = mod.GetData(entity)
	if entityData.SalFreeze ~= true then return end
	if entity.HitPoints >= amount then return end

	local Ent = source.Entity
	local player = Ent:ToPlayer() or mod:GetPlayerFromTear(Ent)
	local tear = Ent:ToTear()

	if tear then
		local entTearData = mod.GetData(tear)
		if entTearData.IsSalTear == true then return end
	end

	if not player then return end
	
	local rng = player:GetCollectibleRNG(items.COLLECTIBLE_SAL)
	local randomTears = rng:RandomInt(4, 6)
	
	for _ = 1, randomTears do
		local tears = Isaac.Spawn(EntityType.ENTITY_TEAR, 0, 0, entity.Position, RandomVector() * (player.ShotSpeed * 10), player):ToTear()

		if not tears then return end

		local tearData = mod.GetData(tears)
		
		mod.ForceSaltTear(tears)
		tears:AddTearFlags(TearFlags.TEAR_PIERCING)
		tearData.IsSalTear = true
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, Sal.KillingSalEnemy)