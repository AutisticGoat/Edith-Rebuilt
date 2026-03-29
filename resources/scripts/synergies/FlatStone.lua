local mod = EdithRebuilt
local modules = mod.Modules
local Land = modules.LAND
local EdithMod = modules.EDITH
local TEdithMod = modules.TEDITH
local TargetArrow = modules.TARGET_ARROW
local Player = modules.PLAYER

-- La lógica de FlatStone difiere sustancialmente entre parry y stomp:
--   Parry:  IsEdith(true), multiplier 1.6, llama ParryLandManager
--   Stomp:  IsEdith(false), multiplier 1.4, llama EdithStomp + TriggerLandenemyJump,
--           además verifica IsDefensiveStomp y aplica un Mult de daño previo

-- ── Primer ENTITY_LAND: dispara los mini-saltos ──────────────────────────────

---@param player EntityPlayer
---@param JumpData JumpData
local function ParryFlatStoneMiniJumps(_, player, JumpData)
    if not Player.IsEdith(player, true) then return end
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_FLAT_STONE) then return end
    if JumpData.Tags.EdithRebuilt_FlatStoneLand then return end

    Land.TriggerFlatStoneMiniJumps(player, 7, 1.6)
    TargetArrow.RemoveEdithTarget(player)
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, ParryFlatStoneMiniJumps, mod.Enums.Tables.JumpParams.TEdithJump)

---@param player EntityPlayer
---@param JumpData JumpData
local function StompFlatStoneMiniJumps(_, player, JumpData)
    if not Player.IsEdith(player, false) then return end

    local params = EdithMod.GetJumpStompParams(player)

    if params.IsDefensiveStomp then return end
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_FLAT_STONE) then return end
    if JumpData.Tags.EdithRebuilt_FlatStoneLand then return end

    Land.TriggerFlatStoneMiniJumps(player, 7, 1.6)
    TargetArrow.RemoveEdithTarget(player)
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, StompFlatStoneMiniJumps, mod.Enums.Tables.JumpParams.EdithJump)

-- ── Segundo ENTITY_LAND (tag): ejecuta el aterrizaje del mini-salto ───────────

---@param ent Entity
---@param data JumpData
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, function(_, ent, data, pitfall)
    local player = ent:ToPlayer()
    if not player then return end
    if not Player.IsEdith(player, true) then return end

    Land.LandFeedbackManager(player, Land.GetLandSoundTable(true, true), player.Color)
    Land.ParryLandManager(player, TEdithMod.GetHopParryParams(player), true)
    player:MultiplyFriction(0.05)
end, {tag = "EdithRebuilt_FlatStoneLand_Parry"})

---@param ent Entity
---@param data JumpData
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, function(_, ent, data, pitfall)
    local player = ent:ToPlayer()
    if not player then return end
    if not Player.IsEdith(player, false) then return end

    local params = EdithMod.GetJumpStompParams(player)
    local mult = Player.PlayerHasBirthright(player) and 0.9 or 0.75

    params.Damage = params.Damage * mult
    Land.LandFeedbackManager(player, Land.GetLandSoundTable(false, false), player.Color)
    Land.EdithStomp(player, params, true)
    Land.TriggerLandenemyJump(player, params.StompedEntities, params.Knockback, 6, 1.5)
    player:MultiplyFriction(0.05)
end, {tag = "EdithRebuilt_FlatStoneLand"})
