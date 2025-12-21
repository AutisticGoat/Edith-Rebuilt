local mod = EdithRebuilt
local callbacks = mod.Enums.Callbacks
local Modules = mod.Modules
local helpers = Modules.HELPERS
local Player = Modules.PLAYER
local Maths = Modules.MATHS
local Helpers = Modules.HELPERS
local data = mod.DataHolder.GetEntityData

---@param player EntityPlayer
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, function (_, player)
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_GODHEAD) then return end		

    local godTear = Isaac.Spawn(EntityType.ENTITY_TEAR, 0, 0, player.Position, Vector.Zero, player):ToTear() ---@cast godTear EntityTear

    print("Spawn")

    godTear:GetData().IsStompGodTear = true

    godTear.Scale = 1.5 * player.SpriteScale.X
    godTear.CollisionDamage = 0
    godTear.Height = -10
    godTear:AddTearFlags(TearFlags.TEAR_GLOW | TearFlags.TEAR_SPECTRAL | TearFlags.TEAR_PIERCING)

    print(Maths.HasBitFlags(godTear.TearFlags, TearFlags.TEAR_HOMING))

    helpers.ChangeColor(godTear, nil, nil, nil, 0)
end, mod.Enums.Tables.JumpParams.EdithJump)

---@param tear EntityTear  
mod:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, function(_, tear)
    if not tear:GetData().IsStompGodTear then return end
    if Maths.HasBitFlags(tear.TearFlags, TearFlags.TEAR_HOMING) then return end

    print("mierdaaaaaaa")

    tear.Height = -10
    tear.Position = (tear.Parent or tear.SpawnerEntity).Position

    local Count = Player.PlayerHasBirthright(Helpers.GetPlayerFromTear(tear) --[[@as EntityPlayer]]) and 24 or 12

    if tear.FrameCount < Count then return end
    tear:Remove()
end)