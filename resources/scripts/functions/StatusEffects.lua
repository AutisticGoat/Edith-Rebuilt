local SEL = StatusEffectLibrary
local mod = EdithRebuilt
local enums = mod.Enums
local effects = enums.EdithStatusEffects
local ModRNG = require("resources.scripts.functions.RNG")
local Creeps = require("resources.scripts.functions.Creeps")
local Helpers = require("resources.scripts.functions.Helpers")
local Player  = require("resources.scripts.functions.Player")
local data = mod.DataHolder.GetEntityData
local StatusEffects = {}
local Effects = {
    Salt = {
        ID = "EDITH_REBUILT_SALT",
        Sprite = Sprite("gfx/EdithRebuiltSalted.anm2", true),
        Color = Color(1, 1, 1, 1, 0.3, 0.3, 0.3)
    },
    Pepper = {
        ID = "EDITH_REBUILT_PEPPERED",
        Sprite = Sprite("gfx/EdithRebuiltPeppered.anm2", true),
        Color = Color(0.5, 0.5, 0.5)
    },
    Garlic = {
        ID = "EDITH_REBUILT_GARLIC",
        Sprite = Sprite("gfx/EdithRebuiltGarlic.anm2", true),
        Color = Color(1, 1, 1, 1, 1, 238/255, 188/255)
    },
    Oregano = {
        ID = "EDITH_REBUILT_OREGANO",
        Sprite = Sprite("gfx/EdithRebuiltOregano.anm2", true),
        Color = Color(1, 1, 1, 1, 113/255, 120/255, 82/255)
    },
    Cumin = {
        ID = "EDITH_REBUILT_CUMIN",
        Sprite = Sprite("gfx/EdithRebuiltCumin.anm2", true),
        Color = Color(1, 1, 1, 1, 115/255, 84/255, 67/355)
    },
    Turmeric = {
        ID = "EDITH_REBUILT_TURMERIC",
        Sprite = Sprite("gfx/EdithRebuiltTurmeric.anm2", true),
        Color = Color(1, 1, 1, 1, 250/255, 198/255, 49/255)
    },
    Cinnamon = {
        ID = "EDITH_REBUILT_CINNAMON",
        Sprite = Sprite("gfx/EdithRebuiltCinnamon.anm2", true),
        Color = Color(1, 1, 1, 1, 210/255, 105/255, 30/255)
    },
    Ginger = {
        ID = "EDITH_REBUILT_GINGER",
        Sprite = Sprite("gfx/EdithRebuiltGinger.anm2", true),
        Color = Color(1, 1, 1, 1, 239/255, 159/255, 89/255)
    },
    Cinder = {
        ID = "EDITH_REBUILT_CINDER",
        Sprite = Sprite("gfx/EdithRebuiltCinder.anm2", true),
        Color = Color(0.3, 0.3, 0.3)
    },
    HydrargyrumCurse = {
        ID = "EDITH_REBUILT_HYDRARGYRUM_CURSE",
        Sprite = Sprite("gfx/EdithRebuiltHydrargyrum.anm2", true),
        Color = Color(1, 1, 1, 1, 0.5, 0.06, 0.06, 0.91, 0.72, 0.72, 1)
    },
}

for _, Data in pairs(Effects) do
    Data.Sprite:Play("Idle", true)
    SEL.RegisterStatusEffect(Data.ID, Data.Sprite, Data.Color)
end

local Flags = {
    Salt = SEL.StatusFlag[Effects.Salt.ID],
    Pepper = SEL.StatusFlag[Effects.Pepper.ID],
    Garlic = SEL.StatusFlag[Effects.Garlic.ID],
    Oregano = SEL.StatusFlag[Effects.Oregano.ID],
    Cumin = SEL.StatusFlag[Effects.Cumin.ID],
    Turmeric = SEL.StatusFlag[Effects.Turmeric.ID],
    Cinnamon = SEL.StatusFlag[Effects.Cinnamon.ID],
    Ginger = SEL.StatusFlag[Effects.Ginger.ID],
    Cinder = SEL.StatusFlag[Effects.Cinder.ID],
    HydrargyrumCurse = SEL.StatusFlag[Effects.HydrargyrumCurse.ID],
}

