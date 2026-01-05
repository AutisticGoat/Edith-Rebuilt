if not EID then return end
local enums = EdithRebuilt.Enums

local Collectibles = enums.CollectibleType
local Trinkets = enums.TrinketType
local Cards = enums.Card

table.insert(EID.TextReplacementPairs, {"ERSalt","MierdaMierdamierdaMierda"})


---@param ID CollectibleType
---@return string
local function IDToMarkup(ID)
    return "{{Collectible" .. tostring(ID) .. "}} "
end

local SaltEffect = {
    En = IDToMarkup(Collectibles.COLLECTIBLE_SALTSHAKER) .. "Any enemy that walks or pass over the salt will get salted#" .. IDToMarkup(Collectibles.COLLECTIBLE_SALTSHAKER) .. "Salted enemies will move slower and receive x1.2 times more damage", 
}

local iconSprite = Sprite()
iconSprite:Load("gfx/EdithRebuiltIcon.anm2", true)
EID:setModIndicatorName("Edith: Rebuilt")
EID:addIcon("Edith Rebuilt Icon", "EdithRebuiltIcon", 0, 32, 32, -2, -3, iconSprite)
EID:setModIndicatorIcon("Edith Rebuilt Icon")

local Descs = {
    Items = {
        [Collectibles.COLLECTIBLE_SALTSHAKER] = {
            ["en_us"] = {
                Name = "", 
                Desc = "Creates a circle of salt around the player#" .. SaltEffect.En .. "#Killing a salted enemy will spawn salt creep below it"
            },
        },
        [Collectibles.COLLECTIBLE_PEPPERGRINDER] = {
            ["en_us"] = {
                Name = "",
                Desc = "Nearby enemies will get Peppered# Peppered enemies will spawn pepper creep every 2nd hit# Pepper creep deals 4 damage per tick and lasts 8 seconds"
            }
        },
        [Collectibles.COLLECTIBLE_EDITHS_HOOD] = {
            ["en_us"] = {
                Name = "", 
                Desc = "{{ArrowUp}} {{Damage}} x1.35 Damage#Player now will shoot salt tears#Pressing the Drop button will make Isaac jump#The jump has a 3 seconds cooldown#Isaac will spawn a small circle of salt when landing#" .. SaltEffect.En .. "#Killing a salted enemy will spawn tears in random directions",
            }
        },
        [Collectibles.COLLECTIBLE_SULFURIC_FIRE] = {
            ["en_us"] = {
                Name = "", 
                Desc = "On use, nearby enemies will: {{Damage}} Get damaged (Formula: Isaac's Damage + 17.5% of Enemy's Max HP)#{{BrimstoneCurse}} Get Brimstone curse effect#If an enemy dies, it will spawn a brimstone ball",
            }
        },
        [Collectibles.COLLECTIBLE_GILDED_STONE] = {
            ["en_us"] = {
                Name = "", 
                Desc = "{{Coin}} +5 Coins#{{Collectible592}} Chance of shoot rock tears (Depends on your {{Coin}} amount of coins)#Chance of receiving a prize by destroying a rock (Depends on your {{Luck}} luck and {{Coin}} amount of coins), the possible prizes are:#{{Coin}} Penny (75%)#{{Nickel}} Nickel (15%)#{{Dime}} Dime (5%)#{{Collectible74}} One Quarter (4%)#{{Collectible18}} One Dollar(1%)"
            }
        },
        [Collectibles.COLLECTIBLE_HYDRARGYRUM] = {
            ["en_us"] = {
                Name = "", 
                Desc = "Damaging an enemy will make it to shoot Mercury tears in random directions every 15 frames for 4 seconds#Mercury tears will leave creep when they land or hit an enemy#Mercury creep deals fire damage"
            }
        },
        [Collectibles.COLLECTIBLE_SAL] = {
            ["en_us"] = {
                Name = "", 
                Desc = IDToMarkup(Collectibles.COLLECTIBLE_SALTSHAKER) .. "Player will spawn salt on their position every 15 frames#" .. SaltEffect.En .. "#Killing a salted enemy will make it shoot 4-6 tears in random directions",
            }
        },
        [Collectibles.COLLECTIBLE_SALT_HEART] = {
            ["en_us"] = {
                Name = "", 
                Desc = "{{ArrowUp}} {{Damage}} x1.5 Damage##When taking Damage: #{{Heart}} All taken damage will be doubled #Player will shoot 4-6 salt tears in random directions#" .. IDToMarkup(Collectibles.COLLECTIBLE_SALTSHAKER) .. "Player will spawn salt in their position every 3 frames for 5 seconds#" .. SaltEffect.En .. "#{{Heart}} Killing an enemy has a chance to spawn a random heart",
            }
        },
        [Collectibles.COLLECTIBLE_MOLTEN_CORE] = {
            ["en_us"] = {
                Name = "", 
                Desc = "{{ArrowUp}} {{Damage}} +0.5 Damage#Nearby enemies will start to burn#If an enemy dies while being close to Isaac, a Fire jet will spawn in its position",
            }
        },
        [Collectibles.COLLECTIBLE_FATE_OF_THE_UNFAITHFUL] = {
            ["en_us"] = {
                Name = "", 
                Desc = "On use:#{{ArrowUp}} {{Damage}} Damage +1.75#{{Burning}} Enemies will get burn#Deals Damage to enemies depending on their distance to Isaac#The closer, the bigger will be the damage#Nearby enemies will get pushed",
            }
        },
        [Collectibles.COLLECTIBLE_DIVINE_RETRIBUTION] = {
            ["en_us"] = {
                Name = "", 
                Desc = "On use:#{{ArrowUp}} 50% of dealing damage to all enemies in room and get a {{SoulHeart}} soul heart#{{ArrowDown}} 50% chance of Isaac getting damage",
            }
        },
        [Collectibles.COLLECTIBLE_SPICES_MIX] = {
            ["en_us"] = {
                Name = "", 
                Desc = "On use:#Trigger 1 of 8 possible spices effects: Salt, Pepper, Turmeric, Garlic, Cumin, Ginger, Cinnamon, Oregano",
            }
        },
        [Collectibles.COLLECTIBLE_SPICES_MIX] = {
            ["en_us"] = {
                Name = "", 
                Desc = "On use:#Trigger 1 of 8 possible spices effects: Salt, Pepper, Turmeric, Garlic, Cumin, Ginger, Cinnamon, Oregano",
            }
        },
        [Collectibles.COLLECTIBLE_BURNT_HOOD] = { 
            ["en_us"] = {
                Name = "",
                Desc = "On use:#Isaac will do a short jump in place# Landing in an enemy will trigger a parry, damaging the enemy# Perfectly performing a parry will recharge the item"
            }
        },
        [Collectibles.COLLECTIBLE_DIVINE_WRATH] = { 
            ["en_us"] = {
                Name = "",
                Desc = "On use:# Spawn 2 rock rings around Isaac# Shoot 8-12 arched fire rock tears in random directions"
            }
        },
        [Collectibles.COLLECTIBLE_EFFIGY] = { 
            ["en_us"] = {
                Name = "",
                Desc = "On use:# Isaac will do a high jump and a target will appear below him#Once Isaac starts falling, the target will move to Isaac's nearest enemy#Landing will damage the enemy and push it"
            }
        },
        [Collectibles.COLLECTIBLE_CHUNK_OF_BASALT] = { 
            ["en_us"] = {
                Name = "",
                Desc = "Press the Drop button ({{ButtonRT}}) while moving to perform a Dash#If Isaac collides with an enemy while dashing: #{{Damage}} The enemy will be damaged#The enemy will be pushed#If the enemy is killed by the dash, it will shoot 5-8 basalt tears in random directions"
            }
        },
    },
    Trinkets = {
        [Trinkets.TRINKET_RUMBLING_PEBBLE] = {
            ["en_us"] = {
                Name = "Rumbling pebble",
                Desc = "{{Collectible592}} 30% chance of shooting a rock tear#On destroying a rock, this will shoot rock tears in random directions, these will always destroy rocks"
            }
        },
        [Trinkets.TRINKET_GEODE] = {
            ["en_us"] = {
                Name = "Geode",
                Desc = "{{Rune}} 2.5% chance to spawn a rune when killing an enemy#{{Rune}} 25% of destroy the geode and spawn 3 runes on taking damage"
            }
        },
        [Trinkets.TRINKET_PAPRIKA] = {
            ["en_us"] = {
                Name = "Paprika",
                Desc = "Enemies have a 50% of explode on death#{{Burning}} Nearby enemies will get burn, will be pushed and took 25% of explotion's damage"
            }
        },
        [Trinkets.TRINKET_BURNT_SALT] = {
            ["en_us"] = {
                Name = "Burnt salt",
                Desc = "50% chance of shooting a burnt salt tear#Kill an enemy with a burnt salt tear will have a 50% chance of it shoot 5-7 burnt salt tears in random directions"
            }
        },
    },
    Cards = {
        [Cards.CARD_SALT_ROCKS] = {
            ["en_us"] = {
                Name = "Salt rocks",
                Desc = "On use, all enemies in room will get \"salted\":#Enemies have a 50% of not doing their attacks#{{Slow}} Enemies will be slowed#{{Damage}} Enemies will take x1.2 damage"
            }
        },
        [Cards.CARD_JACK_OF_CLUBS] = {
            ["en_us"] = {
                Name = "Jack of clubs",
                Desc = "On use, enemies have a 40% chance of explode#{{Bomb}} If the enemy dies, there's a 50% chance of it dropping a bomb"
            }
        },
        [Cards.CARD_SOUL_EDITH] = {
            ["en_us"] = {
                Name = "Jack of clubs",
                Desc = "On use, the player will jump, on landing:#{{Damage}} Near enemies will be pushed and will receive damage#{{Collectible592}} Rock tears will fall from the ceiling in random positions"
            }
        },
    }
}

local targetFunc = {
    ["Items"] = EID.addCollectible,
    ["Trinkets"] = EID.addTrinket,
    ["Cards"] = EID.addCard,
}

for kind, Desc in pairs(Descs) do
    for id, lang in pairs(Desc) do
        for lang, info in pairs(lang) do
            targetFunc[kind](EID, id, info.Desc, info.Name, lang)
        end
    end
end