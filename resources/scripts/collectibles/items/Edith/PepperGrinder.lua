local mod = edithMod
local sfx = mod.Enums.Utils.SFX

---@param RNG RNG
---@param player EntityPlayer
---@return boolean
function mod:UsePepperGrinder(_, RNG, player)
	local SoundPitch = mod.RandomNumber(0.9, 1.1, RNG)

	for _, enemy in ipairs(Isaac.FindInRadius(player.Position, 100, EntityPartition.ENEMY)) do
		local enemyData = mod.GetData(enemy)
		enemy.Velocity = (enemy.Position - player.Position):Resized(20)
		enemyData.PepperFrames = 60
	end
	
	sfx:Play(mod.Enums.SoundEffect.SOUND_PEPPER_GRINDER, 10, 0, false, SoundPitch, 0)
		
	return true
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.UsePepperGrinder, mod.Enums.CollectibleType.COLLECTIBLE_PEPPERGRINDER)

---@param entity EntityNPC
function mod:myFunction2(entity) 
	local enemyData = mod.GetData(entity)
	
	if not enemyData.PepperFrames then return end
	if enemyData.PepperFrames < 1 then return end
	
	enemyData.PepperFrames = enemyData.PepperFrames - 1
	
	if enemyData.PepperFrames % 10 ~= 0 then return end		
	mod:SpawnPepperCreep(entity, entity.Position, 1, 0.6)
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.myFunction2)