local Spices = {
    [effects.SALTED] = {
        ID = effects.SALTED,
        Duration = 90,
        Color = Color(1, 1, 1, 1, 1.1, 1.1, 1.1),
    },
    [effects.GARLIC] = {
        ID = effects.GARLIC,
        Duration = 90,
        Color = Effects.Garlic.Color,
    },
    [effects.GINGER] = {
        ID = effects.GINGER,
        Duration = 90,
        Color = Effects.Ginger.Color,
    },
    [effects.OREGANO] = {
        ID = effects.OREGANO,
        Duration = 120,
        Color = Effects.Oregano.Color,
    },
    [effects.CUMIN] = {
        ID = effects.CUMIN,
        Duration = 90,
        Color = Effects.Cumin.Color,
    },
    [effects.PEPPERED] = {
        ID = effects.PEPPERED,
        Duration = 120,
        Color = Effects.Pepper.Color,
    },
    [effects.TURMERIC] = {
        ID = effects.TURMERIC,
        Duration = 90,
        Color = Effects.Turmeric.Color,
    },
    [effects.CINNAMON] = {
        ID = effects.CINNAMON,
        Duration = 90,
        Color = Effects.Cinnamon.Color,
    },
}

---@param status EdithStatusEffects
function StatusEffects.GetSpiceEffectData(status)
    return Helpers.When(status, Spices)
end

local randomSpices = {
    [1] = Spices[effects.SALTED],
    [2] = Spices[effects.PEPPERED],
    [3] = Spices[effects.CUMIN],
    [4] = Spices[effects.OREGANO],
    [5] = Spices[effects.TURMERIC],
    [6] = Spices[effects.GINGER],
    [7] = Spices[effects.GARLIC],
    [8] = Spices[effects.CINNAMON],
}

---@param RNG RNG
function StatusEffects.GetRandomSpiceEffect(RNG)
    return Helpers.When(RNG:RandomInt(1, 8), randomSpices)
end

---@param ent Entity
---@param status EdithStatusEffects
---@return boolean
function StatusEffects.EntHasStatusEffect(ent, status)
    return SEL:HasStatusEffect(ent, Flags[status])
end

---@param status EdithStatusEffects
---@param ent Entity
---@param dur integer
---@param src Entity
function StatusEffects.SetStatusEffect(status, ent, dur, src)
    SEL:AddStatusEffect(ent, Flags[status], dur, EntityRef(src))
end

---@param ent Entity
---@param status EdithStatusEffects
function StatusEffects.GetStatusEffectCountdown(ent, status)
    return SEL:GetStatusEffectCountdown(ent, Flags[status])
end

---@param npc EntityNPC
local function OnSaltedUpdate(npc)
    if not StatusEffects.EntHasStatusEffect(npc, effects.SALTED) then return end
    if JumpLib:GetData(npc).Jumping then return end
    npc:MultiplyFriction(0.6)
end

---@param npc EntityNPC
local function OnGarlicUpdate(npc)
    if not StatusEffects.EntHasStatusEffect(npc, effects.GARLIC) then return end
    local player = Helpers.GetPlayerFromRef(SEL:GetStatusEffectData(npc, Flags.Garlic).Source)

    if not player then return end

    if npc.Position:Distance(player.Position) > 80 then return end
    Helpers.TriggerPush(npc, player, 2)
end

---@param npc EntityNPC
local function OnCinnamonUpdate(npc)
    if not StatusEffects.EntHasStatusEffect(npc, effects.CINNAMON) then return end
    npc:MultiplyFriction(0.8)
    local data = SEL:GetStatusEffectData(npc, Flags.Cinnamon)

    if not data then return end
    local player = Helpers.GetPlayerFromRef(data.Source)
    if not player then return end

    if SEL:GetStatusEffectCountdown(npc, Flags.Cinnamon) % 5 ~= 0 then return end

    npc:TakeDamage(2, 0, data.Source, 0)
end

---@param npc EntityNPC
local function OnOreganoUpdate(npc)
    if not StatusEffects.EntHasStatusEffect(npc, effects.OREGANO) then return end
    npc:MultiplyFriction(0.8)
end

---@param npc EntityNPC
local function OnCuminUpdate(npc)
    if not StatusEffects.EntHasStatusEffect(npc, effects.CUMIN) then return end
    data(npc).CuminStopCountdown = data(npc).CuminStopCountdown or 0

    local cuminCountdown = data(npc).CuminStopCountdown

    if cuminCountdown > 0 then
        npc.Velocity = Vector.Zero
        data(npc).CuminStopCountdown = cuminCountdown - 1
    end
end

