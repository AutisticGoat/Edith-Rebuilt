local mod = EdithRebuilt
local enums = mod.Enums
local modules = mod.Modules
local utils = enums.Utils
local game = utils.Game
local sfx = utils.SFX
local effects = enums.EdithStatusEffects
local Status = modules.STATUS_EFFECTS
local Helpers = modules.HELPERS
local ModRNG = modules.RNG
local rng = RNG()
local data = mod.DataHolder.GetEntityData
local CinnamonColors = {
    Puff = Color(210/255, 105/255, 30/255),
    Cloud = Color(0.66, 0.34, 0.37, 1, 0.26, 0.12),
}

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function ()
    rng:SetSeed(game:GetSeeds():GetStartSeed(), 35)
end)

local function SpawnCinnamonPuff(npc, RNG)
    local puff = Status.SpawnSpicePuff(npc, RNG)

    puff.Color = CinnamonColors.Puff
    sfx:Play(enums.SoundEffect.SOUND_CINNAMON_COUGH, 1, 2, false, ModRNG.RandomFloat(RNG, 0.95, 1.15))
end

local function SpawnCinnamonCloud(player, npc)
    local DustCloud = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.SMOKE_CLOUD, 1, npc.Position, Vector.Zero, player):ToEffect() ---@cast DustCloud EntityEffect
    
    DustCloud.Color = CinnamonColors.Cloud
    DustCloud.Timeout = 120
    data(DustCloud).CinnamonCloud = true
end

local function TriggerCoughPush(npc)
    for _, enemy in ipairs(Isaac.FindInRadius(npc.Position, 40, EntityPartition.ENEMY)) do
        Helpers.TriggerPush(enemy, npc, 30)
    end
end

---@param npc EntityNPC
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, function(_, npc)
    if not Status.EntHasStatusEffect(npc, effects.CINNAMON) then return end

    local stsdata = Status.GetStatusEffectData(npc, effects.CINNAMON)
    local player = Helpers.GetPlayerFromRef(stsdata.Source)

    if not player then return end
    if stsdata.Countdown % 20 ~= 0 then return end

    SpawnCinnamonPuff(npc, rng)
    SpawnCinnamonCloud(player, npc)
    TriggerCoughPush(npc)
end)

---@param effect EntityEffect
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, effect)
    if not data(effect).CinnamonCloud then return end

    for _, ent in ipairs(Isaac.FindInRadius(effect.Position, 40, EntityPartition.ENEMY)) do
        if not Helpers.IsEnemy(ent) then goto continue end
        data(ent).IsInCinnamonCloud = true
        ::continue::
    end
end, EffectVariant.SMOKE_CLOUD)

---@param npc EntityNPC
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, function (_, npc)
    local npcData = data(npc)

    if not npcData.IsInCinnamonCloud then
		npcData.CinnamonCount = 0
		return
	end

	npcData.CinnamonCount = npcData.CinnamonCount or 0
	npcData.CinnamonCount = npcData.CinnamonCount + 1

    if npcData.IsInCinnamonCloud then
        npc:MultiplyFriction(0.85)
    end

    if npcData.CinnamonCount % 20 == 0 then
        npc:TakeDamage(3, 0, EntityRef(nil), 0)
    end

	npcData.IsInCinnamonCloud = false
end)