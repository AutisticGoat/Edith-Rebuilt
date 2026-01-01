local mod = EdithRebuilt
local enums = mod.Enums
local modules = mod.Modules
local effects = enums.EdithStatusEffects
local StsEffects = modules.STATUS_EFFECTS
local Helpers = modules.HELPERS
local ModRNG = modules.RNG
local SpicesMix = {}
local data = mod.DataHolder.GetEntityData

local Descriptions = {
    [effects.SALTED] = "Slow and weakness, chance to destroy enemy's shots",
    [effects.PEPPERED] = "Enemies sneezes every 2nd hit, leaving damaging creep",
    [effects.GARLIC] = "The enemies retreat, scattered shots",
    [effects.OREGANO] = "Slower enemies, slowing creep",
    [effects.CUMIN] = "Erratic movement, damaging enemies stops them",
    [effects.TURMERIC] = "Weaker enemies, infecting clouds on hit",
    [effects.CINNAMON] = "Cosntant damage over time",
    [effects.GINGER] = "More pushable enemies, infecting clouds on kill",
}

---@param _ any
---@param RNG RNG
---@param player EntityPlayer
function SpicesMix:OnSpicesMixUse(_, RNG, player)
    local data = StsEffects.GetRandomSpiceEffect(RNG)
    local RandCol = data.Color
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

    Game():GetHUD():ShowItemText(data.ID, Descriptions[data.ID])

    return true
end 
mod:AddCallback(ModCallbacks.MC_USE_ITEM, SpicesMix.OnSpicesMixUse, enums.CollectibleType.COLLECTIBLE_SPICES_MIX)