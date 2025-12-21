local mod = EdithRebuilt
local enums = mod.Enums
local tables = enums.Tables
local utils = enums.Utils
local game = utils.Game
local modules = mod.Modules
local Player = modules.PLAYER
local Helpers = modules.HELPERS
local Maths = modules.MATHS
local TargetArrow = modules.TARGET_ARROW
local costumes = enums.NullItemID

---@param entity Entity
---@param input InputHook
---@param action ButtonAction|KeySubType
---@return integer|boolean?
mod:AddCallback(ModCallbacks.MC_INPUT_ACTION, function (_, entity, input, action)
    if not entity then return end
    local player = entity:ToPlayer()

    if not player then return end
    if not Player.IsAnyEdith(player) then return end
    if input ~= InputHook.GET_ACTION_VALUE then return end

    return tables.OverrideActions[action]
end)

---@param player EntityPlayer
---@param cacheFlag CacheFlag
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, cacheFlag)
    if not Player.IsAnyEdith(player) then return end
    if cacheFlag == CacheFlag.CACHE_DAMAGE then
        player.Damage = player.Damage * 1.5
    elseif cacheFlag == CacheFlag.CACHE_RANGE then
        local Range = (Helpers.IsVestigeChallenge() and player:GetPlayerType() == enums.PlayerType.PLAYER_EDITH) and 4.25 or 2.5
        player.TearRange = Player.rangeUp(player.TearRange, Range)
    end
end)

local whiteListCostumes = {
	[costumes.ID_EDITH_SCARF] = true,
	[costumes.ID_EDITH_B_SCARF] = true,
    [costumes.ID_EDITH_B_GRUDGE_SCARF] = true,
    [costumes.ID_EDITH_VESTIGE_SCARF] = true,
}

---@param itemconfig ItemConfigItem
---@param player EntityPlayer
---@return boolean?
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_ADD_COSTUME, function(_, itemconfig, player)
    if not Player.IsAnyEdith(player) then return end
    if Helpers.When(itemconfig.Costume.ID, whiteListCostumes, false) then return end
    return true
end)

mod:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, function(_, tear)
    local player = Helpers.GetPlayerFromTear(tear)

	if not player then return end
	if not Player.IsAnyEdith(player) then return end
	if tear.FrameCount ~= 1 then return end

	tear.Mass = tear.Mass * 10
end)

---@param player EntityPlayer
---@param flags DamageFlag
---@return boolean?
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, function(_, player, _, flags)
    local roomType = game:GetRoom():GetType()

    if not Player.IsAnyEdith(player) then return end
	if Maths.HasBitFlags(flags, DamageFlag.DAMAGE_ACID) or (roomType ~= RoomType.ROOM_SACRIFICE and Maths.HasBitFlags(flags, DamageFlag.DAMAGE_SPIKES)) then return false end
end)

---@param tear EntityTear
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, function(_, tear)
    local player = Helpers.GetPlayerFromTear(tear)

	if not player then return end
    if not Player.IsAnyEdith(player) then return end

    local isTainted = Player.IsEdith(player, true)
    local target = TargetArrow.GetEdithTarget(player)

	Helpers.ForceSaltTear(tear, isTainted)

    if isTainted then return end
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_MARKED) then return end	
	if not target then return end

    tear.Velocity = -((tear.Position - target.Position):Normalized()):Resized(player.ShotSpeed * 10)
end)