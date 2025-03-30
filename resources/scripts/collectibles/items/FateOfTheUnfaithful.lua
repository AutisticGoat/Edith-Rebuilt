local mod = edithMod
local enums = mod.Enums
local utils = enums.Utils
local game, sfx = utils.Game, utils.SFX
local items = enums.CollectibleType
local FOTU = {}

---@param rng RNG
---@param player EntityPlayer
---@param flag UseFlag
---@return boolean?
function FOTU:OnFatefulUse(_, rng, player, flag)
    if flag & UseFlag.USE_CARBATTERY == UseFlag.USE_CARBATTERY then return end
    local Hascarbattery = player:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY) 
    local roomEnt = Isaac.GetRoomEntities()
    local playerPos = player.Position

    for _, ent in ipairs(roomEnt) do
        if not (ent:IsVulnerableEnemy() and ent:IsActiveEnemy()) then goto Break end
        ent:AddBurn(EntityRef(player), 83, Hascarbattery and 3 or 1.5)
        ent:AddBrimstoneMark(EntityRef(player), Hascarbattery and 180 or 90)

        local entPos = ent.Position

        if playerPos:Distance(entPos) > 50 then goto Break end
        local newVel = ((playerPos - entPos) * -1):Resized(20)
        ent:AddKnockback(EntityRef(player), newVel, 5,false)
        ::Break::
    end

    game:ShakeScreen(10)
    sfx:Play(SoundEffect.SOUND_FIREDEATH_HISS, 1, 0, false, rng:RandomInt(95,105)/100)
    return true
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, FOTU.OnFatefulUse, items.COLLECTIBLE_FATE_OF_THE_UNFAITHFUL)

---@param player EntityPlayer
---@param flags CacheFlag
function FOTU:FateCache(player, flags)
    local effects = player:GetEffects()
    local FateEffect = effects:GetCollectibleEffect(items.COLLECTIBLE_FATE_OF_THE_UNFAITHFUL)
    if FateEffect == nil then return end
    local Hascarbattery = player:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY) 
    player.Damage = player.Damage * (Hascarbattery and 2 or 1.75)
end
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, FOTU.FateCache, CacheFlag.CACHE_DAMAGE)