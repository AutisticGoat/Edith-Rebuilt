local game = Game()
local json = require("json")

local function copyTable(sourceTab)
	local targetTab = {}
	sourceTab = sourceTab or {}
	
	if type(sourceTab) ~= "table" then
		error("[ERROR] - cucco_helper.copyTable - invalid argument #1, table expected, got " .. type(sourceTab), 2)
	end

	for i, v in pairs(sourceTab) do
		if type(v) == "table" then
			targetTab[i] = copyTable(sourceTab[i])
		else
			targetTab[i] = sourceTab[i]
		end
	end
	
	return targetTab
end

local SAVE_DATA = {}
local GLOBAL_DATA = {}
local FLOOR_DATA = {}
local PERSISTENT_PLAYER_DATA = {}
local GLOWING_HOURGLASS_DATA = {}
local CHAPI_DATA = "" -- Only used if your mod uses Custom Health API

local TEMPORARY_DATA = {}

local script = {}
local library = {}
local modRef

--- Call this on your main.lua file following this example:
---
--- local mod = RegisterMod("name", 1)
---
--- require("path.savedata").init(mod)
function library.init(mod)
    modRef = mod

    modRef:AddPriorityCallback(ModCallbacks.MC_POST_NEW_LEVEL, 1000, script.onLevelSave)
    modRef:AddPriorityCallback(ModCallbacks.MC_PRE_GAME_EXIT, 1000, script.onExitSave)
    modRef:AddCallback(ModCallbacks.MC_POST_SAVESLOT_LOAD, script.loadSaveData)
    modRef:AddPriorityCallback(ModCallbacks.MC_PLAYER_INIT_PRE_LEVEL_INIT_STATS, -200, script.resetPlayerData)
    modRef:AddPriorityCallback(ModCallbacks.MC_PRE_LEVEL_INIT, -200, script.resetFloorData)
    modRef:AddPriorityCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, -200, script.playerUpdate, PlayerVariant.PLAYER)
    modRef:AddPriorityCallback(ModCallbacks.MC_POST_GLOWING_HOURGLASS_SAVE, -200, script.postGlowingHourglassSave)
    modRef:AddPriorityCallback(ModCallbacks.MC_PRE_GLOWING_HOURGLASS_LOAD, -200, script.preGlowingHourglassLoad)

	modRef:AddPriorityCallback(ModCallbacks.MC_FAMILIAR_INIT, -200, script.resetTemporaryData)
	modRef:AddPriorityCallback(ModCallbacks.MC_POST_NPC_INIT, -200, script.resetTemporaryData)
	modRef:AddPriorityCallback(ModCallbacks.MC_POST_TEAR_INIT, -200, script.resetTemporaryData)
	modRef:AddPriorityCallback(ModCallbacks.MC_POST_BOMB_INIT, -200, script.resetTemporaryData)
	modRef:AddPriorityCallback(ModCallbacks.MC_POST_SLOT_INIT, -200, script.resetTemporaryData)
	modRef:AddPriorityCallback(ModCallbacks.MC_POST_LASER_INIT, -200, script.resetTemporaryData)
	modRef:AddPriorityCallback(ModCallbacks.MC_POST_KNIFE_INIT, -200, script.resetTemporaryData)
	modRef:AddPriorityCallback(ModCallbacks.MC_POST_PLAYER_INIT, -200, script.resetTemporaryData)
	modRef:AddPriorityCallback(ModCallbacks.MC_POST_PICKUP_INIT, -200, script.resetTemporaryData)
	modRef:AddPriorityCallback(ModCallbacks.MC_POST_EFFECT_INIT, -200, script.resetTemporaryData)
	modRef:AddPriorityCallback(ModCallbacks.MC_POST_PROJECTILE_INIT, -200, script.resetTemporaryData)
end

