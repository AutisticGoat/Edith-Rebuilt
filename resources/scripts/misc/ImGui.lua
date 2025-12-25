local mod = EdithRebuilt
local enums = mod.Enums
local tables = enums.Tables
local variants = enums.EffectVariant
local ImGuiTables = tables.ImGuiTables
local callbacks = enums.Callbacks
local achievements = enums.Achievements
local RenderMenu = true
local SaveManager = mod.SaveManager
local data = mod.DataHolder.GetEntityData

---@class EdithData
---@field TargetDesign number
---@field TargetColor table
---@field TargetLine boolean
---@field RGBMode boolean
---@field RGBSpeed number
---@field EnableExtraGore boolean
---@field DisableSaltGibs boolean
---@field StompSound number
---@field StompVolume number
---@field JumpCooldownSound number
---@field DropKey2Jump boolean
---@field TrainingMode boolean
---@field CustomStompDmgMult number
---@field DefensiveStompWindow number
---@field CustomJumpButton Keyboard|integer
---@field SaltShakerSlot integer

---@class TEdithData
---@field ArrowDesign number
---@field ArrowColor table
---@field EnableHopdashTrail boolean
---@field TrailDesign number
---@field TrailColor table
---@field RGBMode boolean
---@field RGBSpeed number
---@field EnableExtraGore boolean
---@field DisableSaltGibs boolean
---@field HopSound number
---@field ParrySound number
---@field Volume number
---@field ParryCooldownSound number

---@class MiscData 
---@field CustomActionKey Keyboard
---@field EnableShakescreen boolean

local function isTaintedEdithUnlocked()
	return Isaac.GetPersistentGameData():Unlocked(achievements.ACHIEVEMENT_TAINTED_EDITH)
end

local MainPrefix = "EdithRebuilt_"
local Prefixes = {
	Menu = MainPrefix .. "Menu_",
	Window = MainPrefix .. "Window_",
	TabBar = MainPrefix .. "TabBar_",
	Tab = MainPrefix .. "Tab_",
	Separator = MainPrefix .. "Separator_",
	ProgressBar = MainPrefix .. "ProgressBar_",
	Edith = {
		Visuals = MainPrefix .. "Edith_" .. "Visuals_",
		Sounds = MainPrefix .. "Edith_" .. "Sounds_" ,
		Gameplay = MainPrefix .. "Edith_" .. "Gameplay_",
	},
	TEdith = {
		Visuals = MainPrefix .. "Tainted_Edith_" .. "Visuals_",
		Sounds = MainPrefix .. "Tainted_Edith_" .. "Sounds_",
		Gameplay = MainPrefix .. "Tainted_Edith_" .. "Gameplay_",
	},
	Misc = {
		Input = MainPrefix .. "Misc_" .. "Input_",
		ResetData = MainPrefix .. "Misc_" .. "ResetData_",
		Misc = MainPrefix .. "Misc_" .. "Misc_",
	}
}

