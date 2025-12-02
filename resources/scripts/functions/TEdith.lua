local mod = EdithRebuilt
local data = mod.CustomDataWrapper.getData
local maths = require("resources.scripts.functions.Maths")
local TEdith = {}

---@class TEdithParryParams
---@field Damage number
---@field Radius number
---@field Knockback number

local DefaultStompParams = {
    Damage = 0,
    Radius = 0,
    Knockback = 0,

} --[[@as TEdithParryParams]]

---@param player EntityPlayer
---@return TEdithParryParams
function TEdith.GetParryParams(player)
    data(player).ParryParams = data(player).ParryParams or DefaultStompParams 
    local params = data(player).ParryParams ---@cast DefaultStompParams TEdithParryParams

    return params
end

---@class TEdithHopParams
---@field Damage number
---@field Knockback number
---@field Radius number
local DefaultHopParams = {
    Damage = 0,
    Knockback = 0,
    Radius = 0,
}

---@generic growth, offset, curve
---@param const number
---@param var number
---@param params { growth: number, offset: number, curve: number }
---@return number
function TEdith.HopHeightCalc(const, var, params)
    -- Validaciones estrictas
    assert(type(var) == "number", "var should be a number")
    assert(var >= 0 and var <= 100, "var should be a number between 0 and 100")

    -- Caso exclusivo cuando variable es exactamente 100
    if var == 100 then return const end

	local limit = 0.999999
    local growth = math.max(0, params.growth or 1) 
    local offset = maths.Clamp(params.offset or 0, -1, 1) 
    local curve = math.max(0.1, math.min(params.curve or 1, 10))
	local formula = (var / 100) ^ curve * growth + offset
    local progresion = math.min(formula, limit)

    -- Resultado final garantizado que nunca iguala la constante
    return const * maths.Clamp(progresion, 0, limit)
end

---@param player EntityPlayer
---@param charge number
---@param BRMult number
function TEdith.AddHopDashCharge(player, charge, BRMult)
	local playerData = data(player)
	local shouldAddToBrCharge = mod.PlayerHasBirthright(player) and playerData.ImpulseCharge >= 100

	playerData.ImpulseCharge = maths.Clamp(playerData.ImpulseCharge + charge, 0, 100)
	
	if not shouldAddToBrCharge then return end
	playerData.BirthrightCharge = shouldAddToBrCharge and maths.Clamp(playerData.BirthrightCharge + (charge * BRMult), 0, 100)
end

return TEdith