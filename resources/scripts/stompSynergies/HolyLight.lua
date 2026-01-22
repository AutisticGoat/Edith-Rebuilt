local mod = EdithRebuilt
local enums = mod.Enums
local ModRNG = mod.Modules.RNG
local Callbacks = enums.Callbacks
local Player = mod.Modules.PLAYER

---@param player EntityPlayer
---@param ent Entity
---@param params EdithJumpStompParams
function mod:StompDamageAdders(player, ent, params)
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_HOLY_LIGHT) then return end

    local rng = player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_HOLY_LIGHT)
    local formula = 1 / math.max((10 - (player.Luck * 0.9)), 2)

    if not ModRNG.RandomBoolean(rng, formula) then return end

    local DamageMult = Player.PlayerHasBirthright(player) and 4 or 3

    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 10, ent.Position, Vector.Zero, player)
    ent:TakeDamage(params.Damage * DamageMult, DamageFlag.DAMAGE_LASER, EntityRef(player), 0)
end
mod:AddCallback(Callbacks.OFFENSIVE_STOMP_HIT, mod.StompDamageAdders)