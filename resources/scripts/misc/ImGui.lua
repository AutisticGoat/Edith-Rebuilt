local mod = EdithRebuilt
local enums = mod.Enums
local tables = enums.Tables
local variants = enums.EffectVariant
local ImGuiTables = tables.ImGuiTables
local callbacks = enums.Callbacks
local RenderMenu = true
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
    { nombre = "CreditsElement", titulo = "Credits" }
}

for _, elemento in ipairs(elementos) do
    manageElement(elemento.nombre, elemento.titulo)
end

local ventanas = {
    { nombre = "settingswindow", titulo = "Settings" },
    { nombre = "creditsWindow", titulo = "Credits" }
}

for _, ventana in ipairs(ventanas) do
	if RenderMenu == false and ImGui.ElementExists(ventana.nombre) then return end
    ImGui.CreateWindow(ventana.nombre, ventana.titulo .. " \u{f118}\u{f5b3}\u{f118}")
end

ImGui.LinkWindowToElement("settingswindow", "edithSettings")
ImGui.LinkWindowToElement("creditsWindow", "CreditsElement")

local function ResetSaveData(isTainted)
	local SaveManager = mod.SaveManager
	if not SaveManager then return end
	local menuData = SaveManager.GetSettingsSave()
	if not menuData then return end

	local EdithData = menuData.EdithData
	local TEdithData = menuData.TEdithData

	if isTainted then
		TEdithData.ArrowColor = {Red = 1, Green = 0, Blue = 0}
		TEdithData.TrailColor = {Red = 1, Green = 0, Blue = 0}
		TEdithData.ArrowDesign = 1
		TEdithData.TaintedHopSound = 1
		TEdithData.taintedStompVolume = 100
		TEdithData.TaintedParrySound = 1
		TEdithData.RGBMode = false
		TEdithData.EnableGore = false
		TEdithData.RGBSpeed = 0.005
		TEdithData.TrailDesign = 1
	else
		EdithData.TargetColor = {Red = 1, Green = 1, Blue = 1}
		EdithData.stompsound = 1
		EdithData.stompVolume = 100
		EdithData.EnableGore = false
		EdithData.targetdesign = 1
		EdithData.DisableGibs = false
		EdithData.RGBMode = false
		EdithData.RGBSpeed = 0.005
		EdithData.targetline = false
		EdithData.CooldownSound = 1
	end

	mod:UpdateImGuiData()

	RenderMenu = true
end

local OptionsIDs = {
	"StompSound", 
	"StompVolume", 
	"TargetDesign", 
	"DisableGibs", 
	"SetRGB", 
	"SetRGBSpeed", 
	"EnableGore",
	"TargetLine", 
	"arrowDesign", 
	"hopSound", 
	"parrySound", 
	"TaintedDisableGibs", 
	"TaintedSetRGB", 
	"TaintedSetRGBSpeed", 
	"StompTaintedVolume", 
	"ScreenShake",
	"EdithSetting", 
	"TaintedEdithSetting", 
	"MiscSetting", 
	"EdithTargetColor", 
	"EdithResetButton", 
	"TaintedEdithArrowColor", 
	"TaintedEdithResetButton", 
	"TaintedTrailDesign",
	"Settings",
} 

function CheckIntegrity()
	for _, ID in ipairs(OptionsIDs) do
		if not ImGui.ElementExists(ID) then return false end
	end
	return true
end

function mod:UpdateImGuiData()
	local SaveManager = mod.SaveManager
	
	if not SaveManager and not SaveManager.IsLoaded() then return end
	local saveData = SaveManager.GetSettingsSave()

	if not saveData then return end
	local EdithData = saveData.EdithData
	local TEdithData = saveData.TEdithData
	local miscData = saveData.miscData

	if not CheckIntegrity() then return end

	local data = {
		["StompSound"] = (EdithData.stompsound - 1) or 0,
		["StompVolume"] = EdithData.stompVolume or 100,
		["TargetDesign"] = (EdithData.targetdesign - 1) or 0,
		["JumpCooldownSound"] = (EdithData.CooldownSound - 1) or 0,
		["DisableGibs"] = EdithData.DisableGibs or false,
		["SetRGB"] = EdithData.RGBMode or false,
		["EnableGore"] = EdithData.EnableGore or false,
		["SetRGBSpeed"] = EdithData.RGBSpeed or 0.005,
		["TargetLine"] = EdithData.targetline or false,
		["arrowDesign"] = (TEdithData.ArrowDesign - 1) or 0,
		["hopSound"] = (TEdithData.TaintedHopSound - 1) or 0,
		["TaintedDisableGibs"] = TEdithData.DisableGibs or false,
		["TaintedSetRGB"] = TEdithData.RGBMode or false,
		["TaintedEnableGore"] = TEdithData.EnableGore or false,
		["TaintedSetRGBSpeed"] = TEdithData.RGBSpeed or 0.005,
		["StompTaintedVolume"] = TEdithData.taintedStompVolume or 100,
		["taintedEnableTrail"] = TEdithData.EnableTrail or false,
		["TaintedTrailDesign"] = (TEdithData.TaintedParrySound - 1) or 0,
		["parrySound"] = (TEdithData.TaintedParrySound - 1) or 0,
		["ScreenShake"] = miscData.shakescreen or false,
	}

	for option, newValue in pairs(data) do
		ImGui.UpdateData(option, ImGuiData.Value, newValue)
	end
