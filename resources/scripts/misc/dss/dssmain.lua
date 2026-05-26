local DSSModName = "Dead Sea Scrolls (Edith: Rebuilt)"
local DSSCoreVersion = 7
local mod = EdithRebuilt
local saveManager = mod.SaveManager
local MenuProvider = {}

local BREAK_LINE = {str = "", fsize = 1, nosel = true}

local function GenerateTooltip(str)
    local endTable = {}
    local currentString = ""
    for w in str:gmatch("%S+") do
        local newString = currentString .. w .. " "
        if newString:len() >= 15 then
            table.insert(endTable, currentString)
            currentString = ""
        end

        currentString = currentString .. w .. " "
    end

    table.insert(endTable, currentString)
    return {strset = endTable}
end

function MenuProvider.SaveSaveData()
    saveManager.GetPersistentSave()
end

function MenuProvider.GetPaletteSetting()
    return saveManager.GetPersistentSave().MenuPalette
end

function MenuProvider.SavePaletteSetting(var)
    saveManager.GetPersistentSave().MenuPalette = var
end

function MenuProvider.GetGamepadToggleSetting()
    return saveManager.GetPersistentSave().GamepadToggle
end

function MenuProvider.SaveGamepadToggleSetting(var)
    saveManager.GetPersistentSave().GamepadToggle = var
end

function MenuProvider.GetMenuKeybindSetting()
    return saveManager.GetPersistentSave().MenuKeybind
end

function MenuProvider.SaveMenuKeybindSetting(var)
    saveManager.GetPersistentSave().MenuKeybind = var
end

function MenuProvider.GetMenuHintSetting()
    return saveManager.GetPersistentSave().MenuHint
end

function MenuProvider.SaveMenuHintSetting(var)
    saveManager.GetPersistentSave().MenuHint = var
end

function MenuProvider.GetMenuBuzzerSetting()
    return saveManager.GetPersistentSave().MenuBuzzer
end

function MenuProvider.SaveMenuBuzzerSetting(var)
    saveManager.GetPersistentSave().MenuBuzzer = var
end

function MenuProvider.GetMenusNotified()
    return saveManager.GetPersistentSave().MenusNotified
end

function MenuProvider.SaveMenusNotified(var)
    saveManager.GetPersistentSave().MenusNotified = var
end

function MenuProvider.GetMenusPoppedUp()
    return saveManager.GetPersistentSave().MenusPoppedUp
end

function MenuProvider.SaveMenusPoppedUp(var)
    saveManager.GetPersistentSave().MenusPoppedUp = var
end

local dssmenucore = include("resources.scripts.misc.dss.dssmenucore")
local dssmod = dssmenucore.init(DSSModName, MenuProvider)
local edithDir = {
    main = {
        title = "edith: rebuilt",
        buttons = {
            {str = "resume game", action = "resume"},
            -- {str = "settings", dest = "settings"},
            dssmod.changelogsButton
        },
        tooltip = dssmod.menuOpenToolTip
    },
    menuOptions = {
        title = "menu options",
        buttons = {
            dssmod.gamepadToggleButton,
            dssmod.menuKeybindButton,
            dssmod.paletteButton,
            dssmod.menuHintButton,
            dssmod.menuBuzzerButton
        },
    },
}

local edithDirKey = {
    Item = edithDir.main,
    Main = "main",
    Idle = false,
    MaskAlpha = 1,
    Settings = {},
    SettingsChanged = false,
    Path = {}
}

DeadSeaScrollsMenu.AddMenu(
    "Edith: Rebuilt",
    {
        Run = dssmod.runMenu,
        Open = dssmod.openMenu,
        Close = dssmod.closeMenu,
        Directory = edithDir,
        DirectoryKey = edithDirKey
    }
)
