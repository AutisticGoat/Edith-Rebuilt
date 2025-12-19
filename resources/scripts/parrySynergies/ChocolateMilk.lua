local mod = EdithRebuilt
local callbacks = mod.Enums.Callbacks
local Player = mod.Modules.PLAYER
local data = mod.CustomDataWrapper.getData

-- Pendiente de rehacer

---@param player EntityPlayer
---@param params TEdithHopParryParams
mod:AddCallback(callbacks.PERFECT_PARRY, function(_, player, _, params)
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK) then return end

    local ChocoMult = data(player).ParryChocoMult

    if ChocoMult > 0 then
        params.ParryDamage = params.ParryDamage * (2 * ChocoMult)
    end

    data(player).ParryChocoMult = 0
end)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function(_, player)
    if JumpLib:GetData(player).Jumping then return end
    if not Player.IsPlayerShooting(player) then return end

    local weapon = player:GetWeapon(1)

    if not weapon then return end
    local chargePercent = weapon:GetCharge() / weapon:GetMaxCharge()

    data(player).ParryChocoMult = chargePercent
end)