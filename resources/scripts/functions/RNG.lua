local mod = EdithRebuilt
local enums = mod.Enums
local utils = enums.Utils
local modRNG = {}

---Returns a chance based boolean
---@param rng? RNG if `nil`, the function will use Mod's `RNG` object instead
---@param chance? number if `nil`, default chance will be 0.5 (50%)
function modRNG.RandomBoolean(rng, chance)
	return (rng or utils.RNG):RandomFloat() <= (chance or 0.5)
end

---Helper function for a better management of random floats, allowing to use min and max values, like `math.random()` and `RNG:RandomInt()`
---@param rng? RNG if `nil`, the function will use Mod's `RNG` object instead
---@param min number
---@param max? number if `nil`, returned number will be one between 0 and `min`
function modRNG.RandomFloat(rng, min, max)
	if not max then
		max = min
		min = 0
	end

	min = min * 1000
	max = max * 1000

	return (rng or utils.RNG):RandomInt(min, max) / 1000
end

return modRNG