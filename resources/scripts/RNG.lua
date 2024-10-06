local edithRNG = {}

local function setRNG()
	local RECOMMENDED_SHIFT_IDX = 35
	local game = edithMod.Enums.Utils.Game
	local seeds = game:GetSeeds()
	local startSeed = seeds:GetStartSeed()
	local rng = RNG()


	rng:SetSeed(startSeed, RECOMMENDED_SHIFT_IDX)

	edithMod.Enums.Utils.RNG = rng

end

function edithMod:GameStartedFunction()
	setRNG()
end
edithMod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, edithMod.GameStartedFunction)

function edithMod:InitRNG()
	if not edithMod.Enums.Utils.RNG then
		setRNG()
		print("RNG puesto")
	end
	
	-- print(edithMod.Enums.Utils.RNG)
end
edithMod:AddCallback(ModCallbacks.MC_POST_RENDER, edithMod.InitRNG)

-- print(game, seed, RunSeed)