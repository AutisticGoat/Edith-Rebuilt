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

local function actualizarCampo(nombre, campo, valorPorDefecto, Tipo)
    local SaveManager = edithMod.saveManager
    if not SaveManager then return end
    local saveData = SaveManager.GetDeadSeaScrollsSave()

    local updateFunctions = {
		["ComboBox"] = function() return (saveData[campo] - 1) or valorPorDefecto end,
        ["Slider"] = function() return saveData[campo] or valorPorDefecto end,
        ["Checkbox"] = function() return saveData[campo] or valorPorDefecto end,
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
				saveData.TargetColor = {
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
			saveData.targetdesign = index + 1
		end, 0)
		agregarCheckbox("EdithSetting", "SetRGB", "Set RGB Mode", function(check)
			saveData.RGBMode = check
		end, false)
		agregarSlider("EdithSetting", "SetRGBSpeed", "Set RGB Speed", function(index, val)
			saveData.RGBSpeed = index
		end, 1, 1, 255, "%d%")
		agregarCheckbox("EdithSetting", "TargetLine", "Enable Target line", function(check)
				saveData.targetline = check
			end, false)
		agregarSlider("EdithSetting", "TargetLineSpace", "Set Line Space", function(index, val)
				saveData.linespace = index
			end, 16, 1, 50, "%d%")
		-- Visuals end
		
		-- sounds
		agregarElemento("EdithSetting", "SoundSeparator", ImGuiElement.SeparatorText, "Sound")

		agregarSlider("EdithSetting", "StompVolume", "Set stomp volume", function(index, val)
			saveData.stompVolume = index
		end, 100, 25, 100, "%d%")
		agregarCombobox("EdithSetting", "StompSound", "Set Stomp Sound", 
		{
			"Stone", 
			"Antibirth", 
			"Fart Reverb",
			"Vine Boom"
		}, 
		function(index, val)
			saveData.stompsound = index + 1
		end, 0)
		-- sounds end
		
		-- reset
		
		agregarElemento("EdithSetting", "resetSeparator", ImGuiElement.SeparatorText, "Reset")
		agregarBoton("EdithSetting", "resetButton", "Reset settings", function()
			edithMod:ResetSaveData(false)
		end, false)
		-- 
		
			
		actualizarCampo("StompSound", "stompsound", 0, "ComboBox")
		actualizarCampo("StompVolume", "stompVolume", 100, "Slider")
		actualizarCampo("TargetDesign", "targetdesign", 0, "ComboBox")
		actualizarCampo("SetRGB", "RGBMode", false, "Checkbox")
		actualizarCampo("SetRGBSpeed", "RGBSpeed", 16,"Slider")	
		actualizarCampo("TargetLine", "targetline", false, "Checkbox")
		actualizarCampo("TargetLineSpace", "linespace", 16, "Slider")
			
		local color = saveData.TargetColor
			
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
			saveData.ArrowColor = {
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
			saveData.ArrowDesign = index + 1
		end, 0)
			
		actualizarCampo("arrowDesign", "ArrowDesign", 1, "ComboBox")
			
		local arrowcolor = saveData.ArrowColor
		ImGui.UpdateData("TaintedEdithArrowColor", ImGuiData.ColorValues, 
		{
			arrowcolor.Red,
			arrowcolor.Green,
			arrowcolor.Blue,
		})
			
		agregarElemento("TaintedEdithSetting", "taintedSoundSeparator", ImGuiElement.SeparatorText, "Sound")
			
		agregarSlider("TaintedEdithSetting", "StompTaintedVolume", "Set stomp volume", function(index, val)
			saveData.taintedStompVolume = index
		end, 100, 25, 100, "%d%")
			
		actualizarCampo("StompTaintedVolume", "taintedStompVolume", 100, "Slider")
		
		agregarElemento("TaintedEdithSetting", "taintedresetSeparator", ImGuiElement.SeparatorText, "Reset")
		agregarBoton("TaintedEdithSetting", "taintedresetButton", "Reset settings", function()
			edithMod:ResetSaveData(true)
		end, false)
		
	-- Tainted Edith Configs end
		
	-- Misc Configs
		agregarCheckbox("MiscSetting", "ScreenShake", "Enable Stomp screen shake", function(check)
			saveData.shakescreen = check
		end, false)
			
		actualizarCampo("ScreenShake", "shakescreen", false, "Checkbox")
	-- Misc Configs end
    end
end

function edithMod:ResetSaveData(isTainted)
	local SaveManager = edithMod.saveManager
	local menuData = SaveManager.GetDeadSeaScrollsSave()
	
	if not isTainted then
		menuData.TargetColor = {Red = 1, Green = 1, Blue = 1}
		menuData.stompsound = 1
		menuData.stompVolume = 100
		menuData.targetdesign = 1
		menuData.RGBMode = false
		menuData.RGBSpeed = 16
		menuData.targetline = false
		menuData.linespace = 16
	else
		menuData.ArrowColor = {Red = 1, Green = 0, Blue = 0}
		menuData.ArrowDesign = 1
		menuData.taintedStompVolume = 100
	end
end

function edithMod:CheckImGuiIntegrity()
	local elements = {
		"edithWindow",
		"StompSound",
		"StompVolume",
		"edithSettings",
		"TargetDesign", 
		"SetRGB", 
		"SetRGBSpeed",
		"TargetLine",
		"TargetLineSpace",
		"ScreenShake",	
		
		
		"TaintedEdithArrowColor",
		"arrowDesign",
		"StompTaintedVolume",
	}

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

function edithMod:ResetImGui()
	local elements = {
		-- Edith
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
	}
	for _, element in ipairs(elements) do
		if ImGui.ElementExists(element) then
			ImGui.RemoveElement(element)
		end
	end
end

function edithMod:InitSaveData()
	local SaveManager = edithMod.saveManager
	local menuData = SaveManager.GetDeadSeaScrollsSave()
	
	
	menuData.TargetColor = menuData.TargetColor or {Red = 1, Green = 1, Blue = 1}
	menuData.stompsound = menuData.stompsound or 1
	menuData.stompVolume = menuData.stompVolume or 100
	menuData.targetdesign = menuData.targetdesign or 1
	menuData.RGBMode = menuData.RGBMode or false
	menuData.RGBSpeed = menuData.RGBSpeed or 16
	menuData.targetline = menuData.targetline or false
	menuData.linespace = menuData.linespace or 16
	
	menuData.ArrowColor = menuData.ArrowColor or {Red = 1, Green = 1, Blue = 1}
	menuData.ArrowDesign = menuData.ArrowDesign or 1
	menuData.taintedStompVolume = menuData.taintedStompVolume or 100
end

local function SetImGuiReset()
	edithMod:ResetImGui()
end
mod:AddCallback(ModCallbacks.MC_PRE_MOD_UNLOAD, SetImGuiReset)
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, SetImGuiReset)
mod:AddCallback(ModCallbacks.MC_POST_RENDER, OptionsUpdate)
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, OptionsUpdate)