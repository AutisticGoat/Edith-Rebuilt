local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local utils = enums.Utils
local game = utils.Game
local modules = mod.Modules
local Helpers = modules.HELPERS
local ModRNG = modules.RNG
local Player = modules.PLAYER
local BitMask = modules.BIT_MASK
local sfx = utils.SFX

local DR = {
    DAMAGE_BASE = 40,
    DAMAGE_JUDAS_MULT = 1.5,
}

---@param player EntityPlayer
local function TriggerBadOutcome(player)
    sfx:Play(SoundEffect.SOUND_THUMBS_DOWN)
    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 1, player.Position, Vector.Zero, nil)
end

---@param hasCarBattery boolean
---@param isJudasWithBirthright boolean
---@return number
local function GetRetributionDamage(hasCarBattery, isJudasWithBirthright)
    local base = hasCarBattery and DR.DAMAGE_BASE * 2 or DR.DAMAGE_BASE
    return base * (isJudasWithBirthright and DR.DAMAGE_JUDAS_MULT or 1)
end

---@param player EntityPlayer
---@param hasCarBattery boolean
---@param isJudasWithBirthright boolean
local function HealPlayer(player, hasCarBattery, isJudasWithBirthright)
    local heartsToAdd = hasCarBattery and 4 or 2
    local healFunc = isJudasWithBirthright and player.AddBlackHearts or player.AddSoulHearts
    healFunc(player, heartsToAdd)
end

---@param player EntityPlayer
---@param isJudasWithBirthright boolean
---@return boolean
local function TriggerGoodOutcome(player, isJudasWithBirthright)
    local roomEnemies = Helpers.GetEnemies()
    if #roomEnemies <= 0 then return false end

    local hasCarBattery = player:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY)

    HealPlayer(player, hasCarBattery, isJudasWithBirthright)

    sfx:Play(isJudasWithBirthright and SoundEffect.SOUND_UNHOLY or SoundEffect.SOUND_SUPERHOLY)

    local damage = GetRetributionDamage(hasCarBattery, isJudasWithBirthright)
    for _, enemy in pairs(roomEnemies) do
        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 10, enemy.Position, Vector.Zero, nil)
        enemy:TakeDamage(damage, DamageFlag.DAMAGE_LASER, EntityRef(player), 0)
    end
    return true
end

---@param rng RNG
---@param player EntityPlayer
---@param flags UseFlag
---@return boolean?
mod:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, _, rng, player, flags)
    if BitMask.HasBitFlags(flags, UseFlag.USE_CARBATTERY --[[@as BitSet128]]) then return end

    local isJudasWithBirthright = Player.IsJudasWithBirthright(player)

    if ModRNG.RandomBoolean(rng) then
        TriggerBadOutcome(player)
    else
        if not TriggerGoodOutcome(player, isJudasWithBirthright) then return end
    end

    game:ShakeScreen(DR.SHAKE_INTENSITY)
    return true
end, items.COLLECTIBLE_DIVINE_RETRIBUTION)