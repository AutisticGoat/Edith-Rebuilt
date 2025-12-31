local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local TEdith = mod.Modules.TEDITH
local Land = mod.Modules.LAND
local BurntHood = {}

---@param player EntityPlayer
function BurntHood:OnUse(_, _, player)
    if JumpLib:GetData(player).Jumping then return end
    TEdith.InitTaintedEdithParryJump(player, "BrokenHoodParry")
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, BurntHood.OnUse, items.COLLECTIBLE_BURNT_HOOD)

---@param player EntityPlayer
function BurntHood:ParryJump(player)
	local PerfectParry = Land.ParryLandManager(player, TEdith.GetHopParryParams(player), false)
	Land.LandFeedbackManager(player, Land.GetLandSoundTable(true, PerfectParry), Color(1, 1, 1), PerfectParry)

	if not PerfectParry then return end

	player:SetMinDamageCooldown(20)
	player:FullCharge(ActiveSlot.SLOT_PRIMARY)
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, BurntHood.ParryJump, { tag = "BrokenHoodParry" })