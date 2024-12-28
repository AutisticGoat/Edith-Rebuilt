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