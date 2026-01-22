local mod = EdithRebuilt
local callbacks = mod.Enums.Callbacks
local Modules = mod.Modules
local helpers = Modules.HELPERS
local Player = Modules.PLAYER
local data = mod.DataHolder.GetEntityData

---@param player EntityPlayer
mod:AddCallback(callbacks.OFFENSIVE_STOMP, function (_, player)
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_GODHEAD) then return end		

    local scaleBase = Player.PlayerHasBirthright(player) and 2 or 1.5
    local godTear = Isaac.Spawn(EntityType.ENTITY_TEAR, 0, 0, player.Position, Vector.Zero, player):ToTear() ---@cast godTear EntityTear

    godTear.Scale = scaleBase * player.SpriteScale.X
    godTear.CollisionDamage = 0
    godTear.Height = -10
    godTear:AddTearFlags(TearFlags.TEAR_GLOW | TearFlags.TEAR_SPECTRAL | TearFlags.TEAR_PIERCING)

    data(godTear).IsStompGodTear = true
    godTear:Update()

    helpers.ChangeColor(godTear, nil, nil, nil, 0)
end)

---@param tear EntityTear  
mod:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, function(_, tear)
    if not data(tear).IsStompGodTear then return end

    tear.Height = -10
    tear.Position = (tear.Parent or tear.SpawnerEntity).Position

    local Count = Player.PlayerHasBirthright(helpers.GetPlayerFromTear(tear) --[[@as EntityPlayer]]) and 24 or 12

    if tear.FrameCount < Count then return end
    tear:Remove()
end)