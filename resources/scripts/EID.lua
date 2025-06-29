if not EID then return end
local enums = EdithRebuilt.Enums

local Collectibles = enums.CollectibleType
local Trinkets = enums.TrinketType
local Cards = enums.Card

table.insert(EID.TextReplacementPairs, {"ERSalt","MierdaMierdamierdaMierda"})

local SaltEffect = {
    Es = "{{Petrify}} Cualquier enemigo que pise o pase sobre la sal será petrificado",
    En = "{{Petrify}} Any enemy that walks or pass over the salt will get petrified"
}

---@param ID CollectibleType
---@return string
local function IDToMarkup(ID)
    return "{{Collectible" .. tostring(ID) .. "}} "
end

local iconSprite = Sprite()
iconSprite:Load("gfx/EdithRebuiltIcon.anm2", true)
EID:setModIndicatorName("Edith: Rebuilt")
EID:addIcon("Edith Rebuilt Icon", "EdithRebuiltIcon", 0, 32, 32, -2, -3, iconSprite)
EID:setModIndicatorIcon("Edith Rebuilt Icon")

local Descs = {
    Items = {
        [Collectibles.COLLECTIBLE_SALTSHAKER] = {
            ["spa"] = {
                Name = "Salero", 
                Desc = "Crea un círculo de sal alrededor del jugador#{{Petrify}} Cualquier enemigo que pise o pase sobre la sal será petrificado"
            },
            ["en_us"] = {
                Name = "Salt Shaker", 
                Desc = "Creates a circle of salt around the player#{{Petrify}} Any enemy that walks or pass over the salt will get petrified"
            }
        },
        [Collectibles.COLLECTIBLE_GILDED_STONE] = {
             ["spa"] = {
                Name = "Piedra dorada", 
                Desc = "{{Coin}} +5 Monedas#{{Collectible592}} Probabilidad de disparar lágrimas de roca (Depende de tu {{Coin}} cantidad de monedas)#Posibilidad de recibir un premio al destruir una roca (Depende de tu {{Luck}} suerte y {{Coin}} cantidad de monedas), los posibles premios son:#{{Coin}} Centavo (75%)#{{Nickel}} Níquel (15%)#{{Dime}} Diez centavos (5%)#{{Collectible74}} Un Cuarto (4%)#{{Collectible18}} Un Dólar(1%)"
            },
            ["en_us"] = {
                Name = "", 
                Desc = "{{Coin}} +5 Coins#{{Collectible592}} Chance of shoot rock tears (Depends on your {{Coin}} amount of coins)#Chance of receiving a prize by destroying a rock (Depends on your {{Luck}} luck and {{Coin}} amount of coins), the possible prizes are:#{{Coin}} Penny (75%)#{{Nickel}} Nickel (15%)#{{Dime}} Dime (5%)#{{Collectible74}} One Quarter (4%)#{{Collectible18}} One Dollar(1%)"
            }
        },
        [Collectibles.COLLECTIBLE_HYDRARGYRUM] = {
             ["spa"] = {
                Name = "", 
                Desc = "Dañar a un enemigo hará que este comience a disparar lágrimas de Mercurio en direcciones aleatorias cada 15 frames durante 4 segundos#Matar a un enemigo en este estado creará una llamarada sobre el"
            },
            ["en_us"] = {
                Name = "", 
                Desc = "Damaging an enemy will make it to shoot Mercury tears in random directions every 15 frames for 4 seconds#Killing an enemy in this state will create a fire burst on top of it"
            }
        },
        [Collectibles.COLLECTIBLE_EDITHS_HOOD] = {
             ["spa"] = {
                Name = "Capucha de Edith", 
                Desc = "{{ArrowDown}} {{Tears}} Lágrimas x0.8#{{ArrowUp}} {{Damage}} Daño x1.35#El jugador disparará lágrimas de sal#" .. IDToMarkup(Collectibles.COLLECTIBLE_SALTSHAKER) .. " 20% de probabilidad de crear sal bajo el enemigo al morir#" .. SaltEffect.Es,
            },
            ["en_us"] = {
                Name = "", 
                Desc = "{{ArrowDown}} {{Tears}} x0.8 Tears #{{ArrowUp}} {{Damage}} x1.35 Damage#Player now will shoot salt tears#" .. IDToMarkup(Collectibles.COLLECTIBLE_SALTSHAKER) .. "20% change of spawning salt below the enemy when killing it#" .. SaltEffect.En,
            }
        },
        [Collectibles.COLLECTIBLE_SAL] = {
             ["spa"] = {
                Name = "", 
                Desc = IDToMarkup(Collectibles.COLLECTIBLE_SALTSHAKER) .. "El jugador creará sal en su posición cada 15 frames#" .. SaltEffect.Es .. "# Matar a un enemigo petrificado lo hará disparar 4-6 lágrimas de sal en direcciones aleatorias",
            },
            ["en_us"] = {
                Name = "", 
                Desc = IDToMarkup(Collectibles.COLLECTIBLE_SALTSHAKER) .. "Player will spawn salt on their position every 15 frames#" .. SaltEffect.En .. "#Killing a petrified enemy will make it shoot 4-6 tears in random directions",
            }
        },
        [Collectibles.COLLECTIBLE_SALT_HEART] = {
             ["spa"] = {
                Name = "Corazón de sal", 
                Desc = "{{ArrowUp}} {{Damage}} Daño x1.5#{{Heart}} Todo daño entrante será duplicado#Al recibir daño: #Dispararás 4-6 lágrimas de sal en direcciones aleatorias#" .. IDToMarkup(Collectibles.COLLECTIBLE_SALTSHAKER) .. "El jugador creará sal en su posición cada 5 frames durante 3 segundos#" .. SaltEffect.Es,
            },
            ["en_us"] = {
                Name = "", 
                Desc = "{{ArrowUp}} {{Damage}} x1.5 Damage#{{Heart}} Every taking damage will be double#When taking Damage: #Player will shoot 4-6 salt tears in random directions#" .. IDToMarkup(Collectibles.COLLECTIBLE_SALTSHAKER) .. "Player will spawn salt in their position every 3 frames for 5 seconds#" .. SaltEffect.En,
            }
        },
        [Collectibles.COLLECTIBLE_MOLTEN_CORE] = {
             ["spa"] = {
                Name = "Nuclueo Derretido", 
                Desc = "{{ArrowUp}} {{Damage}} Daño x1.5#{{Heart}} Todo daño entrante será duplicado#Al recibir daño: #Dispararás 4-6 lágrimas de sal en direcciones aleatorias#" .. IDToMarkup(Collectibles.COLLECTIBLE_SALTSHAKER) .. "El jugador creará sal en su posición cada 5 frames durante 3 segundos#" .. SaltEffect.Es,
            },
            ["en_us"] = {
                Name = "", 
                Desc = "{{ArrowUp}} {{Damage}} x1.5 Damage#{{Heart}} Every taking damage will be double#When taking Damage: #Player will shoot 4-6 salt tears in random directions#" .. IDToMarkup(Collectibles.COLLECTIBLE_SALTSHAKER) .. "Player will spawn salt in their position every 3 frames for 5 seconds#" .. SaltEffect.En,
            }
        },
    },
    Trinkets = {
        [Trinkets.TRINKET_RUMBLING_PEBBLE] = {
            ["spa"] = {
                Name = "Guijarro ruidoso",
                Desc = "{{Collectible592}} 30% de probabilidad de lanzar una lágrima de roca#Al destruir una roca, esta disparará lágrimas de roca en direcciones aleatorias, estas siempre podrán destruir rocas"
            },
            ["en_us"] = {
                Name = "Rumbling pebble",
                Desc = "{{Collectible592}} 30% chance of shooting a rock tear#On destroying a rock, this will shoot rock tears in random directions, these will always destroy rocks"
            }
        },
        [Trinkets.TRINKET_GEODE] = {
            ["spa"] = {
                Name = "Geoda",
                Desc = "{{Rune}} Los enemigos tienen un 2.5% de probabilidad de generar una runa al morir#{{Rune}} 25% de probabilidad de destruir la geoda y generar 3 runas al recibir daño"
            },
            ["en_us"] = {
                Name = "Geode",
                Desc = "{{Rune}} 2.5% chance to spawn a rune when killing an enemy#{{Rune}} 25% of destroy the geode and spawn 3 runes on taking damage"
            }
        },
        [Trinkets.TRINKET_PAPRIKA] = {
            ["spa"] = {
                Name = "Páprika",
                Desc = "Los enemigos tienen un 50% de probabilidad de explotar al morir#{{Burning}} Los enemigos cercanos serán quemados, empujados y recibirán un 25% del daño de la explosión"
            },
            ["en_us"] = {
                Name = "Paprika",
                Desc = "Enemies have a 50% of explode on death#{{Burning}} Nearby enemies will get burn, will be pushed and took 25% of explotion's damage"
            }
        },
        [Trinkets.TRINKET_BURNT_SALT] = {
            ["spa"] = {
                Name = "Sal quemada",
                Desc = "50% de probabilidad de lanzar una lágrima de sal quemada#Matar a un enemigo con una lágrima de sal quemada tendrá un 50% de probabilidad de hacerlo disparar 5-7 lágrimas de sal en direcciones aleatorias"
            },
            ["en_us"] = {
                Name = "Burnt salt",
                Desc = "50% chance of shooting a burnt salt tear#Kill an enemy with a burnt salt tear will have a 50% chance of it shoot 5-7 burnt salt tears in random directions"
            }
        },
    },
    Cards = {
        [Cards.CARD_SALT_ROCKS] = {
            ["spa"] = {
                Name = "Rocas de sal",
                Desc = "Tras el uso, todos los enemigos de la sala serán \"salados\":#Los enemigos tienen un 50% de probabilidad de no realizar ataques#{{Slow}} Los enemigos serán ralentizados#{{Damage}} Los enemigos recibirán 1.2 veces más daño"
            },
            ["en_us"] = {
                Name = "Salt rocks",
                Desc = "On use, all enemies in room will get \"salted\":#Enemies have a 50% of not doing their attacks#{{Slow}} Enemies will be slowed#{{Damage}} Enemies will take x1.2 damage"
            }
        },
        [Cards.CARD_JACK_OF_CLUBS] = {
            ["spa"] = {
                Name = "Jota de tréboles",
                Desc = "Tras el uso, los enemigos tienen un 40% de probabilidad de explotar#{{Bomb}} Si el enemigo muere, tiene un 50% de soltar una bomba al morir"
            },
            ["en_us"] = {
                Name = "Jack of clubs",
                Desc = "On use, enemies have a 40% chance of explode#{{Bomb}} If the enemy dies, there's a 50% chance of it dropping a bomb"
            }
        },
        [Cards.CARD_SOUL_EDITH] = {
            ["spa"] = {
                Name = "Alma de Edith",
                Desc = "Tras el uso, el jugador saltará, al aterrizar:#{{Damage}} Los enemigos cercanos serán empujados y dañados#{{Collectible592}} Caerán lágrimas de roca del techo en posiciones aleatorias"
            },
            ["en_us"] = {
                Name = "Jack of clubs",
                Desc = "On use, the player will jump, on landing:#{{Damage}} Near enemies will be pushed and will receive damage#{{Collectible592}} Rock tears will fall from the ceiling in random positions"
            }
        },
    }
}

for kind, Desc in pairs(Descs) do
    local targetFunc = {
        ["Items"] = EID.addCollectible,
        ["Trinkets"] = EID.addTrinket,
        ["Cards"] = EID.addCard,
    }

    local func = targetFunc[kind]

    for id, lang in pairs(Desc) do
        for lang, info in pairs(lang) do
            ---@diagnostic disable-next-line: param-type-mismatch
            func(EID, id, info.Desc, info.Name, lang)
        end
    end
end

local buff = XMLData.GetModById(0)

for k, v in pairs(buff) do
    print(k, v)
end

EID:addCollectible(357, "{{Timer}} Duplicates all your familiars for the room#{{Collectible113}} Grants a Demon Baby for the room if Isaac has no familiars", "Box of Friends", "en")

