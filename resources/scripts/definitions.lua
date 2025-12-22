local EdithPlayer = Isaac.GetPlayerTypeByName("Edith​​​", false)
local EdithBPlayer = Isaac.GetPlayerTypeByName("Edith​​​", true)
local edithJumpTag = "edithRebuilt_EdithJump"
local tedithJumpTag = "edithRebuilt_TaintedEdithJump"
local tedithHopTag = "edithRebuilt_TaintedEdithHop"
local edithHoodJumpTag = "edithRebuilt_EdithsHoodJump"

EdithRebuilt.Enums = {
	PlayerType = {
		PLAYER_EDITH = EdithPlayer,
		PLAYER_EDITH_B = EdithBPlayer,
	},
	CollectibleType = {
		-- Edith Items
		COLLECTIBLE_SALTSHAKER = Isaac.GetItemIdByName("Salt Shaker"),
		COLLECTIBLE_PEPPERGRINDER = Isaac.GetItemIdByName("Pepper Grinder"),
		COLLECTIBLE_EDITHS_HOOD = Isaac.GetItemIdByName("Edith's Hood"),
		COLLECTIBLE_SULFURIC_FIRE = Isaac.GetItemIdByName("Sulfuric Fire"),
		COLLECTIBLE_SAL = Isaac.GetItemIdByName("Sal"),
		COLLECTIBLE_MOLTEN_CORE = Isaac.GetItemIdByName("Molten Core"),
		COLLECTIBLE_GILDED_STONE = Isaac.GetItemIdByName("Gilded Stone"),
		COLLECTIBLE_FATE_OF_THE_UNFAITHFUL = Isaac.GetItemIdByName("Fate of the unfaithful"),
		COLLECTIBLE_SALT_HEART = Isaac.GetItemIdByName("Salt Heart"),
		COLLECTIBLE_DIVINE_RETRIBUTION = Isaac.GetItemIdByName("Divine Retribution"),
		COLLECTIBLE_HYDRARGYRUM = Isaac.GetItemIdByName("Hydrargyrum"),
		COLLECTIBLE_SPICES_MIX = Isaac.GetItemIdByName("Spices Mix"),

		--- Tainted Edith Items
		COLLECTIBLE_BURNT_HOOD = Isaac.GetItemIdByName("Burnt Hood"),
		COLLECTIBLE_DIVINE_WRATH = Isaac.GetItemIdByName("Divine Wrath"),

		COLLECTIBLE_EFFIGY = Isaac.GetItemIdByName("Effigy"),
		COLLECTIBLE_CHUNK_OF_BASALT = Isaac.GetItemIdByName("Chunk of Basalt"),
	},
	TrinketType = {
		TRINKET_GEODE = Isaac.GetTrinketIdByName("Geode"),
		TRINKET_RUMBLING_PEBBLE = Isaac.GetTrinketIdByName("Rumbling Pebble"),
		
		TRINKET_PAPRIKA = Isaac.GetTrinketIdByName("Paprika"),
		TRINKET_BURNT_SALT = Isaac.GetTrinketIdByName("Burnt Salt"),
	},
	Card = {
		CARD_JACK_OF_CLUBS = Isaac.GetCardIdByName("Jack_of_Clubs"),
		CARD_SALT_ROCKS = Isaac.GetCardIdByName("SaltRocks"),
		CARD_SOUL_EDITH = Isaac.GetCardIdByName("SoulOfEdith"),
	},
	NullItemID = {
		ID_EDITH_SCARF = Isaac.GetCostumeIdByPath("gfx/characters/EdithHood.anm2"),
		ID_EDITH_B_SCARF = Isaac.GetCostumeIdByPath("gfx/characters/EdithTaintedHood.anm2"),
		ID_EDITH_VESTIGE_SCARF = Isaac.GetCostumeIdByPath("gfx/characters/EdithVestigeHood.anm2"),
		ID_EDITH_B_GRUDGE_SCARF = Isaac.GetCostumeIdByPath("gfx/characters/EdithTaintedGrudgeHood.anm2"),
	},
	EffectVariant = {
		EFFECT_EDITH_TARGET = Isaac.GetEntityVariantByName("Edith Target"),
		EFFECT_EDITH_B_TARGET = Isaac.GetEntityVariantByName("Edith Tainted Arrow"),
	},
	Challenge = {
		CHALLENGE_VESTIGE = Isaac.GetChallengeIdByName("[Edith: Rebuilt] Vestige"),
		CHALLENGE_GRUDGE = Isaac.GetChallengeIdByName("[Edith: Rebuilt] Grudge")
	},
	Callbacks = {
		-- Called everytime a Perfect Parry is triggered (player: EntityPlayer, entity: Entity)
		---* player `EntityPlayer`
		---* entity `Entity`
		---* params `TEdithHopParryParams`
		PERFECT_PARRY = "EdithRebuilt_PERFECT_PARRY",

		-- Called everytime an enemy is killed by a Perfect Parry is triggered
		---* player `EntityPlayer`
		---* entity `Entity`
		PERFECT_PARRY_KILL = "EdithRebuilt_PERFECT_PARRY_KILL",

		-- Called everytime Edith does an offensive stomp
		---* player `EntityPlayer`
		---* params `EdithJumpStompParams`
		OFFENSIVE_STOMP = "EdithRebuilt_OFFENSIVE_STOMP",

		-- Called everytime Edith does an offensive stomp and damages at least `One` Enemy
		---* player `EntityPlayer`
		---* entity `Entity`
		---* params `EdithJumpStompParams`
		OFFENSIVE_STOMP_HIT = "EdithRebuilt_OFFENSIVE_STOMP_HIT",

		-- Called everytime Edith does an offensive stomp and kills at least `One` Enemy
		---* player `EntityPlayer`
		---* entity `Entity`
		---* params `EdithJumpStompParams`
		OFFENSIVE_STOMP_KILL = "EdithRebuilt_OFFENSIVE_STOMP_KILL",

		-- Called everytime Edith's Target (or Tainted Edith's arrow) changes its design		
		TARGET_SPRITE_CHANGE = "EdithRebuilt_TARGET_SPRITE_CHANGE",

		-- Called everytime Tainted Edith's trail sprite is changed	
		TRAIL_SPRITE_CHANGE = "EdithRebuilt_TRAIL_SPRITE_CHANGE",
	},
	SubTypes = {
		SALT_CREEP = Isaac.GetEntitySubTypeByName("Salt Creep"),
		PEPPER_CREEP = Isaac.GetEntitySubTypeByName("Pepper Creep"),
		CINDER_CREEP = Isaac.GetEntitySubTypeByName("Cinder Creep"),
		OREGANO_CREEP = Isaac.GetEntitySubTypeByName("Oregano Creep"),
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
		SOUND_MACHINE = Isaac.GetSoundIdByName("Machine"),
		SOUND_MECHANIC = Isaac.GetSoundIdByName("Mechanic"),
		SOUND_KNIGHT = Isaac.GetSoundIdByName("Knight"),
		SOUND_JACK_OF_CLUBS = Isaac.GetSoundIdByName("JackOfClubs"),
		SOUND_SOUL_OF_EDITH = Isaac.GetSoundIdByName("SoulOfEdith"),
		SOUND_BLOQUEO = Isaac.GetSoundIdByName("BLOQUEO"),
		SOUND_NAUTRASH = Isaac.GetSoundIdByName("Nautrash"),
	},
	Achievements = {
		-- Edith unlocks
		ACHIEVEMENT_EDITH = Isaac.GetAchievementIdByName("EdithRebuilt_Edith"),
		ACHIEVEMENT_SALT_SHAKER = Isaac.GetAchievementIdByName("EdithRebuilt_Salt Shaker"),
		ACHIEVEMENT_PEPPER_GRINDER = Isaac.GetAchievementIdByName("EdithRebuilt_Pepper Grinder"),
		ACHIEVEMENT_SAL = Isaac.GetAchievementIdByName("EdithRebuilt_Sal"),
		ACHIEVEMENT_SALT_HEART = Isaac.GetAchievementIdByName("EdithRebuilt_Salt Heart"),
		ACHIEVEMENT_FAITH_OF_THE_UNFAITHFUL = Isaac.GetAchievementIdByName("EdithRebuilt_Faith Of The Unfaithful"),
		ACHIEVEMENT_MOLTEN_CORE = Isaac.GetAchievementIdByName("EdithRebuilt_Molten Core"),
		ACHIEVEMENT_GILDED_STONE = Isaac.GetAchievementIdByName("EdithRebuilt_Gilded Stone"),
		ACHIEVEMENT_GEODE = Isaac.GetAchievementIdByName("EdithRebuilt_Geode"),
		ACHIEVEMENT_SULFURIC_FIRE = Isaac.GetAchievementIdByName("EdithRebuilt_Sulfuric Fire"),
		ACHIEVEMENT_RUMBLING_PEBBLE = Isaac.GetAchievementIdByName("EdithRebuilt_Rumbling Pebble"),
		ACHIEVEMENT_DIVINE_RETRIBUTION = Isaac.GetAchievementIdByName("EdithRebuilt_Divine Retribution"),
		ACHIEVEMENT_SPICES_MIX = Isaac.GetAchievementIdByName("EdithRebuilt_SpicesMix"),
		ACHIEVEMENT_EDITHS_HOOD = Isaac.GetAchievementIdByName("EdithRebuilt_Ediths Hood"),
		ACHIEVEMENT_HYDRARGYRUM = Isaac.GetAchievementIdByName("EdithRebuilt_Hydrargyrum"),
		ACHIEVEMENT_TAINTED_EDITH = Isaac.GetAchievementIdByName("EdithRebuilt_The Punished"),
		-- Edith unlocks end
		
		-- Tainted Edith unlocks
		ACHIEVEMENT_SALT_ROCKS = Isaac.GetAchievementIdByName("EdithRebuilt_Salt Rocks"),
		ACHIEVEMENT_BURNT_SALT = Isaac.GetAchievementIdByName("EdithRebuilt_Burnt Salt"),
		ACHIEVEMENT_JACK_OF_CLUBS = Isaac.GetAchievementIdByName("EdithRebuilt_Jack of Clubs"),
		ACHIEVEMENT_PAPRIKA = Isaac.GetAchievementIdByName("EdithRebuilt_Paprika"),
		ACHIEVEMENT_BURNT_HOOD = Isaac.GetAchievementIdByName("EdithRebuilt_Burnt Hood"),
		ACHIEVEMENT_SOUL_OF_EDITH = Isaac.GetAchievementIdByName("EdithRebuilt_Soul of Edith"),
		ACHIEVEMENT_DIVINE_WRATH = Isaac.GetAchievementIdByName("EdithRebuilt_Divine Wrath"),
		-- Tainted Edith unlocks end

		ACHIEVEMENT_VESTIGE = Isaac.GetAchievementIdByName("EdithRebuilt_Vestige"),
		ACHIEVEMENT_EFFIGY = Isaac.GetAchievementIdByName("EdithRebuilt_Effigy"),
		ACHIEVEMENT_GRUDGE = Isaac.GetAchievementIdByName("EdithRebuilt_Grudge"),
		ACHIEVEMENT_CHUNK_OF_BASALT = Isaac.GetAchievementIdByName("EdithRebuilt_Chunk of Basalt"),


		ACHIEVEMENT_THANK_YOU = Isaac.GetAchievementIdByName("EdithRebuilt_Thank You"),
	},
	Utils = {
		Game = Game(),
		SFX = SFXManager(),
		RNG = RNG(),
		Level = Game():GetLevel(),
	},
	---@enum SaltTypes
	SaltTypes = {
		SALT_SHAKER = "SaltShaker",
		SALT_SHAKER_JUDAS = "SaltShakerJudas",
		SAL = "Sal",
		SALT_HEART = "SaltHeart",
		EDITHS_HOOD = "EdithsHood",
	},
	---@enum ConfigDataTypes
	ConfigDataTypes = {
		EDITH = "EdithData",
		TEDITH = "TEdithData",
		MISC = "MiscData",
	},
	---@enum EdithStatusEffects
	EdithStatusEffects = {
		SALTED = "Salted",
		CINDER = "Cinder",
		GARLIC = "Garlic",
		OREGANO = "Oregano",
		CUMIN = "Cumin",
		TURMERIC = "Turmeric",
		CINNAMON = "Cinnamon",
		GINGER = "Ginger",
		PEPPERED = "Peppered",
		HYDRARGYRUM_CURSE = "HydrargyrumCurse"
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
		ArrowSuffix = {
			[1] = "_arrow",
			[2] = "_grudge",
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
			[10] = "_Chile",
		},
		TargetLineColorValues = {
			[2] = {R = 245/255, G = 169/255, B = 184/255},
			[3] = {R = 1, G = 0, B = 1},
			[4] = {R = 1, G = 154/255, B = 86/255},
			[5] = {R = 155/255, G = 79/255, B = 150/255},
			[6] = {R = 123/255, G = 173/255, B = 226/255},
			[7] = {R = 128/255, G = 0, B = 128/255},
			[8] = {R = 154/255, G = 89/255, B = 207/255},
			[9] = {R = 0, G = 36/255, B = 125/255},
			[10] = {R = 213/255, G = 43/255, B = 30/255}
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
			[TearVariant.NAIL_BLOOD] = true,
		},
		BackdropColors = {
			[BackdropType.CORPSE3] = Color(0.75, 0.2, 0.2),
			[BackdropType.DROSS] = Color(92/255, 81/255, 71/255),
			[BackdropType.BLUE_WOMB] = Color(0, 0, 0, 1, 0.3, 0.4, 0.6),
			[BackdropType.CORPSE] = Color(0, 0, 0, 1, 0.62, 0.65, 0.62),
			[BackdropType.CORPSE2] = Color(0, 0, 0, 1, 0.55, 0.57, 0.55),
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
			EdithJump = edithJumpTag,
			TEdithHop = tedithHopTag,
			TEdithJump = tedithJumpTag,
			EdithsHoodJump = edithHoodJumpTag,
		},
		JumpFlags = {
			EdithJump = (JumpLib.Flags.DISABLE_SHOOTING_INPUT | JumpLib.Flags.DISABLE_LASER_FOLLOW | JumpLib.Flags.DISABLE_BOMB_INPUT | JumpLib.Flags.FAMILIAR_FOLLOW_FOLLOWERS | JumpLib.Flags.FAMILIAR_FOLLOW_ORBITALS | JumpLib.Flags.FAMILIAR_FOLLOW_TEARCOPYING | JumpLib.Flags.NO_HURT_PITFALL),
			TEdithHop = (JumpLib.Flags.COLLISION_GRID | JumpLib.Flags.COLLISION_ENTITY | JumpLib.Flags.OVERWRITABLE | JumpLib.Flags.DISABLE_COOL_BOMBS | JumpLib.Flags.IGNORE_CONFIG_OVERRIDE | JumpLib.Flags.FAMILIAR_FOLLOW_ORBITALS | JumpLib.Flags.DAMAGE_CUSTOM),
			TEdithJump = (JumpLib.Flags.COLLISION_GRID | JumpLib.Flags.OVERWRITABLE | JumpLib.Flags.DISABLE_COOL_BOMBS | JumpLib.Flags.IGNORE_CONFIG_OVERRIDE | JumpLib.Flags.FAMILIAR_FOLLOW_ORBITALS),
		},
		MovementBasedActives = {
			[CollectibleType.COLLECTIBLE_SUPLEX] = true,
			[CollectibleType.COLLECTIBLE_PONY] = true,
			[CollectibleType.COLLECTIBLE_WHITE_PONY] = true,
		},
		JumpParams = {
			EdithJump = {
				tag = edithJumpTag,
				type = EntityType.ENTITY_PLAYER,
				player = EdithPlayer,
			},
			TEdithJump = {
				tag = tedithJumpTag,
				type = EntityType.ENTITY_PLAYER,
				player = EdithBPlayer,
			},
			TEdithHop = {
				tag = tedithHopTag,
				type = EntityType.ENTITY_PLAYER,
				player = EdithBPlayer,
			},
			EdithsHoodJump = {
				tag = edithHoodJumpTag,
				type = EntityType.ENTITY_PLAYER,
			}
		},
		GridEntTypes = {
			[GridEntityType.GRID_TRAPDOOR] = true,
			[GridEntityType.GRID_STAIRS] = true,
			[GridEntityType.GRID_GRAVITY] = true,
		},
		Chap4Backdrops = {
			[BackdropType.WOMB] = true,
			[BackdropType.UTERO] = true,
			[BackdropType.SCARRED_WOMB] = true,
			[BackdropType.BLUE_WOMB] = true,
			[BackdropType.CORPSE] = true,
			[BackdropType.CORPSE2] = true,
			[BackdropType.CORPSE3] = true,
			[BackdropType.MORTIS] = true, --- Who knows
		},
		ImGuiTables = {
			TargetDesign = {
				"Choose Color", 
				"Trans", 
				"Rainbow",
				"Lesbian",
				"Bisexual", 
				"Gay", 
				"Ace",
				"Enby",
				"Venezuela",
				"Chile",
			},
			StompSound = {
				"Stone", 
				"Antibirth", 
				"Fart Reverb",
				"Vine Boom"
			}, 	
			ArrowDesign = {
				"Arrow", 
				"Grudge", 
			},
			TrailDesign = {
				"Choose color",
				"Trans",
				"Rainbow",
				"Lesbian",
				"Bisexual",
				"Gay",
				"Ace",
				"Enby",
				"Pansexual",
				"Straight",
				"Commander Video",
				"Italy",
			},
			HopSound = {
				"Stone", 
				"Yippee", 
				"Spring",
			}, 
			ParrySound = {
				"Stone", 
				"Taunt", 
				"Vine Boom",
				"Fart Reverb",
				"Solarian",
				"Machine",
				"Mechanic",
				"Knight",
				"Bloqueo",
				"Nautrash",
			}, 
		},
		BlacklistedPickupVariants = { -- Pickups blacklisted from use on `Entity:ForceCollide()`
			[PickupVariant.PICKUP_PILL] = true,
			[PickupVariant.PICKUP_TAROTCARD] = true,
			[PickupVariant.PICKUP_TRINKET] = true,
			[PickupVariant.PICKUP_COLLECTIBLE] = true,
			[PickupVariant.PICKUP_BROKEN_SHOVEL] = true,
		},
		PhysicsFamiliar = {
			[FamiliarVariant.SAMSONS_CHAINS] = true,
			[FamiliarVariant.PUNCHING_BAG] = true,
			[FamiliarVariant.CUBE_BABY] = true,
		},
		CooldownSounds = {
			[1] = {
				SoundID = SoundEffect.SOUND_STONE_IMPACT,
				Pitch = 1.2,
			},
			[2] = {
				SoundID = SoundEffect.SOUND_BEEP,
				Pitch = 0.8
			} 
		},
		RemoveTargetItems = {
			[CollectibleType.COLLECTIBLE_ESAU_JR] = true,
			[CollectibleType.COLLECTIBLE_CLICKER] = true,
		},
		DisableLandFeedbackGrids = {
			[GridEntityType.GRID_TRAPDOOR] = true,
			[GridEntityType.GRID_STAIRS] = true,
			[GridEntityType.GRID_GRAVITY] = true,
		},
		TEdithTrailParams = {
			[1] = { Suffix = "", Size = 2 },
			[2] = { Suffix = "_trans", Size = 2 },
			[3] = { Suffix = "_rainbow", Size = 2 },
			[4] = { Suffix = "_lesbian", Size = 2 },
			[5] = { Suffix = "_bi", Size = 1 },
			[6] = { Suffix = "_gay", Size = 1 },
			[7] = { Suffix = "_ace", Size = 1 },
			[8] = { Suffix = "_enby", Size = 1 },
			[9] = { Suffix = "_pan", Size = 1 },
			[10] = { Suffix = "_straight", Size = 1 },
			[11] = { Suffix = "_CommanderVideo", Size = 1 },
			[12] = { Suffix = "_italy", Size = 1 },
		}
	},
	Misc = {
		TearPath = "gfx/tears/",
		HeadAdjustVec = Vector.Zero,
		TargetPath = "gfx/effects/EdithTarget/effect_000_edith_target",
		ArrowPath = "gfx/effects/TaintedEdithArrow/effect_000_tainted_edith",
		TrailPath = "gfx/effects/TaintedEdithTrail/trail",
		VestigeSpritePath = "gfx/characters/costumes/characterEdithVestige.png",
		GrudgeSpritePath = "gfx/characters/costumes/characterTaintedEdithGrudge.png",
		TargetLineColor = Color(1, 1, 1),
		SaltShakerDist = Vector(0, 60),
		ColorDefault = Color(1, 1, 1, 1),
		JumpReadyColor = Color(1, 1, 1, 1, 0.5, 0.5, 0.5),
		PerfectParryRadius = 12,
		ImpreciseParryRadius = 35,
		BurntSaltColor = Color(0.3, 0.3, 0.3),
		ChargeBarleftVector = Vector(-8, 10),
		ChargeBarcenterVector = Vector(0, 10),
		ChargeBarrightVector = Vector(8, 10),
		PaprikaColor = Color(0.8, 0.2, 0),
		ParryPartitions = EntityPartition.ENEMY | EntityPartition.BULLET | EntityPartition.TEAR, --[[@as EntityPartition|integer]]
		NewProjectilFlags = ProjectileFlags.HIT_ENEMIES | ProjectileFlags.CANT_HIT_PLAYER,
	},
}