local elementTab = {}
local Elements = {
	Menu = {
		SubMenu = {
			Settings = Prefixes.Menu .. "Settings",
			Credits = Prefixes.Menu .. "Credits",
			Progress = Prefixes.Menu .. "Progress",
			Changelog = Prefixes.Menu .. "Changelog",
		},
		Windows = {
			Settings = Prefixes.Window .. "Settings",
			Credits = Prefixes.Window .. "Credits",
			Progress = Prefixes.Window .. "Progress",
			Changelog = Prefixes.Window .. "Changelog",
		},
		TabBars = {
			Settings = Prefixes.TabBar .. "Settings",
			Edith = Prefixes.TabBar .. "Edith",
			TEdith = Prefixes.TabBar .. "Tainted_Edith",
			Credits = Prefixes.TabBar .. "Credits",
			Changelog = Prefixes.TabBar .. "Changelog"
		},
		Tabs = {
			Edith = {
				Main = Prefixes.Tab .. "Edith_Main",
				Visuals = Prefixes.Tab .. "Edith_Visuals",
				Sounds = Prefixes.Tab .. "Edith_Sounds",
				Gameplay = Prefixes.Tab .. "Edith_Gameplay"
			},
			TEdith = {
				Main = Prefixes.Tab .. "Tainted_Edith_Main",
				Visuals = Prefixes.Tab .. "Tainted_Edith_Visuals",
				Sounds = Prefixes.Tab .. "Tainted_Edith_Sounds",
				-- Gameplay = Prefixes.Tab .. "TaintedEdith_Gameplay"
			},
			Misc = {
				Main = Prefixes.Tab .. "Misc_Main"
			},
			Credits = {
				Resources = Prefixes.Tab .. "Resources",
				Contributors = Prefixes.Tab .. "Contributors",
				Testers = Prefixes.Tab .. "Testers",
				Team = Prefixes.Tab .. "Team"
			},
		},
		Separator = {
			Edith = {
				Visuals = {
					Target = Prefixes.Separator .. "Edith_Visual_Target",
					RGB = Prefixes.Separator .. "Edith_Visual_RGB",
					Stomp = Prefixes.Separator .. "Edith_Visua_lStomp,"
				},
				Sounds = {
					Stomp = Prefixes.Separator .. "Edith_Sounds_Stomp",
					Cooldown = Prefixes.Separator .. "Edith_Sounds_Cooldown"
				},
				Gameplay = {
					Stomp = Prefixes.Separator .. "Edith_Gameplay_Misc",
					Inputs = Prefixes.Separator .. "Edith_Gameplay_Inputs",
					Salt_Shaker = Prefixes.Separator .. "Edith_Gameplay_Salt_Shaker",
				}
			},
			TEdith = {
				Visuals = {
					Arrow = Prefixes.Separator .. "Tainted_Edith_Visual_Arrow",
					Trail = Prefixes.Separator .. "Tainted_Edith_Visual_Trail",
					RGB = Prefixes.Separator .. "Tainted_Edith_Visual_RGB",
					HopParry = Prefixes.Separator .. "Tainted_Edith_Visual_HopParry,"
				},
				Sounds = {
					HopParry = Prefixes.Separator .. "Tainted_Edith_Sounds_HopParry",
					Cooldown = Prefixes.Separator .. "Tainted_Edith_Sounds_Cooldown"
				},
				-- Gameplay = {
				-- 	Inputs = Prefixes.Separator .. "TEdith_Gameplay_Inputs",
				-- 	Training = Prefixes.Separator .. "TEdith_GameplayTraining"
				-- }
			},
			Misc = {
				Input = Prefixes.Separator .. "Misc_Input",
				ResetData = Prefixes.Separator .. "Misc_ResetData",
				Misc = Prefixes.Separator .. "Misc_Misc",
			},
		},
		ProgressBar = {
			Edith = Prefixes.ProgressBar .. "Edith",
			TEdith = Prefixes.ProgressBar .. "TEdith",
			General = Prefixes.ProgressBar .. "General"
		}
	},
	Options = {
		Edith = {
		Visuals = {
			TargetDesign = Prefixes.Edith.Visuals .. "TargetDesign",
			TargetColor = Prefixes.Edith.Visuals .. "TargetColor",
			TargetLine = Prefixes.Edith.Visuals .. "TargetLine",
			SetRGBMode = Prefixes.Edith.Visuals .. "SetRGBMode",
			SetRGBSpeed = Prefixes.Edith.Visuals .. "SetRGBSpeed",
			EnableExtraGore = Prefixes.Edith.Visuals .. "EnableExtraGore",
			DisableSaltGibs = Prefixes.Edith.Visuals .. "DisableGibs",
		},
		Sounds = {
			SetStompSound = Prefixes.Edith.Sounds .. "SetStompSound",
			SetStompVolume = Prefixes.Edith.Sounds .. "SetStompVolume",
			SetJumpCooldownSound = Prefixes.Edith.Sounds .. "SetJumpCooldownSound",
		},
		Gameplay = {
			EnableDropKey2Jump = Prefixes.Edith.Gameplay .. "EnableDropKey2Jump",
			CustomJumpKey = Prefixes.Edith.Gameplay .. "CustomJumpKey",
			SaltShakerSlot = Prefixes.Edith.Gameplay .. "SaltShaker",
			-- EnableTrainingMode = Prefixes.Edith.Gameplay .. "EnableTrainingMode",
			DefensiveStompWindow = Prefixes.Edith.Gameplay .. "DefensiveStompWindow",
		}
	},
	TEdith = {
		Visuals = {
			ArrowDesign = Prefixes.TEdith.Visuals .. "ArrowDesign",
			ArrowColor = Prefixes.TEdith.Visuals .. "ArrowColor",
			EnableHopdashTrail = Prefixes.TEdith.Visuals .. "EnableHopdashTrail",
			TrailDesign = Prefixes.TEdith.Visuals .. "TrailDesign",
			TrailColor = Prefixes.TEdith.Visuals .. "TrailColor",
			SetRGBMode = Prefixes.TEdith.Visuals .. "SetRGBMode",
			SetRGBSpeed = Prefixes.TEdith.Visuals .. "SetRGBSpeed",
			EnableExtraGore = Prefixes.TEdith.Visuals .. "EnableExtraGore",
			DisableSaltGibs = Prefixes.TEdith.Visuals .. "DisableSaltGibs",
		},
		Sounds = {
			SetHopSound = Prefixes.TEdith.Sounds .. "SetHopSound",
			SetParrySound = Prefixes.TEdith.Sounds .. "SetParrySound",
			SetVolume = Prefixes.TEdith.Sounds .. "SetVolume",
			SetParryCooldownSound = Prefixes.TEdith.Sounds .. "SetParryCooldownSound",
		}
		},
		Misc = {
			CustomActionKey = Prefixes.Misc.Input .. "CustomActionKey",
			ResetEdithData = Prefixes.Misc.ResetData .. "ResetEdithData",
			ResetTEdithData = Prefixes.Misc.ResetData .. "ResetTaintedEdithData",
			EnableShakescreen = Prefixes.Misc.Misc .. "EnableShakescreen",
		}
	}
}

local Menu = Elements.Menu
local Options = Elements.Options

if not ImGui.ElementExists("EdithRebuilt") then
	if RenderMenu == false then return end
    ImGui.CreateMenu('EdithRebuilt', '\u{f11a} Edith: Rebuilt')
end

local function AddMenuElement(name, title)
	if RenderMenu == false and ImGui.ElementExists(name) then return end
    ImGui.AddElement("EdithRebuilt", name, ImGuiElement.MenuItem, "\u{f013} " .. title)
end

local MenuElements = {
    { name = Menu.SubMenu.Settings, title = "Settings" },
    { name = Menu.SubMenu.Credits, title = "Credits" },
    { name = Menu.SubMenu.Progress, title = "Progress" },
    { name = Menu.SubMenu.Changelog, title = "Changelog" }
}

for _, Menu in ipairs(MenuElements) do
    AddMenuElement(Menu.name, Menu.title)
end

local windows = {
    { name = Menu.Windows.Settings, title = "Settings" },
    { name = Menu.Windows.Credits, title = "Credits" },
	{ name = Menu.Windows.Progress, title = "Progress"},
	{ name = Menu.Windows.Changelog, title = "Changelog"},
}

for _, window in ipairs(windows) do
	if RenderMenu == false and ImGui.ElementExists(window.name) then return end
    ImGui.CreateWindow(window.name, window.title)
end

local links = {
	{ window = Menu.Windows.Settings, menu = Menu.SubMenu.Settings },
	{ window = Menu.Windows.Credits, menu = Menu.SubMenu.Credits },
	{ window = Menu.Windows.Progress, menu = Menu.SubMenu.Progress },
	{ window = Menu.Windows.Changelog, menu = Menu.SubMenu.Changelog },
}

for _, link in ipairs(links) do
	ImGui.LinkWindowToElement(link.window, link.menu)
end

