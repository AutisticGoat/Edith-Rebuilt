local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local modules = mod.Modules
local EdithMod = modules.EDITH
local Helpers = modules.HELPERS
local Jump = modules.JUMP
local TargetArrow = modules.TARGET_ARROW
local Land = modules.LAND
local jumpData = { tag = "EdithRebuilt_EffigyJump" }

---@param player EntityPlayer
---@param jumpParams EdithJumpStompParams
local function SetEffigyStompParams(player, jumpParams)
    jumpParams.Damage = 40 + player.Damage
    jumpParams.Radius = 40
    jumpParams.Knockback = 20
end

---@param player EntityPlayer
local function TryEffigyDash(player)
    if Jump.GetJumpFrame(player) then return end
    EdithMod.EdithDash(player, TargetArrow.GetEdithTargetDirection(player), TargetArrow.GetEdithTargetDistance(player), 40 )
end

mod:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, _, _, player)
    if Jump.IsJumping(player) then return end
    Jump.InitEdithJump(player, jumpData.tag, true)

    if not Helpers.GetNearestEnemy(player) then return end
    TargetArrow.SpawnEdithTarget(player, false)
end, items.COLLECTIBLE_EFFIGY)

mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, function(_, player)
    local jumpParams = EdithMod.GetJumpStompParams(player)
    SetEffigyStompParams(player, jumpParams)

    Land.EdithStomp(player, jumpParams, true)
    Land.LandFeedbackManager(player, Land.GetLandSoundTable(false, false), Color.Default, false)
    Land.TriggerLandenemyJump(player, jumpParams.StompedEntities, jumpParams.Knockback, 3, 2)

    TargetArrow.RemoveEdithTarget(player, false)
    player:SetMinDamageCooldown(20)
end, jumpData)

mod:AddCallback(JumpLib.Callbacks.ENTITY_UPDATE_60, function(_, player)
    local nearestEnemy = Helpers.GetNearestEnemy(player)
    if not nearestEnemy then return end

    local target = TargetArrow.GetEdithTarget(player, false)
    if not target then return end

    target.Position = nearestEnemy.Position

    TryEffigyDash(player)

    if JumpLib:IsFalling(player) then
        player.Position = target.Position
    end
end, jumpData)