local utils = edithMod.Enums.Utils
local game = utils.Game
local RECOMMENDED_SHIFT_IDX = 35

local function setRNG()
	local rng = utils.RNG
	local seeds = game:GetSeeds()
	local startSeed = seeds:GetStartSeed()
	
	rng:SetSeed(startSeed, RECOMMENDED_SHIFT_IDX)	
end
edithMod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, setRNG)