local mod = edithMod
local enums = mod.Enums
local items = enums.CollectibleType
local SulfuricFire = {}
local RangeUse = 80

---@param player EntityPlayer
---@return boolean
function SulfuricFire:UseSulfuricFire(_, _, player)
	for _, enemy in pairs(Isaac.FindInRadius(player.Position, RangeUse, EntityPartition.ENEMY)) do
		local Flame = Isaac.Spawn(
			EntityType.ENTITY_EFFECT,
			EffectVariant.FIRE_JET,
			0,
			enemy.Position,
			Vector.Zero,
			player
		)
		
		local enemyMaxHP = enemy.MaxHitPoints
		local damageFormula = player.Damage + (enemyMaxHP * 0.15)
		local enemyHP = enemy.HitPoints
		
		Flame.CollisionDamage = player.Damage + damageFormula
		enemy:AddBrimstoneMark(EntityRef(player), 150)
		
		if enemyHP <= Flame.CollisionDamage then
			player:FireBrimstoneBall(enemy.Position, Vector.Zero)
		end
	end
	return true
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, SulfuricFire.UseSulfuricFire, items.COLLECTIBLE_SULFURIC_FIRE)
