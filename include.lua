local scriptsPath = "resources/scripts"

local includeFiles = {
	-- Cosas necesarias
	"/definitions",
	"/functions/helper_functions",
	"/functions/special_functions",
	"/ImGui",
	
	-- Items
	"/collectibles/items/SaltShaker",
	"/collectibles/items/PepperGrinder",
	"/collectibles/items/EdithsHood",
	"/collectibles/items/SulfuricFire",
	"/collectibles/items/Sal",
	-- Items fin
	
	-- Trinkets
	"/collectibles/trinkets/geode",
	"/collectibles/trinkets/rumblingpebble",
	-- Trinkets fin
	
	-- Entidades
	"/entities/Effects/SaltCreep",
	"/entities/Effects/PepperCreep",
	"/entities/Effects/Edith_Target",
	"/entities/Effects/Edith_Target_B",
	-- Entidades fin
	
	-- Personajes
	"/entities/Players/Edith",
	"/entities/Players/Edith_B",
	-- Personajes fin
	

	-- sinergias pisotones
	"/stompSynergies/blackPowder",
	"/stompSynergies/brimstone",
	"/stompSynergies/techX",
	"/stompSynergies/MomsKnife",
	"/stompSynergies/Rockwaves",
	"/stompSynergies/SpiritSword",
	"/stompSynergies/EpicFetus",
	
	"/RNG",
}

for _, v in ipairs(includeFiles) do
	include(scriptsPath .. v)
end