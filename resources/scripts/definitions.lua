edithMod.Enums = {
	PlayerType = {
		PLAYER_EDITH = Isaac.GetPlayerTypeByName("Edith", false),
		PLAYER_EDITH_B = Isaac.GetPlayerTypeByName("Edith", true),
	},
	CollectibleType = {
		COLLECTIBLE_SALTSHAKER = Isaac.GetItemIdByName("Salt Shaker"),
		COLLECTIBLE_PEPPERGRINDER = Isaac.GetItemIdByName("Pepper Grinder"),
		COLLECTIBLE_EDITHS_HOOD = Isaac.GetItemIdByName("Edith's Hood"),
		COLLECTIBLE_SULFURIC_FIRE = Isaac.GetItemIdByName("Sulfuric Fire"),
		COLLECTIBLE_SAL = Isaac.GetItemIdByName("Sal"),
		COLLECTIBLE_MOLTEN_CORE = Isaac.GetItemIdByName("Molten Core"),
		COLLECTIBLE_GILDED_STONE = Isaac.GetItemIdByName("Gilded Stone"),
	},
	TrinketType = {
		TRINKET_GEODE = Isaac.GetTrinketIdByName("Geode"),
		TRINKET_RUMBLING_PEBBLE = Isaac.GetTrinketIdByName("Rumbling Pebble"),
	},
	NullItemID = {
		ID_EDITH_SCARF = Isaac.GetCostumeIdByPath("gfx/characters/EdithHood.anm2"),
		ID_EDITH_B_SCARF = Isaac.GetCostumeIdByPath("gfx/characters/EdithTaintedHood.anm2"),
	},
	EffectVariant = {
		EFFECT_EDITH_TARGET = Isaac.GetEntityVariantByName("Edith Target"),
		EFFECT_EDITH_B_TARGET = Isaac.GetEntityVariantByName("Edith Tainted Arrow"),
	},
	SubTypes = {
		SALT_CREEP = Isaac.GetEntitySubTypeByName("Salt Creep"),
		PEPPER_CREEP = Isaac.GetEntitySubTypeByName("Pepper Creep"),
	},
	SoundEffect = {
		SOUND_EDITH_STOMP = Isaac.GetSoundIdByName("Edith Stomp"),
		SOUND_EDITH_STOMP_WATER = Isaac.GetSoundIdByName("Edith Stomp Water"),
		SOUND_WATERSPLASH = Isaac.GetSoundIdByName("Water Splash"),
		SOUND_PIZZA_TAUNT = Isaac.GetSoundIdByName("Taunt"),
		SOUND_FART_REVERB = Isaac.GetSoundIdByName("Fart Reverb"),
		SOUND_VINE_BOOM = Isaac.GetSoundIdByName("Vine Boom"),
		SOUND_SALT_SHAKER = Isaac.GetSoundIdByName("Salt Shaker"),
		SOUND_PEPPER_GRINDER = Isaac.GetSoundIdByName("Pepper Grinder"),
		SOUND_YIPPEE = Isaac.GetSoundIdByName("Yippee"),
		SOUND_SPRING = Isaac.GetSoundIdByName("Spring"),
		SOUND_SOLARIAN = Isaac.GetSoundIdByName("Solarian"),
	},
	Utils = {
		Game = Game(),
		SFX = SFXManager(),
		RNG = RNG(),
		Room = nil,
		Level = nil,
	},
	Tables = {
		OverrideActions = {
			[ButtonAction.ACTION_LEFT] = 0,
			[ButtonAction.ACTION_RIGHT] = 0,
			[ButtonAction.ACTION_UP] = 0,
			[ButtonAction.ACTION_DOWN] = 0,
		},
		OverrideWeapons = {
			[WeaponType.WEAPON_BRIMSTONE] = true,
			[WeaponType.WEAPON_KNIFE] = true,
			[WeaponType.WEAPON_LASER] = true,
			[WeaponType.WEAPON_BOMBS] = true,
			[WeaponType.WEAPON_ROCKETS] = true,
			[WeaponType.WEAPON_TECH_X] = true,
			[WeaponType.WEAPON_SPIRIT_SWORD] = true
		},
		DegreesToDirection = {
			[0] = Direction.RIGHT,
			[90] = Direction.DOWN,
			[180] = Direction.LEFT,
			[270] = Direction.UP,
			[360] = Direction.RIGHT,
		},
		ArrowSuffix = {
			[1] = "_arrow",
			[2] = "_arrow_pointy",
			[3] = "_triangle_line",
			[4] = "_triangle_full",
			[5] = "_chevron_line",
			[6] = "_chevron_full",
			[7] = "_grudge",
		},		
		TargetSuffix = {
			[1] = "",
			[2] = "_trans",
			[3] = "_rainbow",
			[4] = "_lesbian",
			[5] = "_bisexual",
			[6] = "_gay",
			[7] = "_ace",
			[8] = "_enby",
			[9] = "_Venezuela",
		},	
		ColorValues = {
			[2] = {R = 245/255, G = 169/255, B = 184/255},
			[3] = {R = 1, G = 0, B = 1},
			[4] = {R = 1, G = 154/255, B = 86/255},
			[5] = {R = 155/255, G = 79/255, B = 150/255},
			[6] = {R = 123/255, G = 173/255, B = 226/255},
			[7] = {R = 128/255, G = 0, B = 128/255},
			[8] = {R = 154/255, G = 89/255, B = 207/255},
			[9] = {R = 0, G = 36/255, B = 125/255},
		},
		FrameLimits = {
			["Idle"] = 12,
			["Blink"] = 2
		},
		BloodytearVariants = {
			[TearVariant.BLOOD] = true,
			[TearVariant.GLAUCOMA_BLOOD] = true,
			[TearVariant.CUPID_BLOOD] = true,
			[TearVariant.PUPULA_BLOOD] = true,
			[TearVariant.GODS_FLESH_BLOOD] = true,
		},
		TearShatterColor = {
			[true] = {
				[true] = {0.4, 0.125, 0.125},
				[false] = {0.4, 0.4, 0.4}
			},
			[false] = {
				[true] = {0.65, 0.1, 0.1},
				[false] = {1, 1, 1}
			}
		},
		Runes = {
			Card.RUNE_HAGALAZ,
			Card.RUNE_JERA,
			Card.RUNE_EHWAZ,
			Card.RUNE_DAGAZ,
			Card.RUNE_ANSUZ,
			Card.RUNE_PERTHRO,
			Card.RUNE_BERKANO,
			Card.RUNE_ALGIZ,
			Card.RUNE_BLANK,
			Card.RUNE_BLACK,
		},
		JumpTags = {
			EdithJump = "edithMod_EdithJump",
			TEdithJump = "edithMod_TaintedEdithJump",
			TEdithParry = "edithMod_TaintedEdithParry",
		},
		JumpFlags = {
			EdithJump = (JumpLib.Flags.DISABLE_SHOOTING_INPUT | JumpLib.Flags.DISABLE_LASER_FOLLOW | JumpLib.Flags.DISABLE_BOMB_INPUT),
			TEdithJump = (JumpLib.Flags.COLLISION_GRID | JumpLib.Flags.COLLISION_ENTITY | JumpLib.Flags.OVERWRITABLE | JumpLib.Flags.DISABLE_COOL_BOMBS | JumpLib.Flags.IGNORE_CONFIG_OVERRIDE | JumpLib.Flags.FAMILIAR_FOLLOW_ORBITALS),
			TEdithParry = (JumpLib.Flags.COLLISION_GRID | JumpLib.Flags.OVERWRITABLE | JumpLib.Flags.DISABLE_COOL_BOMBS | JumpLib.Flags.IGNORE_CONFIG_OVERRIDE | JumpLib.Flags.FAMILIAR_FOLLOW_ORBITALS),
		},
	},
	Misc = {
		TearPath = "gfx/tears/",
		ObscureDiv = 155/255,
	},
}

