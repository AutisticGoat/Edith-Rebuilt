local mod = EdithRebuilt
local enums = mod.Enums
local costumes = enums.NullItemID
local utils = enums.Utils
local tables = enums.Tables
local game = utils.Game
local JumpParams = tables.JumpParams
local modules = mod.Modules
local EdithMod = modules.EDITH
local Land = modules.LAND
local TargetArrow = modules.TARGET_ARROW
local effects = modules.STATUS_EFFECTS
local helpers = modules.HELPERS
local Player = modules.PLAYER
local ModRNG = modules.RNG
local params = EdithMod.GetJumpStompParams
local Edith = {}

---@param player EntityPlayer
function Edith:EdithInit(player)
	if not Player.IsEdith(player, false) then return end
	Player.SetNewANM2(player, "gfx/EdithAnim.anm2")
	local isVestige = helpers.IsVestigeChallenge()
	local costume = isVestige and costumes.ID_EDITH_VESTIGE_SCARF or costumes.ID_EDITH_SCARF

	player:AddNullCostume(costume)
	Player.SetChallengeSprite(player, Isaac.GetChallenge())
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, Edith.EdithInit)

---@param player EntityPlayer
local function EdithTeleportManager(player)
	if not player:GetSprite():IsPlaying("TeleportDown") then return end
	JumpLib:QuitJump(player)
	TargetArrow.RemoveEdithTarget(player, false)
end

---@param player EntityPlayer
function Edith:OnEdithUpdate(player)
	if not Player.IsEdith(player, false) then return end
	if player:IsDead() then TargetArrow.RemoveEdithTarget(player) return end

	if player.FrameCount == 0 and helpers.GetConfigData("EdithData").SaltShakerSlot == 1 then
		player:RemoveCollectible(enums.CollectibleType.COLLECTIBLE_SALTSHAKER)
		player:SetPocketActiveItem(enums.CollectibleType.COLLECTIBLE_SALTSHAKER, ActiveSlot.SLOT_POCKET, false)
	end

	local isMoving = TargetArrow.IsEdithTargetMoving(player)
	local isKeyStompPressed = helpers.IsKeyStompPressed(player)
	local hasMarked = player:HasCollectible(CollectibleType.COLLECTIBLE_MARKED)
	local isShooting = Player.IsPlayerShooting(player)
	local jumpData = JumpLib:GetData(player)
	local isPitfall = JumpLib:IsPitfalling(player)
	local isJumping = EdithMod.IsJumping(player)
	local IsVestige = helpers.IsVestigeChallenge() 
	local jumpParams = params(player)

	if player.FrameCount > 0 and (isMoving or isKeyStompPressed or (hasMarked and isShooting)) and not isPitfall and not jumpData.Tags.EdithRebuilt_FlatStoneLand then
		TargetArrow.SpawnEdithTarget(player)
	end

	EdithTeleportManager(player)
	Player.ManageEdithWeapons(player)
	EdithMod.CustomDropBehavior(player, jumpData)
	EdithMod.DashItemBehavior(player)

	local target = TargetArrow.GetEdithTarget(player)
	if not target then return end

	EdithMod.TargetMovementManager(player, target, isMoving)
	EdithMod.JumpTriggerManager(player, jumpParams, isKeyStompPressed, isJumping, IsVestige)
	EdithMod.HeadDirectionManager(player, isJumping, isShooting, isKeyStompPressed)
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, Edith.OnEdithUpdate)

---@param player EntityPlayer
---@return boolean
local function IsInTrapdoor(player)
	local grid = game:GetRoom():GetGridEntityFromPos(player.Position)
	return grid and grid:GetType() == GridEntityType.GRID_TRAPDOOR or false
end	

---@param player EntityPlayer
function Edith:OnStartingJump(player)
	local jumpParams = params(player)
	jumpParams.JumpStartPos = player.Position
	jumpParams.JumpStartDist = TargetArrow.GetEdithTargetDistance(player)

	if not player:HasCollectible(CollectibleType.COLLECTIBLE_LUMP_OF_COAL) then return end
	local rng = player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_LUMP_OF_COAL)
	jumpParams.CoalBonus = ModRNG.RandomFloat(rng, 0.5, 0.6) * TargetArrow.GetEdithTargetDistance(player) / 40
end
mod:AddCallback(JumpLib.Callbacks.POST_ENTITY_JUMP, Edith.OnStartingJump, JumpParams.EdithJump)

---@param player EntityPlayer
---@param pitfall boolean
function Edith:OnEdithLanding(player, _, pitfall)
	local edithTarget = TargetArrow.GetEdithTarget(player)
	local jumpParams = params(player)

	if not edithTarget then return end

	if pitfall then
		TargetArrow.RemoveEdithTarget(player)
		return
	end

	if helpers.IsVestigeChallenge() then
		player:PlayExtraAnimation("BigJumpFinish")
	end

	if not IsInTrapdoor(player) then
		Land.LandFeedbackManager(player, Land.GetLandSoundTable(false), player.Color, false)
	end

	EdithMod.StompDamageManager(player, jumpParams)
	EdithMod.StompKnockbackManager(player, jumpParams)
	EdithMod.StompRadiusManager(player, jumpParams)
	EdithMod.StompCooldownManager(player, jumpParams)
	EdithMod.BombStompManager(player, jumpParams)

	edithTarget:GetSprite():Play("Idle")

	Land.EdithStomp(player, jumpParams, true)
	Land.TriggerLandenemyJump(jumpParams, 8, 2)

	player:SetMinDamageCooldown(25)
	player:MultiplyFriction(0.1)

	jumpParams.RocketLaunch = false	

	EdithMod.StompTargetRemover(player, jumpParams)
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, Edith.OnEdithLanding, JumpParams.EdithJump)

