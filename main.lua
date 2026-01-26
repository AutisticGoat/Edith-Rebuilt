EdithRebuilt = RegisterMod("Edith: Rebuilt", 1) --[[@as ModReference|table]]
local mod = EdithRebuilt
local font = Font()
font:Load("font/pftempestasevencondensed.fnt")

if not REPENTOGON then
    mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
        local text = "REPENTOGON is missing"
        local text2 = "check repentogon.com"
        font:DrawStringScaledUTF8(text, Isaac.GetScreenWidth()/1.1 - font:GetStringWidthUTF8(text)/2, Isaac.GetScreenHeight()/1.2, 1, 1, KColor(2,.5,.5,1), 1, true )
        font:DrawStringScaledUTF8(text2, Isaac.GetScreenWidth()/1.1 - font:GetStringWidthUTF8(text2)/2, Isaac.GetScreenHeight()/1.2 + 8, 1, 1, KColor(2,.5,.5,1), 1, true )
    end)
	return 
end

if not REPENTANCE_PLUS then
	mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
        local text = "This mod is meant to be used with Repentance+ DLC"
        local text2 = "Look for it on steam"
        font:DrawStringScaledUTF8(text, Isaac.GetScreenWidth()/1.1 - font:GetStringWidthUTF8(text)/2, Isaac.GetScreenHeight()/1.2, 1, 1, KColor(2,.5,.5,1), 1, true )
        font:DrawStringScaledUTF8(text2, Isaac.GetScreenWidth()/1.1 - font:GetStringWidthUTF8(text2)/2, Isaac.GetScreenHeight()/1.2 + 8, 1, 1, KColor(2,.5,.5,1), 1, true )
    end)
end

EdithRebuilt.DataHolder = include("resources.scripts.libs.DataHolder")
EdithRebuilt.TempStatsLib = require("resources.scripts.libs.TempStatsLib")
EdithRebuilt.SaveManager = require("resources.scripts.libs.EdithRebuiltSaveManager")
EdithRebuilt.SaveManager.Init(mod)
EdithRebuilt.Hsx = require("resources.scripts.libs.lhsx")

EdithRebuilt.Version = "v1.7.0b"

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
}

include("include")

local utils = mod.Enums.Utils
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function()
	utils.RNG:SetSeed(utils.Game:GetSeeds():GetStartSeed())
end)

Isaac.DebugString("Edith Rebuilt " .. EdithRebuilt.Version .. " loaded correctly")
print("Edith Rebuilt " .. EdithRebuilt.Version .. " loaded correctly")