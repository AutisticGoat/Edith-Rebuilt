local mod = EdithRebuilt
local sfx = mod.Enums.Utils.SFX
local data = mod.CustomDataWrapper.getData
local modules = mod.Modules
local herlpers = modules.HELPERS
local ModRNG = modules.RNG
local PepperGrinder = {}

---@param RNG RNG
---@param player EntityPlayer
---@return boolean?
function PepperGrinder:UsePepperGrinder(_, RNG, player, flag)
	if flag & UseFlag.USE_CARBATTERY == UseFlag.USE_CARBATTERY then return end
    local hasCarBattery = player:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY) 
	local playerPos = player.Position
	local frames = hasCarBattery and 120 or 60

	for _, enemy in ipairs(Isaac.FindInRadius(playerPos, 100, EntityPartition.ENEMY)) do
		herlpers.TriggerPush(enemy, player, 20)
		mod.SetPeppered(enemy, frames, player)
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
	local X = ModRNG.RandomFloat(RNG, 0.8, 1)
	local Y = ModRNG.RandomFloat(RNG, 0.8, 1)

	PepperCloud.SpriteScale = PepperCloud.SpriteScale * Vector(X, Y)

	mod:ChangeColor(PepperCloud, 0.4, 0.4, 0.4)
	sfx:Play(mod.Enums.SoundEffect.SOUND_PEPPER_GRINDER, 10, 0, false, ModRNG.RandomFloat(RNG, 0.9, 1.1))
	return true
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, PepperGrinder.UsePepperGrinder, mod.Enums.CollectibleType.COLLECTIBLE_PEPPERGRINDER)