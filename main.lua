EdithRebuilt = RegisterMod("Edith: Rebuilt", 1)
local mod = EdithRebuilt

EdithRebuilt.CustomDataWrapper = require("resources.scripts.EdithRebuiltsavedata")
EdithRebuilt.CustomDataWrapper.init(EdithRebuilt)
EdithRebuilt.SaveManager = require("resources.scripts.EdithRebuiltSaveManager")
EdithRebuilt.SaveManager.Init(mod)

local myFolder = "resources.scripts.EdithKotryLibraryOfIsaac"
local LOCAL_TSIL = include(myFolder .. ".TSIL")
LOCAL_TSIL.Init(myFolder)

mod.JumpLib = include("resources/scripts/EdithKotryJumpLib")
mod.JumpLib.Init(mod)

include("include")

local tables = mod.Enums.Tables
local utils = mod.Enums.Utils

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function()
	utils.RNG:SetSeed(utils.Game:GetSeeds():GetStartSeed())
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

---@param player EntityPlayer
---@param flags DamageFlag
---@return boolean?
function mod:PlayerDamageManager(player, _, flags)
    local game = mod.Enums.Utils.Game
    local roomType = game:GetRoom():GetType()

    if not mod:IsAnyEdith(player) then return end
	if mod.HasBitFlags(flags, DamageFlag.DAMAGE_ACID) or (roomType ~= RoomType.ROOM_SACRIFICE and mod.HasBitFlags(flags, DamageFlag.DAMAGE_SPIKES)) then return false end
end
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, mod.PlayerDamageManager)