---@param npc EntityNPC
local function OnNPCUpdate(_, npc)
	local jumpData = JumpLib:GetData(npc)

	if not jumpData.Jumping then return end
	if not effects.EntHasStatusEffect(npc, "Salted") and npc.HitPoints <= 0 then return end
	if jumpData.Tags.EdithRebuilt_EnemyJump then return true end
end
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, OnNPCUpdate)

---@param player EntityPlayer
function Edith:OnEdithPEffectUpdate(player)
	if not Player.IsEdith(player, false) then return end
	local jumpParams = params(player)

	if jumpParams.RocketLaunch then return end
	EdithMod.CooldownUpdate(player, jumpParams)
	EdithMod.JumpMovement(player)
end
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, Edith.OnEdithPEffectUpdate)

---@param player EntityPlayer
---@param jumpdata JumpData
function Edith:OnEdithJump60Update(player, jumpdata)
	local jumpIntData = JumpLib.Internal:GetData(player)
	local jumpParams = params(player)

	EdithMod.DefensiveStompManager(player, jumpIntData, jumpParams)
	EdithMod.FallBehavior(player, jumpdata, jumpParams)
	EdithMod.BombFall(player, jumpdata, jumpParams)
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_UPDATE_60, Edith.OnEdithJump60Update, JumpParams.EdithJump)

function Edith:EdithOnNewRoom()
	for _, player in pairs(PlayerManager.GetPlayers()) do
		if not Player.IsEdith(player, false) then goto Break end
		helpers.ChangeColor(player, _, _, _, 1)
		TargetArrow.RemoveEdithTarget(player)
		params(player).CanJump = false
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
	local player = helpers.GetPlayerFromRef(source)

	if not player then return end
	if not Player.IsEdith(player, false) then return end
	if not JumpLib:GetData(player).Jumping then return end  
	local HasHeels = player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_HEELS)

	if not (familiar or (HasHeels and damage == 12)) then return end
	return false
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, Edith.DamageStuff)

---@param player EntityPlayer
function Edith:EdithRender(player)
	local sprite = player:GetSprite()
	local grid = game:GetRoom():GetGridEntityFromPos(player.Position)

	if not grid then return end

	local trapdoor = grid:ToTrapDoor()

	if not trapdoor then return end

	local trapdoorSprite = trapdoor:GetSprite():GetLayer(0):GetSpritesheetPath()
	IsFleshTrapdoor = string.find(trapdoorSprite, "womb") ~= nil or string.find(trapdoorSprite, "corpse") ~= nil

	if not IsFleshTrapdoor then return end
	if not Player.IsEdith(player, false) then return end
	if not sprite:IsPlaying("Trapdoor") then return end
	if sprite:GetFrame() ~= 8 then return end

	game:StartStageTransition(false, 0, player)
end
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_RENDER, Edith.EdithRender)

---@param ID CollectibleType
---@param player EntityPlayer
function Edith:OnActiveItemRemoveTarget(ID, _, player)
	if not helpers.When(ID, tables.RemoveTargetItems, false) then return end
	TargetArrow.RemoveEdithTarget(player)
end
mod:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, Edith.OnActiveItemRemoveTarget)

---@param ID CollectibleType
---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, function (_, ID, _, player)
	if ID ~= CollectibleType.COLLECTIBLE_KAMIKAZE then return end
	if not Player.IsEdith(player, false) then return end
	if not EdithMod.IsJumping(player) then return end

	return true
end)

---@param bomb EntityBomb
function Edith:OnBombExplode(bomb)
	if not bomb:GetSprite():IsPlaying("Explode") then return end
	local player 
	for _, ent in ipairs(Isaac.FindInRadius(bomb.Position, helpers.GetBombRadiusFromDamage(bomb.ExplosionDamage), EntityPartition.PLAYER)) do
		player = ent:ToPlayer() ---@cast player EntityPlayer
		if not Player.IsEdith(player, false) then goto continue end
		EdithMod.ExplosionRecoil(player, params(player), bomb)
		::continue::
	end
end
mod:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, Edith.OnBombExplode)

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function()
	local pool = game:GetItemPool()

	for _, player in ipairs(PlayerManager.GetPlayers()) do
		if Player.IsAnyEdith(player) then		
			pool:RemoveCollectible(CollectibleType.COLLECTIBLE_GNAWED_LEAF)
			pool:RemoveCollectible(CollectibleType.COLLECTIBLE_NIGHT_LIGHT)
		end
	end
end)