local mod = EdithRebuilt
local enums = mod.Enums
local tables = enums.Tables
local variants = enums.EffectVariant
local ImGuiTables = tables.ImGuiTables
local callbacks = enums.Callbacks
local achievements = enums.Achievements
local RenderMenu = true
local SaveManager = mod.SaveManager
local data = mod.CustomDataWrapper.getData

if not ImGui.ElementExists("edithRebuilt") then
	if RenderMenu == false then return end
    ImGui.CreateMenu('edithRebuilt', '\u{f11a} Edith: Rebuilt')
end

local function manageElement(nombre, titulo)
	if RenderMenu == false and ImGui.ElementExists(nombre) then return end
    ImGui.AddElement("edithRebuilt", nombre, ImGuiElement.MenuItem, "\u{f013} " .. titulo)
end

local elementos = {
    { nombre = "edithSettings", titulo = "Settings" },
    { nombre = "CreditsElement", titulo = "Credits" },
    { nombre = "ProgressElement", titulo = "Progress" }
}

for _, elemento in ipairs(elementos) do
    manageElement(elemento.nombre, elemento.titulo)
end

local ventanas = {
    { nombre = "settingswindow", titulo = "Settings" },
    { nombre = "creditsWindow", titulo = "Credits" },
	{ nombre = "progressWindow", titulo = "Progress"},
}

for _, ventana in ipairs(ventanas) do
	if RenderMenu == false and ImGui.ElementExists(ventana.nombre) then return end
    ImGui.CreateWindow(ventana.nombre, ventana.titulo .. " \u{f118}\u{f5b3}\u{f118}")
end

ImGui.LinkWindowToElement("settingswindow", "edithSettings")
ImGui.LinkWindowToElement("creditsWindow", "CreditsElement")
ImGui.LinkWindowToElement("progressWindow", "ProgressElement")

local MainPrefix = "EdithRebuilt_"
local Prefixes = {
	Edith = {
		Visuals = MainPrefix .. "Edith_" .. "Visuals_",
		Sounds = MainPrefix .. "Edith_" .. "Sounds_" ,
		Gameplay = MainPrefix .. "Edith_" .. "Gameplay_",
	},
	TEdith = {
		Visuals = MainPrefix .. "TEdith_" .. "Visuals_",
		Sounds = MainPrefix .. "TEdith_" .. "Sounds_",
		Gameplay = MainPrefix .. "TEdith_" .. "Gameplay_",
	},
	Misc = {
		Input = MainPrefix .. "Misc_" .. "Input_",
		ResetData = MainPrefix .. "Misc_" .. "ResetData_",
		Misc = MainPrefix .. "Misc_" .. "Misc_",
	}
}

local elementTab = {}
local options = {
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
			EnableTrainingMode = Prefixes.Edith.Gameplay .. "EnableTrainingMode",
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
			SetVolume = Prefixes.TEdith.Sounds .. "SerVolume",
		}
	},
	Misc = {
		CustomActionKey = Prefixes.Misc.Input .. "CustomActionKey",
		ResetEdithData = Prefixes.Misc.ResetData .. "ResetEdithData",
		ResetTEdithData = Prefixes.Misc.ResetData .. "ResetTEdithData",
		EnableShakescreen = Prefixes.Misc.Misc .. "EnableShakescreen",
	}
}

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

---@class MiscData 
---@field CustomActionKey Keyboard
---@field EnableShakescreen boolean

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
	end

	mod:UpdateImGuiData()

	RenderMenu = true
end

local function recorrerTablaImGui(tabla, prefijo)
    prefijo = prefijo or ""
    for clave, valor in pairs(tabla) do
        if type(valor) == "table" then
            recorrerTablaImGui(valor, prefijo .. clave .. ".")
        else
			if not ImGui.ElementExists(valor) then
				elementTab[clave] = valor
			end
        end
    end
end

recorrerTablaImGui(options)
function mod:CheckIntegrity()
	for _, ID in pairs(elementTab) do
		if not ImGui.ElementExists(ID) then return false end
	end
	return true
end

