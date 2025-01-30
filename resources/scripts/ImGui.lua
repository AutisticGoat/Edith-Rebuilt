local mod = edithMod

if not ImGui.ElementExists("edithMod") then
    ImGui.CreateMenu('edithMod', '\u{f11a} Edith: Rebuild')
end

local function manageElement(nombre, titulo)
	if ImGui.ElementExists(nombre) then
		ImGui.RemoveElement(nombre)
	end

    if not ImGui.ElementExists(nombre) then
        ImGui.AddElement("edithMod", nombre, ImGuiElement.MenuItem, "\u{f013} " .. titulo)
    end
end

local elementos = {
    { nombre = "edithSettings", titulo = "Settings" },
    { nombre = "progressElement", titulo = "Progress" },
    { nombre = "CreditsElement", titulo = "Credits" }
}

for _, elemento in ipairs(elementos) do
    manageElement(elemento.nombre, elemento.titulo)
end

local ventanas = {
    { nombre = "settingswindow", titulo = "Settings" },
    { nombre = "progressWindow", titulo = "Progress" },
    { nombre = "creditsWindow", titulo = "Credits" }
}

for _, ventana in ipairs(ventanas) do
    if not ImGui.ElementExists(ventana.nombre) then
        ImGui.CreateWindow(ventana.nombre, ventana.titulo .. " \u{f118}\u{f5b3}\u{f118}")
    end
end

ImGui.LinkWindowToElement("settingswindow", "edithSettings")
ImGui.LinkWindowToElement("progressWindow", "progressElement")
ImGui.LinkWindowToElement("creditsWindow", "CreditsElement")

---comment
---@param nombre string
---@param subtabla string
---@param campo string
---@param valorPorDefecto any
---@param Tipo string
local function actualizarCampo(nombre, subtabla, campo, valorPorDefecto, Tipo)
    local SaveManager = edithMod.saveManager
    if not SaveManager then return end
    local saveData = SaveManager.GetDeadSeaScrollsSave()

	local subtablas = {
		["EDITHDATA"] = saveData.EdithData,
		["TEDITHDATA"] = saveData.TEdithData,
		["MISCDATA"] = saveData.miscData,
	}

	local targetTable = subtablas[string.upper(subtabla)]

    local updateFunctions = {
		["ComboBox"] = function() return (targetTable[campo] - 1) or valorPorDefecto end,
        ["Slider"] = function() return targetTable[campo] or valorPorDefecto end,
        ["Checkbox"] = function() return targetTable[campo] or valorPorDefecto end,
    }

    local updateValue = updateFunctions[Tipo]()
    ImGui.UpdateData(nombre, ImGuiData.Value, updateValue)
end


local function agregarCombobox(padre, nombre, titulo, opciones, callback, valorPorDefecto)
    if not ImGui.ElementExists(nombre) then
        ImGui.AddCombobox(
            padre,
            nombre,
            titulo,
            callback,
            opciones,
            valorPorDefecto,
            false
        )
    end
end

local function agregarSlider(padre, nombre, titulo, callback, default, minimo, maximo, formato)
    if not ImGui.ElementExists(nombre) then
        ImGui.AddSliderInteger(
            padre,
            nombre,
            titulo,
            callback,
            default,
            minimo,
            maximo,
            formato
        )
    end
end

local function agregarCheckbox(padre, nombre, titulo, callback, activo)
    if not ImGui.ElementExists(nombre) then
        ImGui.AddCheckbox(
            padre,
            nombre,
            titulo,
            callback,
            activo
        )
    end
end

local function agregarColorinput(Padre, nombre, titulo, callback, rojo, verde, azul, alfa)
	if not ImGui.ElementExists(nombre) then
	ImGui.AddInputColor(
		Padre, 
		nombre, 
		titulo, 
		callback, 
		rojo, 
		verde, 
		azul,
		alfa)
	end
end

local function agregarElemento(padre, nombre, tipo, etiqueta)
	if not ImGui.ElementExists(nombre) then 
		ImGui.AddElement(padre, nombre, tipo, etiqueta)
	end
end

