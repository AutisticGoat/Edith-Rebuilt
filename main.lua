edithMod = RegisterMod("Edith Kotry Build", 1)
local mod = edithMod

local myFolder = "resources.scripts.EdithKotryLibraryOfIsaac"
local LOCAL_TSIL = require(myFolder .. ".TSIL")
LOCAL_TSIL.Init(myFolder)

edithMod.JumpLib = include("resources/scripts/EdithKotryJumpLib")
edithMod.JumpLib.Init(mod)

include("include")
edithMod.saveManager = include("resources.scripts.save_manager")
edithMod.saveManager.Init(mod)