local mod = edithMod
local enums = mod.Enums
local items = enums.CollectibleType
local utils = enums.Utils
local game = utils.Game
local sfx = utils.SFX

local DivineRetribution = {}

---@return Entity[]
local function GetRoomEnemies()
	local roomEntities = Isaac.GetRoomEntities()
	local enemies = {}
	for _, ent in ipairs(roomEntities) do
		if ent:IsActiveEnemy() and ent:IsVulnerableEnemy() then
			table.insert(enemies, ent)
		end
	end
	return enemies
end

---@param rng RNG
---@param player EntityPlayer
---@param flags UseFlag
---@return boolean?
function DivineRetribution:OnDRUse(_, rng, player, flags)
    local CarBatteryUse = (flags == flags | UseFlag.USE_CARBATTERY)
    if CarBatteryUse then return end

    local remainingHits = TSIL.Players.GetPlayerNumHitsRemaining(player)

    if (mod:isChap4() and remainingHits == 2) or remainingHits == 1 then return end
    local BlessChance = rng:RandomInt(2)

    if BlessChance == 0 then
        sfx:Play(SoundEffect.SOUND_THUMBS_DOWN, 1, 0, false, 1, 0)
        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 1, player.Position, Vector.Zero, nil)
    else
        local enemiesCount = GetRoomEnemies()
        if #enemiesCount <= 0 then return end
        local Hascarbattery = player:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY)

        player:AddSoulHearts(1)

        sfx:Play(SoundEffect.SOUND_SUPERHOLY, 1, 0, false, 1, 0)
        for _, enemies in pairs(enemiesCount) do
            Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 10, enemies.Position, Vector.Zero, nil)
            enemies:TakeDamage(Hascarbattery and 40 or 20, DamageFlag.DAMAGE_LASER | DamageFlag.DAMAGE_NO_PENALTIES, EntityRef(player), 0)
        end
    end
    game:ShakeScreen(10)
    return true
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, DivineRetribution.OnDRUse, items.COLLECTIBLE_DIVINE_RETRIBUTION)