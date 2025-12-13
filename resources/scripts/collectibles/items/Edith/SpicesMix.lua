local mod = EdithRebuilt
local enums = mod.Enums
local modules = mod.Modules
local effects = enums.EdithStatusEffects
local StsEffects = modules.STATUS_EFFECTS
local Helpers = modules.HELPERS
local ModRNG = modules.RNG
local SpicesMix = {}

---@param _ any
---@param RNG RNG
---@param player EntityPlayer
function SpicesMix:OnSpicesMixUse(_, RNG, player)
    local data = StsEffects.GetRandomSpiceEffect(RNG)

    RandCol = data.Color

    local Puff = Isaac.Spawn(
        EntityType.ENTITY_EFFECT,
        EffectVariant.POOF02,
        2,
        player.Position,
        Vector.Zero,
        player
    )

    Puff:GetSprite().PlaybackSpeed = ModRNG.RandomFloat(RNG, 0.9, 1.1)

    local X = ModRNG.RandomFloat(RNG, 0.85, 1.15)
    local Y = ModRNG.RandomFloat(RNG, 0.85, 1.15)

    Puff.SpriteScale = Vector(X, Y)

    enums.Utils.SFX:Play(SoundEffect.SOUND_SUMMON_POOF, 1, 0, false, ModRNG.RandomFloat(RNG, 0.8, 1.2))

    local newColor = data.ID == "Salted" and RandCol or Color(RandCol.RO, RandCol.GO, RandCol.BO)

    Puff:SetColor(newColor, -1, 1000, false, false)

    for _, enemy in ipairs(Isaac.FindInRadius(player.Position, 60, EntityPartition.ENEMY)) do
        if not Helpers.IsEnemy(enemy) then goto continue end
        StsEffects.SetStatusEffect(data.ID, enemy, data.Duration, player)
        ::continue::
    end

    return true
end 
mod:AddCallback(ModCallbacks.MC_USE_ITEM, SpicesMix.OnSpicesMixUse, enums.CollectibleType.COLLECTIBLE_SPICES_MIX)