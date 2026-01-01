local mod = EdithRebuilt
local callbacks = mod.Enums.Callbacks
local data = mod.DataHolder.GetEntityData

---@param player EntityPlayer
mod:AddCallback(callbacks.OFFENSIVE_STOMP, function(_, player)
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_LOST_CONTACT) then return end		

    local capsule = Capsule(player.Position, Vector.One, 0, 45)

    for _, ent in ipairs(Isaac.FindInCapsule(capsule, EntityPartition.BULLET)) do
        ent:Kill()
    end
end)