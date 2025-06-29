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

function mod:OverrideTaintedInputs(entity, input, action)
    if not entity then return end
    local player = entity:ToPlayer()
    
    if not player then return end
    if not mod:IsAnyEdith(player) then return end
    if input ~= 2 then return end
    
    return tables.OverrideActions[action]
end
mod:AddCallback(ModCallbacks.MC_INPUT_ACTION, mod.OverrideTaintedInputs)

---@param player EntityPlayer
---@param cacheFlag CacheFlag
function mod:SetEdithStats(player, cacheFlag)
    if not mod:IsAnyEdith(player) then return end

    local cacheActions = {
        [CacheFlag.CACHE_DAMAGE] = function()
            player.Damage = player.Damage * 1.5
        end,
        [CacheFlag.CACHE_RANGE] = function()
            player.TearRange = mod.rangeUp(player.TearRange, 2.5)
        end,
    }
        
    mod.WhenEval(cacheFlag, cacheActions)
end
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.SetEdithStats)

---@param player EntityPlayer
---@param flags DamageFlag
---@return boolean?
function mod:PlayerDamageManager(player, _, flags)
    local game = mod.Enums.Utils.Game
    local room = game:GetRoom()
    local roomType = room:GetType()

    if not mod:IsAnyEdith(player) then return end

	if mod.HasBitFlags(flags, DamageFlag.DAMAGE_ACID) or (roomType ~= RoomType.ROOM_SACRIFICE and mod.HasBitFlags(flags, DamageFlag.DAMAGE_SPIKES)) then return false end
end
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, mod.PlayerDamageManager)