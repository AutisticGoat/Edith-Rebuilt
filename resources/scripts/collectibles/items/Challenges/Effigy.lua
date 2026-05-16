local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local tables = enums.Tables
local jumpTags = tables.JumpTags
local modules = mod.Modules
local EdithMod = modules.EDITH
local Helpers = modules.HELPERS
local Jump = modules.JUMP
local BitMask = modules.BIT_MASK
local Maths = modules.MATHS
local TargetArrow = modules.TARGET_ARROW
local Player = modules.PLAYER
local Land = modules.LAND
local sfx = enums.Utils.SFX
local data = mod.DataHolder.GetEntityData

---@param player EntityPlayer
local function GetEffigyState(player)
    local EffigySlot = player:GetActiveItemSlot(items.COLLECTIBLE_EFFIGY)

    if EffigySlot == -1 then return 0 end

    return player:GetActiveItemDesc(EffigySlot).VarData
end

---@param entity Entity
---@param input InputHook
---@param action ButtonAction|KeySubType
---@return integer|boolean?
mod:AddCallback(ModCallbacks.MC_INPUT_ACTION, function(_, entity, input, action)
    if not entity then return end

    local player = entity:ToPlayer()

    if not player then return end
    if GetEffigyState(player) == 0 then return end
    if not data(player).EffigyHopCooldown then return end
    if data(player).EffigyHopCooldown <= 0 then return end
    if input ~= InputHook.GET_ACTION_VALUE then return end

    return tables.OverrideActions[action]
end)


---@param player EntityPlayer
local function IsLilith(player)
    local type = player:GetPlayerType()
    return type == PlayerType.PLAYER_LILITH or type == PlayerType.PLAYER_LILITH_B
end 

---@param player EntityPlayer
---@param VarData integer
local function UpdateShotCapacity(player, VarData)
    if IsLilith(player) then return end
    player:SetCanShoot(VarData == 1)
end

---@param player EntityPlayer
---@param VarData integer
local function EffigyCostumeManager(player, VarData)
    if VarData == 0 then
        player:AddNullCostume(enums.NullItemID.EDITH)
    elseif VarData == 1 then
        player:TryRemoveNullCostume(enums.NullItemID.EDITH)
    end
end

---@param player EntityPlayer
---@param VarData integer
local function ChangeEffigyState(player, VarData, slot)
    player:SetActiveVarData(VarData == 0 and 1 or 0, slot)
    UpdateShotCapacity(player, VarData)
    EffigyCostumeManager(player, VarData)

    return VarData
end

---@param jumpData JumpData
---@return boolean
local function IsEffigyJump(jumpData)
    return Jump.IsSpecificJump(jumpData, jumpTags.EffigyHop) or Jump.IsSpecificJump(jumpData, jumpTags.EffigyJump)
end

local function ManageEffigyBigJump(player)
    if not Helpers.IsKeyStompTriggered(player) then return end
    if data(player).EffigyJumpCooldown > 0 then return end

    Jump.InitEdithJump(player, jumpTags.EffigyJump, true)
end

---@param player EntityPlayer
local function ManageEffigyHop(player)
    if not TargetArrow.IsEdithTargetMoving(player) then return end
    if data(player).EffigyHopCooldown > 0 then return end

    Jump.InitEdithJump(player, jumpTags.EffigyHop, false)
end

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function(_, player)
    if GetEffigyState(player) == 0 then return end
    if Jump.IsJumping(player) then return end

    ManageEffigyHop(player)
    ManageEffigyBigJump(player)
end)

---@param player EntityPlayer
---@param flag UseFlag
---@param slot ActiveSlot
mod:AddCallback(ModCallbacks.MC_USE_ITEM, function (_, _, _, player, flag, slot)
    if BitMask.HasBitFlags(flag, UseFlag.USE_CARBATTERY --[[@as BitSet128]]) then return end

    local varData = ChangeEffigyState(player, player:GetActiveItemDesc(slot).VarData, slot)
    EffigyCostumeManager(player, varData)

    player:SetMinDamageCooldown(30)
    return true
end, items.COLLECTIBLE_EFFIGY)

---@param player EntityPlayer
---@param jumpParams EdithJumpStompParams
---@param jumpData JumpData
local function EffigyHopLand(player, jumpParams, jumpData)
    if not Jump.IsSpecificJump(jumpData, jumpTags.EffigyHop) then return end

    jumpParams.Damage = player.Damage * 3
    jumpParams.Knockback = 30
    jumpParams.Radius = 40