local function agregarBoton(padre, nombre, etiqueta, funcion, mini)
	if not ImGui.ElementExists(nombre) then 
		ImGui.AddButton(padre, nombre, etiqueta, funcion, mini)
	end
end

local function agregarTabBar(padre, nombre)
	if not ImGui.ElementExists(nombre) then 
		ImGui.AddTabBar(padre, nombre)
	end
end

local function agregarTab(padre, nombre, etiqueta)
	if not ImGui.ElementExists(nombre) then 
		ImGui.AddTab(padre, nombre, etiqueta)
	end
end

local function OptionsUpdate()
	local SaveManager = edithMod.saveManager
	
	if not SaveManager then return end
	local saveData = SaveManager.GetDeadSeaScrollsSave()

	local EdithData = saveData.EdithData
	local TEdithData = saveData.TEdithData
	local miscData = saveData.miscData

    if SaveManager.IsLoaded() then
		agregarTabBar("settingswindow", "Settings")
		agregarTab("Settings", "EdithSetting", "Edith")
		agregarTab("Settings", "TaintedEdithSetting", "Tainted Edith")
		agregarTab("Settings", "MiscSetting", "Misc")
	-- Edith configs
		-- Visuals 
		agregarElemento("EdithSetting", "VisualSeparator", ImGuiElement.SeparatorText, "Visuals")
			
		agregarColorinput("EdithSetting", "EdithTargetColot", "Target Color", 
			function(r, g, b)
				EdithData.TargetColor = {
					Red = r,
					Green = g,
					Blue = b,
				}
			end, 
		1, 1, 1)
		
		agregarCombobox("EdithSetting", "TargetDesign", "Set Target Design", 		
		{
			"Choose Color", 
			"Trans", 
			"Rainbow",
			"Lesbian",
			"Bisexual", 
			"Gay", 
			"Ace",
			"Enby",
			"Venezuela",
		}, 
		function(index, val)
			EdithData.targetdesign = index + 1
		end, 0)
		agregarCheckbox("EdithSetting", "SetRGB", "Set RGB Mode", function(check)
			EdithData.RGBMode = check
		end, false)
		agregarSlider("EdithSetting", "SetRGBSpeed", "Set RGB Speed", function(index, val)
			EdithData.RGBSpeed = index
		end, 1, 1, 255, "%d%")
		agregarCheckbox("EdithSetting", "TargetLine", "Enable Target line", function(check)
			EdithData.targetline = check
			end, false)
		agregarSlider("EdithSetting", "TargetLineSpace", "Set Line Space", function(index, val)
			EdithData.linespace = index
			end, 16, 1, 50, "%d%")
		-- Visuals end
		
		-- sounds
		agregarElemento("EdithSetting", "SoundSeparator", ImGuiElement.SeparatorText, "Sound")

		agregarSlider("EdithSetting", "StompVolume", "Set stomp volume", function(index, val)
			EdithData.stompVolume = index
		end, 100, 25, 100, "%d%")
		agregarCombobox("EdithSetting", "StompSound", "Set Stomp Sound", 
		{
			"Stone", 
			"Antibirth", 
			"Fart Reverb",
			"Vine Boom"
		}, 
		function(index, val)
			EdithData.stompsound = index + 1
		end, 0)
		-- sounds end
		
		-- reset
		
		agregarElemento("EdithSetting", "resetSeparator", ImGuiElement.SeparatorText, "Reset")
		agregarBoton("EdithSetting", "resetButton", "Reset settings", function()
			edithMod:ResetSaveData(false)
		end, false)
		-- 
		
		actualizarCampo("StompSound", "EdithData", "stompsound", 0, "ComboBox")
		actualizarCampo("StompVolume", "EdithData", "stompVolume", 100, "Slider")
		actualizarCampo("TargetDesign", "EdithData", "targetdesign", 0, "ComboBox")
		actualizarCampo("SetRGB", "EdithData", "RGBMode", false, "Checkbox")
		actualizarCampo("SetRGBSpeed", "EdithData", "RGBSpeed", 16,"Slider")	
		actualizarCampo("TargetLine", "EdithData", "targetline", false, "Checkbox")
		actualizarCampo("TargetLineSpace", "EdithData", "linespace", 16, "Slider")
			
		local color = EdithData.TargetColor
			
		ImGui.UpdateData("EdithTargetColot", ImGuiData.ColorValues, 
			{
				color.Red,
				color.Green,
				color.Blue,
			}
		)
	-- Edith configs end
		
	-- Tainted Edith Configs
		agregarElemento("TaintedEdithSetting", "taintedVisualSeparator", ImGuiElement.SeparatorText, "Visuals")
	
		agregarColorinput("TaintedEdithSetting", "TaintedEdithArrowColor", "Arror Color", 
		function(r, g, b)
			TEdithData.ArrowColor = {
				Red = r,
				Green = g,
				Blue = b,
			}
		end,
		1, 1, 1)
			
		agregarCombobox("TaintedEdithSetting", "arrowDesign", "Set Arrow Design", 		
		{
			"Arrow", 
			"Arrow (pointy)", 
			"Triangle (line)",
			"Triangle (full)",
			"Chevron (line)", 
			"Chevron (full)", 
			"Grudge", 
		}, 
			
		function(index, val)
			TEdithData.ArrowDesign = index + 1
		end, 0)
			
		actualizarCampo("arrowDesign", "TEdithData", "ArrowDesign", 1, "ComboBox")
			
		local arrowcolor = TEdithData.ArrowColor
		ImGui.UpdateData("TaintedEdithArrowColor", ImGuiData.ColorValues, 
		{
			arrowcolor.Red,
			arrowcolor.Green,
			arrowcolor.Blue,
		})
		agregarCheckbox("TaintedEdithSetting", "TaintedSetRGB", "Set RGB Mode", function(check)
			TEdithData.RGBMode = check
		end, false)
		actualizarCampo("TaintedSetRGB", "TEdithData", "RGBMode", false, "Checkbox")
		
		agregarSlider("TaintedEdithSetting", "TaintedSetRGBSpeed", "Set RGB Speed", function(index, val)
			TEdithData.RGBSpeed = index
		end, 1, 1, 255, "%d%")
		actualizarCampo("TaintedSetRGBSpeed", "TEdithData", "RGBSpeed", 16,"Slider")	
			
		agregarElemento("TaintedEdithSetting", "taintedSoundSeparator", ImGuiElement.SeparatorText, "Sound")
			
		agregarCombobox("TaintedEdithSetting", "hopSound", "Set Hop Sound", 		
		{
			"Stone", 
			"Yippee", 
			"Spring",
		}, 
			
		function(index, val)
			TEdithData.TaintedHopSound = index + 1
		end, 0)
		actualizarCampo("hopSound", "TEdithData", "TaintedHopSound", 1, "ComboBox")
		
		agregarCombobox("TaintedEdithSetting", "parrySound", "Set Jump Sound", 		
		{
			"Stone", 
			"Taunt", 
			"Vine Boom",
			"Fart Reverb",
			"Solarian",
		}, 
			
		function(index, val)
			TEdithData.TaintedParrySound = index + 1
		end, 0)
			
		actualizarCampo("parrySound", "TEdithData", "TaintedParrySound", 1, "ComboBox")
			
		agregarSlider("TaintedEdithSetting", "StompTaintedVolume", "Set stomp volume", function(index, val)
			TEdithData.taintedStompVolume = index 
		end, 100, 25, 100, "%d%")
			
		actualizarCampo("StompTaintedVolume", "TEdithData", "taintedStompVolume", 100, "Slider")
		agregarElemento("TaintedEdithSetting", "taintedresetSeparator", ImGuiElement.SeparatorText, "Reset")
		agregarBoton("TaintedEdithSetting", "taintedresetButton", "Reset settings", function()
			edithMod:ResetSaveData(true)
		end, false)
		
	-- Tainted Edith Configs end
		
	-- Misc Configs
		agregarCheckbox("MiscSetting", "ScreenShake", "Enable Stomp screen shake", function(check)
			miscData.shakescreen = check
		end, false)
			
		actualizarCampo("ScreenShake", "MiscData", "shakescreen", false, "Checkbox")
	-- Misc Configs end
    end
