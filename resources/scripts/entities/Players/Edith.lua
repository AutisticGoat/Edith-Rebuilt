local mod = EdithRebuilt
local enums = mod.Enums
local misc = enums.Misc
local players = enums.PlayerType
local costumes = enums.NullItemID
local utils = enums.Utils
local tables = enums.Tables
local level = utils.Level
local game = utils.Game 
local sfx = utils.SFX
local JumpParams = tables.JumpParams
local data = mod.CustomDataWrapper.getData
local VecDir = include("resources.scripts.functions.VecDir")
local Maths = include("resources.scripts.functions.Maths")
local EdithMod = include("resources.scripts.functions.Edith")
local params = EdithMod.GetJumpStompParams

local Edith = {}



--[[
	Desbloqueada por morir por una fuente de fuego
]]

---@param player EntityPlayer
---@param jumps integer
local function setEdithJumps(player, jumps)
	params(player).Jumps = jumps
end

---@param player EntityPlayer
---@return integer
local function GetNumTears(player)
	return player:GetMultiShotParams(WeaponType.WEAPON_TEARS):GetNumTears()
end

---@param player EntityPlayer
function Edith:EdithInit(player)
	if not mod.IsEdith(player, false) then return end
	mod.SetNewANM2(player, "gfx/EdithAnim.anm2")
	local isVestige = mod.IsVestigeChallenge()

	local costume = isVestige and costumes.ID_EDITH_VESTIGE_SCARF or costumes.ID_EDITH_SCARF

	mod.ForceCharacterCostume(player, players.PLAYER_EDITH, costume)

	if isVestige then
		for i = 0, 14 do
			player:GetSprite():ReplaceSpritesheet(i, "gfx/characters/costumes/characterEdithVestige.png", true)
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, Edith.EdithInit)

---@param player EntityPlayer
function Edith:EdithJumpHandler(player)
	if not mod.IsEdith(player, false) then return end

	local playerData = data(player)
	if player:IsDead() then mod.RemoveEdithTarget(player); playerData.isJumping = false return end

	local isMoving = mod.IsEdithTargetMoving(player)
	local isKeyStompPressed = mod.IsKeyStompPressed(player)
	local hasMarked = player:HasCollectible(CollectibleType.COLLECTIBLE_MARKED)
	local isShooting = mod:IsPlayerShooting(player)
	local jumpData = JumpLib:GetData(player)
	local isPitfall = JumpLib:IsPitfalling(player)
	local isJumping = jumpData.Jumping 
	local IsVestige = mod.IsVestigeChallenge() 
	local jumpparams = params(player)

	playerData.isJumping = playerData.isJumping or false
	playerData.ExtraJumps = playerData.ExtraJumps or 0

	-- print(JumpLib:IsFalling(player))

	if player.FrameCount > 0 and (isMoving or isKeyStompPressed or (hasMarked and isShooting)) and not isPitfall then
		mod.SpawnEdithTarget(player)
	end

	mod.ManageEdithWeapons(player)
	mod.CustomDropBehavior(player, jumpData)
	mod.DashItemBehavior(player)

	-- print(jumpparams.Jumps)

	local target = mod.GetEdithTarget(player)
	if not target then return end

	EdithMod.TargetMovementManager(player, target, isMoving)

	if isKeyStompPressed and not isJumping and not IsVestige then
		setEdithJumps(player, GetNumTears(player))
	end

	if jumpparams.Cooldown == 0 and jumpparams.Jumps > 0 and not isJumping and not IsVestige then
		mod.InitEdithJump(player)
		playerData.isJumping = true
	end

	
	
	local dir = mod.GetEdithTargetDistance(player) <= 5 and Direction.DOWN or VecDir.VectorToDirection(mod.GetEdithTargetDirection(player))
	
	if not (isJumping or (not isShooting) or (isKeyStompPressed)) then return end
	player:SetHeadDirection(dir, 1, true)
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, Edith.EdithJumpHandler)

---@param player EntityPlayer
---@return boolean
local function isNearTrapdoor(player)
	local room = game:GetRoom()
	local playerPos = player.Position
	local gent, GentType

	for i = 1, room:GetGridSize() do
		gent = room:GetGridEntity(i)

		if not gent then goto Break end
		GentType = gent:GetType()

		if GentType == GridEntityType.GRID_GRAVITY then return true end
		if not mod.When(GentType, tables.DisableLandFeedbackGrids, false) then
			return playerPos:Distance(gent.Position) <= 20
		end
		::Break::
	end
	return false
end

---@param player EntityPlayer
function Edith:OnStartingJump(player)
	data(player).JumpStartPos = player.Position
	data(player).JumpStartDist = mod.GetEdithTargetDistance(player)

	if not player:HasCollectible(CollectibleType.COLLECTIBLE_LUMP_OF_COAL) then return end
	local rng = player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_LUMP_OF_COAL)
	data(player).CoalBonus = mod.RandomFloat(rng, 0.5, 0.6) * mod.GetEdithTargetDistance(player) / 40
end
mod:AddCallback(JumpLib.Callbacks.POST_ENTITY_JUMP, Edith.OnStartingJump, JumpParams.EdithJump)

