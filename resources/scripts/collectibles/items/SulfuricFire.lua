local RangeUse = 80

function edithMod:UseSulfuricFire(Id, RNG, player, flags, slot, data)
	for i, enemy in pairs(Isaac.FindInRadius(player.Position, RangeUse, EntityPartition.ENEMY)) do
		local Flame = Isaac.Spawn(
			EntityType.ENTITY_EFFECT,
			EffectVariant.FIRE_JET,
			0,
			enemy.Position,
			Vector.Zero,
			player
		):ToEffect()
		
		local enemyMaxHP = enemy.MaxHitPoints
		local damageFormula = player.Damage + (enemyMaxHP * 0.15)
		local enemyHP = enemy.HitPoints
		
		Flame.CollisionDamage = damageFormula		
		enemy:AddBrimstoneMark(EntityRef(player), 150)
		
		if enemyHP <= Flame.CollisionDamage then
			local brimBall = player:FireBrimstoneBall(enemy.Position, Vector.Zero)
		end
	end
	return true
end
