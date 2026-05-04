local mod = EdithRebuilt
local enums = mod.Enums
local card = enums.Card
local sounds = enums.SoundEffect
local utils = enums.Utils
local sfx = utils.SFX
local rng = utils.RNG
local jumpFlags = enums.Tables.JumpFlags
local modules = mod.Modules
local Helpers = modules.HELPERS
local Creep = modules.CREEPS
local Land = modules.LAND
local ModRNG = modules.RNG
local data = mod.DataHolder.GetEntityData
local damageBase = 13.5

local function InitEdithJump(player)
	local soundeffect = player.CanFly and SoundEffect.SOUND_ANGEL_WING or SoundEffect.SOUND_SHELLGAME
	local DustCloud = Isaac.Spawn(
		EntityType.ENTITY_EFFECT,
		EffectVariant.POOF01,
		1,
		player.Position,
		Vector.Zero,
		player
	)

    sfx:Play(soundeffect)

	DustCloud.DepthOffset = -100

	local config = {
		Height = 15,
		Speed = 1.5,
		Tags = "SoulOfEdithJump",
		Flags = jumpFlags.EdithJump,
	}

	JumpLib:Jump(player, config)
end

mod:AddCallback(ModCallbacks.MC_PRE_USE_CARD, function (_, _, player)
	InitEdithJump(player)
    sfx:Play(sounds.SOUND_SOUL_OF_EDITH)
end, card.CARD_SOUL_EDITH)

local SoundPick = {
	[1] = SoundEffect.SOUND_STONE_IMPACT, ---@type SoundEffect
	[2] = sounds.SOUND_EDITH_STOMP,
	[3] = sounds.SOUND_FART_REVERB,
	[4] = sounds.SOUND_VINE_BOOM,
}

local function SpawnSaltTears(player)
	for _ = 1, rng:RandomInt(18, 36) do 
        local tear = Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.ROCK, 0, Isaac.GetRandomPosition(), Vector.Zero, player):ToTear()
		if not tear then return end
		tear.CollisionDamage = tear.CollisionDamage * 1.2
        tear.Height = -600 * ModRNG.RandomFloat(rng, 0.9, 1.1)
		tear.FallingSpeed = 4 * ModRNG.RandomFloat(rng, 0.6, 1.8)
        tear.FallingAcceleration = 2.5 * ModRNG.RandomFloat(rng, 0.6, 1.8)
		tear:AddTearFlags(TearFlags.TEAR_SPECTRAL | TearFlags.TEAR_PIERCING)
		Helpers.ForceSaltTear(tear, false)
		data(tear).IsSoulOfEdithTear = true
    end
end

---@param player EntityPlayer
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, function (_, player)
	local rawFormula = ((damageBase + player.Damage) / 1.5)
    local playerData = data(player)

	for _, ent in pairs(Isaac.FindInCapsule(Capsule(player.Position, Vector.One, 0, 50), EntityPartition.ENEMY)) do
		ent:TakeDamage(rawFormula, 0, EntityRef(player), 0)
		Helpers.TriggerPush(ent, player, 20)
	end

    playerData.IsSoulOfEdithJump = true
	Land.LandFeedbackManager(player, SoundPick, Color(1, 1, 1, 0))
    playerData.IsSoulOfEdithJump = false

    SpawnSaltTears(player)
end, { tag = "SoulOfEdithJump" })

mod:AddCallback(ModCallbacks.MC_POST_TEAR_DEATH, function(_, tear)
	if not data(tear).IsSoulOfEdithTear then return end

	Creep.SpawnSaltCreep(tear, tear.Position, 3, 5, 5, 3, enums.SaltTypes.SALT_SHAKER, false, false)
end)