local function UpdateImGuiData()
	-- print("Loaded function")

	if not SaveManager.IsLoaded() then return end
	local saveData = SaveManager.GetSettingsSave()
	
	-- print("Loaded Save Manager")

	if not saveData then return end

	-- print("Loaded save data")

	-- if not mod:CheckImGuiIntegrity() then return end
	
	

	local EdithData = saveData.EdithData ---@cast EdithData EdithData
	local TEdithData = saveData.TEdithData ---@cast TEdithData TEdithData
	local MiscData = saveData.MiscData ---@cast MiscData MiscData
	local Options = Elements.Options
	local EdithOptions = Options.Edith
	local TEdithOptions = Options.TEdith
	local MiscOptions = Options.Misc

	local data = {
		[MiscOptions.CustomActionKey] = MiscData.CustomActionKey or Keyboard.KEY_Z,
		[MiscOptions.EnableShakescreen] = MiscData.EnableShakescreen or false,

		[EdithOptions.Visuals.TargetDesign] = (EdithData.TargetDesign - 1) or 0,
		[EdithOptions.Visuals.TargetLine] = EdithData.TargetLine or false,
		[EdithOptions.Visuals.SetRGBMode] = EdithData.RGBMode or false,
		[EdithOptions.Visuals.SetRGBSpeed] = EdithData.RGBSpeed or 0.005,
		[EdithOptions.Visuals.EnableExtraGore] = EdithData.EnableExtraGore or false,
		[EdithOptions.Visuals.DisableSaltGibs] = EdithData.DisableSaltGibs or false,
		[EdithOptions.Sounds.SetStompSound] = (EdithData.StompSound - 1) or 0,
		[EdithOptions.Sounds.SetStompVolume] = EdithData.StompVolume or 100,
		[EdithOptions.Sounds.SetJumpCooldownSound] = (EdithData.JumpCooldownSound - 1) or 0,
		[EdithOptions.Gameplay.DefensiveStompWindow] = EdithData.DefensiveStompWindow or 15,
		[EdithOptions.Gameplay.SaltShakerSlot] = EdithData.SaltShakerSlot or 0,
	}

	if isTaintedEdithUnlocked() then
		local taintedData = {
			[TEdithOptions.Visuals.ArrowDesign] = (TEdithData.ArrowDesign - 1) or 0,
			[TEdithOptions.Visuals.EnableHopdashTrail] = TEdithData.EnableHopdashTrail or false,
			[TEdithOptions.Visuals.TrailDesign] = (TEdithData.TrailDesign - 1) or 0,
			[TEdithOptions.Visuals.SetRGBMode] = TEdithData.RGBMode or false,
			[TEdithOptions.Visuals.SetRGBSpeed] = TEdithData.RGBSpeed or 0.005,
			[TEdithOptions.Visuals.EnableExtraGore] = TEdithData.EnableExtraGore or false,
			[TEdithOptions.Visuals.DisableSaltGibs] = TEdithData.DisableSaltGibs or false,
			[TEdithOptions.Sounds.SetHopSound] = (TEdithData.HopSound - 1) or 0,
			[TEdithOptions.Sounds.SetParrySound] = (TEdithData.ParrySound - 1) or 0,
			[TEdithOptions.Sounds.SetVolume] = TEdithData.Volume or 100,
		}

		for k, v in pairs(taintedData) do
			data[k] = v
		end

		local arrowcolor = TEdithData.ArrowColor
		local trailColor = TEdithData.TrailColor

		ImGui.UpdateData(TEdithOptions.Visuals.ArrowColor, ImGuiData.ColorValues, 
		{
			arrowcolor.Red,
			arrowcolor.Green,
			arrowcolor.Blue,
		})
		ImGui.UpdateData(TEdithOptions.Visuals.TrailColor, ImGuiData.ColorValues, 
		{
			trailColor.Red,
			trailColor.Green,
			trailColor.Blue,
		})
	end

	for option, newValue in pairs(data) do
		ImGui.UpdateData(option, ImGuiData.Value, newValue)
	end

	ImGui.UpdateData(MiscOptions.CustomActionKey, ImGuiData.Value, MiscData.CustomActionKey)

	local targetColor = EdithData.TargetColor

	ImGui.UpdateData(EdithOptions.Visuals.TargetColor, ImGuiData.ColorValues, 
	{
		targetColor.Red,
		targetColor.Green,
		targetColor.Blue,
	})
end

local function ResetSaveData(isTainted)
	local SaveManager = mod.SaveManager
	if not SaveManager then return end
	local menuData = SaveManager.GetSettingsSave()
	if not menuData then return end

	local EdithData = menuData.EdithData ---@cast EdithData EdithData
	local TEdithData = menuData.TEdithData ---@cast TEdithData TEdithData

	if isTainted then
		TEdithData.ArrowColor = {Red = 1, Green = 0, Blue = 0}
		TEdithData.TrailColor = {Red = 1, Green = 0, Blue = 0}
		TEdithData.ArrowDesign = 1
		TEdithData.HopSound = 1
		TEdithData.Volume = 100
		TEdithData.ParrySound = 1
		TEdithData.RGBMode = false
		TEdithData.EnableExtraGore = false
		TEdithData.RGBSpeed = 0.005
		TEdithData.TrailDesign = 1
	else
		EdithData.TargetColor = {Red = 1, Green = 1, Blue = 1}
		EdithData.StompSound = 1
		EdithData.StompVolume = 100
		EdithData.EnableExtraGore = false
		EdithData.TargetDesign = 1
		EdithData.DisableSaltGibs = false
		EdithData.RGBMode = false
		EdithData.RGBSpeed = 0.005
		EdithData.TargetLine = false
		EdithData.JumpCooldownSound = 1
		EdithData.DefensiveStompWindow = 15
		EdithData.SaltShakerSlot = 0
	end

	UpdateImGuiData()

	RenderMenu = true
end

local TEdithOptions = {}

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
	UpdateImGuiData()
end)

---@param tabla table
---@param prefijo? string
local function recorrerTablaImGui(tabla, prefijo)
    prefijo = prefijo or ""
    for clave, valor in pairs(tabla) do
        if type(valor) == "table" then
            recorrerTablaImGui(valor, prefijo .. clave .. ".")
        else
			if not ImGui.ElementExists(valor) then
				if not string.find(valor, "Tainted") then 
					elementTab[clave] = valor
				end
			end
        end
    end
end
recorrerTablaImGui(Elements)

local function AddTEdithOptionsToElements()
	if not isTaintedEdithUnlocked() then return end
	for k, v in pairs(TEdithOptions) do
		elementTab[k] = v
	end
