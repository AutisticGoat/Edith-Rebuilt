local mod = EdithRebuilt
local Brim = {}

---@param player EntityPlayer
---@param ent Entity
function Brim:BrimParry(player, ent)
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE) then return end

    local totalRays = 4
    local shootDegrees = 360 / totalRays
	for	i = 1, totalRays do
		local laser = player:FireDelayedBrimstone(shootDegrees * i, player)
		local brimData = mod.CustomDataWrapper.getData(laser)
        laser.Position = ent.Position
		laser:SetMaxDistance(player.TearRange / 5)
		laser:AddTearFlags(player.TearFlags)
		brimData.ParryBrimstone = true
        -- brimData.Ent = ent
	end
end
mod:AddCallback(mod.Enums.Callbacks.PERFECT_PARRY_KILL, Brim.BrimParry)