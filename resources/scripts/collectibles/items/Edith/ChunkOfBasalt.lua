---@diagnostic disable: undefined-field 
local mod = EdithRebuilt
local enums = mod.Enums
local misc = enums.Misc
local items = enums.CollectibleType
local utils = enums.Utils
local ChunkOfBasalt = {}

---@param player EntityPlayer
function ChunkOfBasalt:TriggerBasaltDash(player)
    if not player:HasCollectible(items.COLLECTIBLE_CHUNK_OF_BASALT) then return end
    
    
    local playerData = mod.GetData(player)

    playerData.BasaltCount = playerData.BasaltCount or 60

    if player.Velocity:Length() <= 7 then
        playerData.IsBasaltDassh = false
    end

    if playerData.IsBasaltDassh then
        player:CreateAfterimage(5, player.Position)
    end

    if not mod:IsKeyStompTriggered(player) then return end
    
    if playerData.IsBasaltDassh then return end

    if playerData.BasaltCount > 0 then return end
    playerData.BasaltCount = 60
    utils.SFX:Play(SoundEffect.SOUND_SHELLGAME)
    mod.EdithDash(player, player:GetMovementInput():Normalized(), 60, 2)
    playerData.IsBasaltDassh = true
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, ChunkOfBasalt.TriggerBasaltDash)

---@param player EntityPlayer
function ChunkOfBasalt:Timer(player)
    if not player:HasCollectible(items.COLLECTIBLE_CHUNK_OF_BASALT) then return end
    local playerData = mod.GetData(player)

    if playerData.IsBasaltDassh then return end
    playerData.BasaltCount = math.max(playerData.BasaltCount - 1, 0)

    if playerData.BasaltCount ~= 1 then return end
    utils.SFX:Play(SoundEffect.SOUND_STONE_IMPACT)
    player:SetColor(misc.BurnedSaltColor, 5, -1, true, false)
end
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, ChunkOfBasalt.Timer)

---@param player EntityPlayer
---@param collider Entity
---@return boolean?
function ChunkOfBasalt:OnCollidingWithEnemy(player, collider)
    if not player:HasCollectible(items.COLLECTIBLE_CHUNK_OF_BASALT) then return end
    local playerData = mod.GetData(player)
    if not playerData.IsBasaltDassh then return end
    
    local damageFormula = player.Damage * (player.Velocity:Length() / 4)

    collider:TakeDamage(damageFormula, 0, EntityRef(player), 0)

    utils.SFX:Play(SoundEffect.SOUND_MEATY_DEATHS)
    mod.TriggerPush(player, collider, 10, 1, false)

    if collider.HitPoints > damageFormula then return end
    for i = 1, math.random(5, 8) do
        local tear = Isaac.Spawn(EntityType.ENTITY_TEAR, 0, 0, collider.Position, RandomVector():Resized(15),  player):ToTear()

        if not tear then return end

        mod.ForceSaltTear(tear, true)
    end

    player:SetMinDamageCooldown(20)
end
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_COLLISION, ChunkOfBasalt.OnCollidingWithEnemy)

function ChunkOfBasalt:DenyDamage(player)
    local playerData = mod.GetData(player)

    if playerData.IsBasaltDassh then 
        playerData.IsBasaltDassh = false
        return false
    end
end
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, ChunkOfBasalt.DenyDamage)