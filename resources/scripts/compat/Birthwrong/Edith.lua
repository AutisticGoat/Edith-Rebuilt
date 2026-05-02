---@diagnostic disable: undefined-global
if not Birthwrong then return end

local mod = EdithRebuilt
local enums = mod.Enums
local modules = mod.Modules
local Helpers = modules.HELPERS
local Maths = modules.MATHS
local Status = modules.STATUS_EFFECTS
local Jump = modules.JUMP
local game = enums.Utils.Game
local saveManager = mod.SaveManager

Birthwrong.registerDescription(enums.PlayerType.PLAYER_EDITH, "Dissolution, flooded rooms", "algo debe de hacer luego lo voy a pensar")

---@param player EntityPlayer
---@param amount integer
local function AddToSpeedReductionCounter(player, amount)
    local runSave = saveManager.GetRunSave(player)
    if not runSave then return end

    runSave.SpeedReduction = math.max(runSave.SpeedReduction + amount, 0)
end

local waterAmount = 0

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function (_, player)
    local runSave = saveManager.GetRunSave(player)
    
    if not runSave then return end
    if not Birthwrong.hasCharacterBW(player, enums.PlayerType.PLAYER_EDITH) then return end

    runSave.SpeedReduction = runSave.SpeedReduction or 0

    if waterAmount < 1 then 
        waterAmount = math.min(waterAmount + 0.05, 1)
        game:GetRoom():SetWaterAmount(waterAmount)
        return 
    end

    if Jump.IsJumping(player) then return end
    if player.FrameCount % 20 ~= 0 then return end
    if Maths.Round(player.MoveSpeed, 2) == 0.1 then return end

    Helpers.SpawnSaltGib(player, 4, 2)

    player:SetCanShoot(player.MoveSpeed >= 0.7)

    AddToSpeedReductionCounter(player, 1)
    player:AddCacheFlags(CacheFlag.CACHE_SPEED, true)
end)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player)
    local runSave = saveManager.GetRunSave(player)

    if not runSave then return end
    if not Birthwrong.hasCharacterBW(player, enums.PlayerType.PLAYER_EDITH) then return end    

    player.MoveSpeed = player.MoveSpeed - (0.01 * runSave.SpeedReduction)
end, CacheFlag.CACHE_SPEED)

---@param player EntityPlayer
---@param ent Entity
mod:AddCallback(enums.Callbacks.OFFENSIVE_STOMP_KILL, function (_, player, ent)
    if not Birthwrong.hasCharacterBW(player, enums.PlayerType.PLAYER_EDITH) then return end
    if not Helpers.IsEnemy(ent) then return end
    if not Status.EntHasStatusEffect(ent, enums.EdithStatusEffects.SALTED) then return end
    AddToSpeedReductionCounter(player, -5)
    player:AddCacheFlags(CacheFlag.CACHE_SPEED, true)
end)

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function ()
    for _, player in ipairs(PlayerManager.GetPlayers()) do
        if not Birthwrong.hasCharacterBW(player, enums.PlayerType.PLAYER_EDITH) then goto continue end
        game:GetRoom():SetWaterAmount(1)
        ::continue::
    end
end)