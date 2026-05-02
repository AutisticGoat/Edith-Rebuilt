local mod = EdithRebuilt
local modules = mod.Modules
local effects = mod.Enums.EdithStatusEffects
local Status = modules.STATUS_EFFECTS
local Creeps = modules.CREEPS
local Player = modules.PLAYER
local CinderCreeps = 10
local ndegrees = 360/CinderCreeps

---@param player EntityPlayer
---@param ent Entity
local function OnCinderParry(_, player, ent)
    if not Status.EntHasStatusEffect(ent, effects.CINDER) then return end

    local HasBirthright = Player.PlayerHasBirthright(player)
    local damage = HasBirthright and 1.25 or 0.75

    for i = 1, CinderCreeps do
      Creeps.SpawnCinderCreep(player, player.Position + Vector(0, 40):Rotated(i * ndegrees), damage, 6)
	end
end
mod:AddCallback(mod.Enums.Callbacks.PERFECT_PARRY, OnCinderParry)