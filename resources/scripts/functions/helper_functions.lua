function edithMod:GetPlayers(functionCheck, ...)
	local args = {...}
	local players = {}
	local game = Game()
	
	for i=1, game:GetNumPlayers() do
		local player = Isaac.GetPlayer(i-1)
		local argsPassed = true
		
		if type(functionCheck) == "function" then
			for j=1, #args do
				if args[j] == "player" then
					args[j] = player
				elseif args[j] == "currentPlayer" then
					args[j] = i
				end
			end
			
			if not functionCheck(table.unpack(args)) then
				argsPassed = false	
			end
		end
		
		if argsPassed then
			players[#players+1] = player
		end
	end
	
	return players
end

---comment
---@param entity Entity
---@return EntityPlayer?
function edithMod:GetPlayerFromTear(entity)
	for i=1, 3 do
		local check = nil
		if i == 1 then
			check = entity.Parent
		elseif i == 2 then
			check = entity.SpawnerEntity
		end
		if check then
			if check.Type == EntityType.ENTITY_PLAYER then
				return edithMod:GetPtrHashEntity(check):ToPlayer()
			elseif check.Type == EntityType.ENTITY_FAMILIAR then
				return check:ToFamiliar().Player:ToPlayer()
			end
		end
	end
	return nil
end

function edithMod:GetData(entity)
	local data = entity:GetData()
	data.edithMod = data.edithMod or {}
	return data.edithMod
end

function edithMod:GetPtrHashEntity(entity)
	if entity then
		if entity.Entity then
			entity = entity.Entity
		end
		for _, matchEntity in pairs(Isaac.FindByType(entity.Type, entity.Variant, entity.SubType, false, false)) do
			if GetPtrHash(entity) == GetPtrHash(matchEntity) then
				return matchEntity
			end
		end
	end
	return nil
end