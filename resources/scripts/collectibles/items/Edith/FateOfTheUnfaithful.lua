local mod = EdithRebuilt
local enums = mod.Enums
local utils = enums.Utils
local game, sfx = utils.Game, utils.SFX
local items = enums.CollectibleType
local modules = mod.Modules
local ModRNG = modules.RNG
local Helpers = modules.HELPERS
local FOTU = {}

---@param rng RNG
---@param player EntityPlayer
---@param flag UseFlag
---@return boolean?
function FOTU:OnFatefulUse(_, rng, player, flag)
    if mod.HasBitFlags(flag, UseFlag.USE_CARBATTERY) then return end
    local Hascarbattery = player:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY) 
    local playerPos = player.Position

    for _, ent in ipairs(Helpers.GetEnemies()) do
        ent:AddBurn(EntityRef(player), 83, Hascarbattery and 3 or 1.5)
        ent:AddBrimstoneMark(EntityRef(player), Hascarbattery and 180 or 90)

        if playerPos:Distance(ent.Position) > 50 then goto Break end
        mod.TriggerPush(ent, player, 20, 5, false)
        ::Break::
    end

    game:ShakeScreen(10)
    sfx:Play(SoundEffect.SOUND_FIREDEATH_HISS, 1, 0, false, ModRNG.RandomFloat(rng, 0.95, 1.05))
    return true
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, FOTU.OnFatefulUse, items.COLLECTIBLE_FATE_OF_THE_UNFAITHFUL)

---@param player EntityPlayer
function FOTU:FateCache(player)
    if not player:GetEffects():GetCollectibleEffect(items.COLLECTIBLE_FATE_OF_THE_UNFAITHFUL) then return end
    local Hascarbattery = player:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY) 
    player.Damage = player.Damage * (Hascarbattery and 2 or 1.75)
end
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, FOTU.FateCache, CacheFlag.CACHE_DAMAGE)