end

function edithMod:ResetSaveData(isTainted)
	local SaveManager = edithMod.saveManager
	local menuData = SaveManager.GetDeadSeaScrollsSave()
	local EdithData = menuData.EdithData
	local TEdithData = menuData.TEdithData

	if isTainted then
		TEdithData.ArrowColor = {Red = 1, Green = 0, Blue = 0}
		TEdithData.ArrowDesign = 1
		TEdithData.TaintedHopSound = 1
		TEdithData.taintedStompVolume = 100
		TEdithData.TaintedParrySound = 1
		TEdithData.RGBMode = false
		TEdithData.RGBSpeed = 16
	else
		EdithData.TargetColor = {Red = 1, Green = 1, Blue = 1}
		EdithData.stompsound = 1
		EdithData.stompVolume = 100
		EdithData.targetdesign = 1
		EdithData.RGBMode = false
		EdithData.RGBSpeed = 16
		EdithData.targetline = false
		EdithData.linespace = 16
	end
end

local elements = {
	"Settings",
	"EdithSetting",
	
	"EdithTargetColot",
	"StompSound",
	"StompVolume",
	"TargetDesign", 
	"SetRGB", 
	"SetRGBSpeed",
	"TargetLine",
	"TargetLineSpace",
	"ScreenShake",
	"resetButton",
		
		
	"TaintedEdithArrowColor",
	"arrowDesign",
	"StompTaintedVolume",
	"TaintedSetRGB", 
	"TaintedSetRGBSpeed",
	"hopSound",
	"parrySound",
}
	
