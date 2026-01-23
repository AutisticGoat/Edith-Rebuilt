local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local Helpers = mod.Modules.HELPERS
local Player = mod.Modules.PLAYER
local SulfuricFire = {}

---@param player EntityPlayer
---@return boolean
local function HasSulfuricFireDamageBoost(player)
	return TempStatLib and TempStatLib:GetTempStat(player, "EdithRebuilt_SulfuricFire") ~= nil
end

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
	local baseDamagencrease = 2.5 * JudasMult * CarBatteryMult
	local hitEnemies = 0

	for _, enemy in pairs(Isaac.FindInRadius(player.Position, radius, EntityPartition.ENEMY)) do
		hitEnemies = hitEnemies + 1

		local damage = player.Damage + (enemy.MaxHitPoints * 0.175)
		Helpers.SpawnFireJet(enemy.Position, damage * JudasMult * CarBatteryMult)
		Helpers.TriggerPush(enemy, player, 20)
		enemy:AddBrimstoneMark(ref, 150)		
	end

	if hitEnemies <= 0 then return end

	local StatConfigs = {
        Amount = baseDamagencrease * hitEnemies,
        Duration = 120,
        Stat = CacheFlag.CACHE_DAMAGE,
        Identifier = "EdithRebuilt_SulfuricFire"
    } --[[@as TempStatConfig]]


	mod.TempStatsLib(function(player)
        return mod.SaveManager.GetRunSave(player)
    end)

	TempStatLib:AddTempStat(player, StatConfigs)

	enums.Utils.Game:ShakeScreen(12)
	return true
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, SulfuricFire.UseSulfuricFire, items.COLLECTIBLE_SULFURIC_FIRE)

---@param tear EntityTear
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, function(_, tear)
	local player = Helpers.GetPlayerFromTear(tear)

	if not player then return end
	if not HasSulfuricFireDamageBoost(player) then return end

	tear.Color = Color(1, 0.2, 0.2, 1, 0, 0, 0, 0, 0, 0, 0.34)
end)

---@param ent Entity
---@param source EntityRef
mod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, function (_, ent, source)
	if not ent:ToNPC() then return end

	local player = Helpers.GetPlayerFromRef(source)

	if not player then return end
	if not HasSulfuricFireDamageBoost(player) then return end
	player:FireBrimstoneBall(ent.Position, Vector.Zero)
end)