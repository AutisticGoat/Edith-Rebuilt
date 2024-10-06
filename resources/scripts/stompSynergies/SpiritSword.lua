function edithMod:BrimStomp(player)
    if player:HasCollectible(CollectibleType.COLLECTIBLE_SPIRIT_SWORD) then
        -- Obtener datos del jugador y la espada
        local playerData = JumpLib:GetData(player)
        local isJumping = playerData.Jumping

        -- Verificar si se ha presionado la tecla de salto
        if edithMod:IsKeyStompPressed(player) then return end

        -- Crear un nuevo cuchillo (espada espiritual)
        local knife = player:FireKnife(
            player,
            90,
            true,
            0,
            KnifeVariant.SPIRIT_SWORD
        )

        -- Obtener datos del cuchillo
        local knifeData = edithMod:GetData(knife)
        local knifeSprite = knife:GetSprite()

        -- Configurar el cuchillo
        knifeSprite:Play("SpinDown", true)
        knife.Visible = false

        -- Crear un efecto de poof
        local effect = TSIL.EntitySpecific.SpawnEffect(
            EffectVariant.POOF01,
            0,
            player.Position
        )

        -- Configurar el efecto
        effect:FollowParent(player)
        local effectSprite = effect:GetSprite()
        local spritePath = "gfx/008.010_spirit sword.anm2"
        effectSprite:Load(spritePath, true)
        effectSprite:Play("SpinDown")

        -- Calcular el daño
        local damageMult = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and 0.75 or 0.5
        local baseDamage = ((player.Damage * 8) + 10)
        local formula = baseDamage * damageMult

        -- Configurar el cuchillo
        knife.SpriteScale = knife.SpriteScale * 1.7
        knifeData.StompSword = true
        knife.CollisionDamage = formula
    end
end
edithMod:AddCallback(JumpLib.Callbacks.PLAYER_LAND, edithMod.BrimStomp, {
    tag = "edithMod_EdithJump",
})

function edithMod:RemoveStompKnife(knife)
    local knifeSprite = knife:GetSprite()
    local knifeData = edithMod:GetData(knife)
	
    if knife.Variant ~= KnifeVariant.SPIRIT_SWORD or not knifeData.StompSword then
        return
    end

    if knifeSprite:GetAnimation() == "SpinDown" and knifeSprite:IsFinished() then
        knife:Remove()
    end
end
edithMod:AddCallback(ModCallbacks.MC_POST_KNIFE_UPDATE, edithMod.RemoveStompKnife)

