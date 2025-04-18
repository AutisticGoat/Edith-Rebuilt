local scriptsPath = "resources/scripts/"
local col = "collectibles/"
local ent = "entities/"
local stmpSyn = "stompSynergies/"


local includeFiles = {
	-- Cosas necesarias
	"definitions",
	"functions/helper_functions",
	"functions/functions",
	"functions/EdithClasses",
	"functions/unlock_functions",
	"ImGui",
	"EdithKotryHudHelper",
	"lhsx",
	"resources/scripts/functions/functions",       -- Added for better autocomplete
	
	-- Items
	col .. "items/Edith/SaltShaker",
	col .. "items/Edith/PepperGrinder",
	col .. "items/Edith/EdithsHood",
	col .. "items/Edith/SulfuricFire",
	col .. "items/Edith/Sal",
	col .. "items/Edith/MoltenCore",
	col .. "items/Edith/GildedStone",
	col .. "items/Edith/FateOfTheUnfaithful",
	col .. "items/Edith/SaltHeart",
	col .. "items/Edith/DivineRetribution",
	col .. "items/Edith/Hydrargyrum",
	col .. "items/TEdith/BurnedHood",
	-- Items fin

	-- Trinkets
	col .. "trinkets/Edith/geode",
	col .. "trinkets/Edith/rumblingpebble",
	col .. "trinkets/TEdith/Paprika",
	col .. "trinkets/TEdith/BurnedSalt",
	-- Trinkets fin
	
	col .. "consumables/JackOfClubs",

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
	-- stmpSyn .. "blackPowder",
	-- stmpSyn .. "brimstone",
	-- stmpSyn .. "techX",
	-- stmpSyn .. "MomsKnife",
	-- stmpSyn .. "Rockwaves",
	-- stmpSyn .. "SpiritSword",
	-- stmpSyn .. "EpicFetus",
		
	"RNG",
}

for _, v in ipairs(includeFiles) do
	include(scriptsPath .. v)
end
