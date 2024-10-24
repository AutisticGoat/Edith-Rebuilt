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
	},
	TrinketType = {
		TRINKET_GEODE = Isaac.GetTrinketIdByName("Geode"),
		TRINKET_RUMBLING_PEBBLE = Isaac.GetTrinketIdByName("Rumbling Pebble"),
	},
	NullItemID = {
		ID_EDITH_SCARF = Isaac.GetCostumeIdByPath("gfx/characters/character_004xa_edith_scarf.anm2"),
		ID_EDITH_B_SCARF = Isaac.GetCostumeIdByPath("gfx/characters/character_004xb_edith_scarf.anm2"),
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
	},
	Utils = {
		Game = Game(),
		SFX = SFXManager(),
		RNG = RNG(),
	},
}
edithMod.Enums.Utils.Room = edithMod.Enums.Utils.Game:GetRoom()
edithMod.Enums.Utils.Level = edithMod.Enums.Utils.Game:GetLevel()