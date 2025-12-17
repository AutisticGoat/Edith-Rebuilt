local mod = EdithRebuilt
local Brim = {}
local totalRays = 4
local shootDegrees = 360 / totalRays
local data = mod.CustomDataWrapper.getData

---@param player EntityPlayer
---@param ent Entity
function Brim:BrimParry(player, ent)
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE) then return end
	player:FireBrimstoneBall(player.Position, Vector.Zero)
end
mod:AddCallback(mod.Enums.Callbacks.PERFECT_PARRY_KILL, Brim.BrimParry)