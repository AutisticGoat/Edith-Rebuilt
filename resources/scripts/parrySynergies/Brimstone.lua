local mod = EdithRebuilt
local Brim = {}
local totalRays = 4
local shootDegrees = 360 / totalRays
local data = mod.CustomDataWrapper.getData

---@param player EntityPlayer
---@param ent Entity
function Brim:BrimParry(player, ent)
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE) then return end

	local laser
	for	i = 1, totalRays do
		laser = player:FireDelayedBrimstone(shootDegrees * i, player)
        laser.Position = ent.Position
		laser:SetMaxDistance(player.TearRange / 5)
		laser:AddTearFlags(player.TearFlags)
		data(laser).ParryBrimstone = true
	end
end
mod:AddCallback(mod.Enums.Callbacks.PERFECT_PARRY_KILL, Brim.BrimParry)