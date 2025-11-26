local mod = EdithRebuilt
local enums = mod.Enums
local players = enums.PlayerType
local costumes = enums.NullItemID
local utils = enums.Utils
local tables = enums.Tables
local game = utils.Game 
local JumpParams = tables.JumpParams
local EdithMod = include("resources.scripts.functions.Edith")
local Land = include("resources.scripts.functions.Land")
local helpers = include("resources.scripts.functions.Helpers")
local params = EdithMod.GetJumpStompParams
local Edith = {}

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
function Edith:OnEdithUpdate(player)
	if not mod.IsEdith(player, false) then return end
	if player:IsDead() then mod.RemoveEdithTarget(player) return end

	local isMoving = mod.IsEdithTargetMoving(player)
	local isKeyStompPressed = mod.IsKeyStompPressed(player)
	local hasMarked = player:HasCollectible(CollectibleType.COLLECTIBLE_MARKED)
	local isShooting = mod:IsPlayerShooting(player)
	local jumpData = JumpLib:GetData(player)
	local isPitfall = JumpLib:IsPitfalling(player)
	local isJumping = EdithMod.IsJumping(player)
	local IsVestige = helpers.IsVestigeChallenge() 
	local jumpParams = params(player)

	if player.FrameCount > 0 and (isMoving or isKeyStompPressed or (hasMarked and isShooting)) and not isPitfall then
		mod.SpawnEdithTarget(player)
	end

	EdithMod.ManageEdithWeapons(player)
	EdithMod.CustomDropBehavior(player, jumpData)
	EdithMod.DashItemBehavior(player)

	local target = mod.GetEdithTarget(player)
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
	jumpParams.JumpStartDist = mod.GetEdithTargetDistance(player)

	if not player:HasCollectible(CollectibleType.COLLECTIBLE_LUMP_OF_COAL) then return end
	local rng = player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_LUMP_OF_COAL)
	jumpParams.CoalBonus = mod.RandomFloat(rng, 0.5, 0.6) * mod.GetEdithTargetDistance(player) / 40
end
mod:AddCallback(JumpLib.Callbacks.POST_ENTITY_JUMP, Edith.OnStartingJump, JumpParams.EdithJump)

---@param player EntityPlayer
---@param pitfall boolean
function Edith:OnEdithLanding(player, _, pitfall)
	local edithTarget = mod.GetEdithTarget(player)
	local jumpParams = params(player)

	if not edithTarget then return end
	jumpParams.Jumps = math.max(jumpParams.Jumps - 1, 0)

	if pitfall then
		mod.RemoveEdithTarget(player)
		return
	end

	if not IsInTrapdoor(player) then
		Land.LandFeedbackManager(player, mod:GetLandSoundTable(false), player.Color, false)
	end

	EdithMod.StompDamageManager(player, jumpParams)
	EdithMod.StompKnockbackManager(player, jumpParams)
	EdithMod.StompRadiusManager(player, jumpParams)
	EdithMod.StompCooldownManager(player, jumpParams)
	EdithMod.StompTargetRemover(player, jumpParams)
	EdithMod.BombStompManager(player, jumpParams)

	player:SetMinDamageCooldown(25)
	player:MultiplyFriction(0.1)
	
	Land.EdithStomp(player, jumpParams, true)
	edithTarget:GetSprite():Play("Idle")

	jumpParams.RocketLaunch = false
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, Edith.OnEdithLanding, JumpParams.EdithJump)

---@param player EntityPlayer
function Edith:OnEdithPEffectUpdate(player)
	if not mod.IsEdith(player, false) then return end
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
		if not mod.IsEdith(player, false) then goto Break end
		mod:ChangeColor(player, _, _, _, 1)
		mod.RemoveEdithTarget(player)
		EdithMod.SetJumps(player, 0)
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

		EdithMod.ExplosionRecoil(player, params(player), bomb)

		::continue::
	end
end
mod:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, Edith.OnBombExplode)