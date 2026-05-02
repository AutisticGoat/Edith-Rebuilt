local mod = EdithRebuilt
local enums = mod.Enums
local players = enums.PlayerType
local achievements = enums.Achievements
local utils = enums.Utils
local game = utils.Game
local level = utils.Level
local Helpers = mod.Modules.HELPERS
local UnlockTable = {
    Edith = {
        [CompletionType.MOMS_HEART] = {
            Unlock = achievements.ACHIEVEMENT_GEODE,
            Difficulty = Difficulty.DIFFICULTY_HARD,
        },
        [CompletionType.ISAAC] = {
            Unlock = achievements.ACHIEVEMENT_SALT_SHAKER,
            Difficulty = Difficulty.DIFFICULTY_HARD,
        },
        [CompletionType.SATAN] = {
            Unlock = achievements.ACHIEVEMENT_SULFURIC_FIRE,
            Difficulty = Difficulty.DIFFICULTY_HARD,
        },
        [CompletionType.BOSS_RUSH] = {
            Unlock = achievements.ACHIEVEMENT_RUMBLING_PEBBLE,
            Difficulty = Difficulty.DIFFICULTY_HARD,
        },
        [CompletionType.BLUE_BABY] = {
            Unlock = achievements.ACHIEVEMENT_PEPPER_GRINDER,
            Difficulty = Difficulty.DIFFICULTY_HARD,
        },
        [CompletionType.LAMB] = {
            Unlock = achievements.ACHIEVEMENT_FAITH_OF_THE_UNFAITHFUL,
            Difficulty = Difficulty.DIFFICULTY_HARD,
        },
        [CompletionType.MEGA_SATAN] = {
            Unlock = achievements.ACHIEVEMENT_MOLTEN_CORE,
            Difficulty = Difficulty.DIFFICULTY_HARD,
        },
        [CompletionType.ULTRA_GREED] = {
            Unlock = achievements.ACHIEVEMENT_HYDRARGYRUM,
            Difficulty = Difficulty.DIFFICULTY_GREED,
        },
        [CompletionType.HUSH] = {
            Unlock = achievements.ACHIEVEMENT_SAL,
            Difficulty = Difficulty.DIFFICULTY_HARD,
        },
        [CompletionType.DELIRIUM] = {
            Unlock = achievements.ACHIEVEMENT_SPICES_MIX,
            Difficulty = Difficulty.DIFFICULTY_HARD,
        },
        [CompletionType.MOTHER] = {
            Unlock = achievements.ACHIEVEMENT_DIVINE_RETRIBUTION,
            Difficulty = Difficulty.DIFFICULTY_HARD,
        },
        [CompletionType.BEAST] = {
            Unlock = achievements.ACHIEVEMENT_EDITHS_HOOD,
            Difficulty = Difficulty.DIFFICULTY_HARD,
        },
    },
    TEdith = {
        [CompletionType.MEGA_SATAN] = {
            Unlock = achievements.ACHIEVEMENT_SALT_ROCKS,
            Difficulty = Difficulty.DIFFICULTY_HARD,
        },
        [CompletionType.MOTHER] = {
            Unlock = achievements.ACHIEVEMENT_PAPRIKA,
            Difficulty = Difficulty.DIFFICULTY_HARD,
        },
        [CompletionType.DELIRIUM] = {
            Unlock = achievements.ACHIEVEMENT_BURNT_HOOD,
            Difficulty = Difficulty.DIFFICULTY_HARD,
        },
        [CompletionType.BEAST] = {
            Unlock = achievements.ACHIEVEMENT_DIVINE_WRATH,
            Difficulty = Difficulty.DIFFICULTY_HARD,
        },
        TaintedMarksGroup = {
            [TaintedMarksGroup.SOULSTONE] = achievements.ACHIEVEMENT_SOUL_OF_EDITH,
            [TaintedMarksGroup.POLAROID_NEGATIVE] = achievements.ACHIEVEMENT_BURNT_SALT
        }
    }
}

local GreedierUnlocks = {
    [players.PLAYER_EDITH] = {
        achievements.ACHIEVEMENT_HYDRARGYRUM,
        achievements.ACHIEVEMENT_GILDED_STONE,
    },
    [players.PLAYER_EDITH_B] = {
        achievements.ACHIEVEMENT_JACK_OF_CLUBS,
    }
}

local function ThankYou()
    local pgd = Isaac.GetPersistentGameData()
    local isComplete = true

    for _, v in pairs(achievements) do
        if v == achievements.ACHIEVEMENT_THANK_YOU then goto continue end
        if not pgd:Unlocked(v) then
            isComplete = false
            break
        end
        ::continue::
    end

    if not isComplete then return end
    pgd:TryUnlock(achievements.ACHIEVEMENT_THANK_YOU)