local baseRange = 6.5
local baseHeight = -23.45
local baseMultiplier = -70 / baseRange
local function ShootMercuryTear(player, position, rng)
	local tear
	local fallSpeedVar

    -- for _ = 1, rng:RandomInt(minTears, maxTears) do
        tear = Isaac.Spawn(EntityType.ENTITY_TEAR, 0, 0, position, rng:RandomVector():Resized(20), player):ToTear()

        if not tear then return end

        fallSpeedVar = ModRNG.RandomFloat(rng, 1.8, 2.2)

		Helpers.ForceSaltTear(tear, false)
		tear.Height = baseHeight * 3
        tear.Velocity = tear.Velocity * ModRNG.RandomFloat(rng, 0.2, 0.6)
        tear.FallingAcceleration = (ModRNG.RandomFloat(rng, 0.7, 1.6)) * 3
        tear.FallingSpeed = (baseMultiplier * (fallSpeedVar)) 
        tear.CollisionDamage = tear.CollisionDamage * rng:RandomInt(8, 12) / 10
		tear.Scale = tear.CollisionDamage/3.5
        tear:ChangeVariant(TearVariant.METALLIC)
        tear:AddTearFlags(TearFlags.TEAR_PIERCING)

		data(tear).IsHydrargyrumTear = true
    -- end
end

---@param npc EntityNPC
local function OnHydrargyrumCurseUpdate(npc)
    if not StatusEffects.EntHasStatusEffect(npc, effects.HYDRARGYRUM_CURSE) then return end
    if SEL:GetStatusEffectCountdown(npc, Flags.HydrargyrumCurse) % 15 ~= 0 then return end

    local player = Helpers.GetPlayerFromRef(SEL:GetStatusEffectData(npc, Flags.HydrargyrumCurse).Source) 
    if not player then return end

    ShootMercuryTear(player, npc.Position, enums.Utils.RNG)
end

---@param tear EntityTear
local function OnMercuryTearDeath(_, tear)
    if not data(tear).IsHydrargyrumTear then return end

    local player = Helpers.GetPlayerFromTear(tear)
    if not player then return end
    local weapon = player:GetWeapon(1)
    if not weapon then return end

    local tearHits = player:GetTearHitParams(weapon:GetWeaponType())
    tearHits.TearFlags = TearFlags.TEAR_NORMAL | TearFlags.TEAR_BURN

    local Creep = player:SpawnAquariusCreep(tearHits)
    Creep.Position = tear.Position
    Creep.Color = Color(0, 0, 0, 1, 0.6, 0.6, 0.6)
end
mod:AddCallback(ModCallbacks.MC_POST_TEAR_DEATH, OnMercuryTearDeath)

---@param npc EntityNPC
local function OnNpcUpdate(_, npc)
    OnSaltedUpdate(npc)
    OnHydrargyrumCurseUpdate(npc)
    OnGarlicUpdate(npc)
    OnCinnamonUpdate(npc)
    OnOreganoUpdate(npc)
    OnCuminUpdate(npc)
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, OnNpcUpdate)

local dmgFlags = {
    Salt = false,
    Turmeric = false,
    Cumin = false,
}

---@param entity Entity
---@param amount number
---@param flags DamageFlag
---@param source EntityRef
---@param Cooldown integer
local function OnDamagincSaltedEnemy(_, entity, amount, flags, source, Cooldown)
    if not StatusEffects.EntHasStatusEffect(entity, effects.SALTED) then return end
    if not amount == (amount * 1.2) then return end
    if dmgFlags.Salt == true then return end

    dmgFlags.Salt = true
    entity:TakeDamage(amount * 1.2, flags, source, Cooldown)
    dmgFlags.Salt = false
    return false
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, OnDamagincSaltedEnemy)

---@param entity Entity
---@param amount number
---@param flags DamageFlag
---@param source EntityRef
---@param Cooldown integer
local function OnDamagincTurmericEnemy(_, entity, amount, flags, source, Cooldown)
    if not StatusEffects.EntHasStatusEffect(entity, effects.TURMERIC) then return end
    if not amount == (amount * 1.25) then return end
    if dmgFlags.Turmeric == true then return end

    dmgFlags.Turmeric = true
    entity:TakeDamage(amount * 1.2, flags, source, Cooldown)
    dmgFlags.Turmeric = false

    local rng = RNG(math.max(Random(), 1))

    for _, enemy in ipairs(Isaac.FindInRadius(entity.Position, 60, EntityPartition.ENEMY)) do
        if GetPtrHash(entity) == GetPtrHash(enemy) then goto continue end
        if not Helpers.IsEnemy(enemy) then goto continue end
        if not ModRNG.RandomBoolean(rng, 0.35) then goto continue end

        local Puff = Isaac.Spawn(
            EntityType.ENTITY_EFFECT,
            EffectVariant.POOF02,
            2,
            entity.Position,
            Vector.Zero,
            entity
        )

        Puff:GetSprite().PlaybackSpeed = ModRNG.RandomFloat(rng, 0.9, 1.1)

        Puff.Color = Effects.Turmeric.Color

        StatusEffects.SetStatusEffect(effects.TURMERIC, enemy, 90, entity)
        ::continue::
    end

    return false
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, OnDamagincTurmericEnemy)

