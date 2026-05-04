local mod = EdithRebuilt
local enums = mod.Enums
local game = enums.Utils.Game
local card = enums.Card
local sfx = enums.Utils.SFX
local saltTypes = enums.SaltTypes
local modules = mod.Modules
local Helpers = modules.HELPERS
local Creeps = modules.CREEPS
local StatusEffects = modules.STATUS_EFFECTS
local BitMask = modules.BIT_MASK
local data = mod.DataHolder.GetEntityData

mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
    for _, enemy in pairs(Helpers.GetEnemies()) do
        StatusEffects.SetStatusEffect("Salt", enemy, -1, player)
        Helpers.SpawnSaltGib(enemy, 5, 3, nil, true)
        data(enemy).SaltType = BitMask.AddBitFlags(data(enemy).SaltType, saltTypes.SALT_ROCKS)
    end
    sfx:Play(SoundEffect.SOUND_ROCK_CRUMBLE)
    game:ShakeScreen(8)
end, card.CARD_SALT_ROCKS)

---@param player EntityPlayer
---@param npc EntityNPC
---@param rng RNG
local function ShootSaltTears(player, npc, rng)
	local FireRock = {
		variant = TearVariant.ROCK,
		position = npc.Position,
		velocity = rng:RandomVector():Resized(20) + npc.Velocity,
        ---@param tear EntityTear
		apply = function(tear)
            Helpers.ForceSaltTear(tear, false)
            data(tear).SaltRocksTear = true
		end,
	}

	Helpers.ShootArchedTear(player, rng, 10, 15, FireRock)
end

---@param npc EntityNPC
---@param source EntityRef
mod:AddCallback(PRE_NPC_KILL.ID, function (_, npc, source)
    if not StatusEffects.EntHasStatusEffect(npc, enums.EdithStatusEffects.SALTED) then return end

    local player = Helpers.GetPlayerFromRef(source)
    if not player then return end
    if not BitMask.HasBitFlags(data(npc).SaltType, saltTypes.SALT_ROCKS --[[@as BitSet128]]) then return end

    local rng = RNG(math.max(Random(), 1))
    ShootSaltTears(player, npc, rng)
end)

---@param tear EntityTear
mod:AddCallback(ModCallbacks.MC_POST_TEAR_DEATH, function(_, tear)
    if not data(tear).SaltRocksTear then return end

    Creeps.SpawnSaltCreep(tear, tear.Position, 3, 5, 5, 5, saltTypes.SALT_ROCKS, false, false)
end)