end

---@param player EntityPlayer
---@param jumpParams EdithJumpStompParams
---@param jumpData JumpData
local function EffigyJumpLand(player, jumpParams, jumpData)
    if not Jump.IsSpecificJump(jumpData, jumpTags.EffigyJump) then return end

    jumpParams.Damage = (player.Damage * 10) + 15
    data(player).EffigyJumpCooldown = 240
end

---@param player EntityPlayer
---@param jumpParams EdithJumpStompParams
---@param jumpData JumpData
local function EffigyGeneralLand(player, jumpParams, jumpData)
    Land.LandFeedbackManager(player, Land.GetLandSoundTable(false), player.Color, jumpData)
    Land.EdithStomp(player, jumpParams, true)
    player:MultiplyFriction(0.1)
    player:SetMinDamageCooldown(20)
    data(player).EffigyHopCooldown = 15
end

---@param entity Entity
---@param jumpData JumpData
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, function (_, entity, jumpData)
    if not IsEffigyJump(jumpData) then return end

    local player = entity:ToPlayer()
    if not player then return end

    local jumpParams = EdithMod.GetJumpStompParams(player)

    EffigyHopLand(player, jumpParams, jumpData)
    EffigyJumpLand(player, jumpParams, jumpData)
    EffigyGeneralLand(player, jumpParams, jumpData)
end)

---@param pData table
local function EffigyJumpCooldownManager(pData)
    if not pData.EffigyJumpCooldown then return end
    pData.EffigyJumpCooldown = math.max(pData.EffigyJumpCooldown - 1, 0)
end

local function EffigyHopCooldownManager(pData)
    if not pData.EffigyHopCooldown then return end
    pData.EffigyHopCooldown = math.max(pData.EffigyHopCooldown - 1, 0)
end

---@param player EntityPlayer
---@param pData table
local function HopCooldownIndicator(player, pData)
    if not pData.EffigyHopCooldown then return end
    if pData.EffigyHopCooldown ~= 1 then return end

    Player.SetColorCooldown(player, -0.8, 5)
    sfx:Play(SoundEffect.SOUND_BEEP)
end

---@param player EntityPlayer
---@param pData table
local function JumpCooldownIndicator(player, pData)
    if not pData.EffigyJumpCooldown then return end
    if pData.EffigyJumpCooldown > 0 then return end

    pData.EffigyJumpBlink = pData.EffigyJumpBlink or 0
    pData.EffigyJumpBlink = Maths.Clamp(pData.EffigyJumpBlink + 1, 0, 20)

    if pData.EffigyJumpBlink == 20 then
        Player.SetColorCooldown(player, 0.5, 5)
        pData.EffigyJumpBlink = 0
    end
end

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
    if GetEffigyState(player) == 0 then return end

    local pData = data(player)

    JumpCooldownIndicator(player, pData)
    EffigyJumpCooldownManager(pData)
    EffigyHopCooldownManager(pData)
    HopCooldownIndicator(player, pData)
end)

---@param ent Entity
---@param jumpData JumpData
mod:AddCallback(JumpLib.Callbacks.ENTITY_UPDATE_60, function (_, ent, jumpData)
    if not Jump.IsSpecificJump(jumpData, jumpTags.EffigyHop) then return end

    ent.Velocity = ent.Velocity * 1.05
end)

---@param first boolean
---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_ADD_COLLECTIBLE, function (_, _, _, first, _, _, player)
    if not first then return end
    local pData = data(player)

    pData.EffigyJumpCooldown = 0
    pData.EffigyHopCooldown = 0
    pData.BigJumpUses = 0
end, items.COLLECTIBLE_EFFIGY)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_TRIGGER_COLLECTIBLE_REMOVED, function (_, player)
    player:TryRemoveNullCostume(enums.NullItemID.EDITH)
end, items.COLLECTIBLE_EFFIGY)

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function ()
    for _, player in ipairs(PlayerManager.GetPlayers()) do
        local effigySlot = player:GetActiveItemSlot(items.COLLECTIBLE_EFFIGY)
        local VarData = player:GetActiveItemDesc(effigySlot).VarData

        if effigySlot == -1 then goto continue end
        if GetEffigyState(player) ~= 1 then goto continue end

        ChangeEffigyState(player, VarData, effigySlot)

        ::continue::
    end
end)    