end
mod:AddCallback(ModCallbacks.MC_POST_ACHIEVEMENT_UNLOCK, ThankYou)

---@param player PlayerType
---@param pgd PersistentGameData
---@param difficulty Difficulty
local function GreedierUnlockManager(player, pgd, difficulty)
    if difficulty ~= Difficulty.DIFFICULTY_GREEDIER then return end

    for _, ach in ipairs(GreedierUnlocks[player]) do
        pgd:TryUnlock(ach, true)
    end
end

local function TaintedMarksGroupUnlockManager(pgd)
    for group, ach in pairs(UnlockTable.TEdith.TaintedMarksGroup) do
        if Isaac.AllTaintedCompletion(players.PLAYER_EDITH_B, group) == 2 then
            pgd:TryUnlock(ach)
        end
    end
end

---@param mark CompletionType
---@param player PlayerType
---@return {Difficulty: Difficulty, Unlock: Achievement}?
local function GetUnlockTable(mark, player)
    local tableRef = (
        player == players.PLAYER_EDITH and UnlockTable.Edith or
        player == players.PLAYER_EDITH_B and UnlockTable.TEdith
    )

    if not tableRef then return end
    return Helpers.When(mark, tableRef)
end

---@param mark CompletionType
---@param player PlayerType
---@param pgd PersistentGameData
---@param difficulty Difficulty
local function TriggerMarkUnlock(mark, player, pgd, difficulty)
    local unlock = GetUnlockTable(mark, player)

    if not unlock then return end
    if difficulty ~= unlock.Difficulty then return end

    pgd:TryUnlock(unlock.Unlock)
end

---@param player PlayerType
---@param pgd PersistentGameData
local function CompletionBonusManager(player, pgd)
    if player == players.PLAYER_EDITH_B then
        TaintedMarksGroupUnlockManager(pgd)
    end

    if Isaac.AllMarksFilled(players.PLAYER_EDITH) == 2 then
        pgd:TryUnlock(achievements.ACHIEVEMENT_SALT_HEART)
    end
end

---@param mark CompletionType
---@param player PlayerType
mod:AddCallback(ModCallbacks.MC_POST_COMPLETION_MARK_GET, function(_, mark, player)
    local pgd = Isaac.GetPersistentGameData()
    local difficulty = game.Difficulty

    GreedierUnlockManager(player, pgd, difficulty)
    TriggerMarkUnlock(mark, player, pgd, difficulty)
    CompletionBonusManager(player, pgd)
    ThankYou()
end)

local taintedAchievement = {
    [players.PLAYER_EDITH] = {unlock = achievements.ACHIEVEMENT_TAINTED_EDITH, gfx = "gfx/characters/costumes/characterTaintedEdith.png"}
}

mod:AddCallback(ModCallbacks.MC_POST_SLOT_UPDATE, function(_, slot)
    if not slot:GetSprite():IsFinished("PayPrize") then return end
    local d = slot:GetData().Tainted

    if not d then return end

    Isaac.GetPersistentGameData():TryUnlock(d.unlock)
end, SlotVariant.HOME_CLOSET_PLAYER)

local function SetupSlot(slot, gfx, data)
    slot:GetSprite():ReplaceSpritesheet(0, gfx, true)
    slot:GetData().Tainted = data
end

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
    if level:GetStage() ~= LevelStage.STAGE8 then return end
    if level:GetCurrentRoomDesc().SafeGridIndex ~= 94 then return end
    if game:AchievementUnlocksDisallowed() then return end

    local playerType = Isaac.GetPlayer():GetPlayerType()
    local data = taintedAchievement[playerType]

    if not data then return end
    if Isaac.GetPersistentGameData():Unlocked(data.unlock) then return end

    local room = game:GetRoom()

    if room:IsFirstVisit() then
        for _, k in ipairs(Isaac.FindByType(17)) do k:Remove() end
        for _, i in ipairs(Isaac.FindByType(5)) do i:Remove() end

        local slot = Isaac.Spawn(6, 14, 0, room:GetCenterPos(), Vector.Zero, nil)
        SetupSlot(slot, data.gfx, data)
    else
        for _, slot in ipairs(Isaac.FindByType(6, 14)) do
            SetupSlot(slot, data.gfx, data)
        end
    end
end)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
    local PGD = Isaac.GetPersistentGameData()

    if PGD:Unlocked(achievements.ACHIEVEMENT_EDITH) then return end
    if player:GetNumBombs() < 25 then return end
    PGD:TryUnlock(achievements.ACHIEVEMENT_EDITH)
end)