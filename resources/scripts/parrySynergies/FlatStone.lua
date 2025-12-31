local mod = EdithRebuilt
local modules = mod.Modules
local Land = modules.LAND
local TEdithMod = modules.TEDITH
local TargetArrow = modules.TARGET_ARROW
local Player = modules.PLAYER

---@param player EntityPlayer
---@param JumpData JumpData
function mod:FLatStoneStomp(player, JumpData)
    if not player:ToPlayer() then return end
    if not Player.IsEdith(player, true) then return end
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_FLAT_STONE) then return end
    if JumpData.Tags.EdithRebuilt_FlatStoneLand then return end
    Land.TriggerFlatStoneMiniJumps(player, 7, 1.6)
    TargetArrow.RemoveEdithTarget(player)
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, mod.FLatStoneStomp, mod.Enums.Tables.JumpParams.TEdithJump)

---@param ent Entity
---@param data JumpData
---@param pitfall boolean
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, function(_, ent, data, pitfall)
    local player = ent:ToPlayer()
    if not player then return end
    if not Player.IsEdith(player, true) then return end

    Land.LandFeedbackManager(player, Land.GetLandSoundTable(true, true), player.Color)
    Land.ParryLandManager(player, TEdithMod.GetHopParryParams(player), true)
    player:MultiplyFriction(0.05)
end, {tag = "EdithRebuilt_FlatStoneLand"})