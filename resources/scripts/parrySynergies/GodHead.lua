local mod = EdithRebuilt
local callbacks = mod.Enums.Callbacks
local helpers = mod.Modules.HELPERS
local data = mod.CustomDataWrapper.getData

---@param player EntityPlayer
mod:AddCallback(callbacks.OFFENSIVE_STOMP, function(_, player)
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_GODHEAD) then return end		
	
    local godTear = player:FireTear(player.Position, Vector.Zero)
    
    godTear.Scale = 1.5 * player.SpriteScale.X
    godTear.CollisionDamage = 0
    godTear.Height = -10
    godTear:AddTearFlags(TearFlags.TEAR_GLOW | TearFlags.TEAR_SPECTRAL | TearFlags.TEAR_PIERCING)

    data(godTear).IsParryGodTear = true
    helpers.ChangeColor(godTear, nil, nil, nil, 0)
end)

---@param tear EntityTear  
function mod:RemoveKnife(tear)	
    if not data(tear).IsParryGodTear then return end
    tear.Height = -10
    tear.Position = (tear.Parent or tear.SpawnerEntity).Position

    if tear.FrameCount < 12 then return end
    tear:Remove()
end
mod:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, mod.RemoveKnife)