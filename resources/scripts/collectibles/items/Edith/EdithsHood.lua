local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local EdithsHood = {}

function EdithsHood:ShootSaltTears(tear)
	local player = mod:GetPlayerFromTear(tear)
	
	if not player then return end
	if mod:IsAnyEdith(player) then return end
	if not player:HasCollectible(items.COLLECTIBLE_EDITHS_HOOD) then return end
	
	mod.ForceSaltTear(tear)
end
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, EdithsHood.ShootSaltTears)

function EdithsHood:Stats(player, flags)
	if not player:HasCollectible(items.COLLECTIBLE_EDITHS_HOOD) then return end

	if flags == CacheFlag.CACHE_DAMAGE then
		player.Damage = player.Damage * 1.35
	elseif flags == CacheFlag.CACHE_FIREDELAY then
		player.MaxFireDelay = mod.tearsUp(player.MaxFireDelay, 0.8, true)
	end	
end
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, EdithsHood.Stats)

local maxCreep = 5	
local saltDegrees = 360 / maxCreep

---@param entity Entity
---@param source EntityRef
function EdithsHood:KillingSalEnemy(entity, source)
	if not source.Entity or source.Type == 0 then return end
	local player = mod.GetPlayerFromRef(source)
	if not player then return end
	if not player:HasCollectible(items.COLLECTIBLE_EDITHS_HOOD) then return end
	if not (entity:IsActiveEnemy() and entity:IsVulnerableEnemy()) then return end

	local rng = player:GetCollectibleRNG(items.COLLECTIBLE_EDITHS_HOOD)	
	
	if not mod.RandomBoolean(rng, 0.2) then return end

	for i = 1, maxCreep do
		mod:SpawnSaltCreep(player, entity.Position + Vector(0, 18):Rotated(saltDegrees*i), 1, 5, 1, 3, "Hood")
	end
end
mod:AddCallback(PRE_NPC_KILL.ID, EdithsHood.KillingSalEnemy)