local mod = EdithRebuilt
local enums = mod.Enums
local sfx = enums.Utils.SFX
local modules = mod.Modules
local Helpers = modules.HELPERS
local TEdithMod = modules.TEDITH
local Player = modules.PLAYER
local Grudge = {}

---@param player EntityPlayer
---@param collider Entity
function Grudge:OnTaintedEdithGrudgeCollision(player, collider)
    if not Player.IsEdith(player, true) then return end
    if not Helpers.IsGrudgeChallenge() then return end
    if not Helpers.IsEnemy(collider) then return end

    local HopParams = TEdithMod.GetHopParryParams(player)

    if not HopParams.GrudgeDash then return end

    local Aceleration = player.Velocity:Length()
    local Damage = (
        (player.Damage / 2) +
        (player.MoveSpeed) / 3 + 
        (Aceleration / 4) * ((TEdithMod.GetHopDashCharge(player, false, true) / 200) / 2)
    )

    sfx:Play(SoundEffect.SOUND_MEATY_DEATHS)
    Helpers.TriggerPush(collider, player, 15)
    collider:TakeDamage(Damage, DamageFlag.DAMAGE_CRUSH, EntityRef(player), 0)
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_COLLISION, Grudge.OnTaintedEdithGrudgeCollision)