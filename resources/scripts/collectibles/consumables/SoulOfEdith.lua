local mod = EdithRebuilt
local enums = mod.Enums 
local card = enums.Card
local sounds = enums.SoundEffect
local utils = enums.Utils
local sfx = utils.SFX
local rng = utils.RNG
local jumpFlags = enums.Tables.JumpFlags
local data = mod.CustomDataWrapper.getData
local damageBase = 13.5
local SoulOfEdith = {}

function SoulOfEdith.InitEdithJump(player)
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

function SoulOfEdith:OnUse(_, player)
    SoulOfEdith.InitEdithJump(player)

    sfx:Play(sounds.SOUND_SOUL_OF_EDITH)
end
mod:AddCallback(ModCallbacks.MC_PRE_USE_CARD, SoulOfEdith.OnUse, card.CARD_SOUL_EDITH)

local SoundPick = {
	[1] = SoundEffect.SOUND_STONE_IMPACT, ---@type SoundEffect
	[2] = sounds.SOUND_EDITH_STOMP,
	[3] = sounds.SOUND_FART_REVERB,
	[4] = sounds.SOUND_VINE_BOOM,
}

---@param player EntityPlayer
function SoulOfEdith:ParryJump(player)
	local rawFormula = ((damageBase + player.Damage) / 1.5) 
    local playerData = data(player)

	for _, ent in pairs(Isaac.FindInCapsule(Capsule(player.Position, Vector.One, 0, 50), EntityPartition.ENEMY)) do
		ent:TakeDamage(rawFormula, 0, EntityRef(player), 0)
		mod.TriggerPush(ent, player, 20, 3, true)
	end
    
    playerData.IsSoulOfEdithJump = true
	mod.LandFeedbackManager(player, SoundPick, Color(1, 1, 1, 0))
    playerData.IsSoulOfEdithJump = false

	local tear 
    for _ = 1, rng:RandomInt(25, 40) do 
        tear = Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.ROCK, 0, Isaac.GetRandomPosition(), Vector.Zero, player):ToTear()
		if not tear then return end
		tear.CollisionDamage = tear.CollisionDamage * 1.2
        tear.Height = -600 * mod.RandomFloat(rng, 0.9, 1.1)
		tear.FallingSpeed = 4 * mod.RandomFloat(rng, 0.6, 1.8)
        tear.FallingAcceleration = 2.5 * mod.RandomFloat(rng, 0.6, 1.8)
		tear:AddTearFlags(TearFlags.TEAR_SPECTRAL)
		mod.ForceSaltTear(tear, false)
		data(tear).IsSoulOfEdithTear = true
    end
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, SoulOfEdith.ParryJump, { tag = "SoulOfEdithJump" })

---@param tear EntityTear
function mod:OnTearDeath(tear)
	-- if not data(tear).IsSoulOfEdithTear then return end

	-- mod:SpawnSaltCreep(tear, tear.Position, 2, 3, 5, 5, "SoulOfEdith")
end
mod:AddCallback(ModCallbacks.MC_POST_TEAR_DEATH, mod.OnTearDeath)