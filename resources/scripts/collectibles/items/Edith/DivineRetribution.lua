local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local utils = enums.Utils
local game = utils.Game
local modules = mod.Modules
local Helpers = modules.HELPERS
local ModRNG = modules.RNG
local sfx = utils.SFX
local DivineRetribution = {}

---@param rng RNG
---@param player EntityPlayer
---@param flags UseFlag
---@return boolean?
function DivineRetribution:OnDRUse(_, rng, player, flags)
    if mod.HasBitFlags(flags, UseFlag.USE_CARBATTERY) then return end
    local IsJudasWithBirthright = mod.IsJudasWithBirthright(player)

    if ModRNG.RandomBoolean(rng) then
        sfx:Play(SoundEffect.SOUND_THUMBS_DOWN)
        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 1, player.Position, Vector.Zero, nil)
    else
        local roomEnemies = Helpers.GetEnemies()
        if #roomEnemies <= 0 then return end
        local Hascarbattery = player:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY)
        local damage = (Hascarbattery and 50 or 25) * (IsJudasWithBirthright and 1.5 or 1)
        local healFunc = IsJudasWithBirthright and player.AddBlackHearts or player.AddSoulHearts
        healFunc(player, 1)
        local sound = IsJudasWithBirthright and SoundEffect.SOUND_UNHOLY or SoundEffect.SOUND_SUPERHOLY

        sfx:Play(sound)
        for _, enemies in pairs(roomEnemies) do
            Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 10, enemies.Position, Vector.Zero, nil)
            enemies:TakeDamage(damage, DamageFlag.DAMAGE_LASER, EntityRef(player), 0)
        end
    end
    game:ShakeScreen(15)
    return true
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, DivineRetribution.OnDRUse, items.COLLECTIBLE_DIVINE_RETRIBUTION)