local mod = EdithRebuilt
local callbacks = mod.Enums.Callbacks
local Helpers = mod.Modules.HELPERS

---@param player EntityPlayer
---@param ent Entity
mod:AddCallback(callbacks.PERFECT_PARRY, function(_, player, ent)
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_LITTLE_HORN) then return end		
    if not Helpers.IsEnemy(ent) then return end

    local tear = Isaac.Spawn(EntityType.ENTITY_TEAR, 0, 0, ent.Position, Vector.Zero, player):ToTear() ---@cast tear EntityTear

    tear.CollisionDamage = 0
    tear.Visible = false
    tear.Color = Color(0, 0, 0, 0)
    tear:AddTearFlags(TearFlags.TEAR_HORN)
end)