local mod = EdithRebuilt
local enums = mod.Enums
local challenges = enums.Challenge
local misc = enums.Misc
local players = enums.PlayerType
local maths = require("resources.scripts.functions.Maths")
local Helpers = require("resources.scripts.functions.Helpers")
local player = {}

---@param player EntityPlayer
---@param challenge Challenge
function player.SetChallengeSprite(player, challenge)
	if challenge == Challenge.CHALLENGE_NULL then return end

	local sprite = (
		challenge == challenges.CHALLENGE_GRUDGE and misc.GrudgeSpritePath or 
		challenge == challenges.CHALLENGE_VESTIGE and misc.VestigeSpritePath
	)

	if not sprite then return end

	for i = 0, 14 do
		player:GetSprite():ReplaceSpritesheet(i, sprite, true)
	end
end


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

---@param p EntityPlayer
---@return integer
function player.GetNumTears(p)
	return p:GetMultiShotParams(WeaponType.WEAPON_TEARS):GetNumTears()
end

---@param player EntityPlayer
function player.PlayerHasBirthright(player)
	return player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)
end

---@param player EntityPlayer
function player.ManageEdithWeapons(player)
	local weapon = player:GetWeapon(1)

	if not weapon then return end

	local weaponType = weapon:GetWeaponType()

	if not Helpers.When(weaponType, enums.Tables.OverrideWeapons, false) then return end

	local newWeapon = Isaac.CreateWeapon(WeaponType.WEAPON_TEARS, player)
	Isaac.DestroyWeapon(weapon)

	if weaponType == WeaponType.WEAPON_LUDOVICO_TECHNIQUE then return end

	player:EnableWeaponType(WeaponType.WEAPON_TEARS, true)
	player:SetWeapon(newWeapon, 1)	
end

---Changes `player`'s ANM2 file
---@param player EntityPlayer
---@param FilePath string
function player.SetNewANM2(player, FilePath)
	local playerSprite = player:GetSprite()

	if not (playerSprite:GetFilename() ~= FilePath and not player:IsCoopGhost()) then return end
	playerSprite:Load(FilePath, true)
	playerSprite:Update()
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
	return p:GetPlayerType() == PlayerType.PLAYER_JUDAS and player.PlayerHasBirthright(p)
end

---@param p EntityPlayer
---@return boolean
function player.HasTanukiStatueEffect(p)
---@diagnostic disable-next-line: undefined-field
	return p:GetGnawedLeafTimer() >= 60
end

---@param p EntityPlayer
---@param tainted boolean
function player.SetCustomSprite(p, tainted)
	player.SetChallengeSprite(p, Isaac.GetChallenge())	

	if not Helpers.IsModChallenge() then return end

	local costumeDesc = p:GetCostumeSpriteDescs()[1]
	local hoodPath = tainted and enums.Misc.GrudgeHoodPath or enums.Misc.VestigeHoodPath

	costumeDesc:GetSprite():ReplaceSpritesheet(0, hoodPath, true)
end

return player