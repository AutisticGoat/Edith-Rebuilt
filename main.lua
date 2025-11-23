EdithRebuilt = RegisterMod("Edith: Rebuilt", 1)
local mod = EdithRebuilt

EdithRebuilt.CustomDataWrapper = require("resources.scripts.libs.EdithRebuiltSaveData")
EdithRebuilt.CustomDataWrapper.init(mod)
EdithRebuilt.SaveManager = require("resources.scripts.libs.EdithRebuiltSaveManager")
EdithRebuilt.SaveManager.Init(mod)

include("resources.scripts.libs.EdithKotryJumpLib").Init(mod)
include("include")

local enums = mod.Enums
local utils = enums.Utils
local game = utils.Game

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function()
	utils.RNG:SetSeed(game:GetSeeds():GetStartSeed())
end)

-- mod:AddCallback(enums.Callbacks.OFFENSIVE_STOMP, function()

-- 	print("Offensive stomp!")
-- end)