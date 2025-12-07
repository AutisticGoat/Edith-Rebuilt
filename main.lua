EdithRebuilt = RegisterMod("Edith: Rebuilt", 1)
local mod = EdithRebuilt

EdithRebuilt.CustomDataWrapper = require("resources.scripts.libs.EdithRebuiltSaveData")
EdithRebuilt.CustomDataWrapper.init(mod)
EdithRebuilt.SaveManager = require("resources.scripts.libs.EdithRebuiltSaveManager")
EdithRebuilt.SaveManager.Init(mod)

include("resources.scripts.libs.EdithKotryJumpLib").Init()
include("resources.scripts.definitions")

EdithRebuilt.Modules = {
	FLOOR = include("resources.scripts.functions.Floor"),
	RNG = include("resources.scripts.functions.RNG"),
	HELPERS = include("resources.scripts.functions.Helpers"),
	VEC_DIR = include("resources.scripts.functions.VecDir"),
	JUMP = include("resources.scripts.functions.Jump"),
	MATHS = include("resources.scripts.functions.Maths"),
	TARGET_ARROW = include("resources.scripts.functions.TargetArrow"),
	PLAYER = include("resources.scripts.functions.Player"),
	EDITH = include("resources.scripts.functions.Edith"),
	LAND = include("resources.scripts.functions.Land"),
	TEDITH = include("resources.scripts.functions.TEdith"),
}

for k, v in pairs(EdithRebuilt.Modules) do
	print(k, v)
end

include("include")

local utils = mod.Enums.Utils
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function()
	utils.RNG:SetSeed(utils.Game:GetSeeds():GetStartSeed())
end)