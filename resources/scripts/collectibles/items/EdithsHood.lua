local mod = edithMod
local enums = mod.Enums
local items = enums.CollectibleType

function mod:ShootSaltTears(tear)
	local player = mod:GetPlayerFromTear(tear)
	
	if not player then return end
	if mod:IsAnyEdith(player) then return end
	if not player:HasCollectible(items.COLLECTIBLE_EDITHS_HOOD) then return end
	
	mod.ForceSaltTear(tear)
end
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, mod.ShootSaltTears)

function mod:HoodStats(player, flags)
	if not player:HasCollectible(items.COLLECTIBLE_EDITHS_HOOD) then return end

	if flags == CacheFlag.CACHE_DAMAGE then
		player.Damage = player.Damage * 1.35
	elseif flags == CacheFlag.CACHE_FIREDELAY then
		player.MaxFireDelay = mod.tearsUp(player.MaxFireDelay, 0.8, true)
	end	
end
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.HoodStats)

local maxCreep = 5	
local saltDegrees = 360 / maxCreep

---@param tear EntityTear
---@param collider Entity
function mod:onKillWithTear(tear, collider)
	local player = mod:GetPlayerFromTear(tear)
	
	if not player then return end 
	if not player:HasCollectible(items.COLLECTIBLE_EDITHS_HOOD) then return end
	if not (collider:IsActiveEnemy() and collider:IsVulnerableEnemy()) then return end
	if collider.HitPoints > tear.CollisionDamage then return end

	local rng = player:GetCollectibleRNG(items.COLLECTIBLE_EDITHS_HOOD)	
	local randomSpawnChance = mod.RandomNumber(1, 5, rng)
	
	if randomSpawnChance ~= 1 then return end
	
	for i = 1, maxCreep do
		mod:SpawnSaltCreep(player, collider.Position + Vector(0, 18):Rotated(saltDegrees*i), 1, 5, 1, "SaltShakerSpawn")
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_TEAR_COLLISION, mod.onKillWithTear)