function mod:UpdateImGuiData()
	if not SaveManager.IsLoaded() then return end
	local saveData = SaveManager.GetSettingsSave()

	if not saveData then return end
	if not mod:CheckIntegrity() then return end

	print("as[ojdaopsjopaodsop]")

	local EdithData = saveData.EdithData ---@cast EdithData EdithData
	local TEdithData = saveData.TEdithData ---@cast TEdithData TEdithData
	local MiscData = saveData.MiscData
	local EdithOptions = options.Edith
	local TEdithOptions = options.TEdith
	local MiscOptions = options.Misc

	local data = {
		[EdithOptions.Visuals.TargetDesign] = (EdithData.TargetDesign - 1) or 0,
		[EdithOptions.Visuals.TargetLine] = EdithData.TargetLine or false,
		[EdithOptions.Visuals.SetRGBMode] = EdithData.RGBMode or false,
		[EdithOptions.Visuals.SetRGBSpeed] = EdithData.RGBSpeed or 0.005,
		[EdithOptions.Visuals.EnableExtraGore] = EdithData.EnableExtraGore or false,
		[EdithOptions.Visuals.DisableSaltGibs] = EdithData.DisableSaltGibs or false,
		[EdithOptions.Sounds.SetStompSound] = (EdithData.StompSound - 1) or 0,
		[EdithOptions.Sounds.SetStompVolume] = EdithData.StompVolume or 100,
		[EdithOptions.Sounds.SetJumpCooldownSound] = (EdithData.JumpCooldownSound - 1) or 0,
		[EdithOptions.Gameplay.EnableDropKey2Jump] = EdithData.DropKey2Jump or false,
		[EdithOptions.Gameplay.EnableTrainingMode] = EdithData.TrainingMode or false,

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

		-- [MiscOptions.CustomActionKey] = MiscData.CustomActionKey or Keyboard.KEY_Z,
		[MiscOptions.EnableShakescreen] = MiscData.EnableShakescreen or false,
	}

	for option, newValue in pairs(data) do
		ImGui.UpdateData(option, ImGuiData.Value, newValue)
	end
end

local TrainingOptions = {
	EdithStompMultDamage = Prefixes.Edith.Gameplay .. "EdithStompMultDamage",
}

---@param enabled boolean
local function DisplayTrainingOptions(enabled)
	if not SaveManager.IsLoaded() then return end
	local saveData = SaveManager.GetSettingsSave()

	if not saveData then return end
	local EdithData = saveData.EdithData
	local TEdithData = saveData.TEdithData
	local MiscData = saveData.MiscData

	if enabled then
		ImGui.AddDragFloat("EdithGameplaySettings", TrainingOptions.EdithStompMultDamage, "Set Stomp damage Mult", 
		function(val)
			EdithData.CustomStompDmgMult = val
		end, 1, 0.005, 1, 2)
	else
		for _, options in pairs(TrainingOptions) do
			ImGui.RemoveElement(options)
		end
	end
end

local function OptionsUpdate()	
	if not SaveManager.IsLoaded() then return end
	local saveData = SaveManager.GetSettingsSave()
	
	if not saveData then return end
	if mod:CheckIntegrity() then return end
	
	local EdithData = saveData.EdithData ---@cast EdithData EdithData
	local TEdithData = saveData.TEdithData ---@cast TEdithData TEdithData
	local MiscData = saveData.MiscData ---@cast MiscData MiscData

	local EdithOptions = options.Edith
	local TEdithOptions = options.TEdith
	local MiscOptions = options.Misc

	ImGui.AddTabBar("settingswindow", "Settings")
	ImGui.AddTab("Settings", "EdithSetting", "Edith")
	ImGui.AddTab("Settings", "TaintedEdithSetting", "Tainted Edith")
	ImGui.AddTab("Settings", "MiscSetting", "Misc")

	ImGui.AddTabBar("EdithSetting", "EdithSettings")
	ImGui.AddTab("EdithSettings", "EdithVisualSettings", "Visuals")
	ImGui.AddTab("EdithSettings", "EdithSoundsSettings", "Sounds")
	ImGui.AddTab("EdithSettings", "EdithGameplaySettings", "Gameplay")

	ImGui.AddTabBar("TaintedEdithSetting", "TaintedEdithSettings")
	ImGui.AddTab("TaintedEdithSettings", "TaintedEdithVisualSettings", "Visuals")
	ImGui.AddTab("TaintedEdithSettings", "TaintedEdithSoundsSettings", "Sounds")

	ImGui.AddTabBar("creditsWindow", "Credits")
	ImGui.AddTab("Credits", "CreditsResources", "Resources")
	ImGui.AddTab("Credits", "CreditsColabTesters", "Colaborators and testers")
	ImGui.AddTab("Credits", "CreditsDevTeam", "Dev team")

