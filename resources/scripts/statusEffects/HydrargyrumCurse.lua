---@diagnostic disable: undefined-field
local mod = EdithRebuilt
local modules = mod.Modules
local effects = mod.Enums.EdithStatusEffects
local Status = modules.STATUS_EFFECTS
local Helpers = modules.HELPERS
local data = mod.DataHolder.GetEntityData
local CreepColor = Color(0, 0, 0, 1, 0.6, 0.6, 0.6)

local function ShootHydrargyrumTears(player, ent, rng)
	local FireRock = {
		variant = TearVariant.METALLIC,
		position = ent.Position,
		velocity = rng:RandomVector():Resized(20) + ent.Velocity,
		apply = function(tear)
			tear:AddTearFlags(TearFlags.TEAR_PIERCING)
            data(tear).IsHydrargyrumTear = true
		end,
	}

	Helpers.ShootArchedTear(player, rng, 1, 1, FireRock)
end

---@param npc EntityNPC
local function OnHydrargyrumCurseUpdate(npc)
    if not Status.EntHasStatusEffect(npc, effects.HYDRARGYRUM_CURSE) then return end

    local statusData = Status.GetStatusEffectData(npc, effects.HYDRARGYRUM_CURSE)
    if statusData.Countdown % 10 ~= 0 then return end

    local player = Helpers.GetPlayerFromRef(statusData.Source)
    if not player then return end

    local rng = RNG(math.max(Random(), 1))

    ShootHydrargyrumTears(player, npc, rng)
end

---@param player EntityPlayer
---@param tear EntityTear
local function SpawnMercuryCreep(player, tear)
    local Creep = Isaac.Spawn(
        EntityType.ENTITY_EFFECT,
        EffectVariant.PLAYER_CREEP_HOLYWATER_TRAIL,
        0,
        tear.Position,
        Vector.Zero,
        player
    ):ToEffect() ---@cast Creep EntityEffect

    Creep.Color = CreepColor
    Creep.SpriteScale = Creep.SpriteScale * 1.5
    Creep:SetTearFlags(TearFlags.TEAR_NORMAL | TearFlags.TEAR_BURN)
    Creep:Update()
end

---@param tear EntityTear
mod:AddCallback(ModCallbacks.MC_POST_TEAR_DEATH, function(_, tear)
    if not data(tear).IsHydrargyrumTear then return end

    local player = Helpers.GetPlayerFromTear(tear)
    if not player then return end

    local weapon = player:GetWeapon(1)
    if not weapon then return end

    SpawnMercuryCreep(player, tear)
end)

---@param npc EntityNPC
local function OnNpcUpdate(_, npc)
    OnHydrargyrumCurseUpdate(npc)
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, OnNpcUpdate)