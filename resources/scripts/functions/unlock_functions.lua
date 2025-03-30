local mod = edithMod
local enums = mod.Enums
local players = enums.PlayerType
local achievements = enums.Achievements
local utils = enums.Utils
local game = utils.Game
local pgd = Isaac.GetPersistentGameData()

local unlocks = {}

local UnlockTable = {
    -- [CompletionType.MOMS_HEART] = achievements.ACHIEVEMENT_SALT_SHAKER,
    [CompletionType.ISAAC] = {
        Unlock = achievements.ACHIEVEMENT_SALT_SHAKER,
        Difficulty = Difficulty.DIFFICULTY_HARD
    },
    -- [CompletionType.SATAN] = achievements.ACHIEVEMENT_SALT_SHAKER,
    -- [CompletionType.BOSS_RUSH] = achievements.ACHIEVEMENT_SALT_SHAKER,
    [CompletionType.BLUE_BABY] = {
        Unlock = achievements.ACHIEVEMENT_PEPPER_GRINDER,
        Difficulty = Difficulty.DIFFICULTY_HARD,
    },
    [CompletionType.LAMB] = {
        Unlock = achievements.ACHIEVEMENT_FAITH_OF_THE_UNFAITHFUL,
        Difficulty = Difficulty.DIFFICULTY_HARD,
    },
        -- [CompletionType.MEGA_SATAN] = achievements.ACHIEVEMENT_SALT_SHAKER,
    -- [CompletionType.ULTRA_GREED] = achievements.ACHIEVEMENT_SALT_SHAKER,
    [CompletionType.HUSH] = {
        Unlock = achievements.ACHIEVEMENT_SALT_SHAKER,
        Difficulty = Difficulty.DIFFICULTY_HARD,
    },
    -- [CompletionType.ULTRA_GREEDIER] = achievements.ACHIEVEMENT_SALT_SHAKER,
    -- [CompletionType.DELIRIUM] = achievements.ACHIEVEMENT_SALT_SHAKER,
    -- [CompletionType.MOTHER] = achievements.ACHIEVEMENT_SALT_SHAKER,
    -- [CompletionType.BEAST] = achievements.ACHIEVEMENT_SALT_SHAKER,
}

---comment
---@param mark CompletionType
function unlocks:OnTriggerCompletion(mark)
    local unlock = mod.When(mark, UnlockTable, nil)

    if not unlock then return end
    if game.Difficulty ~= unlock.Difficulty then return end

    pgd:TryUnlock(unlock.Unlock)

    if Isaac.AllMarksFilled(players.PLAYER_EDITH) ~= 2 then return end
    pgd:TryUnlock(achievements.ACHIEVEMENT_SALT_HEART)
end
mod:AddCallback(ModCallbacks.MC_COMPLETION_MARK_GET, unlocks.OnTriggerCompletion, players.PLAYER_EDITH)

local character = players.PLAYER_EDITH
local achievement = achievements.ACHIEVEMENT_TAINTED_EDITH
local gfxSlot = "gfx/characters/costumes/characterTaintedEdith.png"

local taintedAchievement = {
    [character] = {unlock = achievement, gfx = gfxSlot}
}

function mod:SlotUpdate(slot)
    if not slot:GetSprite():IsFinished("PayPrize") then
        return
    end
    local d = slot:GetData().Tainted
    if d then
        Isaac.GetPersistentGameData():TryUnlock(d.unlock)
    end
end
mod:AddCallback(ModCallbacks.MC_POST_SLOT_UPDATE, mod.SlotUpdate, 14)

function mod:HiddenCloset()
    if game:GetLevel():GetStage() ~= LevelStage.STAGE8 then return end
    if game:GetLevel():GetCurrentRoomDesc().SafeGridIndex ~= 94 then return end
    if game:AchievementUnlocksDisallowed() then return end

    local p = Isaac.GetPlayer():GetPlayerType()
    local d = taintedAchievement[p]
    
    if not d then return end
    local g = Isaac.GetPersistentGameData()

    if g:Unlocked(d.unlock) then return end

    if game:GetRoom():IsFirstVisit() then
        for _, k in ipairs(Isaac.FindByType(17)) do
            k:Remove()
        end
        for _, i in ipairs(Isaac.FindByType(5)) do
            i:Remove()
        end
        local s = Isaac.Spawn(6, 14, 0, game:GetRoom():GetCenterPos(), Vector.Zero, nil)
        s:GetSprite():ReplaceSpritesheet(0, d.gfx, true)
        s:GetData().Tainted = d
    else
        for _, s in ipairs(Isaac.FindByType(6, 14)) do
            s:GetSprite():ReplaceSpritesheet(0, d.gfx, true)
            s:GetData().Tainted = d
        end
    end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.HiddenCloset)

function mod:Mierda()
    local portraitSprite = CharacterMenu.GetCharacterPortraitSprite()
    local characterID = CharacterMenu.GetSelectedCharacterID()


    print(portraitSprite:GetAnimation(), characterID)
end
mod:AddCallback(ModCallbacks.MC_MAIN_MENU_RENDER, mod.Mierda)