end

local function OptionsUpdate()
	local SaveManager = mod.SaveManager
	
	if not SaveManager and not SaveManager.IsLoaded() then return end
	local saveData = SaveManager.GetSettingsSave()

	if not saveData then return end
	local EdithData = saveData.EdithData
	local TEdithData = saveData.TEdithData
	local miscData = saveData.miscData

	if CheckIntegrity() then return end

	ImGui.AddTabBar("settingswindow", "Settings")
	ImGui.AddTab("Settings", "EdithSetting", "Edith")
	ImGui.AddTab("Settings", "TaintedEdithSetting", "Tainted Edith")
	ImGui.AddTab("Settings", "MiscSetting", "Misc")

	ImGui.AddTabBar("EdithSetting", "EdithSettings")
	ImGui.AddTab("EdithSettings", "EdithVisualSettings", "Visuals")
	ImGui.AddTab("EdithSettings", "EdithSoundsSettings", "Sounds")

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
	ImGui.AddCombobox("EdithVisualSettings", "TargetDesign", "Set Target Design", 
		function(index)
			EdithData.targetdesign = index + 1
			for _, target in pairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, variants.EFFECT_EDITH_TARGET)) do
				Isaac.RunCallback(callbacks.TARGET_SPRITE_CHANGE, target)
			end
		end, 
	ImGuiTables.TargetDesign, 0, false)
	ImGui.AddInputColor("EdithVisualSettings", "EdithTargetColor", "Target Color",
		function(r, g, b)
			EdithData.TargetColor = {
				Red = r,
				Green = g,
				Blue = b,
			}
		end, 
	1, 1, 1)
	ImGui.SetHelpmarker("EdithTargetColor", "Only works when target design is set to Choose Color")

	ImGui.AddCheckbox("EdithVisualSettings", "TargetLine", "Enable Target line", function(check)
		EdithData.targetline = check
	end, false)
	

	ImGui.AddElement("EdithVisualSettings", "EdithRGBSeparator", ImGuiElement.SeparatorText, "RGB")
	ImGui.AddCheckbox("EdithVisualSettings", "SetRGB", "Set RGB Mode", function(check)
		EdithData.RGBMode = check
	end, false)
	ImGui.SetHelpmarker("SetRGB", "Makes the target cycle between colors \nOnly works when target design is set to Choose Color")
	ImGui.AddSliderFloat("EdithVisualSettings", "SetRGBSpeed", "Set RGB Speed", function(val)
		EdithData.RGBSpeed = val
	end, 0.005, 0.001, 0.03, "%.5f")

	ImGui.AddElement("EdithVisualSettings", "EdithVisualsStompSeparator", ImGuiElement.SeparatorText, "Stomp")

	ImGui.AddCheckbox("EdithVisualSettings", "EnableGore", "Enable stomp kill extra gore", function(check)
		EdithData.EnableGore = check
	end, false)
	ImGui.AddCheckbox("EdithVisualSettings", "DisableGibs", "Disable salt gibs", function(check)
		EdithData.DisableGibs = check
	end, false)
	-- Visuals end

	-- sounds
	ImGui.AddElement("EdithSoundsSettings", "EdithSoundStompSeparator", ImGuiElement.SeparatorText, "Stomp")
	ImGui.AddCombobox("EdithSoundsSettings", "StompSound", "Set Stomp Sound", 
		function(index)
			EdithData.stompsound = index + 1
		end, 
	ImGuiTables.StompSound, 0)
	ImGui.AddSliderInteger("EdithSoundsSettings", "StompVolume", "Set stomp volume", function(index)
		EdithData.stompVolume = index
	end, 100, 25, 100, "%d%")

	ImGui.AddElement("EdithSoundsSettings", "EdithCooldownSeparator", ImGuiElement.SeparatorText, "Cooldown")
	ImGui.AddCombobox("EdithSoundsSettings", "JumpCooldownSound", "Set jump cooldown sound", 
		function(index)
			EdithData.CooldownSound = index + 1
		end, 
	{"Stone", "Beep"}, 0, true)
	-- sounds end
		
	local color = EdithData.TargetColor
		
	ImGui.UpdateData("EdithTargetColor", ImGuiData.ColorValues, 
		{
			color.Red,
			color.Green,
			color.Blue,
		}
	)
