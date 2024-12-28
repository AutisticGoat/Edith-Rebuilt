local META, META0

local function EditClass(T, newProperty)
	META = {}
	if type(T) == "function" then
		META0 = getmetatable(T())
	else
		local tableMerge = function(t1, t2)
			for k,v in pairs(t2) do
				if type(v) == "table" then
					if type(t1[k] or false) == "table" then
						tableMerge(t1[k] or {}, t2[k] or {})
					else
						t1[k] = v
					end
				else
					t1[k] = v
				end
			end
			return t1
		end

		META0 = getmetatable(T).__class
		local newTable = getmetatable(T).__class
		local currTable = getmetatable(T)
		local currProperty = {""..newProperty.." = self"}
		local AddProp = setmetatable(newTable, currProperty)
		local mergeMeta = tableMerge(newTable, currProperty)
		local currMergedTable = setmetatable(currTable, mergeMeta)
	end
end

local function EndClass()
	local oldIndex = META0.__index
	local newMeta = META
	
	rawset(META0, "__index", function(self, k)
		return newMeta[k] or oldIndex(self, k)
	end)
end
-----------------------------------------------------------------------------------------------------------------------------------------------------------

EditClass(EntityPlayer, "GetDickSize")
function META:GetDickSize()
    local player = self
    return player.TearRange / 40
end

---comment
---@param tainted boolean?
---@return boolean
function META:IsEdith(tainted)
	local player = self
	
	return tainted == true and player:GetPlayerType() == edithMod.Enums.PlayerType.PLAYER_EDITH_B or player:GetPlayerType() == edithMod.Enums.PlayerType.PLAYER_EDITH

	
end
EndClass()