--- Returns a Persistent Player data table that will only
--- reset when restarting a run or using Genesis.
---@param player EntityPlayer
function library.getPlayerData(player, trueData)
    local index = player:GetPlayerIndex() + 1
    local playerType = player:GetPlayerType()

    if not PERSISTENT_PLAYER_DATA[index] then
		if index == 0 then
			if playerType == PlayerType.PLAYER_LAZARUS_B then
				local twin = player:GetFlippedForm()
	
				if twin then
					return PERSISTENT_PLAYER_DATA[twin:GetPlayerIndex() + 1]
				end
			elseif playerType == PlayerType.PLAYER_LAZARUS2_B then
				local twin = player:GetFlippedForm()
	
				if twin then
					return PERSISTENT_PLAYER_DATA[twin:GetPlayerIndex() + 1].TwinData
				end
			end

			return {IGNORE = true, TwinData = {}}
		end

        PERSISTENT_PLAYER_DATA[index] = {}

        if playerType == PlayerType.PLAYER_LAZARUS_B
		or playerType == PlayerType.PLAYER_LAZARUS2_B
		then
			PERSISTENT_PLAYER_DATA[index].TwinData = PERSISTENT_PLAYER_DATA[index].TwinData or {
				IGNORE = true,
				TWIN = true,
				PLAYER_INDEX = index - 1,
			}
		end

		if playerType == PlayerType.PLAYER_THESOUL_B then
			PERSISTENT_PLAYER_DATA[index].IGNORE = true
		end
		
		PERSISTENT_PLAYER_DATA[index].PLAYER_TYPE = playerType
		PERSISTENT_PLAYER_DATA[index].PLAYER_INDEX = index - 1
    end

	if not trueData then
		if playerType == PlayerType.PLAYER_THESOUL_B then
			return PERSISTENT_PLAYER_DATA[index - 1]
		elseif playerType == PlayerType.PLAYER_LAZARUS2_B then
			PERSISTENT_PLAYER_DATA[index].TwinData = PERSISTENT_PLAYER_DATA[index].TwinData or {
				IGNORE = true,
				TWIN = true,
				PLAYER_INDEX = index - 1,
			}
			return PERSISTENT_PLAYER_DATA[index].TwinData
		end
	end

    return PERSISTENT_PLAYER_DATA[index]
end

--- Returns a Persistent data table for the run that will only
--- reset when restarting a run.
function library.getGlobalData()
	return GLOBAL_DATA
end

--- Returns a Persistent data table for the current floor that
--- will reset when changing levels.
function library.getFloorData()
	return FLOOR_DATA
end

--- Alternative to Entity::GetData()
---
--- Acts as a localized version to avoid incompatibilities with
--- other mods.
function library.getData(entity)
	local hash = GetPtrHash(entity)
	TEMPORARY_DATA[hash] = TEMPORARY_DATA[hash] or {}

	return TEMPORARY_DATA[hash]
end

--- Should only be used on CustomHealthAPI.Enums.Callbacks.ON_LOAD
function library.getChapiData()
	return CHAPI_DATA
end

--- Should only be used on CustomHealthAPI.Enums.Callbacks.ON_SAVE
function library.overrideChapiData(newData)
	CHAPI_DATA = newData
end

local function updatePlayerDataStructure(index)
    for i = index + 1, #PERSISTENT_PLAYER_DATA do
		local player = Isaac.GetPlayer(i - 1)
		local playerType = player:GetPlayerType()

        PERSISTENT_PLAYER_DATA[i] = PERSISTENT_PLAYER_DATA[i + 1]
		PERSISTENT_PLAYER_DATA[i].PLAYER_INDEX = i - 1

		if playerType ~= PlayerType.PLAYER_LAZARUS_B
		and playerType ~= PlayerType.PLAYER_LAZARUS2_B
		then
			PERSISTENT_PLAYER_DATA[i].TwinData = nil
		elseif PERSISTENT_PLAYER_DATA[i].TwinData then
			PERSISTENT_PLAYER_DATA[i].TwinData.PLAYER_INDEX = i - 1
		end

		Isaac.GetPlayer(i):AddCacheFlags(CacheFlag.CACHE_ALL, true)
    end
end

local function saveModData()
    SAVE_DATA.PERSISTENT_PLAYER_DATA = copyTable(PERSISTENT_PLAYER_DATA)
    SAVE_DATA.GLOBAL_DATA = copyTable(GLOBAL_DATA)
    SAVE_DATA.FLOOR_DATA = copyTable(FLOOR_DATA)
    SAVE_DATA.CHAPI_DATA = CHAPI_DATA

    modRef:SaveData(json.encode(SAVE_DATA))
