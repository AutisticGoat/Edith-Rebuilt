local mod = EdithRebuilt
local callbacks = mod.Enums.Callbacks
local Player = mod.Modules.PLAYER
local data = mod.DataHolder.GetEntityData
---@param player EntityPlayer
---@param params EdithJumpStompParams
mod:AddCallback(callbacks.OFFENSIVE_STOMP, function(_, player, params)
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK) then return end

    local baseMult = Player.PlayerHasBirthright(player) and 2.5 or 2
    local ChocoMult = data(player).ChocoMult

    params.Damage = params.Damage * (baseMult * ChocoMult)
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