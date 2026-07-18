local mod = EdithRebuilt
local modules = mod.Modules
local Helpers = modules.HELPERS
local RNG = modules.RNG
local DivineWrathID = mod.Enums.CollectibleType.COLLECTIBLE_DIVINE_WRATH

---@param tear EntityTear
mod:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, function (_, tear)
    if tear.FrameCount ~= 1 then return end

    local spawner = tear.Parent or tear.SpawnerEntity

    if not spawner then return end

    local fam = (tear.Parent or tear.SpawnerEntity):ToFamiliar()

    if not fam then return end
    if not Helpers.IsModItemWisp(fam, DivineWrathID) then return end

    tear.CollisionDamage = tear.CollisionDamage * RNG.RandomFloat(fam:GetDropRNG(), 0.75, 1.5)
end)