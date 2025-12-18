local mod = EdithRebuilt
local callbacks = mod.Enums.Callbacks
local data = mod.CustomDataWrapper.getData

---@param player EntityPlayer
mod:AddCallback(callbacks.OFFENSIVE_STOMP, function(_, player)
        if not player:HasCollectible(CollectibleType.COLLECTIBLE_SPIRIT_SWORD) then return end

    local knife = player:FireKnife(
        player,
        90,
        true,
        0,
        KnifeVariant.SPIRIT_SWORD
    )

    local knifeData = data(knife)
    local knifeSprite = knife:GetSprite()

    knifeSprite:Play("SpinDown", true)
    knife.Visible = false

    local effect = Isaac.Spawn(
        EntityType.ENTITY_EFFECT,
        EffectVariant.POOF01,
        0,
        player.Position,
        Vector.Zero,
        nil
    ):ToEffect() ---@cast effect EntityEffect

    effect:FollowParent(player)
    local effectSprite = effect:GetSprite()
    effectSprite:Load("gfx/008.010_spirit sword.anm2", true)
    effectSprite:Play("SpinDown")
    
    local damageMult = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and 0.75 or 0.5
    local baseDamage = ((player.Damage * 8) + 10)
    local formula = baseDamage * damageMult

    knife.SpriteScale = knife.SpriteScale * 1.7
    knifeData.ParrySword = true
    knife.CollisionDamage = formula
end)

---@param knife EntityKnife
function mod:RemoveStompKnife(knife)
    local knifeSprite = knife:GetSprite()
    local knifeData = data(knife)
	
    if knife.Variant ~= KnifeVariant.SPIRIT_SWORD or not knifeData.ParrySword then return end
    if not (knifeSprite:GetAnimation() == "SpinDown" and knifeSprite:IsFinished()) then return end

    knife:Remove()
end
mod:AddCallback(ModCallbacks.MC_POST_KNIFE_UPDATE, mod.RemoveStompKnife)