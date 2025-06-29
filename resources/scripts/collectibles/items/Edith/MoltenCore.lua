local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local utils = enums.Utils
local game = utils.Game
local MoltenCore = {}
local data = mod.CustomDataWrapper.getData

function MoltenCore:MoltenCoreStats(player)
	local MoltenCoreCount = player:GetCollectibleNum(items.COLLECTIBLE_MOLTEN_CORE)
	if MoltenCoreCount < 1 then return end
	player.Damage = player.Damage + (0.8 * MoltenCoreCount)
end

mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, MoltenCore.MoltenCoreStats, CacheFlag.CACHE_DAMAGE)

---@param tear EntityTear
function MoltenCore:OnFiringTears(tear)
	local player = mod:GetPlayerFromTear(tear)

	if not (player and player:HasCollectible(items.COLLECTIBLE_MOLTEN_CORE)) then return end

	local tearData = data(tear)

	tear:ChangeVariant(TearVariant.FIRE_MIND)
	mod:ChangeColor(tear, 0.8, 0.5, 0.4)
	tearData.MoltenCoreTear = true
end

mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, MoltenCore.OnFiringTears)

---@param entity Entity
---@param amount number
---@param source EntityRef
function MoltenCore:KillingSalEnemy(entity, amount, _, source)
	local Ent = source.Entity
	if not Ent or Ent.Type == 0 then return end
	local player = Ent:ToPlayer() or mod:GetPlayerFromTear(Ent)

	if not (player and player:HasCollectible(items.COLLECTIBLE_MOLTEN_CORE)) then return end
	if not (entity:IsActiveEnemy() and entity:IsVulnerableEnemy()) then return end

	entity:AddBurn(source, 120, 1)

	if entity.HitPoints > amount then return end

	local nearEnemies = Isaac.FindInRadius(entity.Position, 60, EntityPartition.ENEMY)
	for _, enemies in pairs(nearEnemies) do
		local Jet = Isaac.Spawn(
			EntityType.ENTITY_EFFECT,
			EffectVariant.FIRE_JET,
			0,
			enemies.Position,
			Vector.Zero,
			player
		)

		Jet.CollisionDamage = player.Damage
		enemies:AddBurn(source, 120, 1)

		if #nearEnemies >= 5 then
			game:ShakeScreen(10)
		end
	end
end

mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, MoltenCore.KillingSalEnemy)
