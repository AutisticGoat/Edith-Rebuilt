---@diagnostic disable: undefined-global
if not BirthcakeRebaked then return end

local mod = EdithRebuilt
local enums = mod.Enums
local players = enums.PlayerType
local EdithSpritePath = "gfx/items/trinkets/EdithRebuilt_Edith_Birthcake.png"
local TEdithSpritePath = "gfx/items/trinkets/EdithRebuilt_T_Edith_Birthcake.png"

local Info = {
    [players.PLAYER_EDITH] = { 
        Description = "Brittle petrification",
        SpriteInfo = {SpritePath = EdithSpritePath, PickupSpritePath = EdithSpritePath}
    },
    [players.PLAYER_EDITH_B] = {
        Description = "Stronger parry",
        SpriteInfo = {SpritePath = TEdithSpritePath, PickupSpritePath = TEdithSpritePath}
    }
}

for k, v in pairs(Info) do
    BirthcakeRebaked.API:AddBirthcakePickupText(k, v.Description)
    BirthcakeRebaked.API:AddBirthcakeSprite(k, v.SpriteInfo)
end