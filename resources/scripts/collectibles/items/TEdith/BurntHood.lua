local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local sounds = enums.SoundEffect
local BurntHood = {}
local funcs = {
    GetData = mod.CustomDataWrapper.getData,
    FeedbackMan = mod.LandFeedbackManager
}

local parryJumpSounds = {
	[1] = SoundEffect.SOUND_ROCK_CRUMBLE,
	[2] = sounds.SOUND_PIZZA_TAUNT,
	[3] = sounds.SOUND_VINE_BOOM,
	[4] = sounds.SOUND_FART_REVERB,
	[5] = sounds.SOUND_SOLARIAN,
	[6] = sounds.SOUND_MACHINE,
	[7] = sounds.SOUND_MECHANIC,
	[8] = sounds.SOUND_KNIGHT,
}

---@param player EntityPlayer
function BurntHood:OnUse(_, _, player)
    if JumpLib:GetData(player).Jumping then return end
    mod:InitTaintedEdithParryJump(player, "BrokenHoodParry")
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, BurntHood.OnUse, items.COLLECTIBLE_BURNT_HOOD)

---@param player EntityPlayer
function BurntHood:ParryJump(player)
	local PerfectParry = mod.ParryLandManager(player, false)
	funcs.FeedbackMan(player, parryJumpSounds, Color(1, 1, 1), PerfectParry)

	if not PerfectParry then return end

	player:SetMinDamageCooldown(20)
	player:FullCharge(ActiveSlot.SLOT_PRIMARY)
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, BurntHood.ParryJump, { tag = "BrokenHoodParry" })