end

function mod:CheckImGuiIntegrity()
	for _, ID in pairs(elementTab) do
		if not ImGui.ElementExists(ID) then return false end
	end
	return true
end

-- local TrainingOptions = {
-- 	EdithStompMultDamage = Prefixes.Edith.Gameplay .. "EdithStompMultDamage",
-- }

local function AddTabBars()
	ImGui.AddTabBar(Elements.Menu.Windows.Settings, Elements.Menu.TabBars.Settings)
	
	ImGui.AddTab(Elements.Menu.TabBars.Settings, Elements.Menu.Tabs.Edith.Main, "Edith")
	if isTaintedEdithUnlocked() then
		ImGui.AddTab(Elements.Menu.TabBars.Settings, Elements.Menu.Tabs.TEdith.Main, "Tainted Edith")
	end
	ImGui.AddTab(Elements.Menu.TabBars.Settings, Elements.Menu.Tabs.Misc.Main, "Misc")
end

local function AddEdithOptions()
	local EdithTabBar = Elements.Menu.TabBars.Edith
	local EdithTab = Elements.Menu.Tabs.Edith.Main
	local EdithVisuals = Elements.Menu.Tabs.Edith.Visuals
	local EdithSounds = Elements.Menu.Tabs.Edith.Sounds
	local EdithGameplay = Elements.Menu.Tabs.Edith.Gameplay
	local OptionVisuals = Elements.Options.Edith.Visuals
	local OptionSounds = Elements.Options.Edith.Sounds
	local OptionGameplay = Elements.Options.Edith.Gameplay
	local Separator = Elements.Menu.Separator.Edith
	local EdithData = SaveManager:GetSettingsSave().EdithData --[[@as EdithData]]

	ImGui.AddTabBar(EdithTab, EdithTabBar)
	ImGui.AddTab(EdithTabBar, EdithVisuals, "Visuals")
	ImGui.AddTab(EdithTabBar, EdithSounds, "Sounds")
	ImGui.AddTab(EdithTabBar, EdithGameplay, "Gameplay")

-- Visuals
	ImGui.AddElement(EdithVisuals, Separator.Visuals.Target, ImGuiElement.SeparatorText, "Target")
	ImGui.AddCombobox(EdithVisuals, OptionVisuals.TargetDesign, "Set Target Design", 
		function(index)
			EdithData.TargetDesign = index + 1
			for _, target in pairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, variants.EFFECT_EDITH_TARGET)) do
				Isaac.RunCallback(callbacks.TARGET_SPRITE_CHANGE, target)
			end
		end,
	ImGuiTables.TargetDesign, 0, false)

	ImGui.AddInputColor(EdithVisuals, OptionVisuals.TargetColor, "Target Color",
		function(r, g, b)
			EdithData.TargetColor = {
				Red = r,
				Green = g,
				Blue = b,
			}
		end,
	1, 1, 1)
	ImGui.SetHelpmarker(OptionVisuals.TargetColor, "Only works when target design is set to Choose Color")
	ImGui.AddCheckbox(EdithVisuals, OptionVisuals.TargetLine, "Enable Target line", 
		function(check)
			EdithData.TargetLine = check
		end,
	false)

	ImGui.AddElement(EdithVisuals, Separator.Visuals.RGB, ImGuiElement.SeparatorText, "RGB")
	ImGui.AddCheckbox(EdithVisuals, OptionVisuals.SetRGBMode, "Set RGB Mode", 
		function(check)
			EdithData.RGBMode = check
		end,
	false)
	ImGui.SetHelpmarker(OptionVisuals.SetRGBMode, "Makes the target cycle between colors \nOnly works when target design is set to Choose Color")

	ImGui.AddSliderFloat(EdithVisuals, OptionVisuals.SetRGBSpeed, "Set RGB Speed",
		function(val)
			EdithData.RGBSpeed = val
		end,
	0.005, 0.001, 0.03, "%.5f")

	ImGui.AddElement(EdithVisuals, Separator.Visuals.Stomp, ImGuiElement.SeparatorText, "Stomp")
	ImGui.AddCheckbox(EdithVisuals, OptionVisuals.EnableExtraGore, "Enable stomp kill extra gore", 
		function(check)
			EdithData.EnableExtraGore = check
		end,
	false)
	ImGui.AddCheckbox(EdithVisuals, OptionVisuals.DisableSaltGibs, "Disable salt gibs", 
		function(check)
			EdithData.DisableSaltGibs = check
		end, 
	false)
-- Visuals end

-- Sounds
	ImGui.AddElement(EdithSounds, Separator.Sounds.Stomp, ImGuiElement.SeparatorText, "Stomp")
	ImGui.AddCombobox(EdithSounds, OptionSounds.SetStompSound, "Set Stomp Sound", 
		function(index)
			EdithData.StompSound = index + 1
		end, 
	ImGuiTables.StompSound, 0)
	ImGui.AddSliderInteger(EdithSounds, OptionSounds.SetStompVolume, "Set stomp volume", 
		function(index)
			EdithData.StompVolume = index
		end, 
	100, 25, 100, "%d%")

	ImGui.AddElement(EdithSounds, Separator.Sounds.Cooldown, ImGuiElement.SeparatorText, "Cooldown")
	ImGui.AddCombobox(EdithSounds, OptionSounds.SetJumpCooldownSound, "Set jump cooldown sound", 
		function(index)
			EdithData.JumpCooldownSound = index + 1
		end, 
	{"Stone", "Beep"}, 0, true)
-- Sounds end

