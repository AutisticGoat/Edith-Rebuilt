local mod = EdithRebuilt
local enums = mod.Enums
local items = enums.CollectibleType
local Hydrargyrum = {}
local data = mod.CustomDataWrapper.getData

---@param entity Entity
---@param amount number
---@param flags DamageFlag
---@param source EntityRef
function Hydrargyrum:GettingDamage(entity, amount, flags, source)
    if source.Type == 0 then return end
    local player = mod.GetPlayerFromRef(source)
    
    if not (player and player:HasCollectible(items.COLLECTIBLE_HYDRARGYRUM)) then return end
    if not mod.IsEnemy(entity) then return end

    local entData = data(entity)

    if entData.MercuryTimer and entity.HitPoints <= amount then
        Isaac.Spawn(
            EntityType.ENTITY_EFFECT,
            EffectVariant.FIRE_JET,
            0,
            entity.Position,
            Vector.Zero,
            nil
        )
    end

    if not (entData.MercuryTimer == 0 or entData.MercuryTimer == nil) then return end
    entData.MercuryTimer = 120
    entData.Player = player
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, Hydrargyrum.GettingDamage)

---@param npc EntityNPC
function Hydrargyrum:OnNPCUpdate(npc)
    local entData = data(npc)
    if not entData.MercuryTimer then return end
    entData.MercuryTimer = math.max(entData.MercuryTimer - 1, 0)
    if entData.MercuryTimer % 15 ~= 0 or entData.MercuryTimer == 0 then return end

    local player = entData.Player ---@type EntityPlayer
    if not player then return end

    local randTear = Isaac.Spawn(
        EntityType.ENTITY_TEAR,
        TearVariant.METALLIC,
        0,
        npc.Position,
        RandomVector():Resized(player.ShotSpeed * 10),
        player
    ):ToTear()

    if not randTear then return end
    randTear.CollisionDamage = randTear.CollisionDamage * 0.1
    randTear:AddTearFlags(TearFlags.TEAR_PIERCING)
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, Hydrargyrum.OnNPCUpdate)