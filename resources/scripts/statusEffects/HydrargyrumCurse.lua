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

    local data = Status.GetStatusEffectData(npc, effects.HYDRARGYRUM_CURSE)
    if data.Countdown % 15 ~= 0 then return end

    local player = Helpers.GetPlayerFromRef(data.Source) 
    if not player then return end

    local rng = RNG(math.max(Random(), 1))

    ShootHydrargyrumTears(player, npc, rng)
end

---@param player EntityPlayer
---@param tear EntityTear
---@param tearParams TearParams
local function SpawnMercuryCreep(player, tear, tearParams)
    local Creep = player:SpawnAquariusCreep(tearParams)
    Creep.Position = tear.Position
    Creep.Color = CreepColor
end

---@param tear EntityTear
mod:AddCallback(ModCallbacks.MC_POST_TEAR_DEATH, function(_, tear)
    if not data(tear).IsHydrargyrumTear then return end

    local player = Helpers.GetPlayerFromTear(tear)

    if not player then return end

    local weapon = player:GetWeapon(1)
    if not weapon then return end

    local tearParams = player:GetTearHitParams(weapon:GetWeaponType())
    tearParams.TearFlags = TearFlags.TEAR_NORMAL | TearFlags.TEAR_BURN

    SpawnMercuryCreep(player, tear, tearParams)
end)

---@param npc EntityNPC
local function OnNpcUpdate(_, npc)
    OnHydrargyrumCurseUpdate(npc)
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, OnNpcUpdate)