-- Gameplay
	ImGui.AddElement(EdithGameplay, Separator.Gameplay.Stomp, ImGuiElement.SeparatorText, "Stomp")
	ImGui.AddSliderInteger(EdithGameplay, OptionGameplay.DefensiveStompWindow, "Change Edith's defensive stomp window",
		function(val)
			EdithData.DefensiveStompWindow = val
		end,
	15, 5, 25)

	ImGui.AddElement(EdithGameplay, Separator.Gameplay.Salt_Shaker, ImGuiElement.SeparatorText, "Salt Shaker")
	ImGui.AddCombobox(EdithGameplay, OptionGameplay.SaltShakerSlot, "Salt Shaker's slot", 
		function(option)
			EdithData.SaltShakerSlot = option
		end
	, {"Main" , "Pocket"}, EdithData.SaltShakerSlot or 0, true)

	ImGui.SetHelpmarker(OptionGameplay.SaltShakerSlot, "\u{21} This will only work  a new run")

	-- ImGui.AddElement(EdithGameplay, Separator.Gameplay.Training, ImGuiElement.SeparatorText, "Training")
	-- ImGui.AddCheckbox(EdithGameplay, OptionGameplay.EnableTrainingMode, "Enable Training Mode", 
	-- 	function(check)
	-- 		EdithData.TrainingMode = check
	-- 		-- DisplayTrainingOptions(check)
	-- 	end,
	-- false)
	-- ImGui.SetHelpmarker(OptionGameplay.EnableTrainingMode, "Enable Edith's training mode, making it able to adjust some values \n\u{21} Mod's achievements will be unobtainable in the run")
-- Gameplay end
end

local function AddTaintedEdithOptions()
	if not isTaintedEdithUnlocked() then return end
	local TEdithTabBar = Elements.Menu.TabBars.TEdith
	local TEdithTab = Elements.Menu.Tabs.TEdith.Main
	local TEdithVisuals = Elements.Menu.Tabs.TEdith.Visuals
	local TEdithSounds = Elements.Menu.Tabs.TEdith.Sounds
	-- local TEdithGameplay = Elements.Menu.Tabs.TEdith.Gameplay
	local OptionVisuals = Elements.Options.TEdith.Visuals
	local OptionSounds = Elements.Options.TEdith.Sounds
	local Separator = Elements.Menu.Separator.TEdith
	local TEdithData = SaveManager:GetSettingsSave().TEdithData --[[@as TEdithData]]

	ImGui.AddTabBar(TEdithTab, TEdithTabBar)
	ImGui.AddTab(TEdithTabBar, TEdithVisuals, "Visuals")
	ImGui.AddTab(TEdithTabBar, TEdithSounds, "Sounds")
	-- ImGui.AddTab(TEdithTabBar, EdithGameplay, "Gameplay")

-- Visuals
	ImGui.AddElement(TEdithVisuals, Separator.Visuals.Arrow, ImGuiElement.SeparatorText, "Arrow")
	ImGui.AddCombobox(TEdithVisuals, OptionVisuals.ArrowDesign, "Set Arrow Design", 		
		function(index)
			TEdithData.ArrowDesign = index + 1
			for _, arrow in pairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, variants.EFFECT_EDITH_B_TARGET)) do
				Isaac.RunCallback(callbacks.TARGET_SPRITE_CHANGE, arrow)
			end
		end,
	ImGuiTables.ArrowDesign, 0)
	ImGui.AddInputColor(TEdithVisuals, OptionVisuals.ArrowColor, "Arror Color", 
		function(r, g, b)
			TEdithData.ArrowColor = {
				Red = r,
				Green = g,
				Blue = b,
			}
		end,
	1, 1, 1)

	ImGui.AddElement(TEdithVisuals, Separator.Visuals.Trail, ImGuiElement.SeparatorText, "Trail")
	ImGui.AddCheckbox(TEdithVisuals, OptionVisuals.EnableHopdashTrail, "Enable hopdash trail", 
		function(check) 
			TEdithData.EnableHopdashTrail = check
		end, 
	false)
	ImGui.AddCombobox(TEdithVisuals, OptionVisuals.TrailDesign, "Set Target Design",
		function(index)
			TEdithData.TrailDesign = index + 1
			for _, trail in pairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.SPRITE_TRAIL)) do
				if not data(trail).EdithRebuilTrail then return end
				Isaac.RunCallback(callbacks.TRAIL_SPRITE_CHANGE, trail)
			end
		end, 
	ImGuiTables.TrailDesign, 0, false)
	ImGui.AddInputColor(TEdithVisuals, OptionVisuals.TrailColor, "Trail Color",
		function(r, g, b)
			TEdithData.TrailColor = {
				Red = r,
				Green = g,
				Blue = b,
			}
		end,
	1, 1, 1)

	ImGui.AddElement(TEdithVisuals, Separator.Visuals.RGB, ImGuiElement.SeparatorText, "RGB")
	ImGui.AddCheckbox(TEdithVisuals, OptionVisuals.SetRGBMode, "Set RGB Mode", 
	function(check)
		TEdithData.RGBMode = check
	end, false)
	ImGui.AddSliderFloat(TEdithVisuals, OptionVisuals.SetRGBSpeed, "Set RGB Speed", 
		function(index)
			TEdithData.RGBSpeed = index
		end,
	0.005, 0.001, 0.03, "%.5f")

	ImGui.AddElement(TEdithVisuals, Separator.Visuals.HopParry, ImGuiElement.SeparatorText, "Hop & Parry")
	ImGui.AddCheckbox(TEdithVisuals, OptionVisuals.EnableExtraGore, "Enable parry kill extra gore", 
		function(check)
			TEdithData.EnableExtraGore = check
		end,
	false)
	ImGui.AddCheckbox(TEdithVisuals, OptionVisuals.DisableSaltGibs, "Disable salt gibs", 
		function(check)
			TEdithData.DisableSaltGibs = check
		end,
	false)
-- Visuals end

-- Sounds
	ImGui.AddElement(TEdithSounds, Separator.Sounds.HopParry, ImGuiElement.SeparatorText, "Hop & Parry")
	ImGui.AddCombobox(TEdithSounds, OptionSounds.SetHopSound, "Set Hop Sound",
		function(index)
			TEdithData.HopSound = index + 1
		end,
	ImGuiTables.HopSound, 0)
	ImGui.AddCombobox(TEdithSounds, OptionSounds.SetParrySound, "Set Parry Sound",
		function(index)
			TEdithData.ParrySound = index + 1
		end,
	ImGuiTables.ParrySound, 0)
	ImGui.AddSliderInteger(TEdithSounds, OptionSounds.SetVolume, "Set stomp volume", 
		function(index)
			TEdithData.Volume = index 
		end,
	100, 25, 100, "%d%")

	ImGui.AddElement(TEdithSounds, Separator.Sounds.Cooldown, ImGuiElement.SeparatorText, "Cooldown")
	ImGui.AddCombobox(TEdithSounds, OptionSounds.SetParryCooldownSound, "Set parry cooldown sound", 
		function(index)
			TEdithData.ParryCooldownSound = index + 1
		end, 
	{"Stone", "Beep"}, 0, true)
