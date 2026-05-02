---@diagnostic disable: undefined-global
if not Birthwrong then return end

local mod = EdithRebuilt
local enums = mod.Enums
local modules = mod.Modules
local ModRNG = modules.RNG
local game = enums.Utils.Game
local saveManager = mod.SaveManager

Birthwrong.registerDescription(enums.PlayerType.PLAYER_EDITH_B, "The sky breaks twice", "algo debe de hacer luego lo voy a pensar")

---@param position Vector
---@param rng RNG
local function SpawnProjectile(position, rng)
    local Proj = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, ProjectileVariant.PROJECTILE_ROCK, 0, position, Vector.Zero, nil):ToProjectile() ---@cast Proj EntityProjectile

    local fireFlag = ModRNG.RandomBoolean(rng, 0.15) and ProjectileFlags.FIRE_WAVE or ProjectileFlags.FIRE_SPAWN

    Proj:AddProjectileFlags(ProjectileFlags.HIT_ENEMIES | fireFlag)
    Proj.Height = -500 * ModRNG.RandomFloat(rng, 0.75, 1.25)
    Proj.FallingAccel = 5 * ModRNG.RandomFloat(rng, 0.75, 1.25)
    Proj.Scale = 1 * ModRNG.RandomFloat(rng, 1, 3)

    return Proj
end

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function (_, player)
    local runSave = saveManager.GetRunSave(player)

    if not runSave then return end
    if not Birthwrong.hasCharacterBW(player, enums.PlayerType.PLAYER_EDITH_B) then return end
    if player.FrameCount % 3 ~= 0 then return end

    local rng = player:GetCollectibleRNG(Birthwrong.birthwrongID)
    local Proj = SpawnProjectile(game:GetRoom():GetRandomPosition(0), rng)

    if Proj.Scale < 2.5 then return end
    if not ModRNG.RandomBoolean(rng, 0.25) then return end
end)