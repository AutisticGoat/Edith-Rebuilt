EdithRebuilt = RegisterMod("Edith: Rebuilt", 1)
local mod = EdithRebuilt

EdithRebuilt.CustomDataWrapper = require("resources.scripts.libs.EdithRebuiltSaveData")
EdithRebuilt.CustomDataWrapper.init(mod)
EdithRebuilt.SaveManager = require("resources.scripts.libs.EdithRebuiltSaveManager")
EdithRebuilt.SaveManager.Init(mod)

include("resources.scripts.libs.EdithKotryJumpLib").Init()

include("resources.scripts.definitions")

EdithRebuilt.Modules = {}
local mods = EdithRebuilt.Modules

mods.FLOOR = include("resources.scripts.functions.Floor")
mods.HELPERS = include("resources.scripts.functions.Helpers")
mods.VEC_DIR = include("resources.scripts.functions.VecDir")
mods.JUMP = include("resources.scripts.functions.Jump")
mods.MATHS = include("resources.scripts.functions.Maths")
mods.PLAYER = include("resources.scripts.functions.Player")
mods.EDITH = include("resources.scripts.functions.Edith")


mods.LAND = include("resources.scripts.functions.Land")
mods.TARGET_ARROW = include("resources.scripts.functions.TargetArrow")
mods.TEDITH = include("resources.scripts.functions.TEdith")


include("include")

local enums = mod.Enums
local utils = enums.Utils
local game = utils.Game

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function()
	utils.RNG:SetSeed(game:GetSeeds():GetStartSeed())
end)