-- Edith configs
	-- Visuals 
	ImGui.AddElement("EdithVisualSettings", "EdithTargetSeparator", ImGuiElement.SeparatorText, "Target")
	ImGui.AddCombobox("EdithVisualSettings", EdithOptions.Visuals.TargetDesign, "Set Target Design", 
		function(index)
			EdithData.TargetDesign = index + 1
			for _, target in pairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, variants.EFFECT_EDITH_TARGET)) do
				Isaac.RunCallback(callbacks.TARGET_SPRITE_CHANGE, target)
			end
		end, 
	ImGuiTables.TargetDesign, 0, false)
	ImGui.AddInputColor("EdithVisualSettings", EdithOptions.Visuals.TargetColor, "Target Color",
		function(r, g, b)
			EdithData.TargetColor = {
				Red = r,
				Green = g,
				Blue = b,
			}
		end,
	1, 1, 1)
	ImGui.SetHelpmarker(EdithOptions.Visuals.TargetColor, "Only works when target design is set to Choose Color")

	ImGui.AddCheckbox("EdithVisualSettings", EdithOptions.Visuals.TargetLine, "Enable Target line", function(check)
		EdithData.TargetLine = check
	end, false)

	ImGui.AddElement("EdithVisualSettings", "EdithRGBSeparator", ImGuiElement.SeparatorText, "RGB")
	ImGui.AddCheckbox("EdithVisualSettings", EdithOptions.Visuals.SetRGBMode, "Set RGB Mode", function(check)
		EdithData.RGBMode = check
	end, false)
	ImGui.SetHelpmarker(EdithOptions.Visuals.SetRGBMode, "Makes the target cycle between colors \nOnly works when target design is set to Choose Color")
	ImGui.AddSliderFloat("EdithVisualSettings", EdithOptions.Visuals.SetRGBSpeed, "Set RGB Speed", function(val)
		EdithData.RGBSpeed = val
	end, 0.005, 0.001, 0.03, "%.5f")

	ImGui.AddElement("EdithVisualSettings", "EdithVisualsStompSeparator", ImGuiElement.SeparatorText, "Stomp")

	ImGui.AddCheckbox("EdithVisualSettings", EdithOptions.Visuals.EnableExtraGore, "Enable stomp kill extra gore", function(check)
		EdithData.EnableExtraGore = check
	end, false)
	ImGui.AddCheckbox("EdithVisualSettings", EdithOptions.Visuals.DisableSaltGibs, "Disable salt gibs", function(check)
		EdithData.DisableSaltGibs = check
	end, false)
	-- Visuals end

	-- sounds
	ImGui.AddElement("EdithSoundsSettings", "EdithSoundStompSeparator", ImGuiElement.SeparatorText, "Stomp")
	ImGui.AddCombobox("EdithSoundsSettings", EdithOptions.Sounds.SetStompSound, "Set Stomp Sound", 
		function(index)
			EdithData.StompSound = index + 1
		end, 
	ImGuiTables.StompSound, 0)
	ImGui.AddSliderInteger("EdithSoundsSettings", EdithOptions.Sounds.SetStompVolume, "Set stomp volume", function(index)
		EdithData.StompVolume = index
	end, 100, 25, 100, "%d%")

	ImGui.AddElement("EdithSoundsSettings", "EdithCooldownSeparator", ImGuiElement.SeparatorText, "Cooldown")
	ImGui.AddCombobox("EdithSoundsSettings", EdithOptions.Sounds.SetJumpCooldownSound, "Set jump cooldown sound", 
		function(index)
			EdithData.JumpCooldownSound = index + 1
		end, 
	{"Stone", "Beep"}, 0, true)
	-- sounds end
		
	local color = EdithData.TargetColor
		
	ImGui.UpdateData(EdithOptions.Visuals.TargetColor, ImGuiData.ColorValues, 
		{
			color.Red,
			color.Green,
			color.Blue,
		}
	)
	-- Gameplay
	ImGui.AddElement("EdithGameplaySettings", "EdithGameplayStompSeparator", ImGuiElement.SeparatorText, "Stomp")
	ImGui.AddCheckbox("EdithGameplaySettings", EdithOptions.Gameplay.EnableDropKey2Jump, "Enable Drop key to jump", function(check)
		EdithData.DropKey2Jump = check
	end, true)

	ImGui.AddElement("EdithGameplaySettings", "EdithGameplayTrainingModeSeparator", ImGuiElement.SeparatorText, "Training")
	ImGui.AddCheckbox("EdithGameplaySettings", EdithOptions.Gameplay.EnableTrainingMode, "Enable Training Mode", function(check)
		EdithData.TrainingMode = check
		DisplayTrainingOptions(check)
	end, true)
	ImGui.SetHelpmarker(EdithOptions.Gameplay.EnableTrainingMode, "Enable Edith's training mode, making it able to adjust some values \n\u{21} Mod's achievements will be unobtainable in the run")
	--Gameplay end
