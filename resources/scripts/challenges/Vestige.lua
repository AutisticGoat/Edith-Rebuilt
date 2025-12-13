local mod = EdithRebuilt
local JumpTags = mod.Enums.Tables.JumpTags
local data = mod.CustomDataWrapper.getData
local modules = mod.Modules
local TargetArrow = modules.TARGET_ARROW
local Helpers = modules.HELPERS
local EdithMod = modules.EDITH
local Player = modules.PLAYER
local Vestige = {}

---@param player EntityPlayer
function Vestige:EdithJumpHandler(player)
    if not Helpers.IsVestigeChallenge() then return end
	if not Player.IsEdith(player, false) then return end

	local playerData = data(player)
	if player:IsDead() then TargetArrow.RemoveEdithTarget(player); playerData.isJumping = false return end

	local isKeyStompTriggered = Helpers.IsKeyStompTriggered(player)
	local jumpData = JumpLib:GetData(player)
	local isJumping = jumpData.Jumping 
	local target = TargetArrow.GetEdithTarget(player)
	local sprite = player:GetSprite()
	local jumpInternalData = JumpLib.Internal:GetData(player)

	playerData.isJumping = playerData.isJumping or false
	playerData.ExtraJumps = playerData.ExtraJumps or 0

    if isKeyStompTriggered and not isJumping and not sprite:IsPlaying("BigJumpUp") and not sprite:IsPlaying("BigJumpFinish") then
        player:PlayExtraAnimation("BigJumpUp")
	end

    if sprite:IsEventTriggered("StartJump") and not isJumping then
        EdithMod.InitEdithJump(player, JumpTags.EdithJump, true)
    end

	if jumpInternalData.UpdateFrame and jumpInternalData.UpdateFrame > 6 then
		EdithMod.EdithDash(player, TargetArrow.GetEdithTargetDirection(player), TargetArrow.GetEdithTargetDistance(player), 50)
	end

	if target and JumpLib:IsFalling(player) then
		player.Position = target.Position
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, Vestige.EdithJumpHandler)