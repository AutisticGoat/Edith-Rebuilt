local SEL = StatusEffectLibrary
local mod = EdithRebuilt
local enums = mod.Enums
local effects = enums.EdithStatusEffects
local ModRNG = require("resources.scripts.functions.RNG")
local Creeps = require("resources.scripts.functions.Creeps")
local data = mod.CustomDataWrapper.getData
local StatusEffects = {}

local Effects = {
    Salted = {
        ID = "EDITH_REBUILT_SALTED",
        Sprite = Sprite("gfx/EdithRebuiltSalted.anm2", true),
        Color = Color(1, 1, 1, 1, 0.3, 0.3, 0.3)
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
    Peppered = {
        ID = "EDITH_REBUILT_PEPPERED",
        Sprite = Sprite("gfx/EdithRebuiltPeppered.anm2", true),
        Color = Color(0.5, 0.5, 0.5)
    }
}

for _, Data in pairs(Effects) do
    Data.Sprite:Play("Idle", true)
    SEL.RegisterStatusEffect(Data.ID, Data.Sprite, Data.Color)
end

local Flags = {
    Salted = SEL.StatusFlag[Effects.Salted.ID],
    Cinder = SEL.StatusFlag[Effects.Cinder.ID],
    HydrargyrumCurse = SEL.StatusFlag[Effects.HydrargyrumCurse.ID],
    Peppered = SEL.StatusFlag[Effects.Peppered.ID],
}

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

---@param npc EntityNPC
local function OnSaltedUpdate(npc)
    if not StatusEffects.EntHasStatusEffect(npc, effects.SALTED) then return end
    npc:MultiplyFriction(0.6)
end

---@param npc EntityNPC
local function OnPepperedUpdate(npc)
    if not StatusEffects.EntHasStatusEffect(npc, effects.PEPPERED) then return end
    npc:MultiplyFriction(0.8)

    local player = SEL:GetStatusEffectData(npc, Flags.Peppered).Source.Entity:ToPlayer() ---@cast player EntityPlayer 
    if SEL:GetStatusEffectCountdown(npc, Flags.Peppered) % 10 ~= 0 then return end
    mod:SpawnPepperCreep(player, npc.Position, 0.5, 3)
end

---@param npc EntityNPC
local function OnHydrargyrumCurseUpdate(npc)
    if not StatusEffects.EntHasStatusEffect(npc, effects.HYDRARGYRUM_CURSE) then return end
    if SEL:GetStatusEffectCountdown(npc, Flags.HydrargyrumCurse) % 15 ~= 0 then return end

    local player = SEL:GetStatusEffectData(npc, Flags.HydrargyrumCurse).Source.Entity:ToPlayer() ---@cast player EntityPlayer 
    if not player then return end

    local randTear = Isaac.Spawn(
        EntityType.ENTITY_TEAR,
        TearVariant.METALLIC,
        0,
        npc.Position,
        RandomVector():Resized(player.ShotSpeed * 10),
        player
    ):ToTear()

    if not randTear then return end
    randTear.CollisionDamage = randTear.CollisionDamage * 0.1
    randTear:AddTearFlags(TearFlags.TEAR_PIERCING)
end

---@param npc EntityNPC
local function OnNpcUpdate(_, npc)
    OnSaltedUpdate(npc)
    OnPepperedUpdate(npc)
    OnHydrargyrumCurseUpdate(npc)
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, OnNpcUpdate)

local flag = false
---@param entity Entity
---@param amount number
---@param flags DamageFlag
---@param source EntityRef
---@param Cooldown integer
local function OnDamagingNpc(_, entity, amount, flags, source, Cooldown)
    if not StatusEffects.EntHasStatusEffect(entity, effects.SALTED) then return end
    if not amount == (amount * 1.2) then return end
    if flag == true then return end

    flag = true
    entity:TakeDamage(amount * 1.2, flags, source, Cooldown)
    flag = false
    return false
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, OnDamagingNpc)

---@param proj EntityProjectile
local function OnSaltedProjInit(_, proj)
    if not proj.SpawnerEntity then return end
    local npc = proj.SpawnerEntity:ToNPC()

    if not npc then return end
    if not StatusEffects.EntHasStatusEffect(npc, effects.SALTED) then return end
    if not ModRNG.RandomBoolean(proj:GetDropRNG()) then return end
    proj.Visible = false
    proj:Kill()
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_INIT, OnSaltedProjInit)
mod:AddCallback(SEL.Callbacks.ID.PRE_REMOVE_ENTITY_STATUS_EFFECT, function(_, entity)
    data(entity).SaltType = nil
end, Flags.Salted)


-- Los enemigos con cenizas pueden recibir daño de los parrys imprecisos (el daño es menor)
-- Dañar a un enemigo con cenizas con un parry impreciso puede cargar el hopdash en un 5%
-- Matar a un enemigo con cenizas usando un parry perfecto soltará creep de ceniza alrededor de Edith, como si fuera el salero pero a menor rango
-- El creep de ceniza hará el efecto que hace actualmente el perfect parry con un enemigo de ceniza, o sea, crear jets de fuego que dañan al enemigo

local CinderCreeps = 10
local ndegrees = 360/CinderCreeps

---@param player EntityPlayer
---@param ent Entity
local function OnCinderParry(_, player, ent)
    if not StatusEffects.EntHasStatusEffect(ent, effects.CINDER) then return end

    for i = 1, CinderCreeps do
		Creeps.SpawnCinderCreep(player, player.Position + Vector(0, 40):Rotated(i * ndegrees), 0.5, 6)
	end

    -- for i = 1, maxCreep do
	-- 	mod:SpawnSaltCreep(player, player.Position + Vector(0, 30):Rotated(saltDegrees*i), 0.1, 5, 1, 3, saltTypes.EDITHS_HOOD)
	-- end

    -- mod.SpawnFireJet(player, ent.Position, player.Damage, true, 0.7)

    -- local capsule = Capsule(ent.Position, Vector.One, 0, enums.Misc.ImpreciseParryRadius + 15)
    -- DebugRenderer.Get(1, true):Capsule(capsule)
end
mod:AddCallback(enums.Callbacks.PERFECT_PARRY, OnCinderParry)

return StatusEffects