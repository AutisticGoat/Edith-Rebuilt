local mod = EdithRebuilt
local funcs = require("resources.scripts.stompSynergies.Funcs")
local EdithJump = require("resources.scripts.stompSynergies.JumpData")

---@param player EntityPlayer
function mod:SwordStomp(player)
	if funcs.DefensiveStomp(player) then return end
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_SPIRIT_SWORD) then return end

    local knife = player:FireKnife(
        player,
        90,
        true,
        0,
        KnifeVariant.SPIRIT_SWORD
    )

    local knifeData = funcs.GetData(knife)
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
    knifeData.StompSword = true
    knife.CollisionDamage = formula
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, mod.SwordStomp, EdithJump)

function mod:RemoveStompKnife(knife)
    local knifeSprite = knife:GetSprite()
    local knifeData = funcs.GetData(knife)
	
    if knife.Variant ~= KnifeVariant.SPIRIT_SWORD or not knifeData.StompSword then return end
    if not (knifeSprite:GetAnimation() == "SpinDown" and knifeSprite:IsFinished()) then return end

    knife:Remove()
end
mod:AddCallback(ModCallbacks.MC_POST_KNIFE_UPDATE, mod.RemoveStompKnife)