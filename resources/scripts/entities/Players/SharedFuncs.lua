local mod = EdithRebuilt
local enums = mod.Enums
local tables = enums.Tables
local utils = enums.Utils
local game = utils.Game
local costumes = enums.NullItemID

---@param entity Entity
---@param input InputHook
---@param action ButtonAction|KeySubType
---@return integer|boolean?
mod:AddCallback(ModCallbacks.MC_INPUT_ACTION, function (_, entity, input, action)
    if not entity then return end
    local player = entity:ToPlayer()

    if not player then return end
    if not mod:IsAnyEdith(player) then return end
    if input ~= InputHook.GET_ACTION_VALUE then return end

    return tables.OverrideActions[action]
end)

---@param player EntityPlayer
---@param cacheFlag CacheFlag
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, cacheFlag)
    if not mod:IsAnyEdith(player) then return end
    if cacheFlag == CacheFlag.CACHE_DAMAGE then
        player.Damage = player.Damage * 1.5
    elseif cacheFlag == CacheFlag.CACHE_RANGE then
        player.TearRange = mod.rangeUp(player.TearRange, 2.5)
    end
end)

local whiteListCostumes = {
	[CollectibleType.COLLECTIBLE_MEGA_MUSH] = true,
	[CollectibleType.COLLECTIBLE_BOOK_OF_SHADOWS] = true,
    [CollectibleType.COLLECTIBLE_PONY] = true,
    [CollectibleType.COLLECTIBLE_WHITE_PONY] = true,
    [CollectibleType.COLLECTIBLE_GODHEAD] = true,
    [CollectibleType.COLLECTIBLE_TRANSCENDENCE] = true,
    [CollectibleType.COLLECTIBLE_FATE] = true,
	[costumes.ID_EDITH_SCARF] = true,
	[costumes.ID_EDITH_B_SCARF] = true,
}

---@param itemconfig ItemConfigItem
---@param player EntityPlayer
---@return boolean?
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_ADD_COSTUME, function(_, itemconfig, player)
    -- print(itemconfig.Costume.ID)

    
    if itemconfig.Costume.ID == 80 then
        print("a[osjdaosjdoj]")
        -- player:RemoveCostume(itemconfig)
        -- player:AddNullCostume(CustomPactCostume)
    end

    -- if not mod:IsAnyEdith(player) then return end
    -- if mod.When(itemconfig.Costume.ID, whiteListCostumes, false) then return end
    -- return true
end)

mod:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, function(_, tear)
    local player = mod:GetPlayerFromTear(tear)

	if not player then return end
	if not mod:IsAnyEdith(player) then return end
	if tear.FrameCount ~= 1 then return end

	tear.Mass = tear.Mass * 10
end)

---@param player EntityPlayer
---@param flags DamageFlag
---@return boolean?
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, function(_, player, _, flags)
    local roomType = game:GetRoom():GetType()

    if not mod:IsAnyEdith(player) then return end
	if mod.HasBitFlags(flags, DamageFlag.DAMAGE_ACID) or (roomType ~= RoomType.ROOM_SACRIFICE and mod.HasBitFlags(flags, DamageFlag.DAMAGE_SPIKES)) then return false end
end)

mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, function(_, tear)
    local player = mod:GetPlayerFromTear(tear)

	if not player then return end
    if not mod:IsAnyEdith(player) then return end

    local isTainted = mod.IsEdith(player, true)
    local target = mod.GetEdithTarget(player)

	mod.ForceSaltTear(tear, isTainted)

    if isTainted then return end
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_MARKED) then return end	
	if not target then return end
	tear.Velocity = mod.ChangeVelToTarget(tear, target, player.ShotSpeed * 10)
end)