end

function script:onLevelSave()
    saveModData()
end

function script:onExitSave()
    saveModData()
end

function script:resetTemporaryData(entity)
	if entity:ToPlayer() then
		
		print("Reset data for Hash:", GetPtrHash(entity))
	end

	local hash = tostring(GetPtrHash(entity))
	TEMPORARY_DATA[hash] = nil
end

function script:loadSaveData(slot, loaded, rawslot)
    if not loaded then
        return
    end

    if Isaac.HasModData(modRef) then
        SAVE_DATA = json.decode(modRef:LoadData())
        PERSISTENT_PLAYER_DATA = copyTable(SAVE_DATA.PERSISTENT_PLAYER_DATA)
        GLOBAL_DATA = copyTable(SAVE_DATA.GLOBAL_DATA)
        FLOOR_DATA = copyTable(SAVE_DATA.FLOOR_DATA)
        CHAPI_DATA = SAVE_DATA.CHAPI_DATA

        saveModData()
    end
end

function script:resetPlayerData(player)
    if player:GetPlayerIndex() == 0
    and game:GetFrameCount() == 0
    then
        PERSISTENT_PLAYER_DATA = {}
    end

    library.getPlayerData(player)
end

function script:resetFloorData()
	FLOOR_DATA = {}
end

function script:playerUpdate(player)
    local data = library.getPlayerData(player)
	local realData = library.getPlayerData(player, true)
	local playerType = player:GetPlayerType()
	local playerIndex = player:GetPlayerIndex()

	if realData.IS_TWIN then
		if playerType ~= PlayerType.PLAYER_LAZARUS_B
		and playerType ~= PlayerType.PLAYER_LAZARUS2_B
		then
			local index = player:GetPlayerIndex() + 1
			PERSISTENT_PLAYER_DATA[index] = data.TwinData
			data = library.getPlayerData(player)
			realData = library.getPlayerData(player, true)

			data.TWIN = nil
			data.IGNORE = nil
			data.PLAYER_TYPE = playerType
		end
	elseif not data.IGNORE
	and not realData.IGNORE
	and data.PLAYER_TYPE ~= playerType
	then
		data.PLAYER_TYPE = playerType

		if data.PLAYER_INDEX == playerIndex then
			return
		end

		updatePlayerDataStructure(playerIndex)
    end

	realData.IS_TWIN = playerType == PlayerType.PLAYER_LAZARUS2_B and true or nil
end

function script:postGlowingHourglassSave(slot)
	slot = slot + 1
	GLOWING_HOURGLASS_DATA[slot] = GLOWING_HOURGLASS_DATA[slot] or {}

    GLOWING_HOURGLASS_DATA[slot].PERSISTENT_PLAYER_DATA = copyTable(PERSISTENT_PLAYER_DATA)
    GLOWING_HOURGLASS_DATA[slot].GLOBAL_DATA = copyTable(GLOBAL_DATA)
    GLOWING_HOURGLASS_DATA[slot].FLOOR_DATA = copyTable(FLOOR_DATA)
    GLOWING_HOURGLASS_DATA[slot].TEMPORARY_DATA = copyTable(TEMPORARY_DATA)
	-- Custom Health API automatically handles Glowing Hourglass
end

function script:preGlowingHourglassLoad(slot)
	slot = slot + 1
	GLOWING_HOURGLASS_DATA[slot] = GLOWING_HOURGLASS_DATA[slot] or {}

    PERSISTENT_PLAYER_DATA = copyTable(GLOWING_HOURGLASS_DATA[slot].PERSISTENT_PLAYER_DATA)
    GLOBAL_DATA = copyTable(GLOWING_HOURGLASS_DATA[slot].GLOBAL_DATA)
    FLOOR_DATA = copyTable(GLOWING_HOURGLASS_DATA[slot].FLOOR_DATA)
    TEMPORARY_DATA = copyTable(GLOWING_HOURGLASS_DATA[slot].TEMPORARY_DATA)
	-- Custom Health API automatically handles Glowing Hourglass
end

return library