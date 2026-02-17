local mod = EdithRebuilt
local enums = mod.Enums
local tables = enums.Tables
local utils = enums.Utils
local game = utils.Game
local modules = mod.Modules
local Player = modules.PLAYER
local Helpers = modules.HELPERS
local Maths = modules.MATHS
local TargetArrow = modules.TARGET_ARROW
local costumes = enums.NullItemID

---@param entity Entity
---@param input InputHook
---@param action ButtonAction|KeySubType
---@return integer|boolean?
mod:AddCallback(ModCallbacks.MC_INPUT_ACTION, function (_, entity, input, action)
    if not entity then return end
    local player = entity:ToPlayer()

    if not player then return end
    if not Player.IsAnyEdith(player) then return end
    if input ~= InputHook.GET_ACTION_VALUE then return end

    return tables.OverrideActions[action]
end)

local ModCostumes = {
    [costumes.EDITH] = true,
    [costumes.T_EDITH] = true,
}

local whiteListCostumes = {
    [costumes.EDITH] = true,
    [costumes.T_EDITH] = true,
    [CollectibleType.COLLECTIBLE_HOLY_MANTLE] = true,
    [CollectibleType.COLLECTIBLE_FATE] = true,
    [CollectibleType.COLLECTIBLE_BOOK_OF_SHADOWS] = true,
    [CollectibleType.COLLECTIBLE_GAMEKID] = true,
}

local function OnAddCostume(_, itemconfig, player)
    if not Player.IsAnyEdith(player) then return end
    if Helpers.When(itemconfig.Costume.ID, whiteListCostumes, false) then return end
    return true
end
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_ADD_COSTUME, OnAddCostume)

---@param itemconfig ItemConfigItem
---@param player EntityPlayer
---@return boolean?
local function OnRemoveCostume(_, itemconfig, player)
    if not Player.IsAnyEdith(player) then return end
    print(itemconfig:IsNull())
    print(itemconfig.Costume.Anm2Path)

    -- print(itemconfig.IsNull(), itemconfig.Name)
    -- print("aaaaaaaaaaaaaaaaa")
    -- if not Helpers.When(itemconfig.Costume.ID, ModCostumes, false) then return end
    return true
end
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_REMOVE_COSTUME, OnRemoveCostume)

mod:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, function(_, tear)
    local player = Helpers.GetPlayerFromTear(tear)

	if not player then return end
	if not Player.IsAnyEdith(player) then return end
	if tear.FrameCount ~= 1 then return end

	tear.Mass = tear.Mass * 10
end)

---@param player EntityPlayer
---@param flags DamageFlag
---@return boolean?
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, function(_, player, _, flags)
    local roomType = game:GetRoom():GetType()

    if not Player.IsAnyEdith(player) then return end
	if Maths.HasBitFlags(flags, DamageFlag.DAMAGE_ACID) or ((roomType ~= RoomType.ROOM_SACRIFICE or roomType ~= RoomType.ROOM_DEVIL) and Maths.HasBitFlags(flags, DamageFlag.DAMAGE_SPIKES)) then return false end
end)

---@param tear EntityTear
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, function(_, tear)
    local player = Helpers.GetPlayerFromTear(tear)

	if not player then return end
    if not Player.IsAnyEdith(player) then return end

    local isTainted = Player.IsEdith(player, true)
    local target = TargetArrow.GetEdithTarget(player)

	Helpers.ForceSaltTear(tear, isTainted)

    if isTainted then return end
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_MARKED) then return end	
	if not target then return end

    tear.Velocity = -((tear.Position - target.Position):Normalized()):Resized(player.ShotSpeed * 10)
end)

---@param player EntityPlayer
---@return NullItemID?
local function GetEdithCostume(player)
    local Vestige = Helpers.IsVestigeChallenge()
    local Grudge = Helpers.IsGrudgeChallenge()

    local isEdith = Player.IsEdith

    return (
        (isEdith(player, false) and (Vestige and costumes.EDITH_VESTIGE or costumes.EDITH)) or
        (isEdith(player, true) and (Grudge and costumes.T_EDITH_GRUDGE or costumes.T_EDITH)) --[[@as NullItemID]]
    )
end

local ReloadCostumeItem = {
    [CollectibleType.COLLECTIBLE_D4] = true,
    [CollectibleType.COLLECTIBLE_D100] = true,
}

---@param ID CollectibleType
---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, ID, _, player)
    if not ReloadCostumeItem[ID] then return end

    local Costume = GetEdithCostume(player)    
    if not Costume then return end
    player:AddNullCostume(Costume)
end)

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function()
	local pool = game:GetItemPool()

	for _, player in ipairs(PlayerManager.GetPlayers()) do
		if Player.IsAnyEdith(player) then		
			pool:RemoveCollectible(CollectibleType.COLLECTIBLE_NIGHT_LIGHT)
			pool:RemoveCollectible(CollectibleType.COLLECTIBLE_MONTEZUMAS_REVENGE)
		end
	end
end)

---@param player EntityPlayer
---@param grid GridEntity
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_GRID_COLLISION, function(_, player, _, grid)
	if not Player.IsAnyEdith(player) then return end
    if grid:GetType() ~= GridEntityType.GRID_ROCK_SPIKED then return end
	return true
end)