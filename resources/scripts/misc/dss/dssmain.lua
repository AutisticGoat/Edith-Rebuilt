---@diagnostic disable: undefined-field
local mod = EdithRebuilt
local saveManager = mod.SaveManager
local menuProvider = {}

function menuProvider.SaveSaveData()
    saveManager.Save()
end

function menuProvider.GetPaletteSetting()
    return saveManager.GetDeadSeaScrollsSave().MenuPalette
end
function menuProvider.SavePaletteSetting(var)
    saveManager.GetDeadSeaScrollsSave().MenuPalette = var
end

function menuProvider.GetHudOffsetSetting()
    return Options.HUDOffset * 10
end

function menuProvider.GetGamepadToggleSetting()
    return saveManager.GetDeadSeaScrollsSave().GamepadToggle
end

function menuProvider.SaveGamepadToggleSetting(var)
    saveManager.GetDeadSeaScrollsSave().GamepadToggle = var
end

function menuProvider.GetMenuKeybindSetting()
    return saveManager.GetDeadSeaScrollsSave().MenuKeybind
end
function menuProvider.SaveMenuKeybindSetting(var)
    saveManager.GetDeadSeaScrollsSave().MenuKeybind = var
end

function menuProvider.GetMenuHintSetting()
    return saveManager.GetDeadSeaScrollsSave().MenuHint
end
function menuProvider.SaveMenuHintSetting(var)
    saveManager.GetDeadSeaScrollsSave().MenuHint = var
end

function menuProvider.GetMenuBuzzerSetting()
    return saveManager.GetDeadSeaScrollsSave().MenuBuzzer
end
function menuProvider.SaveMenuBuzzerSetting(var)
    saveManager.GetDeadSeaScrollsSave().MenuBuzzer = var
end

function menuProvider.GetMenusNotified()
    return saveManager.GetDeadSeaScrollsSave().MenusNotified
end
function menuProvider.SaveMenusNotified(var)
    saveManager.GetDeadSeaScrollsSave().MenusNotified = var
end

function menuProvider.GetMenusPoppedUp()
    return saveManager.GetDeadSeaScrollsSave().MenusPoppedUp
end
function menuProvider.SaveMenusPoppedUp(var)
    saveManager.GetDeadSeaScrollsSave().MenusPoppedUp = var
end

local dssInitializerFunction = include("resources.scripts.misc.dss.dssmenucore")
local dssMod = dssInitializerFunction.init("Dead Sea Scrolls (D!Edith)", menuProvider)
local menu = {}

menu.main = {
    title = "edith: rebuilt",
    tooltip = dssMod.menuOpenToolTip,
    buttons = {
        dssMod.changelogsButton,
    }
}

menu.menuSettings = {
    title = "menu settings",
    buttons = {
        dssMod.hudOffsetButton,
        dssMod.gamepadToggleButton,
        dssMod.menuKeybindButton,
        dssMod.menuHintButton,
        dssMod.menuBuzzerButton,
        dssMod.paletteButton
    }
}

local directoryKey = {
    Item = menu.main,
    Main = "main",
    Idle = false,
    MaskAlpha = 1,
    Settings = {},
    SettingsChanged = false,
    Path = {},
}

DeadSeaScrollsMenu.AddMenu("Edith: Rebuilt", {
    Run = dssMod.runMenu,

    Open = dssMod.openMenu,

    Close = dssMod.closeMenu,

    UseSubMenu = false,
    Directory = menu,
    DirectoryKey = directoryKey
})