EdithRebuilt = RegisterMod("Edith: Rebuilt", 1)
local mod = EdithRebuilt

EdithRebuilt.CustomDataWrapper = require("resources.scripts.EdithRebuiltsavedata")
EdithRebuilt.CustomDataWrapper.init(EdithRebuilt)
EdithRebuilt.SaveManager = require("resources.scripts.EdithRebuiltSaveManager")
EdithRebuilt.SaveManager.Init(mod)

include("resources/scripts/EdithKotryJumpLib").Init(mod)
include("include")

local enums = mod.Enums
local tables = enums.Tables
local utils = enums.Utils
local game = utils.Game
local costumes = enums.NullItemID

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function()
	utils.RNG:SetSeed(game:GetSeeds():GetStartSeed())
end)

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
	[costumes.ID_EDITH_SCARF] = true,
	[costumes.ID_EDITH_B_SCARF] = true,
}

---@param itemconfig ItemConfigItem
---@param player EntityPlayer
---@return boolean?
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_ADD_COSTUME, function(_, itemconfig, player)
    if not mod:IsAnyEdith(player) then return end
    local ID = itemconfig.Costume.ID
    local shouldOverride = mod.When(ID, whiteListCostumes, false)

    if shouldOverride then return end
    return true
end)

---@param player EntityPlayer
---@param flags DamageFlag
---@return boolean?
function mod:PlayerDamageManager(player, _, flags)
    local roomType = game:GetRoom():GetType()

    if not mod:IsAnyEdith(player) then return end
	if mod.HasBitFlags(flags, DamageFlag.DAMAGE_ACID) or (roomType ~= RoomType.ROOM_SACRIFICE and mod.HasBitFlags(flags, DamageFlag.DAMAGE_SPIKES)) then return false end
end
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, mod.PlayerDamageManager)