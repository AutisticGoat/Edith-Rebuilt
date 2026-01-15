---FAMILIAPELUCHESOMOS

local mod = EdithRebuilt
local enums = mod.Enums
local Callbacks = enums.Callbacks
local helpers = mod.Modules.HELPERS
local data = mod.DataHolder.GetEntityData -- ESA NALGOTA VAN PA ENCIMA E MI

---@param player EntityPlayer
local function SpawnLudoTear(player)
    local playerData = data(player)

    if playerData.LudoTear then return end
    local tear = Isaac.Spawn(EntityType.ENTITY_TEAR, 0, 0, player.Position, Vector.Zero, player):ToTear() ---@cast tear EntityTear

    local tearData = data(tear)
    tear:AddTearFlags(player.TearFlags | TearFlags.TEAR_BOUNCE | TearFlags.TEAR_BOUNCE)

    if player:GetPlayerType() == enums.PlayerType.PLAYER_EDITH then
        helpers.ForceSaltTear(tear, false)
    end

    tearData.FakeLudo = true
    playerData.LudoTear = tear
end

function KillLudoTear(player)
    local playerData = data(player)

    if not playerData.LudoTear then return end
    playerData.LudoTear:Remove()
    playerData.LudoTear = nil
end

function mod:ForceSpawnFakeLudoTear(player)
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_LUDOVICO_TECHNIQUE) then return end
    SpawnLudoTear(player)
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, mod.ForceSpawnFakeLudoTear)

---@param tear EntityTear
function mod:LudoTearUpdate(tear)
    local tearData = data(tear)
    local player = helpers.GetPlayerFromTear(tear)

    if not tearData.FakeLudo then return end
    if not player then return end

    tear.Height = -23

    local damageDiv = 3.5
	local multScale = math.max((player.Damage / damageDiv), 1)
    local acceleration = tear.Velocity:Length()
    local playerTearDist = tear.Position:Distance(player.Position)
    local playerTearGridDist = playerTearDist / 40
    
	tear.Scale = 1.55 * multScale
    tear:MultiplyFriction(0.99)

    if tearData.HitByStomp then
        if acceleration <= 0.5 then
            tearData.HitByStomp = false
        end
    else
        tear.Velocity = tear.Velocity + (player.Position - tear.Position):Normalized() * (playerTearGridDist / 4)

        local atractStrenght = 0.4 * playerTearGridDist

        if playerTearDist <= 80 then
            tear:MultiplyFriction(math.min(atractStrenght, 0.95))
        end
    end
end
mod:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, mod.LudoTearUpdate)

---@param player EntityPlayer
---@param params EdithJumpStompParams
function mod:OnKnifeHittingLudoTear(player, params)
    for _, ent in ipairs(params.StompedEntities) do
        local tear = ent:ToTear()

        if not tear then goto continue end
        if not data(tear).FakeLudo then goto continue end

        data(tear).HitByStomp = true
        helpers.TriggerPush(tear, player, 100 + params.Knockback)
        ::continue::
    end
end
mod:AddCallback(Callbacks.OFFENSIVE_STOMP, mod.OnKnifeHittingLudoTear)

function mod:RoomChange()
    for _, player in ipairs(PlayerManager.GetPlayers()) do
        KillLudoTear(player)
    end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.RoomChange)