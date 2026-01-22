local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local Helpers = mod.Modules.HELPERS
local Player = mod.Modules.PLAYER
local SulfuricFire = {}

---@param player EntityPlayer
---@param flag UseFlag
---@return boolean?
function SulfuricFire:UseSulfuricFire(_, _, player, flag)
	if flag & UseFlag.USE_CARBATTERY == UseFlag.USE_CARBATTERY then return end
	local ref = EntityRef(player)
	local IsJudasWithBirthright = Player.IsJudasWithBirthright(player)
	local HasCarBattery = player:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY) 
	local radius = IsJudasWithBirthright and 150 or 100 
	local JudasMult = IsJudasWithBirthright and 1.5 or 1
	local CarBatteryMult = HasCarBattery and 1.25 or 1

	for _, enemy in pairs(Isaac.FindInRadius(player.Position, radius, EntityPartition.ENEMY)) do
		local damage = player.Damage + (enemy.MaxHitPoints * 0.175)
		local Flame = Helpers.SpawnFireJet(enemy.Position, (damage * JudasMult) * CarBatteryMult)
		

		enemy:AddBrimstoneMark(ref, 150)

		if enemy.HitPoints > Flame.CollisionDamage then goto Continue end
		player:FireBrimstoneBall(enemy.Position, Vector.Zero)
		::Continue::
	end

	enums.Utils.Game:ShakeScreen(12)
	return true
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, SulfuricFire.UseSulfuricFire, items.COLLECTIBLE_SULFURIC_FIRE)