-- Edith configs end
	
-- Tainted Edith Configs
	local arrowcolor = TEdithData.ArrowColor
	local trailColor = TEdithData.TrailColor

	ImGui.AddElement("TaintedEdithVisualSettings", "TaintedEdithVisualArrowSeparator", ImGuiElement.SeparatorText, "Arrow")
	ImGui.AddCombobox("TaintedEdithVisualSettings", TEdithOptions.Visuals.ArrowDesign, "Set Arrow Design", 		
		function(index)
			TEdithData.ArrowDesign = index + 1
			for _, arrow in pairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, variants.EFFECT_EDITH_B_TARGET)) do
				Isaac.RunCallback(callbacks.TARGET_SPRITE_CHANGE, arrow)
			end
		end,
	ImGuiTables.ArrowDesign, 0)
	ImGui.AddInputColor("TaintedEdithVisualSettings", TEdithOptions.Visuals.ArrowColor, "Arror Color", 
	function(r, g, b)
		TEdithData.ArrowColor = {
			Red = r,
			Green = g,
			Blue = b,
		}
	end,
	1, 1, 1)

	ImGui.AddElement("TaintedEdithVisualSettings", "TaintedEdithVisualTrailSeparator", ImGuiElement.SeparatorText, "Trail")
	ImGui.AddCheckbox("TaintedEdithVisualSettings", TEdithOptions.Visuals.EnableHopdashTrail, "Enable hopdash trail", 
		function(check) 
			TEdithData.EnableHopdashTrail = check
		end, 
	false)
	ImGui.AddCombobox("TaintedEdithVisualSettings", TEdithOptions.Visuals.TrailDesign, "Set Target Design", 
		function(index)
			TEdithData.TrailDesign = index + 1
			for _, trail in pairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.SPRITE_TRAIL)) do
				if not data(trail).EdithRebuilTrail then return end
				Isaac.RunCallback(callbacks.TRAIL_SPRITE_CHANGE, trail)
			end
		end, 
	ImGuiTables.TrailDesign, 0, false)

	ImGui.AddInputColor("TaintedEdithVisualSettings", TEdithOptions.Visuals.TrailColor, "Trail Color", function(r, g, b)
		TEdithData.TrailColor = {
			Red = r,
			Green = g,
			Blue = b,
		}
	end,
	1, 1, 1)

	ImGui.AddElement("TaintedEdithVisualSettings", "TaintedEdithVisualRGBSeparator", ImGuiElement.SeparatorText, "RGB")
	ImGui.AddCheckbox("TaintedEdithVisualSettings", TEdithOptions.Visuals.SetRGBMode, "Set RGB Mode", function(check)
		TEdithData.RGBMode = check
	end, false)
	ImGui.AddSliderFloat("TaintedEdithVisualSettings", TEdithOptions.Visuals.SetRGBSpeed, "Set RGB Speed", function(index)
		TEdithData.RGBSpeed = index
	end, 0.005, 0.001, 0.03, "%.5f")

	ImGui.AddElement("TaintedEdithVisualSettings", "TaintedEdithVisualHopAndParrySeparator", ImGuiElement.SeparatorText, "Hop & Parry")
	ImGui.AddCheckbox("TaintedEdithVisualSettings", TEdithOptions.Visuals.EnableExtraGore, "Enable parry kill extra gore", function(check)
		TEdithData.EnableExtraGore = check
	end, false)
	ImGui.AddCheckbox("TaintedEdithVisualSettings", TEdithOptions.Visuals.DisableSaltGibs, "Disable salt gibs", function(check)
		TEdithData.DisableSaltGibs = check
	end, false)

	ImGui.AddElement("TaintedEdithSoundsSettings", "TaintedEdithSoundsHopAndParrySeparator", ImGuiElement.SeparatorText, "Hop & Parry")
	ImGui.AddCombobox("TaintedEdithSoundsSettings", TEdithOptions.Sounds.SetHopSound, "Set Hop Sound", 		
		function(index)
			TEdithData.HopSound = index + 1
		end, 
	ImGuiTables.HopSound, 0)
	ImGui.AddCombobox("TaintedEdithSoundsSettings", TEdithOptions.Sounds.SetParrySound, "Set Parry Sound", 		
		function(index)
			TEdithData.ParrySound = index + 1
		end,
	ImGuiTables.ParrySound, 0)
	ImGui.AddSliderInteger("TaintedEdithSoundsSettings", TEdithOptions.Sounds.SetVolume, "Set stomp volume", function(index)
		TEdithData.Volume = index 
	end, 100, 25, 100, "%d%")	

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
-- Tainted Edith Configs end