function edithMod:ResetImGui()
	for _, element in ipairs(elements) do
		if ImGui.ElementExists(element) then
			ImGui.RemoveElement(element)
		end
	end
end

function edithMod:CheckImGuiIntegrity()
	for i, element in pairs(elements) do
		print(elements[i],ImGui.ElementExists(element))
	end
end

function edithMod:CheckMenuDataIntegrity()
	local SaveManager = edithMod.saveManager
	local menuData = SaveManager.GetDeadSeaScrollsSave()
	
	for k, v in pairs(menuData) do
		print(k, v)
	end
end

function edithMod:InitSaveData()
	local SaveManager = edithMod.saveManager
	local menuData = SaveManager.GetDeadSeaScrollsSave()
	
	menuData.EdithData = menuData.EdithData or {}
	menuData.TEdithData = menuData.TEdithData or {}
	menuData.miscData = menuData.miscData or {}

	local EdithData = menuData.EdithData
	local TEdithData = menuData.TEdithData
	local miscData = menuData.miscData


	EdithData.TargetColor = EdithData.TargetColor or {Red = 1, Green = 1, Blue = 1}
	EdithData.stompsound = EdithData.stompsound or 1
	EdithData.stompVolume = EdithData.stompVolume or 100
	EdithData.targetdesign = EdithData.targetdesign or 1
	EdithData.RGBMode = EdithData.RGBMode or false
	EdithData.RGBSpeed = EdithData.RGBSpeed or 16
	EdithData.targetline = EdithData.targetline or false
	EdithData.linespace = EdithData.linespace or 16
	
	TEdithData.ArrowColor = TEdithData.ArrowColor or {Red = 1, Green = 0, Blue = 0}
	TEdithData.ArrowDesign = TEdithData.ArrowDesign or 1
	TEdithData.TaintedHopSound = TEdithData.TaintedHopSound or 1
	TEdithData.taintedStompVolume = TEdithData.taintedStompVolume or 100
	TEdithData.TaintedParrySound = TEdithData.TaintedParrySound or 1
	TEdithData.RGBMode = TEdithData.RGBMode or false
	TEdithData.RGBSpeed = TEdithData.RGBSpeed or 16

	miscData.shakescreen = miscData.shakescreen or true
end

local function SetImGuiReset()
	edithMod:ResetImGui()
	edithMod:InitSaveData()
end

local function initSaveData()
	edithMod:InitSaveData()
end
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, initSaveData)
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, initSaveData)

mod:AddCallback(ModCallbacks.MC_PRE_MOD_UNLOAD, SetImGuiReset)
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, SetImGuiReset)
mod:AddCallback(ModCallbacks.MC_POST_RENDER, OptionsUpdate)
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, OptionsUpdate)