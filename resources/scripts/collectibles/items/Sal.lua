local mod = edithMod
local enums = mod.Enums
local items = enums.CollectibleType
local utils = enums.Utils
local game = utils.Game 

---comment
---@param player EntityPlayer
function mod:SalSpawnSaltCreep(player)
	if not player:HasCollectible(items.COLLECTIBLE_SAL) then return end
	local shouldSpawnSalt = game:GetFrameCount() % 15 == 0

	if not shouldSpawnSalt then return end
	mod:SpawnSaltCreep(player, player.Position, 1, 3, 2, "Sal")
end
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, mod.SalSpawnSaltCreep)

---comment
---@param entity Entity
---@param amount number
---@param source EntityRef
function mod:KillingSalEnemy(entity, amount, _, source)
	local entityData = edithMod:GetData(entity)
	if entityData.SalFreeze ~= true then return end
	if entity.HitPoints >= amount then return end

	local Ent = source.Entity
	local player = Ent:ToPlayer() or edithMod:GetPlayerFromTear(Ent)
	local tear = Ent:ToTear()

	if tear then
		local entTearData = edithMod:GetData(tear)
		if entTearData.IsSalTear == true then return end
	end

	if not player then return end
	
	local rng = player:GetCollectibleRNG(items.COLLECTIBLE_SAL)
	local randomTears = rng:RandomInt(4, 6)
	
	for _ = 1, randomTears do
		local tears = player:FireTear(entity.Position, RandomVector() * (player.ShotSpeed * 10), false, false, false, player, 1)
		local tearData = edithMod:GetData(tears)
		
		tears:AddTearFlags(TearFlags.TEAR_PIERCING)
		tearData.IsSalTear = true
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.KillingSalEnemy)