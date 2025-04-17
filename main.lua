---@diagnostic disable-next-line: lowercase-global
edithMod = RegisterMod("Edith: Rebuilt", 1)
local mod = edithMod

include("resources/scripts/save_manager").Init(mod)

local myFolder = "resources.scripts.EdithKotryLibraryOfIsaac"
local LOCAL_TSIL = include(myFolder .. ".TSIL")
LOCAL_TSIL.Init(myFolder)

mod.JumpLib = include("resources/scripts/EdithKotryJumpLib")
mod.JumpLib.Init(mod)

include("include")

local tables = mod.Enums.Tables

-- some shared functions between edith and tainted Edith, the behave almost the same 

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

---comment
---@param player EntityPlayer
---@param flags DamageFlag
---@return boolean?
function mod:PlayerDamageManager(player, _, flags)
    if not mod:IsAnyEdith(player) then return end
	if mod.HasBitFlags(flags, DamageFlag.DAMAGE_ACID) or mod.HasBitFlags(flags, DamageFlag.DAMAGE_SPIKES) then return false end
end
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, mod.PlayerDamageManager)