edithMod = RegisterMod("Edith Kotry Build", 1)
local mod = edithMod

include("resources/scripts/save_manager").Init(mod)

local myFolder = "resources.scripts.EdithKotryLibraryOfIsaac"
local LOCAL_TSIL = require(myFolder .. ".TSIL")
LOCAL_TSIL.Init(myFolder)

edithMod.JumpLib = include("resources/scripts/EdithKotryJumpLib")
edithMod.JumpLib.Init(mod)

include("resources/scripts/incubus_at_home")

include("include")

local tables = edithMod.Enums.Tables

-- some shared functions between edith and tainted Edith, the behave almost the same 
function edithMod:OverrideTaintedInputs(entity, input, action)
	if not entity then return end
	local player = entity:ToPlayer()
	
	if not player then return end
	if not edithMod:IsAnyEdith(player) then return end
	
	if input == 2 then
		return tables.OverrideActions[action]
	end
end
edithMod:AddCallback(ModCallbacks.MC_INPUT_ACTION, edithMod.OverrideTaintedInputs)

---@param player EntityPlayer
---@param cacheFlag CacheFlag
function edithMod:SetEdithStats(player, cacheFlag)
	if not edithMod:IsAnyEdith(player) then return end

	local cacheActions = {
		[CacheFlag.CACHE_DAMAGE] = function()
			player.Damage = player.Damage * 1.5
		end,
		[CacheFlag.CACHE_RANGE] = function()
			player.TearRange = edithMod.rangeUp(player.TearRange, 2.5)
		end,
	}
		
	edithMod.WhenEval(cacheFlag, cacheActions)
end
edithMod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, edithMod.SetEdithStats)

function edithMod:PlayerDamageManager(player, damage, flags, source, countdown)
	if not edithMod:IsAnyEdith(player) then return end
	
	if flags == DamageFlag.DAMAGE_SPIKES or flags == DamageFlag.DAMAGE_ACID then
		return false
	end
end
edithMod:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, edithMod.PlayerDamageManager)
