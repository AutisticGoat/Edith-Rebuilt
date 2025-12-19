local mod = EdithRebuilt
local modules = mod.Modules
local Land = modules.LAND
local EdithMod = modules.EDITH
local TargetArrow = modules.TARGET_ARROW
local Player = modules.PLAYER

---@param player EntityPlayer
---@param JumpData JumpData
function mod:FLatStoneStomp(player, JumpData)
    if not player:ToPlayer() then return end
    if not Player.IsEdith(player, false) then return end

    local params = EdithMod.GetJumpStompParams(player)

    if params.IsDefensiveStomp then return end
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_FLAT_STONE) then return end
    if JumpData.Tags.EdithRebuilt_FlatStoneLand then return end
    Land.TriggerFlatStoneMiniJumps(player, 7, 1.4)
    TargetArrow.RemoveEdithTarget(player)
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, mod.FLatStoneStomp, mod.Enums.Tables.JumpParams)

---@param ent Entity
---@param data JumpData
---@param pitfall boolean
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, function(_, ent, data, pitfall)
    local player = ent:ToPlayer()
    if not player then return end
    if not Player.IsEdith(player, false) then return end

    local params = EdithMod.GetJumpStompParams(player)
    local Mult = Player.PlayerHasBirthright(player) and 0.9 or 0.75

    params.Damage = params.Damage * Mult
    Land.LandFeedbackManager(player, Land.GetLandSoundTable(false, false), player.Color)
    Land.EdithStomp(player, params, true)
    Land.TriggerLandenemyJump(params, 6, 1.5)
    player:MultiplyFriction(0.05)

end, {tag = "EdithRebuilt_FlatStoneLand"})