---@param entity EntityNPC
local function OnKillingPepperEnemy(_, entity)
    if not StatusEffects.EntHasStatusEffect(entity, effects.PEPPERED) then return end

    data(entity).Hits = data(entity).Hits or 0
    local hits = data(entity).Hits

    data(entity).Hits = hits + 1

    if hits % 2 ~= 0 then return end

    local RNG = entity:GetDropRNG()
    local Puff = Isaac.Spawn(
        EntityType.ENTITY_EFFECT,
        EffectVariant.POOF02,
        2,
        entity.Position,
        Vector.Zero,
        entity
    )

    Puff:GetSprite().PlaybackSpeed = ModRNG.RandomFloat(RNG, 0.9, 1.1)

    local X = ModRNG.RandomFloat(RNG, 0.85, 1.15)
    local Y = ModRNG.RandomFloat(RNG, 0.85, 1.15)

    Puff.Color = Effects.Pepper.Color
    Puff.SpriteScale = Vector(X, Y)

    local Peppers = 10
    local degree = 360/Peppers

    for i = 1, 15 do
        local y = 30 * ModRNG.RandomFloat(RNG, 0.7, 1.4)
        Creeps.SpawnPepperCreep(entity, entity.Position + Vector(0, y):Rotated(i * degree), 4, 8)
    end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, OnKillingPepperEnemy)
mod:AddCallback(PRE_NPC_KILL.ID, OnKillingPepperEnemy)

local function OnDamaginCuminEnemy(_, entity)
    if not StatusEffects.EntHasStatusEffect(entity, effects.CUMIN) then return end
    if dmgFlags.Cumin == true then return end
    data(entity).CuminStopCountdown = 5
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, OnDamaginCuminEnemy)

local function OnDamagincGingerEnemy(_, entity, amount, flags, source, Cooldown)
    if not StatusEffects.EntHasStatusEffect(entity, effects.GINGER) then return end
    entity.Velocity = -entity.Velocity * 10
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, OnDamagincGingerEnemy)

---@param proj EntityProjectile
local function OnSaltedProjInit(proj)
    if not proj.SpawnerEntity then return end
    local npc = proj.SpawnerEntity:ToNPC()

    if not npc then return end
    if not StatusEffects.EntHasStatusEffect(npc, effects.SALTED) then return end
    if not ModRNG.RandomBoolean(proj:GetDropRNG()) then return end
    proj.Visible = false
    proj:Kill()
end

---@param proj EntityProjectile
local function OnGarlicProjInit(proj)
    if not proj.SpawnerEntity then return end
    local npc = proj.SpawnerEntity:ToNPC()

    if not npc then return end
    if not StatusEffects.EntHasStatusEffect(npc, effects.GARLIC) then return end
    proj.Velocity = proj.Velocity + RandomVector() * 3
end

local function StatusProjInit(_, proj)
    OnSaltedProjInit(proj)
    OnGarlicProjInit(proj)
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_INIT, StatusProjInit)

mod:AddCallback(SEL.Callbacks.ID.PRE_REMOVE_ENTITY_STATUS_EFFECT, function(_, entity)
    data(entity).SaltType = nil
end, Flags.Salt)

local CinderCreeps = 10
local ndegrees = 360/CinderCreeps

---@param player EntityPlayer
---@param ent Entity
local function OnCinderParry(_, player, ent)
    if not StatusEffects.EntHasStatusEffect(ent, effects.CINDER) then return end

    local HasBirthright = Player.PlayerHasBirthright(player)
    local damage = HasBirthright and 1.25 or 0.75

    for i = 1, CinderCreeps do
		Creeps.SpawnCinderCreep(player, player.Position + Vector(0, 40):Rotated(i * ndegrees), damage, 6)
	end
end
mod:AddCallback(enums.Callbacks.PERFECT_PARRY, OnCinderParry)

---@param npc EntityNPC
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, function(_, npc)
    if not StatusEffects.EntHasStatusEffect(npc, effects.SALTED) then return end
    Helpers.SpawnSaltGib(npc, 8, 3, nil, true)
end)

return StatusEffects