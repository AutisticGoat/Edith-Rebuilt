local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local utils = enums.Utils
local game = utils.Game
local sfx = utils.SFX
local DivineRetribution = {}

---@param rng RNG
---@param player EntityPlayer
---@param flags UseFlag
---@return boolean?
function DivineRetribution:OnDRUse(_, rng, player, flags)
    local CarBatteryUse = (flags == flags | UseFlag.USE_CARBATTERY)
    if CarBatteryUse then return end

    local remainingHits = TSIL.Players.GetPlayerNumHitsRemaining(player)

    if (mod:isChap4() and remainingHits == 2) or remainingHits == 1 then return end

    if mod.RandomBoolean(rng) then
        sfx:Play(SoundEffect.SOUND_THUMBS_DOWN)
        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 1, player.Position, Vector.Zero, nil)
    else
        local enemiesCount = mod.GetEnemies()
        if #enemiesCount <= 0 then return end
        local Hascarbattery = player:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY)

        player:AddSoulHearts(1)

        sfx:Play(SoundEffect.SOUND_SUPERHOLY)
        for _, enemies in pairs(enemiesCount) do
            Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 10, enemies.Position, Vector.Zero, nil)
            enemies:TakeDamage(Hascarbattery and 50 or 25, DamageFlag.DAMAGE_LASER, EntityRef(player), 0)
        end
    end
    game:ShakeScreen(10)
    return true
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, DivineRetribution.OnDRUse, items.COLLECTIBLE_DIVINE_RETRIBUTION)