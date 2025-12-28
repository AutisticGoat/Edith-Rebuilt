EdithRebuilt = RegisterMod("Edith: Rebuilt", 1)
local mod = EdithRebuilt

EdithRebuilt.DataHolder = include("resources.scripts.libs.DataHolder")
EdithRebuilt.CustomDataWrapper = include("resources.scripts.libs.EdithRebuiltSaveData")
EdithRebuilt.SaveManager = require("resources.scripts.libs.EdithRebuiltSaveManager")
EdithRebuilt.SaveManager.Init(mod)
EdithRebuilt.Hsx = require("resources.scripts.libs.lhsx")

EdithRebuilt.Version = "v1.5.1.1"

include("resources.scripts.libs.prenpckillcallback")
include("resources.scripts.libs.EdithKotryJumpLib").Init()
include("resources.scripts.definitions")
include("resources.scripts.libs.status_effect_library")

EdithRebuilt.Modules = {
	FLOOR = include("resources.scripts.functions.Floor"),
	RNG = include("resources.scripts.functions.RNG"),
	HELPERS = include("resources.scripts.functions.Helpers"),
	VEC_DIR = include("resources.scripts.functions.VecDir"),
	MATHS = include("resources.scripts.functions.Maths"),
	TARGET_ARROW = include("resources.scripts.functions.TargetArrow"),
	PLAYER = include("resources.scripts.functions.Player"),
	EDITH = include("resources.scripts.functions.Edith"),
	LAND = include("resources.scripts.functions.Land"),
	TEDITH = include("resources.scripts.functions.TEdith"),
	STATUS_EFFECTS = include("resources.scripts.functions.StatusEffects"),
	CREEPS = include("resources.scripts.functions.Creeps"),
	-- DATA_HOLDER = include("resources.scripts.functions.DataHolder")
}

include("include")

local utils = mod.Enums.Utils
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function()
	utils.RNG:SetSeed(utils.Game:GetSeeds():GetStartSeed())
end)

Isaac.DebugString("Edith Rebuilt " .. EdithRebuilt.Version .. " loaded correctly")
print("Edith Rebuilt " .. EdithRebuilt.Version .. " loaded correctly")

---@param Slot LevelGeneratorRoom
---@param RoomConfig RoomConfigRoom
---@param Seed integer
mod:AddCallback(ModCallbacks.MC_PRE_LEVEL_PLACE_ROOM, function (_, Slot, RoomConfig, Seed)
	if RoomConfig.Type == RoomType.ROOM_TREASURE then
		print("tesoro")
	end
end)