local Maths = {}

---Expontential function
---@param number number
---@param coeffcient number
---@param power number
---@return integer
function Maths.exp(number, coeffcient, power)
    return number ~= 0 and coeffcient * number ^ (power - 1) or 0
end

---Logaritmic function
---@param x number
---@param base number
---@return number?
function Maths.Log(x, base)
    if x <= 0 or base <= 1 then
        return nil
    end

    local logNatural = math.log(x)
    local logBase = math.log(base)
    
    return logNatural / logBase
end

--- Rounds a number to the closest number of decimal places given.
--- Defaults to rounding to the nearest integer. 
--- (from Library of Isaac)
---@param n number
---@param decimalPlaces integer? @Default: 0
---@return number
function Maths.Round(n, decimalPlaces)
	decimalPlaces = decimalPlaces or 0
	local mult = 10^(decimalPlaces or 0)
	return math.floor(n * mult + 0.5) / mult
end

--- Helper function to clamp a number into a range (from Library of Isaac).
---@param a number
---@param min number
---@param max number
---@return number
function Maths.Clamp(a, min, max)
	if min > max then
		local temp = min
		min = max
		max = temp
	end

	return math.max(min, math.min(a, max))
end

return Maths