---@param player EntityPlayer
---@param pitfall boolean
function Edith:EdithLanding(player, _, pitfall)
	local playerData = data(player)
	local edithTarget = mod.GetEdithTarget(player)
	local jumpParams = params(player)

	if not edithTarget then return end
	jumpParams.Jumps = math.max(jumpParams.Jumps - 1, 0)

	if pitfall then
		mod.RemoveEdithTarget(player)
		playerData.isJumping = false
		return
	end

	if isNearTrapdoor(player) == false then
		mod.LandFeedbackManager(player, mod:GetLandSoundTable(false), player.Color, false)
	end

	EdithMod.StompDamageManager(player, jumpParams)
	EdithMod.StompKnockbackManager(player, jumpParams)
	EdithMod.StompRadiusManager(player, jumpParams)
	EdithMod.StompCooldownManager(player, jumpParams)
	EdithMod.StompTargetRemover(player, jumpParams)
	EdithMod.BombStompManager(player, jumpParams)

	player:SetMinDamageCooldown(25)

	print("================================")
	for k, v in pairs(jumpParams) do
		print(k, v)
	end

	mod:EdithStomp(player, jumpParams.Radius, jumpParams.Damage, jumpParams.Knockback, true)
	edithTarget:GetSprite():Play("Idle")

	-- if not mod.IsKeyStompPressed(player) and not mod.IsEdithTargetMoving(player) then
	-- 	if distance <= 5 and distance >= 60 then
	-- 		player.Position = edithTarget.Position
	-- 	end
	-- 	if playerData.ExtraJumps <= 0 then
	-- 		mod.RemoveEdithTarget(player)
	-- 	end
	-- end
	-- playerData.IsFalling = false

	playerData.isJumping = false
	playerData.RocketLaunch = false
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, Edith.EdithLanding, JumpParams.EdithJump)

---@param player EntityPlayer
function Edith:EdithPEffectUpdate(player)
	if not mod.IsEdith(player, false) then return end

	local playerData = data(player)
	local jumpparams = params(player)

	if jumpparams.RocketLaunch then return end

	jumpparams.Cooldown = math.max(jumpparams.Cooldown - 1, 0)

	if jumpparams.Cooldown == 1 and player.FrameCount > 20 then
		mod.SetColorCooldown(player, 0.6, 5)
		local EdithSave = mod.GetConfigData("EdithData") ---@cast EdithSave EdithData
		local soundTab = tables.CooldownSounds[EdithSave.JumpCooldownSound or 1]
		local pitch = soundTab.Pitch == 1.2 and (soundTab.Pitch * mod.RandomFloat(player:GetDropRNG(), 1, 1.1)) or soundTab.Pitch
		sfx:Play(soundTab.SoundID, 2, 0, false, pitch)
		jumpparams.StompedEntities = nil
		jumpparams.IsDefensiveStomp = false
	end

	if mod.IsVestigeChallenge() then return end
	if not mod.GetEdithTarget(player) then return end
	if not playerData.isJumping then return end

	local div = (mod.IsKeyStompPressed(player) and player.CanFly) and 70 or 50
	mod.EdithDash(player, mod.GetEdithTargetDirection(player, false), mod.GetEdithTargetDistance(player), div)
end
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, Edith.EdithPEffectUpdate)

---@param player EntityPlayer
---@param jumpdata JumpConfig
function Edith:EdithBomb(player, jumpdata)
	local jumpinternalData = JumpLib.Internal:GetData(player)
	local jumpParams = params(player)

	mod.FallBehavior(player)
	mod.BombFall(player, jumpdata)

	if not mod.IsKeyStompPressed(player) then return end
	if jumpinternalData.UpdateFrame ~= 9 then return end
	if mod.IsVestigeChallenge() then return end

	local CanFly = player.CanFly
	local HeightMult = CanFly and 0.8 or 0.65
	local JumpSpeed = CanFly and 1.2 or 1.5

	jumpParams.IsDefensiveStomp = true
	mod.SetColorCooldown(player, -0.8, 10)
	sfx:Play(SoundEffect.SOUND_STONE_IMPACT, 1, 0, false, 0.8)
	
	jumpinternalData.StaticHeightIncrease = jumpinternalData.StaticHeightIncrease * HeightMult
	jumpinternalData.StaticJumpSpeed = JumpSpeed
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_UPDATE_60, Edith.EdithBomb, JumpParams.EdithJump)

function Edith:EdithOnNewRoom()
	for _, player in pairs(PlayerManager.GetPlayers()) do
		if not mod.IsEdith(player, false) then goto Break end
		mod:ChangeColor(player, _, _, _, 1)
		mod.RemoveEdithTarget(player)
		setEdithJumps(player, 0)
		::Break::
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, Edith.EdithOnNewRoom)

---@param damage number
---@param source EntityRef
---@return boolean?
function Edith:DamageStuff(_, damage, _, source)
	if source.Type == 0 then return end
	local ent = source.Entity
	local familiar = ent:ToFamiliar()
	local player = mod.GetPlayerFromRef(source)

	if not player then return end
	if not mod.IsEdith(player, false) then return end
	if not JumpLib:GetData(player).Jumping then return end  
	local HasHeels = player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_HEELS)

	if not (familiar or (HasHeels and damage == 12)) then return end
	return false
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, Edith.DamageStuff)

---@param ID CollectibleType
---@param player EntityPlayer
function Edith:OnActiveItemRemoveTarget(ID, _, player)
	if not mod.When(ID, tables.RemoveTargetItems, false) then return end
	mod.RemoveEdithTarget(player)
end
mod:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, Edith.OnActiveItemRemoveTarget)

---@param bomb EntityBomb
function Edith:OnBombExplode(bomb)
	if not bomb:GetSprite():IsPlaying("Explode") then return end
	local player 
	for _, ent in ipairs(Isaac.FindInRadius(bomb.Position, mod.GetBombRadiusFromDamage(bomb.ExplosionDamage), EntityPartition.PLAYER)) do
		player = ent:ToPlayer() ---@cast player EntityPlayer

		if not mod.IsEdith(player, false) then goto continue end
		if not data(player).isJumping then goto continue end

		mod.ExplosionRecoil(player, bomb)

		::continue::
	end
end
mod:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, Edith.OnBombExplode)