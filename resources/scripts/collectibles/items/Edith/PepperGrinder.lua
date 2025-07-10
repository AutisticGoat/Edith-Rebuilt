local mod = EdithRebuilt
local sfx = mod.Enums.Utils.SFX
local data = mod.CustomDataWrapper.getData
local PepperGrinder = {}

---@param RNG RNG
---@param player EntityPlayer
---@return boolean
function PepperGrinder:UsePepperGrinder(_, RNG, player)
	local SoundPitch = RNG:RandomInt(90, 110) / 100
	local playerPos = player.Position

	for _, enemy in ipairs(Isaac.FindInRadius(playerPos, 100, EntityPartition.ENEMY)) do
		mod.TriggerPush(enemy, player, 20, 3, false)
		data(enemy).PepperFrames = 60
	end
	
	local PepperCloud = Isaac.Spawn(
        EntityType.ENTITY_EFFECT,
        EffectVariant.POOF02,
        2,
        playerPos,
        Vector.Zero,
        nil
    )

	mod:ChangeColor(PepperCloud, 0.45, 0.45, 0.45)
	sfx:Play(mod.Enums.SoundEffect.SOUND_PEPPER_GRINDER, 10, 0, false, SoundPitch, 0)		
	return true
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, PepperGrinder.UsePepperGrinder, mod.Enums.CollectibleType.COLLECTIBLE_PEPPERGRINDER)

---@param entity EntityNPC
function PepperGrinder:myFunction2(entity) 
	local enemyData = data(entity)
	
	if not enemyData.PepperFrames then return end
	if enemyData.PepperFrames < 1 then return end
	
	enemyData.PepperFrames = enemyData.PepperFrames - 1
	
	if enemyData.PepperFrames % 10 ~= 0 then return end		
	mod:SpawnPepperCreep(entity, entity.Position, 1, 0.6)
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, PepperGrinder.myFunction2)
