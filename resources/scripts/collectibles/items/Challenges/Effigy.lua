local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local modules = mod.Modules
local EdithMod = modules.EDITH
local Helpers = modules.HELPERS
local TargetArrow = modules.TARGET_ARROW
local Land = modules.LAND
local Effigy = {}
local jumpData = { tag = "EdithRebuilt_EffigyJump", }

---@param player EntityPlayer
---@param flags UseFlag
function Effigy:OnEffigyUse(_, _, player, flags)
    if JumpLib:GetData(player).Jumping then return end
    EdithMod.InitEdithJump(player, "EdithRebuilt_EffigyJump", true)

    if not Helpers.GetNearestEnemy(player) then return end
    TargetArrow.SpawnEdithTarget(player, false)
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, Effigy.OnEffigyUse, items.COLLECTIBLE_EFFIGY)

---@param player EntityPlayer
function Effigy:OnEffigyLand(player)
    local JumpParams = EdithMod.GetJumpStompParams(player)

    JumpParams.Damage = 40 + (player.Damage / 2)
    JumpParams.Radius = 40
    JumpParams.Knockback = 10

    Land.EdithStomp(player, JumpParams, true)
    Land.LandFeedbackManager(player, Land.GetLandSoundTable(false, false), Color.Default, false)
    Land.TriggerLandenemyJump(player, JumpParams, JumpParams.Knockback,3, 2)

    TargetArrow.RemoveEdithTarget(player, false)

    player:SetMinDamageCooldown(20)
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, Effigy.OnEffigyLand, jumpData)

---@param player EntityPlayer
function Effigy:OnEffigyJumpUpdate(player)
    local target = TargetArrow.GetEdithTarget(player, false)
    local jumpInternalData = JumpLib.Internal:GetData(player)
    local NearestEnemy = Helpers.GetNearestEnemy(player)

    if not NearestEnemy then return end
    if not target then return end

    target.Position = NearestEnemy.Position

    if jumpInternalData.UpdateFrame and jumpInternalData.UpdateFrame > 6 then
		EdithMod.EdithDash(player, TargetArrow.GetEdithTargetDirection(player), TargetArrow.GetEdithTargetDistance(player), 40)
	end

    if target and JumpLib:IsFalling(player) then
		player.Position = target.Position
	end
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_UPDATE_60, Effigy.OnEffigyJumpUpdate, jumpData)