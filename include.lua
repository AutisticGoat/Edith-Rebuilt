local scriptsPath = "resources/scripts/"
local col = "collectibles/"
local ent = "entities/"
local stmpSyn = "stompSynergies/"

local includeFiles = {
	-- Cosas necesarias
	"definitions",
	"functions/helper_functions",
	"functions/special_functions",
	"functions/EdithClasses",
	"ImGui",
	"EdithKotryHudHelper",
	
	-- Items
	col .. "items/SaltShaker",
	col .. "items/PepperGrinder",
	col .. "items/EdithsHood",
	col .. "items/SulfuricFire",
	col .. "items/Sal",
	col .. "items/MoltenCore",
	col .. "items/GildedStone",
	-- Items fin
	
	-- Trinkets
	col .. "trinkets/geode",
	col .. "trinkets/rumblingpebble",
	-- Trinkets fin
	
	-- Entidades
	ent .. "Effects/SaltCreep",
	ent .. "Effects/PepperCreep",
	ent .. "Effects/Edith_Target",
	ent .. "Effects/Edith_Target_B",
	-- Entidades fin
	
	-- Personajes
	ent .. "Players/Edith",
	ent .. "Players/Edith_B",
	-- Personajes fin
	
	-- sinergias pisotones
	stmpSyn .. "blackPowder",
	stmpSyn .. "brimstone",
	stmpSyn .. "techX",
	stmpSyn .. "MomsKnife",
	stmpSyn .. "Rockwaves",
	stmpSyn .. "SpiritSword",
	stmpSyn .. "EpicFetus",
		
	"RNG",
}

for _, v in ipairs(includeFiles) do
	include(scriptsPath .. v)
end