-- Edith configs end
	
-- Tainted Edith Configs
	local arrowcolor = TEdithData.ArrowColor
	local trailColor = TEdithData.TrailColor

	ImGui.AddElement("TaintedEdithVisualSettings", "TaintedEdithVisualArrowSeparator", ImGuiElement.SeparatorText, "Arrow")
	ImGui.AddCombobox("TaintedEdithVisualSettings", "arrowDesign", "Set Arrow Design", 		
		function(index)
			TEdithData.ArrowDesign = index + 1
			for _, arrow in pairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, variants.EFFECT_EDITH_B_TARGET)) do
				Isaac.RunCallback(callbacks.TARGET_SPRITE_CHANGE, arrow)
			end
		end,
	ImGuiTables.ArrowDesign, 0)
	ImGui.AddInputColor("TaintedEdithVisualSettings", "TaintedEdithArrowColor", "Arror Color", 
	function(r, g, b)
		TEdithData.ArrowColor = {
			Red = r,
			Green = g,
			Blue = b,
		}
	end,
	1, 1, 1)

	ImGui.AddElement("TaintedEdithVisualSettings", "TaintedEdithVisualTrailSeparator", ImGuiElement.SeparatorText, "Trail")
	ImGui.AddCheckbox("TaintedEdithVisualSettings", "taintedEnableTrail", "Enable hopdash trail", 
		function(check) 
			TEdithData.EnableTrail = check
		end, 
	false)
	ImGui.AddCombobox("TaintedEdithVisualSettings", "TaintedTrailDesign", "Set Target Design", 
		function(index)
			TEdithData.TrailDesign = index + 1
			for _, trail in pairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.SPRITE_TRAIL)) do
				if not data(trail).EdithRebuilTrail then return end
				Isaac.RunCallback(callbacks.TRAIL_SPRITE_CHANGE, trail)
			end
		end, 
	ImGuiTables.TrailDesign, 0, false)

	ImGui.AddInputColor("TaintedEdithVisualSettings", "TaintedEdithTrailColor", "Trail Color", function(r, g, b)
		TEdithData.TrailColor = {
			Red = r,
			Green = g,
			Blue = b,
		}
	end,
	1, 1, 1)

	ImGui.AddElement("TaintedEdithVisualSettings", "TaintedEdithVisualRGBSeparator", ImGuiElement.SeparatorText, "RGB")
	ImGui.AddCheckbox("TaintedEdithVisualSettings", "TaintedSetRGB", "Set RGB Mode", function(check)
		TEdithData.RGBMode = check
	end, false)
	ImGui.AddSliderFloat("TaintedEdithVisualSettings", "TaintedSetRGBSpeed", "Set RGB Speed", function(index)
		TEdithData.RGBSpeed = index
	end, 0.005, 0.001, 0.03, "%.5f")

	ImGui.AddElement("TaintedEdithVisualSettings", "TaintedEdithVisualHopAndParrySeparator", ImGuiElement.SeparatorText, "Hop & Parry")
	ImGui.AddCheckbox("TaintedEdithVisualSettings", "TaintedEnableGore", "Enable parry kill extra gore", function(check)
		TEdithData.EnableGore = check
	end, false)
	ImGui.AddCheckbox("TaintedEdithVisualSettings", "TaintedDisableGibs", "Disable salt gibs", function(check)
		TEdithData.DisableGibs = check
	end, false)

	ImGui.AddElement("TaintedEdithSoundsSettings", "TaintedEdithSoundsHopAndParrySeparator", ImGuiElement.SeparatorText, "Hop & Parry")
	ImGui.AddCombobox("TaintedEdithSoundsSettings", "hopSound", "Set Hop Sound", 		
		function(index)
			TEdithData.TaintedHopSound = index + 1
		end, 
	ImGuiTables.HopSound, 0)
	ImGui.AddCombobox("TaintedEdithSoundsSettings", "parrySound", "Set Parry Sound", 		
		function(index)
			TEdithData.TaintedParrySound = index + 1
		end,
	ImGuiTables.ParrySound, 0)
	ImGui.AddSliderInteger("TaintedEdithSoundsSettings", "StompTaintedVolume", "Set stomp volume", function(index)
		TEdithData.taintedStompVolume = index 
	end, 100, 25, 100, "%d%")	

	ImGui.UpdateData("TaintedEdithArrowColor", ImGuiData.ColorValues, 
	{
		arrowcolor.Red,
		arrowcolor.Green,
		arrowcolor.Blue,
	})

	ImGui.UpdateData("TaintedEdithTrailColor", ImGuiData.ColorValues, 
	{
		trailColor.Red,
		trailColor.Green,
		trailColor.Blue,
	})
