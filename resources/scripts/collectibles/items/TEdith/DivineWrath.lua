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
local function ShootSaltyBabyTear(player, rng, minTears, maxTears)
    local baseMultiplier = -70 / baseRange
    local halfBaseHeight = baseHeight * 1.2
    local tearCount = rng:RandomInt(minTears, maxTears)

    for _ = 1, tearCount do
        local tear = Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.ROCK, 0, player.Position, RandomVector():Resized(10), player):ToTear()

        if not tear then return end

        tear.Velocity = tear.Velocity * rng:RandomInt(2, 6) / 10
        tear.FallingAcceleration = (rng:RandomInt(70, 160) / 100) * 1.2
        local fallSpeedVar = rng:RandomInt(180, 220) / 100
        tear.FallingSpeed = (baseMultiplier * (fallSpeedVar)) 
        tear.Height = halfBaseHeight
        tear.Scale = 1
        tear.CollisionDamage = tear.CollisionDamage * rng:RandomInt(8, 12) / 10
        tear:AddTearFlags(TearFlags.TEAR_BURN)
        tear.Color = Color(1, 0.2, 0, 1)
    end
end

---@param rng RNG
---@param player EntityPlayer
function DivineWrath:OnUse(_, rng, player)
    ShootSaltyBabyTear(player, rng, 8, 12)
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