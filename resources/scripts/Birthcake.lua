---@diagnostic disable: undefined-global
if not BirthcakeRebaked then return end

local mod = EdithRebuilt
local enums = mod.Enums
local players = enums.PlayerType
local path = "gfx/items/trinkets/EdithRebuilt_"
local EdithSuffix = "Edith_Birthcake.png"
local TEdithSuffix = "T_Edith_Birthcake.png"

local Info = {
    [players.PLAYER_EDITH] = { 
        Description = "Brittle petrification",
        SpriteInfo = {SpritePath = path .. EdithSuffix , PickupSpritePath = path .. EdithSuffix}
    },
    [players.PLAYER_EDITH_B] = {
        Description = "Stronger parry",
        SpriteInfo = {SpritePath = path .. TEdithSuffix, PickupSpritePath = path .. TEdithSuffix}
    }
}

for k, v in pairs(Info) do
    BirthcakeRebaked.API:AddBirthcakePickupText(k, v.Description)
    BirthcakeRebaked.API:AddBirthcakeSprite(k, v.SpriteInfo)
end