-- Sounds end
end

local function AddMiscOptions()
	local MiscTab = Menu.Tabs.Misc.Main
	local MiscOptions = Options.Misc
	local Separator = Menu.Separator.Misc
	local MiscData = SaveManager:GetSettingsSave().MiscData --[[@as MiscData]]

	ImGui.AddElement(MiscTab, Separator.Input, ImGuiElement.SeparatorText, "Inputs")
	
	ImGui.AddInputKeyboard(MiscTab, MiscOptions.CustomActionKey, "Set custom action key", 
		function(ID)
			MiscData.CustomActionKey = ID
		end, 
	MiscData.CustomActionKey or Keyboard.KEY_Z)

	ImGui.AddElement(MiscTab, Separator.ResetData, ImGuiElement.SeparatorText, "Reset Data")
	ImGui.AddButton(MiscTab, MiscOptions.ResetEdithData, "Reset Edith Settings", 
		function()
			ResetSaveData(false)
		end, 
	true)
	if isTaintedEdithUnlocked() then
		ImGui.AddButton(MiscTab, MiscOptions.ResetTEdithData, "Reset Tainted Edith Settings", 
			function()
				ResetSaveData(true)
			end, 
		true)
	end
	ImGui.AddElement(MiscTab, Separator.Misc, ImGuiElement.SeparatorText, "Misc")
	ImGui.AddCheckbox(MiscTab, MiscOptions.EnableShakescreen, "Enable Stomp screen shake", 
		function(check)
			MiscData.EnableShakescreen = check
		end, 
	false)
end

local function AddContributors()
	ImGui.AddTabBar(Menu.Windows.Credits, Menu.TabBars.Credits)

	ImGui.AddTab(Menu.TabBars.Credits, Menu.Tabs.Credits.Resources, "Resources")
	ImGui.AddTab(Menu.TabBars.Credits, Menu.Tabs.Credits.Contributors, "Contributors")
	ImGui.AddTab(Menu.TabBars.Credits, Menu.Tabs.Credits.Testers, "Testers")
	ImGui.AddTab(Menu.TabBars.Credits, Menu.Tabs.Credits.Team, "Team")

	-- ImGui.AddElement(, Elements.Menu.SubMenu.Credits, )

	ImGui.AddText(Menu.Tabs.Credits.Resources, 
	[[
	Used resources and utilities:

	- JumpLib (Kerkel)
	- Custom Shockwave API (Brakedude)
	- Pre NPC kill callback (Kerkel)
	- Isaac Save Manager (Catinsurance, Benny)
	- HudHelper (Benny, CatWizard)
	- Status Effect Library (Benny)
	- SaveData System (AgentCucco)
	- lhsx (Ilya Kolbin (iskolbin))
	- Salt Shaker Sound Effect (Joshua Hadley): 
	- Edith water stomp sound effect (ArtNinja) 
	- Nine Sols Perfect Parry sound effect (Red Candle Games) 
	- Pizza Tower taunt sound effect (Tour De Pizza)
	- Ultrakill parry sound effect (New Blood, Arsi "Hakita" Patala)
	- Hollow Knight parry sound effect (Team Cherry) 
	- Iconoclasts parry sound effect (Joakim Sandberg (Konjak))
	]],
	true)

	ImGui.AddText(Menu.Tabs.Credits.Contributors, 
	[[
	Contributors: 

	- JJ: Inspiration to start this project
	- D!Edith team: Inspiration to resume this project
	- Skulldier: Sal concept
	- Marcy: Tainted Edith Birthright idea
	- Sr Kalaka: Edith Sprite
	- Yuls: Tainted Edith sprite base
	]], 
	true)

	ImGui.AddText(Menu.Tabs.Credits.Testers, 
	[[
	Testers:

	- ottostrasse
	- Jozin191
	- Tibu
	- SethoJunk
	- Noirsight
	- Sylvy_owo
	- .radiox
	- Edith's No.1 Fan
	]], 
	true)

	ImGui.AddText(Menu.Tabs.Credits.Team, 
	[[
	Team: 

	- gigamouse: finished Tainted Edith sprite, items sprites
	- Pattowolfx220: Testing, First Tainted Edith sprite, items sprites
	- Kotry: Project leader, coder, unlock sheets sprite
	]],
	true)
end

local function AddProgressBars()
	ImGui.AddProgressBar(Menu.Windows.Progress, Menu.ProgressBar.General, "General unlocks progress", 0)
	ImGui.AddProgressBar(Menu.Windows.Progress, Menu.ProgressBar.Edith, "Edith unlocks progress", 0)

	if isTaintedEdithUnlocked() then
		ImGui.AddProgressBar(Menu.Windows.Progress, Menu.ProgressBar.TEdith, "Tainted Edith unlocks progress", 0)
	end
end

