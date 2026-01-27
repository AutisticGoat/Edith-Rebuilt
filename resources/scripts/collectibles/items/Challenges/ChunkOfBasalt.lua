local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local utils = enums.Utils
local game = utils.Game
local sfx = utils.SFX
local modules = mod.Modules
local Helpers = modules.HELPERS
local EdithMod = modules.EDITH
local Player = modules.PLAYER
local ChunkOfBasalt = {}
local data = mod.DataHolder.GetEntityData

---@param player EntityPlayer
function ChunkOfBasalt:TriggerBasaltDash(player)
    if not player:HasCollectible(items.COLLECTIBLE_CHUNK_OF_BASALT) then return end
    if player:GetMovementDirection() == Direction.NO_DIRECTION then return end

    local playerData = data(player)

    playerData.BasaltCount = playerData.BasaltCount or 60

    if player.Velocity:Length() <= 7 then
        playerData.IsBasaltDassh = false
    end

    if playerData.IsBasaltDassh then
        player:CreateAfterimage(5, player.Position)
    end

    if not Helpers.IsKeyStompTriggered(player) then return end
    if playerData.IsBasaltDassh then return end

    if playerData.BasaltCount > 0 then return end
    playerData.BasaltCount = 60
    playerData.BasaltFlickering = 0
    sfx:Play(SoundEffect.SOUND_SHELLGAME)
    EdithMod.EdithDash(player, player:GetMovementInput():Normalized(), 60, 2)
    playerData.IsBasaltDassh = true
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, ChunkOfBasalt.TriggerBasaltDash)

---@param player EntityPlayer
function ChunkOfBasalt:Timer(player)
    if not player:HasCollectible(items.COLLECTIBLE_CHUNK_OF_BASALT) then return end
    local playerData = data(player)

    if playerData.IsBasaltDassh then return end
    playerData.BasaltCount = playerData.BasaltCount or 0
    playerData.BasaltCount = math.max(playerData.BasaltCount - 1, 0)

    if playerData.BasaltCount ~= 1 then return end
    sfx:Play(SoundEffect.SOUND_STONE_IMPACT)
    player:SetColor(Color(0.3, 0.3, 0.3), 5, -1, true, false)
end
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, ChunkOfBasalt.Timer)

---@param player EntityPlayer
function ChunkOfBasalt:Cooldown(player)
    if not player:HasCollectible(items.COLLECTIBLE_CHUNK_OF_BASALT) then return end
    local playerData = data(player)

    if playerData.BasaltCount > 0 then return end
    playerData.BasaltFlickering = playerData.BasaltFlickering or 0
    playerData.BasaltFlickering = playerData.BasaltFlickering + 1

    if playerData.BasaltFlickering == 10 then
        Player.SetColorCooldown(player, -0.6, 2)
        playerData.BasaltFlickering = 0
    end
end
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, ChunkOfBasalt.Cooldown)

---@param player EntityPlayer
---@param collider Entity
---@return boolean?
function ChunkOfBasalt:OnCollidingWithEnemy(player, collider)
    if not Helpers.IsEnemy(collider) then return end
    if not player:HasCollectible(items.COLLECTIBLE_CHUNK_OF_BASALT) then return end

    local playerData = data(player)
    if not playerData.IsBasaltDassh then return end

    local damageFormula = player.Damage * (player.Velocity:Length() / 5)
    local capsule = Capsule(player.Position, Vector.One, 0, 80)

    collider:TakeDamage(damageFormula, 0, EntityRef(player), 0)

    sfx:Play(SoundEffect.SOUND_MEATY_DEATHS)
    game:ShakeScreen(6)
    Helpers.TriggerPush(player, collider, 10)

    player:SetMinDamageCooldown(30)

    for rocks = 1, 8 do
        CustomShockwaveAPI:SpawnCustomCrackwave(
            player.Position, -- Position
            player, -- Spawner
            40, -- Steps
            rocks * (360 / 8), -- Angle
            1, -- Delay
            1, -- Limit
            player.Damage * 2 -- Damage
        )
    end

    for _, ent in ipairs(Isaac.FindInCapsule(capsule,EntityPartition.ENEMY)) do
        if GetPtrHash(ent) ~= GetPtrHash(collider) then
            collider:TakeDamage(damageFormula * 0.75, 0, EntityRef(player), 0)   
        end
    end
end
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_COLLISION, ChunkOfBasalt.OnCollidingWithEnemy)

function ChunkOfBasalt:DenyDamage(player)
    local playerData = data(player)

    if not playerData.IsBasaltDassh then return end
    playerData.IsBasaltDassh = false
    return false
end
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, ChunkOfBasalt.DenyDamage)

---@param player EntityPlayer
function ChunkOfBasalt:OnGridColl(player)
    local playerData = data(player)

    if not playerData.IsBasaltDassh then return end

    game:ShakeScreen(10)
    for rocks = 1, 8 do
        CustomShockwaveAPI:SpawnCustomCrackwave(
            player.Position, -- Position
            player, -- Spawner
            40, -- Steps
            rocks * (360 / 8), -- Angle
            1, -- Delay
            1, -- Limit
            player.Damage * 2 -- Damage
        )
    end
end
mod:AddCallback(ModCallbacks.MC_PLAYER_GRID_COLLISION, ChunkOfBasalt.OnGridColl)