-- Tainted Edith Configs end

-- Misc Configs

	ImGui.AddElement("MiscSetting", "ResetData", ImGuiElement.SeparatorText, "Reset Data")
	ImGui.AddButton("MiscSetting", "EdithResetButton", "Reset Edith Settings", function()
		ResetSaveData(false)
	end, true)

	ImGui.AddButton("MiscSetting", "TaintedEdithResetButton", "Reset Tainted Edith Settings", function()
		ResetSaveData(true)
	end, true)

	ImGui.AddElement("MiscSetting", "Misc", ImGuiElement.SeparatorText, "Misc")
	ImGui.AddCheckbox("MiscSetting", "ScreenShake", "Enable Stomp screen shake", function(check)
		miscData.shakescreen = check
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

	RenderMenu = false
end

local function DestroyImGuiOptions()
	for _, ID in ipairs(OptionsIDs) do
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
	menuData.miscData = menuData.miscData or {}

	local EdithData = menuData.EdithData
	local TEdithData = menuData.TEdithData
	local miscData = menuData.miscData

	EdithData.TargetColor = EdithData.TargetColor or {Red = 1, Green = 1, Blue = 1}
	EdithData.stompsound = EdithData.stompsound or 1
	EdithData.stompVolume = EdithData.stompVolume or 100
	EdithData.EnableGore = EdithData.EnableGore or false
	EdithData.CooldownSound = EdithData.CooldownSound or 1
	EdithData.targetdesign = EdithData.targetdesign or 1
	EdithData.DisableGibs = EdithData.DisableGibs or false
	EdithData.RGBMode = EdithData.RGBMode or false
	EdithData.RGBSpeed = EdithData.RGBSpeed or 0.5
	EdithData.targetline = EdithData.targetline or false
	
	TEdithData.ArrowColor = TEdithData.ArrowColor or {Red = 1, Green = 0, Blue = 0}
	TEdithData.ArrowDesign = TEdithData.ArrowDesign or 1
	TEdithData.TaintedHopSound = TEdithData.TaintedHopSound or 1
	TEdithData.taintedStompVolume = TEdithData.taintedStompVolume or 100
	TEdithData.TaintedParrySound = TEdithData.TaintedParrySound or 1
	TEdithData.RGBMode = TEdithData.RGBMode or false
	TEdithData.RGBSpeed = TEdithData.RGBSpeed or 0.005
	TEdithData.EnableGore = TEdithData.EnableGore or false
	TEdithData.EnableTrail = TEdithData.EnableTrail or false
	TEdithData.TrailColor = TEdithData.TrailColor or {Red = 1, Green = 0, Blue = 0}
	TEdithData.TrailDesign = TEdithData.TrailDesign or 1

	miscData.shakescreen = miscData.shakescreen or true

	DestroyImGuiOptions()
end

mod:AddCallback(ModCallbacks.MC_MAIN_MENU_RENDER, DestroyImGuiOptions)
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, InitSaveData)
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, InitSaveData)
mod:AddCallback(ModCallbacks.MC_PRE_MOD_UNLOAD, InitSaveData)
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, InitSaveData)
mod:AddCallback(ModCallbacks.MC_POST_RENDER, OptionsUpdate)
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, OptionsUpdate)