edithMod.Enums = {
	PlayerType = {},
	CollectibleType = {},
	TrinketType = {},
	NullItemID = {},
	EffectVariant = {},
	SubTypes = {},
	SoundEffect = {},
	Challenge = {},
	Utils = {},
}

-- playertypes --
	edithMod.Enums.PlayerType.PLAYER_EDITH = Isaac.GetPlayerTypeByName("Edith", false)
	edithMod.Enums.PlayerType.PLAYER_EDITH_B = Isaac.GetPlayerTypeByName("Edith", true)


-- collectibletypes -- 
	edithMod.Enums.CollectibleType.COLLECTIBLE_SALTSHAKER = Isaac.GetItemIdByName("Salt Shaker")
	edithMod.Enums.CollectibleType.COLLECTIBLE_PEPPERGRINDER = Isaac.GetItemIdByName("Pepper Grinder")
	edithMod.Enums.CollectibleType.COLLECTIBLE_EDITHS_HOOD = Isaac.GetItemIdByName("Edith's Hood")
	edithMod.Enums.CollectibleType.COLLECTIBLE_SULFURIC_FIRE = Isaac.GetItemIdByName("Sulfuric Fire")
	edithMod.Enums.CollectibleType.COLLECTIBLE_SAL = Isaac.GetItemIdByName("Sal")

-- trinkettypes 
	edithMod.Enums.TrinketType.TRINKET_GEODE = Isaac.GetTrinketIdByName("Geode")
	edithMod.Enums.TrinketType.TRINKET_RUMBLING_PEBBLE = Isaac.GetTrinketIdByName("Rumbling Pebble")

-- null items --
	edithMod.Enums.NullItemID.ID_EDITH_SCARF = Isaac.GetCostumeIdByPath("gfx/characters/character_004xa_edith_scarf.anm2")
	edithMod.Enums.NullItemID.ID_EDITH_CLOAK = Isaac.GetCostumeIdByPath("gfx/characters/character_004xa_edith_cloak.anm2")
	edithMod.Enums.NullItemID.ID_EDITH_B_SCARF = Isaac.GetCostumeIdByPath("gfx/characters/character_004xb_edith_scarf.anm2")
	

-- effect variants --
	edithMod.Enums.EffectVariant.EFFECT_EDITH_TARGET = Isaac.GetEntityVariantByName("Edith Target")
	edithMod.Enums.EffectVariant.EFFECT_EDITH_B_TARGET = Isaac.GetEntityVariantByName("Edith Tainted Arrow")


	edithMod.Enums.SubTypes.SALT_CREEP = Isaac.GetEntitySubTypeByName("Salt Creep")
	edithMod.Enums.SubTypes.PEPPER_CREEP = Isaac.GetEntitySubTypeByName("Pepper Creep")


-- sound effects --

	edithMod.Enums.SoundEffect.SOUND_EDITH_STOMP = Isaac.GetSoundIdByName("Edith Stomp")
	edithMod.Enums.SoundEffect.SOUND_EDITH_STOMP_WATER = Isaac.GetSoundIdByName("Edith Stomp Water")
	edithMod.Enums.SoundEffect.SOUND_WATERSPLASH = Isaac.GetSoundIdByName("Water Splash")
	edithMod.Enums.SoundEffect.SOUND_PIZZA_TAUNT = Isaac.GetSoundIdByName("Taunt")
	edithMod.Enums.SoundEffect.SOUND_FART_REVERB = Isaac.GetSoundIdByName("Fart Reverb")
	edithMod.Enums.SoundEffect.SOUND_VINE_BOOM = Isaac.GetSoundIdByName("Vine Boom")
	edithMod.Enums.SoundEffect.SOUND_SALT_SHAKER = Isaac.GetSoundIdByName("Salt Shaker")
	edithMod.Enums.SoundEffect.SOUND_PEPPER_GRINDER = Isaac.GetSoundIdByName("Pepper Grinder")
	edithMod.Enums.SoundEffect.SOUND_YIPPEE = Isaac.GetSoundIdByName("Yippee")
	
-- Utils -- 

	edithMod.Enums.Utils.Game = Game()
	edithMod.Enums.Utils.SFX = SFXManager()
