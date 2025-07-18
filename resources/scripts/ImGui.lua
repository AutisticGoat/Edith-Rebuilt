local mod = EdithRebuilt
local enums = mod.Enums
local tables = enums.Tables
local variants = enums.EffectVariant
local ImGuiTables = tables.ImGuiTables
local callbacks = enums.Callbacks
local RenderMenu = true

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
		TEdithData.ArrowDesign = 1
		TEdithData.TaintedHopSound = 1
		TEdithData.taintedStompVolume = 100
		TEdithData.TaintedParrySound = 1
		TEdithData.RGBMode = false
		TEdithData.EnableGore = false
		TEdithData.RGBSpeed = 0.005
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
	"resetButton", 
	"TaintedEdithArrowColor", 
	"taintedresetButton", 
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

	ImGui.UpdateData("StompSound", ImGuiData.Value, (EdithData.stompsound - 1) or 0) 
	ImGui.UpdateData("StompVolume", ImGuiData.Value, EdithData.stompVolume or 100) 
	ImGui.UpdateData("TargetDesign", ImGuiData.Value, (EdithData.targetdesign - 1) or 0)
	ImGui.UpdateData("JumpCooldownSound", ImGuiData.Value, (EdithData.CooldownSound - 1) or 0)
	ImGui.UpdateData("DisableGibs", ImGuiData.Value, EdithData.DisableGibs or false)
	ImGui.UpdateData("SetRGB", ImGuiData.Value, EdithData.RGBMode or false)
	ImGui.UpdateData("EnableGore", ImGuiData.Value, EdithData.EnableGore or false)
	ImGui.UpdateData("SetRGBSpeed", ImGuiData.Value, EdithData.RGBSpeed or 0.005)
	ImGui.UpdateData("TargetLine", ImGuiData.Value, EdithData.targetline or false)
	ImGui.UpdateData("arrowDesign", ImGuiData.Value, (TEdithData.ArrowDesign - 1) or 0)
	ImGui.UpdateData("hopSound", ImGuiData.Value, (TEdithData.TaintedHopSound - 1) or 0)
	ImGui.UpdateData("parrySound", ImGuiData.Value, (TEdithData.TaintedParrySound - 1) or 0)
	ImGui.UpdateData("TaintedDisableGibs", ImGuiData.Value, TEdithData.DisableGibs or false)
	ImGui.UpdateData("TaintedSetRGB", ImGuiData.Value, TEdithData.RGBMode or false)
	ImGui.UpdateData("TaintedEnableGore", ImGuiData.Value, TEdithData.EnableGore or false)
	ImGui.UpdateData("TaintedSetRGBSpeed", ImGuiData.Value, TEdithData.RGBSpeed or 0.005)
	ImGui.UpdateData("StompTaintedVolume", ImGuiData.Value, TEdithData.taintedStompVolume or 100)
	ImGui.UpdateData("ScreenShake", ImGuiData.Value, miscData.shakescreen or false)
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
-- Edith configs
	-- Visuals 
	ImGui.AddElement("EdithSetting", "VisualSeparator", ImGuiElement.SeparatorText, "Visuals")
	ImGui.AddInputColor("EdithSetting", "EdithTargetColor", "Target Color",
		function(r, g, b)
			EdithData.TargetColor = {
				Red = r,
				Green = g,
				Blue = b,
			}
		end, 
	1, 1, 1)
	ImGui.AddCombobox("EdithSetting", "TargetDesign", "Set Target Design", 
		function(index)
			EdithData.targetdesign = index + 1
			for _, target in pairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, variants.EFFECT_EDITH_TARGET)) do
				Isaac.RunCallback(callbacks.TARGET_SPRITE_CHANGE, target)
			end
		end, 
	ImGuiTables.TargetDesign, 0, false)
	ImGui.AddCheckbox("EdithSetting", "EnableGore", "Enable stomp kill extra gore", function(check)
		EdithData.EnableGore = check
	end, false)
	ImGui.AddCheckbox("EdithSetting", "DisableGibs", "Disable salt gibs", function(check)
		EdithData.DisableGibs = check
	end, false)
	ImGui.AddCheckbox("EdithSetting", "TargetLine", "Enable Target line", function(check)
		EdithData.targetline = check
	end, false)
	ImGui.AddCheckbox("EdithSetting", "SetRGB", "Set RGB Mode", function(check)
		EdithData.RGBMode = check
	end, false)
	ImGui.AddSliderFloat("EdithSetting", "SetRGBSpeed", "Set RGB Speed", function(val)
		EdithData.RGBSpeed = val
	end, 0.005, 0.001, 0.03, "%.5f")
	-- Visuals end
	
	-- sounds
	ImGui.AddElement("EdithSetting", "SoundSeparator", ImGuiElement.SeparatorText, "Sound")
	ImGui.AddSliderInteger("EdithSetting", "StompVolume", "Set stomp volume", function(index)
		EdithData.stompVolume = index
	end, 100, 25, 100, "%d%")
	ImGui.AddCombobox("EdithSetting", "StompSound", "Set Stomp Sound", 
		function(index)
			EdithData.stompsound = index + 1
		end, 
	ImGuiTables.StompSound, 0)
	ImGui.AddCombobox("EdithSetting", "JumpCooldownSound", "Set jump cooldown sound", 
		function(index)
			EdithData.CooldownSound = index + 1
		end, 
	{"Stone", "Beep"}, 0, true)
	-- sounds end
	-- reset

	ImGui.AddElement("EdithSetting", "ResetSeparator", ImGuiElement.SeparatorText, "Reset")
	ImGui.AddButton("EdithSetting", "resetButton", "Reset settings", function()
		ResetSaveData(false)
	end, false)
		
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
	ImGui.AddElement("TaintedEdithSetting", "taintedVisualSeparator", ImGuiElement.SeparatorText, "Visuals")

	local arrowcolor = TEdithData.ArrowColor
	ImGui.AddInputColor("TaintedEdithSetting", "TaintedEdithArrowColor", "Arror Color", 
	function(r, g, b)
		TEdithData.ArrowColor = {
			Red = r,
			Green = g,
			Blue = b,
		}
	end,
	1, 1, 1)
	ImGui.AddCombobox("TaintedEdithSetting", "arrowDesign", "Set Arrow Design", 		
		function(index)
			TEdithData.ArrowDesign = index + 1
			for _, arrow in pairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, variants.EFFECT_EDITH_B_TARGET)) do
				Isaac.RunCallback(callbacks.TARGET_SPRITE_CHANGE, arrow)
			end
		end,
	ImGuiTables.ArrowDesign, 0)
	ImGui.AddCheckbox("TaintedEdithSetting", "TaintedEnableGore", "Enable parry kill extra gore", function(check)
		TEdithData.EnableGore = check
	end, false)
	ImGui.AddCheckbox("TaintedEdithSetting", "TaintedDisableGibs", "Disable salt gibs", function(check)
		TEdithData.DisableGibs = check
	end, false)
	ImGui.AddCheckbox("TaintedEdithSetting", "TaintedSetRGB", "Set RGB Mode", function(check)
		TEdithData.RGBMode = check
	end, false)
	ImGui.AddSliderFloat("TaintedEdithSetting", "TaintedSetRGBSpeed", "Set RGB Speed", function(index)
		TEdithData.RGBSpeed = index
	end, 0.005, 0.001, 0.03, "%.5f")
	ImGui.AddElement("TaintedEdithSetting", "taintedSoundSeparator", ImGuiElement.SeparatorText, "Sound")
	ImGui.AddCombobox("TaintedEdithSetting", "hopSound", "Set Hop Sound", 		
		function(index)
			TEdithData.TaintedHopSound = index + 1
		end, 
	ImGuiTables.HopSound, 0)
	ImGui.AddCombobox("TaintedEdithSetting", "parrySound", "Set Parry Sound", 		
		function(index)
			TEdithData.TaintedParrySound = index + 1
		end,
	ImGuiTables.ParrySound, 0)
	ImGui.AddSliderInteger("TaintedEdithSetting", "StompTaintedVolume", "Set stomp volume", function(index)
		TEdithData.taintedStompVolume = index 
	end, 100, 25, 100, "%d%")	
	ImGui.AddElement("TaintedEdithSetting", "taintedresetSeparator", ImGuiElement.SeparatorText, "Reset")
	ImGui.AddButton("TaintedEdithSetting", "taintedresetButton", "Reset settings", function()
		ResetSaveData(true)
	end, false)
	
	ImGui.UpdateData("TaintedEdithArrowColor", ImGuiData.ColorValues, 
	{
		arrowcolor.Red,
		arrowcolor.Green,
		arrowcolor.Blue,
	})
