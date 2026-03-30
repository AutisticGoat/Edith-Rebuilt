local mod = EdithRebuilt
local JumpTags = mod.Enums.Tables.JumpTags
local data = mod.DataHolder.GetEntityData
local modules = mod.Modules
local TargetArrow = modules.TARGET_ARROW
local Helpers = modules.HELPERS
local EdithMod = modules.EDITH
local Player = modules.PLAYER
local Jump = modules.JUMP

---@param player EntityPlayer
---@return boolean
local function IsEdithAndVestige(player)
	return Player.IsEdith(player, false) and Helpers.IsVestigeChallenge()
end

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player)
	if not IsEdithAndVestige(player) then return end
	player.TearRange = Player.rangeUp(player.TearRange, 1.75)
end, CacheFlag.CACHE_RANGE)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function(_, player)
	if not IsEdithAndVestige(player) then return end

	local playerData = data(player)
	if player:IsDead() then 
		TargetArrow.RemoveEdithTarget(player) 
		return
	end

	local isKeyStompTriggered = Helpers.IsKeyStompTriggered(player)
	local jumpData = JumpLib:GetData(player)
	local isJumping = jumpData.Jumping 
	local sprite = player:GetSprite()

    if isKeyStompTriggered and not isJumping and not sprite:IsPlaying("BigJumpUp") and not sprite:IsPlaying("BigJumpFinish") then
        player:PlayExtraAnimation("BigJumpUp")
	end

    if sprite:IsEventTriggered("StartJump") and not isJumping then
        EdithMod.InitEdithJump(player, JumpTags.EdithJump, true)
    end
end)

---@param player EntityPlayer
mod:AddCallback(JumpLib.Callbacks.ENTITY_UPDATE_60, function (_, player)
	if not IsEdithAndVestige(player) then return end

	local target = TargetArrow.GetEdithTarget(player)
	local IsFalling = JumpLib:IsFalling(player)
	local targetDistance = TargetArrow.GetEdithTargetDistance(player)

	if not target then return end

	if Jump.GetJumpFrame(player) > 6 then
		EdithMod.EdithDash(player, TargetArrow.GetEdithTargetDirection(player), targetDistance, 50)
	end

	if IsFalling or targetDistance <= 5 then
		player.Velocity = Vector.Zero
		player.Position = target.Position
	end
end, EdithRebuilt.Enums.Tables.JumpParams.EdithJump)