local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local modules = mod.Modules
local TEdith = modules.TEDITH
local Land = modules.LAND
local Jump = modules.JUMP

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_USE_ITEM, function (_, _, _, player)
	if Jump.IsJumping(player) then return end
    TEdith.InitTaintedEdithParryJump(player, "BrokenHoodParry")
end, items.COLLECTIBLE_BURNT_HOOD)

---@param player EntityPlayer
---@return boolean
local function TriggerParry(player)
	local PerfectParry = Land.ParryLandManager(player, TEdith.GetHopParryParams(player), false)
	Land.LandFeedbackManager(player, Land.GetLandSoundTable(true, PerfectParry), Color(1, 1, 1), PerfectParry)

	return PerfectParry
end

---@param player EntityPlayer
local function TriggerPerfectParryReward(player)
	player:SetMinDamageCooldown(20)
	player:FullCharge(player:GetActiveItemSlot(items.COLLECTIBLE_BURNT_HOOD))
end	

---@param player EntityPlayer
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, function (_, player)
	local PerfectParry = TriggerParry(player)

	if not PerfectParry then return end

	TriggerPerfectParryReward(player)
end, { tag = "BrokenHoodParry" })