local Jump = {}

---@param entity Entity
---@return boolean
function Jump.IsJumping(entity)
	return JumpLib:GetData(entity).Jumping
end

---@param entity Entity
---@return integer
function Jump.GetJumpFrame(entity)
    return Jump.IsJumping(entity) and JumpLib.Internal:GetData(entity).UpdateFrame or 0
end

return Jump