-- Misc Configs
	ImGui.AddElement("MiscSetting", MiscOptions.CustomActionKey, ImGuiElement.SeparatorText, "Input")
		ImGui.AddInputKeyboard("MiscSetting", "Custom action key", "Set custom action key", 
		function(ID)
			MiscData.CustomActionKey = ID
		end, 
	Keyboard.KEY_Z)

	ImGui.AddElement("MiscSetting", "ResetData", ImGuiElement.SeparatorText, "Reset Data")
	ImGui.AddButton("MiscSetting", MiscOptions.ResetEdithData, "Reset Edith Settings", function()
		ResetSaveData(false)
	end, true)

	ImGui.AddButton("MiscSetting", MiscOptions.ResetTEdithData, "Reset Tainted Edith Settings", function()
		ResetSaveData(true)
	end, true)

	ImGui.AddElement("MiscSetting", "Misc", ImGuiElement.SeparatorText, "Misc")
	ImGui.AddCheckbox("MiscSetting", MiscOptions.EnableShakescreen, "Enable Stomp screen shake", function(check)
		MiscData.EnableShakescreen = check
	end, false)

	mod:UpdateImGuiData()

	ImGui.AddText("CreditsResources", 
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

	ImGui.AddText("CreditsColabTesters", 
	[[
		Colaborators:
		- JJ: Inspiration to start this project
		- D!Edith team: Inspiration to resume this project
		- Skulldier: Sal concept
		- Marcy: Tainted Edith Birthright idea
		- Sr Kalaka: Edith Sprite
		- Yuls: Tainted Edith sprite base

		Testers:
		- ottostrasse
		- Jozin191
		- Tibu
		- SethoJunk
		- Noirsight
		- Sylvy_owo
		- .radiox
	]], true, "creditsText")

	ImGui.AddText("CreditsDevTeam", 
	[[
		Team members:
		- gigamouse: finished Tainted Edith sprite, items sprites
		- Pattowolfx220: Testing, First Tainted Edith sprite, items sprites
		- Kotry: Project leader, coder, unlock sheets sprite
	]],
	true)

	ImGui.AddProgressBar("progressWindow", "GeneralUnlockProgress", "General unlocks progress", 0)
	ImGui.AddProgressBar("progressWindow", "EdithUnlockProgress", "Edith unlocks progress", 0)
	ImGui.AddProgressBar("progressWindow", "TEdithUnlockProgress", "Tainted Edith unlocks progress", 0)

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

local function UpdateProgressBar()
	local totaledithUnlocks = GetEdithUnlockedAchs() / 15
	local totaltedithUnlocks = GetTEdithUnlockedAchs() / 7
	local totalgeneralUnlocks = (GetEdithUnlockedAchs() + GetTEdithUnlockedAchs() + (Isaac.GetPersistentGameData():Unlocked(achievements.ACHIEVEMENT_THANK_YOU) and 1 or 0)) / 23

	ImGui.UpdateData("EdithUnlockProgress", ImGuiData.Value, totaledithUnlocks)
	ImGui.UpdateData("TEdithUnlockProgress", ImGuiData.Value, totaltedithUnlocks)
	ImGui.UpdateData("GeneralUnlockProgress", ImGuiData.Value, totalgeneralUnlocks)
end
mod:AddCallback(ModCallbacks.MC_POST_RENDER, UpdateProgressBar)
mod:AddCallback(ModCallbacks.MC_MAIN_MENU_RENDER, UpdateProgressBar)


local function DestroyImGuiOptions()
	for k, ID in ipairs(elementTab) do
		if not ImGui.ElementExists(ID) then goto continue end 
		ImGui.RemoveElement(ID)
		::continue::
	end
end

local function InitSaveData()
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

	DestroyImGuiOptions()
end

mod:AddCallback(ModCallbacks.MC_MAIN_MENU_RENDER, DestroyImGuiOptions)
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, InitSaveData)
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, InitSaveData)
mod:AddCallback(ModCallbacks.MC_PRE_MOD_UNLOAD, InitSaveData)
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, InitSaveData)
mod:AddCallback(ModCallbacks.MC_POST_RENDER, OptionsUpdate)
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, OptionsUpdate)