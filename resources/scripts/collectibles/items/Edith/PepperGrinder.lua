local mod = EdithRebuilt
local sfx = mod.Enums.Utils.SFX
local data = mod.CustomDataWrapper.getData
local PepperGrinder = {}

---@param RNG RNG
---@param player EntityPlayer
---@return boolean?
function PepperGrinder:UsePepperGrinder(_, RNG, player, flag)
	if flag & UseFlag.USE_CARBATTERY == UseFlag.USE_CARBATTERY then return end
    local hasCarBattery = player:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY) 
	local SoundPitch = mod.RandomFloat(RNG, 0.9, 1.1)
	local playerPos = player.Position
	local frames = hasCarBattery and 120 or 60

	for _, enemy in ipairs(Isaac.FindInRadius(playerPos, 100, EntityPartition.ENEMY)) do
		mod.TriggerPush(enemy, player, 20, 3, false)
		mod.PepperEnemy(enemy, player, frames)
		data(enemy).Player = player
	end
	
	local PepperCloud = Isaac.Spawn(
        EntityType.ENTITY_EFFECT,
        EffectVariant.POOF02,
        2,
        playerPos,
        Vector.Zero,
        nil
    )
	local X = mod.RandomFloat(RNG, 0.8, 1)
	local Y = mod.RandomFloat(RNG, 0.8, 1)

	PepperCloud.SpriteScale = PepperCloud.SpriteScale * Vector(X, Y)

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
	mod:SpawnPepperCreep(data(entity).Player, entity.Position, 0.5, 3)
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, PepperGrinder.myFunction2)