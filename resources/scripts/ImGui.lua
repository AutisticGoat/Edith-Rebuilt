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
    { nombre = "edithSettings", titulo = "Edith Settings" },
    { nombre = "taintededithSettings", titulo = "Tainted Edith Settings" },
    { nombre = "miscSettings", titulo = "Misc Settings" }
}

for _, elemento in ipairs(elementos) do
    manageElement(elemento.nombre, elemento.titulo)
end

local ventanas = {
    { nombre = "edithWindow", titulo = "Edith settings" },
    { nombre = "taintededithWindow", titulo = "Tainted Edith settings" },
    { nombre = "miscWindow", titulo = "Misc settings" }
}

for _, ventana in ipairs(ventanas) do
    if not ImGui.ElementExists(ventana.nombre) then
        ImGui.CreateWindow(ventana.nombre, ventana.titulo .. " \u{f118}\u{f5b3}\u{f118}")
    end
end

ImGui.LinkWindowToElement("edithWindow", "edithSettings")
ImGui.LinkWindowToElement("taintededithWindow", "taintededithSettings")
ImGui.LinkWindowToElement("miscWindow", "miscSettings")

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

local function OptionsUpdate()
	local SaveManager = edithMod.saveManager
	
	if not SaveManager then return end
	local saveData = SaveManager.GetDeadSeaScrollsSave()

    if SaveManager.IsLoaded() then
		agregarColorinput("edithWindow", "EdithTargetColot", "Target Color", 
			function(r, g, b)
				saveData.TargetColor = {
					Red = r,
					Green = g,
					Blue = b,
				}
			end, 
		1, 1, 1)
		
		agregarCombobox("edithWindow", "StompSound", "Set Stomp Sound", {"Stone", "Antibirth", "Fart Reverb", "Vine Boom"}, function(index, val)
			saveData.stompsound = index + 1
		end, 0)
		agregarSlider("edithWindow", "StompVolume", "Set stomp volume", function(index, val)
			saveData.stompVolume = index
		end, 100, 25, 100, "%d%")
		agregarCombobox("edithWindow", "StompSound", "Set Stomp Sound", 
		{
			"Stone", 
			"Antibirth", 
			"Fart Reverb",
			"Vine Boom"
		}, 
		function(index, val)
			saveData.stompsound = index + 1
		end, 0)
		agregarCombobox("edithWindow", "TargetDesign", "Set Target Design", 		
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
		agregarCheckbox("edithWindow", "SetRGB", "Set RGB Mode", function(check)
			saveData.RGBMode = check
		end, false)
		agregarSlider("edithWindow", "SetRGBSpeed", "Set RGB Speed", function(index, val)
			saveData.RGBSpeed = index
		end, 1, 1, 255, "%d%")
		agregarCheckbox("edithWindow", "TargetLine", "Enable Target line", function(check)
				saveData.targetline = check
			end, false)
			agregarSlider("edithWindow", "TargetLineSpace", "Set Line Space", function(index, val)
				saveData.linespace = index
			end, 16, 1, 50, "%d%")
			
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
			})
		-- Edith configs end
		
		-- Tainted Edith Configs
			agregarSlider("taintededithWindow", "StompTaintedVolume", "Set stomp volume", function(index, val)
				saveData.taintedStompVolume = index
			end, 100, 25, 100, "%d%")
			actualizarCampo("StompTaintedVolume", "taintedStompVolume", 100, "Slider")
		
		-- Tainted Edith Configs end
		
		-- Misc Configs
			agregarCheckbox("miscWindow", "ScreenShake", "Enable Stomp screen shake", function(check)
				saveData.shakescreen = check
			end, false)
			
			actualizarCampo("ScreenShake", "shakescreen", false, "Checkbox")
		-- Misc Configs end
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
		
		"StompTaintedVolume",
	}

	for i, element in pairs(elements) do
		print(elements[i],ImGui.ElementExists(element))
	end
end

function edithMod:CallbackRemoveTest()
	if not ImGui.ElementExists("EdithTargetColot") then return end

	for i = 0, 10 do
		ImGui.RemoveCallback("EdithTargetColot", i)
	end
	
	ImGui.AddCallback("EdithTargetColot", ImGuiCallback.Active, function(r, g, b, a)
		local SaveManager = edithMod.saveManager
	
		if not SaveManager then return end
		local saveData = SaveManager.GetDeadSeaScrollsSave()
		
		saveData.TargetColor = {
			Red = r,
			Green = g,
			Blue = b,
		}
	end)
end

function edithMod:ResetImGui()
	local elements = {
		-- Edith
		"StompSound",
		"StompVolume",
		"TargetDesign", 
		"SetRGB", 
		"SetRGBSpeed",
		"TargetLine",
		"TargetLineSpace",
		"ScreenShake",
		"StompTaintedVolume",
	}
	for _, element in ipairs(elements) do
		if ImGui.ElementExists(element) then
			ImGui.RemoveElement(element)
		end
	end
end

local function FalseSafeResetImGui(_, player)
	if player.FrameCount ~= 1 then return end
	-- print("Shit setted idk")
	
	edithMod:CallbackRemoveTest()
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, FalseSafeResetImGui)

local function SetImGuiReset()
	edithMod:ResetImGui()
	edithMod:CallbackRemoveTest()
end
mod:AddCallback(ModCallbacks.MC_PRE_MOD_UNLOAD, SetImGuiReset)
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, SetImGuiReset)
mod:AddCallback(ModCallbacks.MC_POST_RENDER, OptionsUpdate)
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, OptionsUpdate)