local function AddChangelogs()
	ImGui.AddTabBar(Menu.Windows.Changelog, Menu.TabBars.Changelog)

	ImGui.AddTab(Menu.TabBars.Changelog, "EdithRebuilt_v1.0.0", "v1.0.0")
	ImGui.AddText("EdithRebuilt_v1.0.0", 
	[[
- Initial mod release
	]], true)

	ImGui.AddTab(Menu.TabBars.Changelog, "EdithRebuilt_v1.0.1", "v1.0.1")
	ImGui.AddText("EdithRebuilt_v1.0.1", 
	[[
- Fixed Tainted Edith's projectile parry not working at all
- Potentially fixed an error that doesn't trigger effect room transition (needs more testing)
- Now Edith won't take damage when pitfalling
- Now Tainted Edith has a chance to spawn Cinder creep when hop-landing (only at 100% hop charge)
- Now Edith can correctly interact with beggars and slots
	]], true)

	ImGui.AddTab(Menu.TabBars.Changelog, "EdithRebuilt_v1.0.2", "v1.0.2")
	ImGui.AddText("EdithRebuilt_v1.0.2", 
	[[
- Removed a leftover console print when stomping slots and beggars
- Fixed Edith's Marked interactions
- Fixed Edith's lump of coal interaction not working at all
- Now T.Edith's arrow will always have grudge design when playing Grudge challenge
- Now all stomp and parry synergies' functions are anonymous functions
- Fixed Edith shooting godhead stomp tears
- Second attempt to fix Target doors issue (hopefully it works now)
	]], true)

	ImGui.AddTab(Menu.TabBars.Changelog, "EdithRebuilt_v1.1.0", "v1.1.0")
	ImGui.AddText("EdithRebuilt_v1.1.0", 
	[[
- Reimplemented mod's data structure (big change that justified going to 1.1.0)
- (Hopefully) Fixed a rare and hard to reproduce error where Tainted Edith was unable to spawn her arrow
- Now Tainted Edith's hop-parry params are properly reset when starting a new run
- Now Edith's jump-stomp params are properly reset when starting a new run
- Fixed Edith triggering beggars and donation machines everytime
- Fixed Edith not getting damage when stomping devil beggars and blood donation machines
- Fixed a potential error regarding Tainted Edith trying to hop at nil charge
- Now target door manager will let you go trough open doors in uncleared rooms
- Fixed Edith being unable to go to black markets
- Fixed Edith going to error room in Rotgut's maggot phase 
	]], true)

	ImGui.AddTab(Menu.TabBars.Changelog, "EdithRebuilt_v1.2.0", "v1.2.0")
	ImGui.AddText("EdithRebuilt_v1.2.0", 
	[[
- Reimplemented mod's data structure (big change that justified going to 1.1.0)
- (Hopefully) Fixed a rare and hard to reproduce error where Tainted Edith was unable to spawn her arrow
- Now Tainted Edith's hop-parry params are properly reset when starting a new run
- Now Edith's jump-stomp params are properly reset when starting a new run
- Fixed Edith triggering beggars and donation machines everytime
- Fixed Edith not getting damage when stomping devil beggars and blood donation machines
- Fixed a potential error regarding Tainted Edith trying to hop at nil charge
- Now target door manager will let you go trough open doors in uncleared rooms
- Fixed Edith being unable to go to black markets
- Fixed Edith going to error room in Rotgut's maggot phase 
	]], true)

	ImGui.AddTab(Menu.TabBars.Changelog, "EdithRebuilt_v1.2.0", "v1.2.0")
	ImGui.AddText("EdithRebuilt_v1.2.0", 
	[[
- Fixed Salt rocks not triggering salted effect to enemies
- Fixed Edith not being able to go to void trough Mega Satan's portal
- Fixed bomb stomp consuming bombs when having dr fetus or epic fetus
- Fixed Salt creep being able to use a nil value to asign salted effect duration
- Fixed Edith being unable to play on Confessionals
- Fixed Tainted Edith's body dissapearing when having flight
- Fixed Edith's Hood not triggering its Landing effect
- Fixed Edith being unable to trigger enemy waves in challenge rooms when stomping stone chests
- Added The Future support
- Added EID support
- Added ingame changelogs
- Increased Edith's defensive stomp window frames (9 > 15)
- Now Defensive stomp frame window can be configured in ImGui Menu 
- Now Pepper creep wont spawn far away from peppered entity
- Now Tainted Edith can consistently interact with blood donation machines, devil beggars and confessionals
- Removed a unused item entry
- Removed leftover prints
	]], true)
end

-- ---@param enabled boolean
-- local function DisplayTrainingOptions(enabled)
-- 	if not SaveManager.IsLoaded() then return end
-- 	local saveData = SaveManager.GetSettingsSave()

-- 	if not saveData then return end
-- 	local EdithData = saveData.EdithData
-- 	local TEdithData = saveData.TEdithData
-- 	local MiscData = saveData.MiscData

-- 	if enabled then
-- 		ImGui.AddDragFloat("EdithGameplaySettings", TrainingOptions.EdithStompMultDamage, "Set Stomp damage Mult", 
-- 		function(val)
-- 			EdithData.CustomStompDmgMult = val
-- 		end, 1, 0.005, 1, 2)
-- 	else
-- 		for _, options in pairs(TrainingOptions) do
-- 			ImGui.RemoveElement(options)
-- 		end
-- 	end
-- end

local function OptionsUpdate()	
	if not RenderMenu then return end
	if not SaveManager.IsLoaded() then return end
	local saveData = SaveManager.GetSettingsSave()

	if not saveData then return end
	if mod:CheckImGuiIntegrity() then return end

	AddTabBars()
	AddEdithOptions()
	AddTaintedEdithOptions()
	AddMiscOptions()
	AddContributors()
	AddProgressBars()
	AddChangelogs()
	UpdateImGuiData()
	RenderMenu = false
end

local totalAchs = {}
local ModAchievements = {
	Edith = {
		achievements.ACHIEVEMENT_SALT_SHAKER,
		achievements.ACHIEVEMENT_SALT_HEART,
		achievements.ACHIEVEMENT_SAL,
		achievements.ACHIEVEMENT_DIVINE_RETRIBUTION,
		achievements.ACHIEVEMENT_MOLTEN_CORE,
		achievements.ACHIEVEMENT_PEPPER_GRINDER,
		achievements.ACHIEVEMENT_PEPPER_GRINDER,
		achievements.ACHIEVEMENT_GILDED_STONE,
		achievements.ACHIEVEMENT_HYDRARGYRUM,
		achievements.ACHIEVEMENT_EDITHS_HOOD,
		achievements.ACHIEVEMENT_CHUNK_OF_BASALT,
		achievements.ACHIEVEMENT_FAITH_OF_THE_UNFAITHFUL,
		achievements.ACHIEVEMENT_GEODE,
		achievements.ACHIEVEMENT_SULFURIC_FIRE,
		achievements.ACHIEVEMENT_TAINTED_EDITH,
	},
	TEdith = {
		achievements.ACHIEVEMENT_BURNT_HOOD,
		achievements.ACHIEVEMENT_PAPRIKA,
		achievements.ACHIEVEMENT_SALT_ROCKS,
		achievements.ACHIEVEMENT_BURNT_SALT,
		achievements.ACHIEVEMENT_DIVINE_WRATH,
		achievements.ACHIEVEMENT_JACK_OF_CLUBS,
		achievements.ACHIEVEMENT_SOUL_OF_EDITH,
	},
	Misc = {
		achievements.ACHIEVEMENT_THANK_YOU
	}
}

