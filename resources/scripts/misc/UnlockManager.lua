local mod = EdithRebuilt
local enums = mod.Enums
local players = enums.PlayerType
local achievements = enums.Achievements
local utils = enums.Utils
local items = enums.CollectibleType
local trinkets = enums.TrinketType
local game = utils.Game
local level = utils.Level
local Helpers = mod.Modules.HELPERS
local unlocks = {}
local UnlockTable = {
    Edith = {
        [CompletionType.MOMS_HEART] = {
            Unlock = achievements.ACHIEVEMENT_GEODE,
            Difficulty = Difficulty.DIFFICULTY_HARD,
            Trinket = trinkets.TRINKET_GEODE
        },
        [CompletionType.ISAAC] = {
            Unlock = achievements.ACHIEVEMENT_SALT_SHAKER,
            Difficulty = Difficulty.DIFFICULTY_HARD,
            Item = items.COLLECTIBLE_SALTSHAKER,
        },
        [CompletionType.SATAN] = {
            Unlock = achievements.ACHIEVEMENT_SULFURIC_FIRE,
            Difficulty = Difficulty.DIFFICULTY_HARD,
            Item = items.COLLECTIBLE_SULFURIC_FIRE,
        },
        [CompletionType.BOSS_RUSH] = {
            Unlock = achievements.ACHIEVEMENT_RUMBLING_PEBBLE,
            Difficulty = Difficulty.DIFFICULTY_HARD,
            Trinket = trinkets.TRINKET_RUMBLING_PEBBLE
        },
        [CompletionType.BLUE_BABY] = {
            Unlock = achievements.ACHIEVEMENT_PEPPER_GRINDER,
            Difficulty = Difficulty.DIFFICULTY_HARD,
            Item = items.COLLECTIBLE_PEPPERGRINDER
        },
        [CompletionType.LAMB] = {
            Unlock = achievements.ACHIEVEMENT_FAITH_OF_THE_UNFAITHFUL,
            Difficulty = Difficulty.DIFFICULTY_HARD,
            Item = items.COLLECTIBLE_FATE_OF_THE_UNFAITHFUL
        },
        [CompletionType.MEGA_SATAN] = {
            Unlock = achievements.ACHIEVEMENT_MOLTEN_CORE,
            Difficulty = Difficulty.DIFFICULTY_HARD,
            Item = items.COLLECTIBLE_MOLTEN_CORE,
        },
        [CompletionType.ULTRA_GREED] = {
            Unlock = achievements.ACHIEVEMENT_HYDRARGYRUM,
            Difficulty = Difficulty.DIFFICULTY_GREED,
            Item = items.COLLECTIBLE_HYDRARGYRUM,
        },
        [CompletionType.HUSH] = {
            Unlock = achievements.ACHIEVEMENT_SAL,
            Difficulty = Difficulty.DIFFICULTY_HARD,
            Item = items.COLLECTIBLE_SAL,
        },
        [CompletionType.ULTRA_GREEDIER] = {
            Unlock = achievements.ACHIEVEMENT_GILDED_STONE,
            Difficulty = Difficulty.DIFFICULTY_GREEDIER,
            Item = items.COLLECTIBLE_GILDED_STONE,
        },
        [CompletionType.DELIRIUM] = {
            Unlock = achievements.ACHIEVEMENT_CHUNK_OF_BASALT,
            Difficulty = Difficulty.DIFFICULTY_HARD,
            Item = items.COLLECTIBLE_CHUNK_OF_BASALT,
        },
        [CompletionType.MOTHER] = {
            Unlock = achievements.ACHIEVEMENT_DIVINE_RETRIBUTION,
            Difficulty = Difficulty.DIFFICULTY_HARD,
            Item = items.COLLECTIBLE_DIVINE_RETRIBUTION,
        },
        [CompletionType.BEAST] = {
            Unlock = achievements.ACHIEVEMENT_EDITHS_HOOD,
            Difficulty = Difficulty.DIFFICULTY_HARD,
            Item = items.COLLECTIBLE_EDITHS_HOOD,
        },
    },
    TEdith = {
        [CompletionType.MEGA_SATAN] = {
            Unlock = achievements.ACHIEVEMENT_SALT_ROCKS,
            Difficulty = Difficulty.DIFFICULTY_HARD,
            Card = enums.Card.CARD_SALT_ROCKS,
        },
        [CompletionType.MOTHER] = {
            Unlock = achievements.ACHIEVEMENT_PAPRIKA,
            Difficulty = Difficulty.DIFFICULTY_HARD,
            Trinket = trinkets.TRINKET_PAPRIKA
        },
        [CompletionType.DELIRIUM] = {
            Unlock = achievements.ACHIEVEMENT_BURNT_HOOD,
            Difficulty = Difficulty.DIFFICULTY_HARD,
            Item = items.COLLECTIBLE_BURNT_HOOD,
        },
        [CompletionType.BEAST] = {
            Unlock = achievements.ACHIEVEMENT_DIVINE_WRATH,
            Difficulty = Difficulty.DIFFICULTY_HARD,
            Item = items.COLLECTIBLE_DIVINE_WRATH,
        },
    }
}

