local mod = EdithRebuilt
local callbacks = mod.Enums.Callbacks
local Player = mod.Modules.PLAYER
local EdithMod = mod.Modules.EDITH
local data = mod.CustomDataWrapper.getData

---@param player EntityPlayer
---@param params EdithJumpStompParams
mod:AddCallback(callbacks.OFFENSIVE_STOMP, function(_, player, params)
    if params.IsDefensiveStomp then return end
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK) then return end

    local ChocoMult = data(player).ChocoMult

    params.Damage = params.Damage * (2 * ChocoMult)
end)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function(_, player)
    if JumpLib:GetData(player).Jumping then return end
    if not Player.IsPlayerShooting(player) then return end

    local weapon = player:GetWeapon(1)

    if not weapon then return end
    local chargePercent = weapon:GetCharge() / weapon:GetMaxCharge()

    data(player).ChocoMult = chargePercent
end)