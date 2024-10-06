-- Registro de variables
edithMod = RegisterMod("Edith Kotry Build", 1)
local mod = edithMod
-- local game = Game()
-- local modrng = RNG()
-- Fin registro de variables

-- Library of Isaac Init
local myFolder = "resources.scripts.EdithKotryLibraryOfIsaac"
local LOCAL_TSIL = require(myFolder .. ".TSIL")
LOCAL_TSIL.Init(myFolder)
-- Library of Isaac Init end

edithMod.JumpLib = include("resources/scripts/EdithKotryJumpLib")
edithMod.JumpLib.Init(mod)

include("include")
edithMod.saveManager = include("resources.scripts.save_manager")
edithMod.saveManager.Init(mod)
-- Save Manager Init