local function GetEdithUnlockedAchs()
	local count = 0
	for _, unlock in ipairs(ModAchievements.Edith) do
		if Isaac.GetPersistentGameData():Unlocked(unlock) then
			count = count + 1
		end
	end
	return count
end

local function GetTEdithUnlockedAchs()
	local count = 0
	for _, unlock in ipairs(ModAchievements.TEdith) do
		if Isaac.GetPersistentGameData():Unlocked(unlock) then
			count = count + 1
		end
	end
	return count
end

local function CheckProgressBarIntegrity()
	local boolean = true
	
	for _, ent in pairs(Menu.ProgressBar) do
		if not ImGui.ElementExists(ent) then
			boolean = false
			break
		end
	end

	return boolean
end

local function UpdateProgressBar()
	if not CheckProgressBarIntegrity() then return end	

	local totaledithUnlocks = GetEdithUnlockedAchs() / 15
	local totaltedithUnlocks = GetTEdithUnlockedAchs() / 7
	local totalgeneralUnlocks = (GetEdithUnlockedAchs() + GetTEdithUnlockedAchs() + (isTaintedEdithUnlocked() and 1 or 0)) / 23

	ImGui.UpdateData(Menu.ProgressBar.Edith, ImGuiData.Value, totaledithUnlocks)
	ImGui.UpdateData(Menu.ProgressBar.TEdith, ImGuiData.Value, totaltedithUnlocks)
	ImGui.UpdateData(Menu.ProgressBar.General, ImGuiData.Value, totalgeneralUnlocks)
end
mod:AddCallback(ModCallbacks.MC_POST_RENDER, UpdateProgressBar)

function mod:DestroyImGuiOptions()
	for _, ID in pairs(elementTab) do
		if not ImGui.ElementExists(ID) then goto continue end 
		ImGui.RemoveElement(ID)
		::continue::
	end
end

local function InitSaveData()
	RenderMenu = true

	local SaveManager = mod.SaveManager
	if not SaveManager and not SaveManager:IsLoaded() then return end
	local menuData = SaveManager.GetSettingsSave()
	if not menuData then return end
	
	menuData.EdithData = menuData.EdithData or {}
	menuData.TEdithData = menuData.TEdithData or {}
	menuData.MiscData = menuData.MiscData or {}

	local EdithData = menuData.EdithData ---@cast EdithData EdithData
	local TEdithData = menuData.TEdithData ---@cast TEdithData TEdithData
	local MiscData = menuData.MiscData ---@cast MiscData MiscData

	EdithData.TargetColor = EdithData.TargetColor or {Red = 1, Green = 1, Blue = 1}
	EdithData.StompSound = EdithData.StompSound or 1
	EdithData.StompVolume = EdithData.StompVolume or 100
	EdithData.EnableExtraGore = EdithData.EnableExtraGore or false
	EdithData.JumpCooldownSound = EdithData.JumpCooldownSound or 1
	EdithData.TargetDesign = EdithData.TargetDesign or 1
	EdithData.DisableSaltGibs = EdithData.DisableSaltGibs or false
	EdithData.RGBMode = EdithData.RGBMode or false
	EdithData.RGBSpeed = EdithData.RGBSpeed or 0.5
	EdithData.TargetLine = EdithData.TargetLine or false
	EdithData.DefensiveStompWindow = EdithData.DefensiveStompWindow or 15
	EdithData.SaltShakerSlot = EdithData.SaltShakerSlot or 0 
	
	TEdithData.ArrowColor = TEdithData.ArrowColor or {Red = 1, Green = 0, Blue = 0}
	TEdithData.ArrowDesign = TEdithData.ArrowDesign or 1
	TEdithData.HopSound = TEdithData.HopSound or 1
	TEdithData.Volume = TEdithData.Volume or 100
	TEdithData.ParrySound = TEdithData.ParrySound or 1
	TEdithData.RGBMode = TEdithData.RGBMode or false
	TEdithData.RGBSpeed = TEdithData.RGBSpeed or 0.005
	TEdithData.EnableExtraGore = TEdithData.EnableExtraGore or false
	TEdithData.EnableHopdashTrail = TEdithData.EnableHopdashTrail or false
	TEdithData.TrailColor = TEdithData.TrailColor or {Red = 1, Green = 0, Blue = 0}
	TEdithData.TrailDesign = TEdithData.TrailDesign or 1

	MiscData.EnableShakescreen = MiscData.EnableShakescreen or true
	MiscData.CustomActionKey = MiscData.CustomActionKey or Keyboard.KEY_Z
	
	mod:DestroyImGuiOptions()
end

function mod:ManageUnlock()
	RenderMenu = false
end
mod:AddCallback(ModCallbacks.MC_POST_ACHIEVEMENT_UNLOCK, mod.ManageUnlock, achievements.ACHIEVEMENT_TAINTED_EDITH)

mod:AddCallback(ModCallbacks.MC_MAIN_MENU_RENDER, mod.DestroyImGuiOptions)
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, InitSaveData)
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, InitSaveData)
mod:AddCallback(ModCallbacks.MC_PRE_MOD_UNLOAD, InitSaveData)
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, InitSaveData)
mod:AddCallback(ModCallbacks.MC_POST_RENDER, OptionsUpdate)
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, OptionsUpdate)
mod:AddCallback(ModCallbacks.MC_PRE_MOD_UNLOAD, OptionsUpdate)
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, OptionsUpdate)
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, OptionsUpdate)

mod:AddCallback(ModCallbacks.MC_POST_ACHIEVEMENT_UNLOCK, function()
	RenderMenu = true
end, achievements.ACHIEVEMENT_TAINTED_EDITH)