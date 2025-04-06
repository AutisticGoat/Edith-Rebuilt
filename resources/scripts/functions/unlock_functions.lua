local mod = edithMod
local enums = mod.Enums
local players = enums.PlayerType
local achievements = enums.Achievements
local utils = enums.Utils
local items = enums.CollectibleType
local trinkets = enums.TrinketType
local game = utils.Game
local unlocks = {}

local UnlockTable = {
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
    -- [CompletionType.ULTRA_GREED] = achievements.ACHIEVEMENT_SALT_SHAKER,
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
        Unlock = achievements.ACHIEVEMENT_THE_BOOK_OF_LUKE,
        Difficulty = Difficulty.DIFFICULTY_HARD,
        Item = items.COLLECTIBLE_THE_BOOK_OF_LUKE,
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
}

function unlocks:CheckStartUnlocks()
    local pgd = Isaac.GetPersistentGameData()

    for unlock, table in pairs(UnlockTable) do
        if pgd:Unlocked(table.Unlock) then goto Break end
        
        print(unlock, "Objeto bloqueado")
        
        -- if table.Item then
        --     game:GetItemPool():RemoveCollectible(table.Item)
        -- end

        -- if table.Trinket then
        --     print(game:GetItemPool():RemoveTrinket(table.Trinket))
        -- end

        ::Break::
    end
end
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, unlocks.CheckStartUnlocks)

---@param mark CompletionType
function unlocks:OnTriggerCompletion(mark)
    local pgd = Isaac.GetPersistentGameData()
    local unlock = mod.When(mark, UnlockTable, 1)

    if game.Difficulty ~= unlock.Difficulty then return end
    pgd:TryUnlock(unlock.Unlock)

    if Isaac.AllMarksFilled(players.PLAYER_EDITH) ~= 2 then return end
    pgd:TryUnlock(achievements.ACHIEVEMENT_SALT_HEART)
end
mod:AddCallback(ModCallbacks.MC_COMPLETION_MARK_GET, unlocks.OnTriggerCompletion, players.PLAYER_EDITH)

local taintedAchievement = {
    [players.PLAYER_EDITH] = {unlock = achievements.ACHIEVEMENT_TAINTED_EDITH, gfx = "gfx/characters/costumes/characterTaintedEdith.png"}
}

function mod:SlotUpdate(slot)
    local pgd = Isaac.GetPersistentGameData()
    if not slot:GetSprite():IsFinished("PayPrize") then return end
    local d = slot:GetData().Tainted
    if not d then return end
    pgd:TryUnlock(d.unlock)
end
mod:AddCallback(ModCallbacks.MC_POST_SLOT_UPDATE, mod.SlotUpdate, 14)

function mod:HiddenCloset()
    local pgd = Isaac.GetPersistentGameData()
    local level = game:GetLevel()
    if level:GetStage() ~= LevelStage.STAGE8 then return end
    if level:GetCurrentRoomDesc().SafeGridIndex ~= 94 then return end
    if game:AchievementUnlocksDisallowed() then return end

    local p = Isaac.GetPlayer():GetPlayerType()
    local d = taintedAchievement[p]
    
    if not d then return end
    if pgd:Unlocked(d.unlock) then return end

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