local scriptsPath = "resources/scripts/"
local col = "collectibles/"
local ent = "entities/"
local stmpSyn = "stompSynergies/"
local parrySyn = "parrySynergies/"
local funcs = "functions/"
local compat = "compat/"
local libs = "libs/"
local misc = "misc/"
local effects = "StatusEffects/"

local includeFiles = {
	-- Cosas necesarias
	"definitions",
	compat .. "EID",
	compat .. "Birthcake",
	compat .. "RunicTablet",
	libs .. "prenpckillcallback",
	libs .. "CustomShockwaveAPI",
	libs .. "lhsx",
	libs .. "EdithKotryHudHelper",
	libs .. "status_effect_library",
	funcs .. "functions",
	funcs .. "unlock_functions",
	misc .. "ImGui",
	misc .. "UnlockManager",
	effects .. "Salted",
	effects .. "Peppered",
	effects .. "HydrargyrumCurse",
	effects .. "Cinder",

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
	ent .. "Effects/Trail",
	-- Entidades fin

	-- Personajes
	ent .. "Players/Edith",
	ent .. "Players/Edith_B",
	ent .. "Players/SharedFuncs",
	-- Personajes fin

	"challenges/Vestige",

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
	stmpSyn .. "Technology",

	parrySyn .. "Brimstone",
}

for _, v in ipairs(includeFiles) do
	include(scriptsPath .. v)
end
