local mod = EdithRebuilt
local data = mod.CustomDataWrapper.getData
local TEdith = {}

---@class TEdithParryParams
---@field Damage number
---@field Radius number
---@field Knockback number
---@field Jumps integer
---@field Cooldown integer
---@field JumpStartPos Vector
---@field JumpStartDist number
---@field CoalBonus number
---@field BombStomp boolean
---@field RocketLaunch boolean
---@field IsDefensiveStomp boolean
---@field StompedEntities Entity[]

local DefaultStompParams = {
    Damage = 0,
    Radius = 0,
    Knockback = 0,
    Jumps = 0,
    Cooldown = 0,
    JumpStartPos = Vector(0, 0),
    JumpStartDist = 0,
    CoalBonus = 0,
    BombStomp = false,
    RocketLaunch = false,
    IsDefensiveStomp = false,
    StompedEntities = {},
} --[[@as TEdithParryParams]]

---@param player EntityPlayer
function TEdith.GetParryParams(player)
    data(player).ParryParams = data(player).ParryParams or DefaultStompParams 
    local params = data(player).ParryParams ---@cast DefaultStompParams TEdithParryParams

    return params
end