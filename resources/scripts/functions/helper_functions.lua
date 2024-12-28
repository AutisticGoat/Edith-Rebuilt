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
-- end

function edithMod:GetData(entity)
	local data = entity:GetData()
	data.edithMod = data.edithMod or {}
	return data.edithMod
end

function edithMod:GetSpawnData(entity)
	if entity and entity.GetData then
		local data = edithMod:GetData(entity)
		return data.SpawnData
	end
	return nil
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

local entitySpawnData = {}
edithMod:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, function(_, type, variant, subType, position, velocity, spawner, seed)
	entitySpawnData[seed] = {
		Type = type,
		Variant = variant,
		SubType = subType,
		Position = position,
		Velocity = velocity,
		SpawnerEntity = spawner,
		InitSeed = seed
	}
end)
edithMod:AddCallback(ModCallbacks.MC_POST_TEAR_INIT, function(_, entity)
	local seed = entity.InitSeed
	local data = edithMod:GetData(entity)
	data.SpawnData = entitySpawnData[seed]
end)
edithMod:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, entity)
	local data = edithMod:GetData(entity)
	data.SpawnData = nil
end)
edithMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
	entitySpawnData = {}
end)