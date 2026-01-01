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
	compat .. "EID",
	compat .. "Birthcake",
	compat .. "RunicTablet",
	compat .. "TheFuture",
	libs .. "prenpckillcallback",
	libs .. "CustomShockwaveAPI",
	libs .. "lhsx",
	libs .. "EdithKotryHudHelper",
	funcs .. "functions",
	funcs .. "unlock_functions",
	misc .. "ImGui",
	misc .. "UnlockManager",

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
	col .. "items/Edith/SpicesMix",
	col .. "items/TEdith/BurntHood",
	col .. "items/TEdith/DivineWrath",
	col .. "items/Challenges/Effigy",
	col .. "items/Challenges/ChunkOfBasalt",
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
	"challenges/Grudge",

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
	stmpSyn .. "Neptunus",
	stmpSyn .. "ChocolateMilk",
	stmpSyn .. "Damage",
	stmpSyn .. "HeadOfTheKeeper",
	stmpSyn .. "FlatStone",
	stmpSyn .. "JacobsLadder",
	stmpSyn .. "GodsFlesh",
	stmpSyn .. "PlaydoughCookie",
	stmpSyn .. "OcularRift",
	stmpSyn .. "HolyLight",
	stmpSyn .. "Jupiter",
	stmpSyn .. "LostContact",
	stmpSyn .. "LittleHorn",
	stmpSyn .. "Peppers",

	parrySyn .. "blackPowder",
	parrySyn .. "brimstone",
	parrySyn .. "techX",
	parrySyn .. "MomsKnife",
	parrySyn .. "Rockwaves",
	parrySyn .. "SpiritSword",
	parrySyn .. "EpicFetus",
	parrySyn .. "StatusEffects",
	parrySyn .. "GodHead",
	parrySyn .. "Technology",
	parrySyn .. "Neptunus",
	parrySyn .. "ChocolateMilk",
	parrySyn .. "Damage",
	parrySyn .. "HeadOfTheKeeper",
	parrySyn .. "FlatStone",
	parrySyn .. "JacobsLadder",
	parrySyn .. "GodsFlesh",
	parrySyn .. "PlaydoughCookie",
	parrySyn .. "OcularRift",
	parrySyn .. "HolyLight",
	parrySyn .. "Jupiter",
	parrySyn .. "LittleHorn",
}

for _, v in ipairs(includeFiles) do
	include(scriptsPath .. v)
end