local game = edithMod.Enums.Utils.Game

edithMod.Enums.Utils.Room = game:GetRoom()
edithMod.Enums.Utils.Level = game:GetLevel()


function edithMod:SetObjects()
	

	-- print(game)
	-- print(game:GetRoom())
	-- print(game:GetLevel())
	
	
	
	-- print(edithMod.Enums)
	-- print(edithMod.Enums.Utils.Room)
	-- print(edithMod.Enums.Utils.Level)
	
	edithMod.Enums.Utils.Room = game:GetRoom()
	edithMod.Enums.Utils.Level = game:GetLevel()
end
edithMod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, edithMod.SetObjects)

-- print()
-- local game = edithMod.Enums.Utils.Game

	-- edithMod.Enums.Utils.Room = game:GetRoom()
	-- edithMod.Enums.Utils.Level = game:GetLevel()

-- local function setRNG()
	

	-- local rng = edithMod.Enums.Utils.RNG
	-- local RECOMMENDED_SHIFT_IDX = 35
	
	-- local seeds = game:GetSeeds()
	-- local startSeed = seeds:GetStartSeed()
	
	-- rng:SetSeed(startSeed, RECOMMENDED_SHIFT_IDX)	
-- end

function edithMod:GameStartedFunction()
	-- print(edithMod.Enums.Utils.Room)
	
end
edithMod:AddCallback(ModCallbacks.MC_POST_UPDATE, edithMod.GameStartedFunction)


-- edithMod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(self)
	-- local game = edithMod.Enums.Utils.Game

	-- edithMod.Enums.Utils.Room = game:GetRoom()
	-- edithMod.Enums.Utils.Level = game:GetLevel()
	
	-- setRNG()
	
	-- print(edithMod.Enums.Utils.Level, edithMod.Enums.Utils.Room)
-- end)

