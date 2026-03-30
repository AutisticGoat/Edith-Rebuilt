local BitMask = {}

---@param bitmaskOffset integer
---@return TearFlags
---@function
function BitMask.TearFlag(bitmaskOffset)
	return bitmaskOffset >= 64 and BitSet128(0, 1 << (bitmaskOffset - 64)) or BitSet128(1 << bitmaskOffset, 0)
end

---Returns true if the first agument contains the second argument
---@generic flag : BitSet128 | integer | TearFlags
---@param flags flag
---@param ... flag[]
---@return boolean
function BitMask.HasBitFlags(flags, ...)
    for _, flag in ipairs({...}) do
        if (flags & flag) == 0 then return false end
    end
    return true
end

---Returns true if the first argument contains any of the flags in the second argument. A looser version of HasBitFlags.
---@generic flag : BitSet128 | integer | TearFlags
---@param flags flag
---@param checkFlag flag
function BitMask.HasAnyBitFlags(flags, checkFlag)
	return flags & checkFlag > 0
end

---Adds the second argument bitflag to the first
---@generic flag : BitSet128 | integer | TearFlags
---@param flags flag
---@param addFlag flag
---@return flag
function BitMask.AddBitFlags(flags, addFlag)
	flags = flags | addFlag
	return flags
end

---Removes the second argument bitflag from the first. If it doesn't have it, it will remain the same
---@generic flag : BitSet128 | integer | TearFlags
---@param flags flag
---@param removeFlag flag
---@return flag
function BitMask.RemoveBitFlags(flags, removeFlag)
	flags = flags & ~removeFlag
	return flags
end

return BitMask