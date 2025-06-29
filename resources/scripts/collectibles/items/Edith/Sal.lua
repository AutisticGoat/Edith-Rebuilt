local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local data = mod.CustomDataWrapper.getData
local Sal = {}

---@param player EntityPlayer
function Sal:SalSpawnSaltCreep(player)
	if not player:HasCollectible(items.COLLECTIBLE_SAL) then return end
	if player.FrameCount % 15 ~= 0 then return end

	local rng = player:GetCollectibleRNG(items.COLLECTIBLE_SAL)
	local randomGib = {
		amount = rng:RandomInt(2, 5),
		speed = rng:RandomInt(100, 250) / 100
	}
	mod:SpawnSaltCreep(player, player.Position, 0, 3, randomGib.amount, randomGib.speed, "Sal", true, true)
end
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, Sal.SalSpawnSaltCreep)

---@param entity Entity
---@param amount number
---@param source EntityRef
function Sal:KillingSalEnemy(entity, amount, _, source)
	local entityData = data(entity)
	if entityData.SalFreeze ~= true then return end
	if entity.HitPoints >= amount then return end

	local Ent = source.Entity
	local player = mod.GetPlayerFromRef(source)
		
	if not player then return end
	if not player:HasCollectible(items.COLLECTIBLE_SAL) then return end

	if Ent then
		local tear = Ent:ToTear()
		local entTearData = data(tear)
		if entTearData.IsSalTear == true then return end
	end
	
	local rng = player:GetCollectibleRNG(items.COLLECTIBLE_SAL)
	local randomTears = rng:RandomInt(4, 6)
	
	for _ = 1, randomTears do
		local tears = Isaac.Spawn(EntityType.ENTITY_TEAR, 0, 0, entity.Position, RandomVector() * (player.ShotSpeed * 10), player):ToTear()

		if not tears then return end

		local tearData = data(tears)
		
		mod.ForceSaltTear(tears)
		tears:AddTearFlags(TearFlags.TEAR_PIERCING)
		tearData.IsSalTear = true
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, Sal.KillingSalEnemy)