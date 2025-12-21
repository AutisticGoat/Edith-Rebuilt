local mod = EdithRebuilt
local enums = mod.Enums
local variants = enums.EffectVariant
local game = enums.Utils.Game
local level = enums.Utils.Level
local helpers = require("resources.scripts.functions.Helpers")
local Player = require("resources.scripts.functions.Player")
local data = mod.CustomDataWrapper.getData
local targetArrow = {}

---Function to get Edith's Target, setting `tainted` to `true` will return Tainted Edith's Arrow
---@param player EntityPlayer
---@param tainted boolean?
---@return EntityEffect
function targetArrow.GetEdithTarget(player, tainted)
	local playerData = data(player)
	return tainted and playerData.TaintedEdithTarget or playerData.EdithTarget
end

---Checks if Edith's target is moving
---@param player EntityPlayer
---@return boolean
function targetArrow.IsEdithTargetMoving(player)
	local k_up = Input.IsActionPressed(ButtonAction.ACTION_UP, player.ControllerIndex)
    local k_down = Input.IsActionPressed(ButtonAction.ACTION_DOWN, player.ControllerIndex)
    local k_left = Input.IsActionPressed(ButtonAction.ACTION_LEFT, player.ControllerIndex)
    local k_right = Input.IsActionPressed(ButtonAction.ACTION_RIGHT, player.ControllerIndex)
	
    return (k_down or k_right or k_left or k_up) or false
end

---Returns distance between Edith and her target
---@param player EntityPlayer
---@return number
function targetArrow.GetEdithTargetDistance(player)
	local target = targetArrow.GetEdithTarget(player, false)
	if not target then return 0 end
	return player.Position:Distance(target.Position)
end

---Function to spawn Edith's Target, setting `tainted` to `true` will Spawn Tainted Edith's Arrow
---@param player EntityPlayer
---@param tainted? boolean
function targetArrow.SpawnEdithTarget(player, tainted)
	if helpers.IsDogmaAppearCutscene() then return end
	if targetArrow.GetEdithTarget(player, tainted or false) then return end 

	local playerData = data(player)
	local TargetVariant = tainted and variants.EFFECT_EDITH_B_TARGET or variants.EFFECT_EDITH_TARGET
	local target = Isaac.Spawn(	
		EntityType.ENTITY_EFFECT,
		TargetVariant,
		0,
		player.Position,
		Vector.Zero,
		player
	):ToEffect() ---@cast target EntityEffect
	target.DepthOffset = -100
	target.SortingLayer = SortingLayer.SORTING_NORMAL
	
	if tainted then
		playerData.TaintedEdithTarget = target
	else
		target.GridCollisionClass = GridCollisionClass.COLLISION_SOLID
		playerData.EdithTarget = target
	end
end

---Function to remove Edith's target
---@param player EntityPlayer
---@param tainted? boolean
function targetArrow.RemoveEdithTarget(player, tainted)
	local target = targetArrow.GetEdithTarget(player, tainted)

	if not target then return end
	target:Remove()

	local playerData = data(player)
	if tainted then
		playerData.TaintedEdithTarget = nil
	else
		playerData.EdithTarget = nil
	end
end

---Returns a normalized vector that represents direction regarding Edith and her Target, set `tainted` to true to check for Tainted Edith's arrow instead
---@param player EntityPlayer
---@param tainted boolean?
---@return Vector
function targetArrow.GetEdithTargetDirection(player, tainted)
	local target = targetArrow.GetEdithTarget(player, tainted or false)
	return (target.Position - player.Position):Normalized()
end

---Manages Edith's Target and Tainted Edith's arrow behavior when going trough doors
---@param effect EntityEffect
---@param player EntityPlayer
---@param triggerDistance number
function targetArrow.TargetDoorManager(effect, player, triggerDistance)
	local room = game:GetRoom()
	local effectPos = effect.Position
	local roomName = level:GetCurrentRoomDesc().Data.Name
	local isTainted = Player.IsEdith(player, true) or false
	local MirrorRoomCheck = roomName == "Mirror Room" and player:HasInstantDeathCurse()
	local playerHasPhoto = (player:HasCollectible(CollectibleType.COLLECTIBLE_POLAROID) or player:HasCollectible(CollectibleType.COLLECTIBLE_NEGATIVE))

	for i = 0, DoorSlot.DOWN1 do
		local door = room:GetDoor(i)
		if not door then goto Break end

		local sprite = door:GetSprite()
		local layer = sprite:GetLayer(0)

		if not layer then goto Break end

		local doorSpritePath = sprite:GetLayer(0):GetSpritesheetPath()
		local MausoleumRoomCheck = string.find(doorSpritePath, "mausoleum") ~= nil
		local StrangeDoorCheck = string.find(doorSpritePath, "mausoleum_alt") ~= nil
		local ShouldMoveToStrangeDoorPos = StrangeDoorCheck and sprite:WasEventTriggered("FX")
		local doorPos = room:GetDoorSlotPosition(i)

		if not (doorPos and effectPos:Distance(doorPos) <= triggerDistance) then 	
			if player.Color.A < 1 then
				helpers.ChangeColor(player, nil, nil, nil, 1)
			end
			goto Break 
		end

		if door:IsOpen() or MirrorRoomCheck or ShouldMoveToStrangeDoorPos then
			player.Position = doorPos
			targetArrow.RemoveEdithTarget(player, isTainted)
		else
			if room:IsClear() then
				if StrangeDoorCheck then
					if not playerHasPhoto then goto Break end
					door:TryUnlock(player)
				elseif MausoleumRoomCheck then
					if not sprite:IsPlaying("KeyOpen") then
						sprite:Play("KeyOpen")
					end

					if sprite:IsFinished("KeyOpen") then
						door:TryUnlock(player, true)
					end
				else
					helpers.ChangeColor(player, 1, 1, 1, 1)
					door:TryUnlock(player)
				end
			end
		end
		::Break::
	end
end

return targetArrow