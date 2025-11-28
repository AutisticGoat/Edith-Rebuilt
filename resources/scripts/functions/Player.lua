local mod = EdithRebuilt
local enums = mod.Enums
local players = enums.PlayerType
local maths = require("resources.scripts.functions.Maths")
local data = mod.CustomDataWrapper.getData

local player = {}

---Checks if player is Edith
---@param player EntityPlayer
---@param tainted boolean set it to `true` to check if player is Tainted Edith
---@return boolean
function player.IsEdith(player, tainted)
	return player:GetPlayerType() == (tainted and players.PLAYER_EDITH_B or players.PLAYER_EDITH)
end

---Checks if any player is Edith
---@param p EntityPlayer
---@return boolean
function player.IsAnyEdith(p)
	return player.IsEdith(p, true) or player.IsEdith(p, false)
end

---@param player EntityPlayer
function player.PlayerHasBirthright(player)
	return player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)
end

---Forcefully adds a costume for a character
---@param player EntityPlayer
---@param playertype PlayerType
---@param costume integer
function player.ForceCharacterCostume(player, playertype, costume)
	local playerData = data(player)

	playerData.HasCostume = {}
	local hasCostume = playerData.HasCostume[playertype] or false

	
	-- local isCurrentPlayerType = player:GetPlayerType() == playertype

	-- if isCurrentPlayerType then
	-- 	if not hasCostume then
	-- 		player:AddNullCostume(costume)
	-- 		playerData.HasCostume[playertype] = true
	-- 	end
	-- else
	-- 	if hasCostume then
	-- 		player:TryRemoveNullCostume(costume)
	-- 		playerData.HasCostume[playertype] = false
	-- 	end
	-- end
end

---Helper function for Edith's cooldown color manager
---@param player EntityPlayer
---@param intensity number
---@param duration integer
function player.SetColorCooldown(player, intensity, duration)
	local pcolor = player.Color
	local col = pcolor:GetColorize()
	local tint = pcolor:GetTint()
	local off = pcolor:GetOffset()
	local Red = off.R + (intensity + ((col.R + tint.R) * 0.2))
	local Green = off.G + (intensity + ((col.G + tint.G) * 0.2))
	local Blue = off.B + (intensity + ((col.B + tint.B) * 0.2))
		
	pcolor:SetOffset(Red, Green, Blue)
	player:SetColor(pcolor, duration, 100, true, false)
end

---Helper tears stat manager function
---@param firedelay number
---@param val number
---@param mult? boolean
---@return number
function player.tearsUp(firedelay, val, mult)
    local currentTears = 30 / (firedelay + 1)
    local newTears = mult and (currentTears * val) or currentTears + val
    return math.max((30 / newTears) - 1, -0.75)
end

---Helper range stat manager function
---@param range number
---@param val number
---@return number
function player.rangeUp(range, val)
    local currentRange = range / 40.0
    local newRange = currentRange + val
    return math.max(1.0, newRange) * 40.0
end

---Returns player's range stat as portrayed in Game's stat HUD
---@param player EntityPlayer
---@return number
function player.GetPlayerRange(player)
	return player.TearRange / 40
end

---Returns player's tears stat as portrayed in game's stats HUD
---@param p EntityPlayer
---@return number
function player.GetplayerTears(p)
    return maths.Round(30 / (p.MaxFireDelay + 1), 2)
end

---Checks if player is shooting by checking if shoot inputs are being pressed
---@param p EntityPlayer
---@return boolean
function player.IsPlayerShooting(p)
	local shoot = {
        l = Input.IsActionPressed(ButtonAction.ACTION_SHOOTLEFT, p.ControllerIndex),
        r = Input.IsActionPressed(ButtonAction.ACTION_SHOOTRIGHT, p.ControllerIndex),
        u = Input.IsActionPressed(ButtonAction.ACTION_SHOOTUP, p.ControllerIndex),
        d = Input.IsActionPressed(ButtonAction.ACTION_SHOOTDOWN, p.ControllerIndex)
    }
	return (shoot.l or shoot.r or shoot.u or shoot.d)
end

---Used to add some interactions to Judas' Birthright effect
---@param p EntityPlayer
function player.IsJudasWithBirthright(p)
	return p:GetPlayerType() == PlayerType.PLAYER_JUDAS and mod.PlayerHasBirthright(p)
end

return player