local scriptsPath = "resources/scripts/"
local col = "collectibles/"
local ent = "entities/"
local stmpSyn = "stompSynergies/"
local parrySyn = "parrySynergies/"
local funcs = "functions/"

local includeFiles = {
	-- Cosas necesarias
	"definitions",
	"EID",
	"Birthcake",
	"prenpckillcallback",
	"CustomShockwaveAPI",
	funcs .. "functions",
	funcs .. "unlock_functions",
	"ImGui",
	"EID",
	"EdithKotryHudHelper",
	"lhsx",
	
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
	col .. "items/TEdith/BurntHood",
	col .. "items/TEdith/DivineWrath",
	col .. "items/Edith/ChunkOfBasalt",
	-- Items fin

	-- Trinkets
	col .. "trinkets/Edith/geode",
	col .. "trinkets/Edith/rumblingpebble",
	col .. "trinkets/TEdith/Paprika",
	col .. "trinkets/TEdith/BurntSalt",
	-- Trinkets fin
	
	col .. "consumables/JackOfClubs",
	col .. "consumables/SaltRocks",
	col .. "consumables/SoulOfEdith",

	-- Entidades
	ent .. "Effects/Creeps",
	ent .. "Effects/Targets",
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
	stmpSyn .. "StatusEffects",
	stmpSyn .. "GodHead",
		
	parrySyn .. "Brimstone",
}

for _, v in ipairs(includeFiles) do
	include(scriptsPath .. v)
end