function mod:ThankYou()
    local pgd = Isaac.GetPersistentGameData()
    local isComplete = true

    for _, v in pairs(achievements) do
        if v == achievements.ACHIEVEMENT_THANK_YOU then goto Break end
        if not pgd:Unlocked(v) then
            isComplete = false
            break
        end
        ::Break::
    end

    if not isComplete then return end
    pgd:TryUnlock(achievements.ACHIEVEMENT_THANK_YOU)
end
mod:AddCallback(ModCallbacks.MC_POST_ACHIEVEMENT_UNLOCK, mod.ThankYou)

---@param mark CompletionType
---@param player PlayerType
---@param pgd PersistentGameData
---@param difficulty Difficulty
local function TriggerEdithUnlocks(mark, player, pgd, difficulty)
    if player ~= players.PLAYER_EDITH then return end

    local tableRef = UnlockTable.Edith 
    local unlock = Helpers.When(mark, tableRef)

    if not unlock then return end

    if difficulty == Difficulty.DIFFICULTY_GREEDIER then
        pgd:TryUnlock(achievements.ACHIEVEMENT_HYDRARGYRUM)
        pgd:TryUnlock(achievements.ACHIEVEMENT_GILDED_STONE)
    end
    
    if difficulty ~= unlock.Difficulty then return end
    pgd:TryUnlock(unlock.Unlock)

    if Isaac.AllMarksFilled(players.PLAYER_EDITH) == 2 then 
        pgd:TryUnlock(achievements.ACHIEVEMENT_SALT_HEART)
    end
end

---@param mark CompletionType
---@param player PlayerType
---@param pgd PersistentGameData
---@param difficulty Difficulty
local function TriggerTEdithUnlocks(mark, player, pgd, difficulty)
    if player ~= players.PLAYER_EDITH_B then return end

    local tableRef = UnlockTable.TEdith
    local unlock = Helpers.When(mark, tableRef, nil)

    if not unlock then return end

    if Isaac.AllTaintedCompletion(players.PLAYER_EDITH_B, TaintedMarksGroup.SOULSTONE) == 2 then
        pgd:TryUnlock(achievements.ACHIEVEMENT_SOUL_OF_EDITH)
    end

    if Isaac.AllTaintedCompletion(players.PLAYER_EDITH_B, TaintedMarksGroup.POLAROID_NEGATIVE) == 2 then
        pgd:TryUnlock(achievements.ACHIEVEMENT_BURNT_SALT)
    end

    if difficulty == Difficulty.DIFFICULTY_GREEDIER then
        pgd:TryUnlock(achievements.ACHIEVEMENT_JACK_OF_CLUBS)
    end

    if difficulty ~= unlock.Difficulty then return end
    pgd:TryUnlock(unlock.Unlock)
end

---@param mark CompletionType
---@param player PlayerType
function unlocks:OnTriggerCompletion(mark, player)
    local pgd = Isaac.GetPersistentGameData()
    local difficulty = game.Difficulty

    TriggerEdithUnlocks(mark, player, pgd, difficulty)
    TriggerTEdithUnlocks(mark, player, pgd, difficulty)

    mod:ThankYou()
end
mod:AddCallback(ModCallbacks.MC_POST_COMPLETION_MARK_GET, unlocks.OnTriggerCompletion)

local taintedAchievement = {
    [players.PLAYER_EDITH] = {unlock = achievements.ACHIEVEMENT_TAINTED_EDITH, gfx = "gfx/characters/costumes/characterTaintedEdith.png"}
}
function mod:SlotUpdate(slot)
    if not slot:GetSprite():IsFinished("PayPrize") then return end
    local d = slot:GetData().Tainted
    if not d then return end
    Isaac.GetPersistentGameData():TryUnlock(d.unlock)
end
mod:AddCallback(ModCallbacks.MC_POST_SLOT_UPDATE, mod.SlotUpdate, 14)

function mod:HiddenCloset()
    if level:GetStage() ~= LevelStage.STAGE8 then return end
    if level:GetCurrentRoomDesc().SafeGridIndex ~= 94 then return end
    if game:AchievementUnlocksDisallowed() then return end

    local p = Isaac.GetPlayer():GetPlayerType()
    local d = taintedAchievement[p]
    
    if not d then return end
    if Isaac.GetPersistentGameData():Unlocked(d.unlock) then return end

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