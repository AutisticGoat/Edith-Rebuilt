local includeFiles = {
	-- Cosas necesarias
	"definitions",
	"resources/scripts/functions/helper_functions",
	"resources/scripts/functions/special_functions",
	"resources/scripts/ImGui",
	
	-- Items
	"resources/scripts/collectibles/items/SaltShaker",
	"resources/scripts/collectibles/items/PepperGrinder",
	"resources/scripts/collectibles/items/EdithsHood",
	"resources/scripts/collectibles/items/SulfuricFire",
	"resources/scripts/collectibles/items/Sal",
	-- Items fin
	
	-- Trinkets
	"resources/scripts/collectibles/trinkets/geode",
	"resources/scripts/collectibles/trinkets/rumblingpebble",
	-- Trinkets fin
	
	-- Entidades
	"resources/scripts/entities/Effects/SaltCreep",
	"resources/scripts/entities/Effects/PepperCreep",
	"resources/scripts/entities/Effects/Edith_Target",
	"resources/scripts/entities/Effects/Edith_Target_B",
	-- Entidades fin
	
	-- Personajes
	"resources/scripts/entities/Players/Edith",
	"resources/scripts/entities/Players/Edith_B",
	-- Personajes fin
	
	-- Desafios	-- Desafios fin

	-- sinergias pisotones
	"resources/scripts/stompSynergies/blackPowder",
	"resources/scripts/stompSynergies/brimstone",
	"resources/scripts/stompSynergies/techX",
	"resources/scripts/stompSynergies/MomsKnife",
	"resources/scripts/stompSynergies/Rockwaves",
	"resources/scripts/stompSynergies/SpiritSword",
	"resources/scripts/stompSynergies/EpicFetus",
	
	
	"resources/scripts/RNG",
}

for _, v in ipairs(includeFiles) do
	include(v)
end