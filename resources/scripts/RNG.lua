local utils = EdithRebuilt.Enums.Utils
local game = utils.Game
local RECOMMENDED_SHIFT_IDX = 35

local function setRNG()
	utils.RNG:SetSeed(game:GetSeeds():GetStartSeed(), RECOMMENDED_SHIFT_IDX)
end
EdithRebuilt:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, setRNG)