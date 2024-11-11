local game = edithMod.Enums.Utils.Game

local function setRNG()
	local rng = edithMod.Enums.Utils.RNG
	local RECOMMENDED_SHIFT_IDX = 35
	
	local seeds = game:GetSeeds()
	local startSeed = seeds:GetStartSeed()
	
	rng:SetSeed(startSeed, RECOMMENDED_SHIFT_IDX)	
end

function edithMod:GameStartedFunction()
	setRNG()
end
edithMod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, edithMod.GameStartedFunction)
edithMod:AddCallback(ModCallbacks.MC_PRE_MOD_UNLOAD, edithMod.GameStartedFunction)

function edithMod:SetObjects()
	edithMod.Enums.Utils.Room = game:GetRoom()
	edithMod.Enums.Utils.Level = game:GetLevel()
	
	-- print(edithMod.Enums.Utils.Room, edithMod.Enums.Utils.Level)
end
edithMod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, edithMod.SetObjects)