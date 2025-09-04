local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local SulfuricFire = {}

---@param player EntityPlayer
---@return boolean
function SulfuricFire:UseSulfuricFire(_, _, player)
	local Flame
	for _, enemy in pairs(Isaac.FindInRadius(player.Position, 80, EntityPartition.ENEMY)) do
		Flame = Isaac.Spawn(
			EntityType.ENTITY_EFFECT,
			EffectVariant.FIRE_JET,
			0,
			enemy.Position,
			Vector.Zero,
			player
		)		
		Flame.CollisionDamage = player.Damage + (enemy.MaxHitPoints * 0.175)
		enemy:AddBrimstoneMark(EntityRef(player), 150)

		if enemy.HitPoints > Flame.CollisionDamage then goto Continue end
		player:FireBrimstoneBall(enemy.Position, Vector.Zero)
		::Continue::
	end
	return true
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, SulfuricFire.UseSulfuricFire, items.COLLECTIBLE_SULFURIC_FIRE)