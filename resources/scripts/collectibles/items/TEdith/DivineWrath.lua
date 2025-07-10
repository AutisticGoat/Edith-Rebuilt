local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local DivineWrath = {}

local baseRange = 6.5
local baseHeight = -23.45

---comment
---@param player EntityPlayer
---@param rng RNG
---@param minTears integer
---@param maxTears integer
local function ShootFireRockTear(player, rng, minTears, maxTears)
    local baseMultiplier = -70 / baseRange
    local halfBaseHeight = baseHeight * 3
	local tear
	local fallSpeedVar

    for _ = 1, rng:RandomInt(minTears, maxTears) do
        tear = Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.ROCK, 0, player.Position, RandomVector():Resized(20), player):ToTear()

        if not tear then return end

        fallSpeedVar = mod.RandomFloat(rng, 1.8, 2.2)

		tear.Visible = false
		tear.Height = halfBaseHeight
        tear.Velocity = tear.Velocity * mod.RandomFloat(rng, 0.2, 0.6)
        tear.FallingAcceleration = (mod.RandomFloat(rng, 0.7, 1.6)) * 3
        tear.FallingSpeed = (baseMultiplier * (fallSpeedVar)) 
        tear.CollisionDamage = tear.CollisionDamage * rng:RandomInt(8, 12) / 10
		tear.Scale = tear.CollisionDamage/3.5
        tear:AddTearFlags(TearFlags.TEAR_BURN)
        mod:ChangeColor(tear, 1, 0.2, 0)

		tear.Visible = true
    end
end

---@param rng RNG
---@param player EntityPlayer
function DivineWrath:OnUse(_, rng, player)
    ShootFireRockTear(player, rng, 8, 12)
    local shockwaveParams = {
		Duration = 6,
		Size = 1,
		Damage = player.Damage / 2,
		DamageCooldown = 120,
		SelfDamage = false,
		DamagePlayers = true,
		DestroyGrid = true,
		GoOverPits = false,
		Color = Color.Default,
		SpriteSheet = mod.ShockwaveSprite(),
		SoundMode = TSIL.Enums.ShockwaveSoundMode.ON_CREATE
	}

	TSIL.ShockWaves.CreateShockwaveRing(
		player, -- Quien creó el shockwave
		player.Position, -- Donde se creó
		30, -- El radio
		shockwaveParams, -- Parámetros extra, definidos arriba
		Vector.One, -- Dirección
		360, -- Qué tan abierto o cerrado estará el círculo
		15, -- Espacio entre cada piedra
		2, -- Número de anillos
	    1, -- Espacio entre cada anillo
		1 -- Cuánto dura cada anillo
	)

	return true
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, DivineWrath.OnUse, items.COLLECTIBLE_DIVINE_WRATH)