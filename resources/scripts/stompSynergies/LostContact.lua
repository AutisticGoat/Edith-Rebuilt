local mod = EdithRebuilt
local callbacks = mod.Enums.Callbacks
local data = mod.DataHolder.GetEntityData

---@param player EntityPlayer
mod:AddCallback(callbacks.OFFENSIVE_STOMP, function(_, player)
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_LOST_CONTACT) then return end		

    local capsule = Capsule(player.Position, Vector.One, 0, 45)

    DebugRenderer.Get(1, false):Capsule(capsule)

    for _, ent in ipairs(Isaac.FindInCapsule(capsule, EntityPartition.BULLET)) do
        ent:Kill()
    end

	-- local knifeEntities = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and 8 or 4
	-- local degrees = 360/knifeEntities
	-- local knife

	-- for i = 1, knifeEntities do
	-- 	knife = player:FireKnife(player, degrees * i, true, 0, 0)
	-- 	knife:Shoot(1, player.TearRange / 3)
	-- 	data(knife).StompKnife = true			
	-- end
end)