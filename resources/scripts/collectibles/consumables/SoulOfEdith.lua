local mod = EdithRebuilt
local enums = mod.Enums 
local card = enums.Card
local sounds = enums.SoundEffect
local utils = enums.Utils
local sfx = utils.SFX
local rng = utils.RNG
local jumpFlags = enums.Tables.JumpFlags
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
    -- if JumpLib:GetData(player).Jumping then return false end
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

local data = mod.CustomDataWrapper.getData
local damageBase = 13.5
---@param player EntityPlayer
function SoulOfEdith:ParryJump(player)
	local DamageStat = player.Damage 
	local rawFormula = ((damageBase + DamageStat) / 1.5) 
	local playerPos = player.Position
    local playerData = data(player)
	local capsule = Capsule(player.Position, Vector.One, 0, 50)
	local ImpreciseParryEnts = Isaac.FindInCapsule(capsule, EntityPartition.ENEMY)

	for _, ent in pairs(ImpreciseParryEnts) do
		local entPos = ent.Position
		local newVelocity = ((playerPos - entPos) * -1):Resized(20)

		ent:TakeDamage(rawFormula, 0, EntityRef(player), 0)
		ent:AddKnockback(EntityRef(player), newVelocity, 5, true)
	end
    
    playerData.IsSoulOfEdithJump = true
	mod.LandFeedbackManager(player, SoundPick, Color(1, 1, 1, 0))
    playerData.IsSoulOfEdithJump = false

    local fallingTearsCount = rng:RandomInt(25, 40)

    for _ = 1, fallingTearsCount do 
        local tear = Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.ROCK, 0, Isaac.GetRandomPosition(), Vector.Zero, player):ToTear()
		if not tear then return end

		tear.CollisionDamage = tear.CollisionDamage * 1.2
        tear.Height = -600 * (rng:RandomInt(90, 110) / 100)
        tear.FallingSpeed = 4 * rng:RandomInt(600, 1800) / 1000
        tear.FallingAcceleration = 2.5 * rng:RandomInt(600, 1800) / 1000
		tear:AddTearFlags(TearFlags.TEAR_SPECTRAL)
    end
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, SoulOfEdith.ParryJump, {
    tag = "SoulOfEdithJump"
})