-- Tainted Edith Configs end
	
-- Misc Configs
	ImGui.AddCheckbox("MiscSetting", "ScreenShake", "Enable Stomp screen shake", function(check)
		miscData.shakescreen = check
	end, false)

	mod:UpdateImGuiData()

	ImGui.AddText("creditsWindow", 
	[[
		Used resources and utilities:
		- Library of Isaac (ThiccoCatto)
		- JumpLib (Kerkel)
		- Pre NPC kill callback (Kerkel)
		- Isaac Save Manager (Catinsurance, Benny)
		- HudHelper (Benny, CatWizard)
		- SaveData System (AgentCucco)
		- lhsx (Ilya Kolbin (iskolbin))
		- Salt Shaker Sound Effect (Joshua Hadley): 
		- Edith water stomp sound effect (ArtNinja) 
		- Nine Sols Perfect Parry sound effect (Red Candle Games) 
		- Pizza Tower taunt sound effect (Tour De Pizza)
		- Ultrakill parry sound effect (New Blood, Arsi "Hakita" Patala)
		- Hollow Knight parry sound effect (Team Cherry) 
		- Iconoclasts parry sound effect (Joakim Sandberg (Konjak))

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

		Team members:
		- gigamouse: finished Tainted Edith sprite, items sprites
		- Pattowolfx220: Testing, First Tainted Edith sprite, items sprites
		- Kotry: Project leader, coder, unlock sheets sprite
	]], true, "creditsText")

	RenderMenu = false
end

local function DestroyImGuiOptions()
	for _, ID in ipairs(OptionsIDs) do
		if ImGui.ElementExists(ID) then
			ImGui.RemoveElement(ID)
		end
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
	TEdithData.RGBSpeed = TEdithData.RGBSpeed or 0.5
	TEdithData.EnableGore = TEdithData.EnableGore or false

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