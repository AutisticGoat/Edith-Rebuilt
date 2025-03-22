local DynamicMinisaacLib = {}

--This Library is a librarified version of the Dynamic Minisaac ModReference.
--Requires Catinsurance's Save Manager to work.

local ModReference = edithMod
local savemanager = edithMod.SaveManager

--Do this in the main.lua:
--GLOBAL_VARIABLE = RegisterMod("The Coolest Motherfucking Mod Ever", 1)
--GLOBAL_VARIABLE.SaveManager = include("path.to.savemanager")
--GLOBAL_VARIABLE.MimicShitNow = include("path.to.minisaac.lib")

--Then return to this lua file and do the following:
--GLOBAL_VARIABLE should replace "Insert your mod's global variable here"
--Replace "Insert your mod's save manager variable here" with GLOBAL_VARIABLE.SaveManager
--Only works with Catinsurance's SaveManager because I fucking suck at programming. Sorry.

--If you want to spawn a mimicking minisaac, do the following:
--GLOBAL_VARIABLE.MimicShitNow:AddIncubusAtHome(EntityPlayer, MinisaacPosition)
--Treat this like the base api's AddMinisaac(), without the playanim argument.
--This function returns an EntityFamiliar Object.

--If both arguments are nil, spawns a mimicking Minisaac that mimics P1 at P1's Position by default.

--!!! DO NOT MESS WITH THE MINISAACS' KEY COUNT(Minisaac.Keys)!!!

DynamicMinisaacLib.TearDelayMult = {
    BRIM = 4,
    MORSHU = 6,
    BONERBRIM = 3,
    FETUS = 3,
    TECH_X = 3,
    EPIC = 8,
    MONSTRO = 4
}

DynamicMinisaacLib.TearDelayModif = {
    CHOC = 2,
    MONSTRO = 4
}

function DynamicMinisaacLib:ShouldNotMimic(Familiar)
    local runSave = savemanager.GetRunSave(Familiar)
    return not (runSave and runSave.IsMimickedMinisaac and not DynamicMinisaacContinued)
end

local NonTearWeaponTypes = {
    WeaponType.WEAPON_BRIMSTONE,
    WeaponType.WEAPON_LASER,
    WeaponType.WEAPON_KNIFE,
    WeaponType.WEAPON_BOMBS,
    WeaponType.WEAPON_ROCKETS,
    WeaponType.WEAPON_MONSTROS_LUNGS,
    WeaponType.WEAPON_LUDOVICO_TECHNIQUE,
    WeaponType.WEAPON_TECH_X,
    WeaponType.WEAPON_BONE,
    WeaponType.WEAPON_SPIRIT_SWORD,
    WeaponType.WEAPON_FETUS,
}

---comment
---@param tear EntityTear
---@return boolean
local function IsMiniIsaacTear(tear)
    local tearSpawner = tear.SpawnerEntity
    if not tearSpawner then return end

    -- DON'T USE PARENT! I already made the mistake of using Entity.Parent for Lewis's tear scale during K&G's development

    return tear.SpawnerEntity.Type == EntityType.ENTITY_FAMILIAR and tear.SpawnerEntity.Variant == FamiliarVariant.MINISAAC
end

---@param tear EntityTear
function DynamicMinisaacLib:InheritTearFlags(tear)
    if not IsMiniIsaacTear(tear) then return end 
    local minisaac = tear.SpawnerEntity:ToFamiliar()

    if not minisaac then return end
    local player = minisaac.Player

    if not player then return end
    local hasNonTearWeapon = false

    for _, v in ipairs(NonTearWeaponTypes) do
        if player:HasWeaponType(v) then
            hasNonTearWeapon = true
        end
    end     

    if hasNonTearWeapon then return end

    if DynamicMinisaacLib:ShouldNotMimic(tear.SpawnerEntity) == true then return end

    if player:HasCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK) then
        if minisaac.Keys < DynamicMinisaacLib.TearDelayModif.CHOC - 1 then
            tear:GetData().RemoveMinisaacTimer = 1
            SFXManager():Play(SoundEffect.SOUND_TEARS_FIRE, 0)
            minisaac.Keys = minisaac.Keys + 1 --Originally a value for Key bums, but we're using this as a stable way to prevent bugs and mimic the charging mechanic of the weapons
        else
            minisaac.Keys = 0
        end
    end

    --[[
        thanks wofsauge
        ...and I wish all luck based tear effects a very FUCK YOU
        FUCK YOU APPLE FUCK YOU TOO TOUGH LOVE
        I FUCKING HATE YOU AND HOPE YOU DIE!!!!!!
    ]]--
    local tempEffects = player:GetTearHitParams(WeaponType.WEAPON_TEARS, 1, 1, player)

    tear.Color = tempEffects.TearColor
    tear:GetData().InitComplete = false
    tear:ChangeVariant(tempEffects.TearVariant)
    tear:AddTearFlags(tempEffects.TearFlags)

    if tear.TearFlags and TearFlags.TEAR_LUDOVICO ~= 0 then
        tear:ClearTearFlags(TearFlags.TEAR_LUDOVICO) --Ludo tear flag makes the tear linger forever
    end
end
ModReference:AddCallback(ModCallbacks.MC_POST_TEAR_INIT, DynamicMinisaacLib.InheritTearFlags)
--Now no longer splits indefinitely

---@param tear EntityTear
function DynamicMinisaacLib:TEARINITLATE(tear) --Code made by peeking TSIL's Post Init Tear Late Callback
    if tear:GetData().InitComplete == false then
        local minisaac = tear.SpawnerEntity:ToFamiliar()
        if not minisaac then return end
        local player = minisaac.Player

        if DynamicMinisaacLib:ShouldNotMimic(tear.SpawnerEntity) == true then return end
        local tempEffects = player:GetTearHitParams(WeaponType.WEAPON_TEARS, 1, 1, player)
        local dmg = ((tempEffects.TearDamage / 3.5) * ((11 / 30) * (30 / (1 + player.MaxFireDelay)))) * 1.4

        if player:HasCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK) then
            dmg = dmg * 3
            tear.Scale = tear.Scale * 2
        end

        tear.CollisionDamage = dmg
        tear:GetData().InitComplete = nil
    end
end
ModReference:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, DynamicMinisaacLib.TEARINITLATE)

--Stops the tear fire sfx

local directionToVector = {
    [Direction.RIGHT] = Vector(1, 0),
    [Direction.LEFT] = Vector(-1, 0),
    [Direction.UP] = Vector(0, -1),
    [Direction.DOWN] = Vector(0, 1),
}

function DynamicMinisaacLib:InheritBrimstone(entity)
    if not IsMiniIsaacTear(entity) then return end
        local minisaac = entity.SpawnerEntity:ToFamiliar()
        local player = minisaac.Player

        if player and player:HasWeaponType(WeaponType.WEAPON_BRIMSTONE) then
            if DynamicMinisaacLib:ShouldNotMimic(entity.SpawnerEntity) == true then return end --Check if you're gonna blacklost or override the minisaacs' behavior
            entity:GetData().RemoveMinisaacTimer = 1
            SFXManager():Play(SoundEffect.SOUND_TEARS_FIRE, 0)

            minisaac.Keys = minisaac.Keys + 1

            local tempEffects = player:GetTearHitParams(WeaponType.WEAPON_BRIMSTONE, 1, 1, player)
            local delay = DynamicMinisaacLib.TearDelayMult.BRIM

            if player:HasCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK) then
                delay = delay * DynamicMinisaacLib.TearDelayModif.CHOC
            end

            if minisaac.Keys >= delay then
                local fireDirection = minisaac.ShootDirection

                if fireDirection == Direction.LEFT then
                    direction = Vector(-1, 0)
                elseif fireDirection == Direction.RIGHT then
                    direction = Vector(1, 0)
                elseif fireDirection == Direction.DOWN then
                    direction = Vector(0, 1)
                elseif fireDirection == Direction.UP then
                    direction = Vector(0, -1)
                end

                local multbrim = (entity.CollisionDamage * ((player.Damage / 3.5) * ((11 / 30) * (30 / (1 + player.MaxFireDelay))))) / (1.12 * player.Damage)

                if player:HasCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK) then
                    multbrim = multbrim * 3
                end

                local brimring = player:FireBrimstone(direction, entity.SpawnerEntity, multbrim)

                brimring.Timeout = 5
                brimring.Parent = entity.SpawnerEntity

                brimring.AngleDegrees = direction:GetAngleDegrees()

                brimring.MaxDistance = 150
                minisaac.Keys = 0

                brimring.ParentOffset = Vector(0, 10)

                if player:HasCollectible(678) then --FUCK
                    for i = 1, 4 do
                        local tempEffect = player:GetTearHitParams(WeaponType.WEAPON_FETUS, 1, 1, player)

                        local sfx = SFXManager()
                        local _ = nil
                        sfx:Play(237, _, _, _, 2)

                        local baby =
                            player:FireTear(
                            minisaac.Position,
                            entity.Velocity:Rotated((player:GetCollectibleRNG(678):RandomInt(100) % 20) - 10),
                            false,
                            true,
                            false,
                            minisaac,
                            (entity.CollisionDamage *
                                ((player.Damage / 3.5) * ((11 / 30) * (30 / (1 + player.MaxFireDelay))))) /
                                (2 * player.Damage)
                    )

                    if baby.Variant ~= tempEffect.TearVariant then
                        baby:ChangeVariant(tempEffect.TearVariant)
                    end

                    baby.Color = tempEffect.TearColor
                    baby.TearFlags = tempEffect.TearFlags | TearFlags.TEAR_FETUS --Fuck

                    if player:HasCollectible(395) then --Techx
                        baby:AddTearFlags(TearFlags.TEAR_FETUS_TECHX)
                    end
                    if player:HasCollectible(579) then --sword
                        baby:AddTearFlags(TearFlags.TEAR_FETUS_SWORD)
                    end
                    if player:HasCollectible(114) then --knife
                        baby:AddTearFlags(TearFlags.TEAR_FETUS_KNIFE)
                    end
                    if player:HasCollectible(52) then --Fetus
                        baby:AddTearFlags(TearFlags.TEAR_FETUS_BOMBER)
                    end
                    if player:HasCollectible(68) then --tech
                        baby:AddTearFlags(TearFlags.TEAR_FETUS_TECH)
                    end
                end
            end
        end
    end
end
ModReference:AddCallback(ModCallbacks.MC_POST_TEAR_INIT, DynamicMinisaacLib.InheritBrimstone)

function DynamicMinisaacLib:InheritTech(entity)
    if
        entity.SpawnerEntity and entity.SpawnerEntity.Type == EntityType.ENTITY_FAMILIAR and
            entity.SpawnerEntity.Variant == FamiliarVariant.MINISAAC
     then
        local minisaac = entity.SpawnerEntity:ToFamiliar()
        local player = minisaac.Player

        if player and player:HasWeaponType(WeaponType.WEAPON_LASER) then
            if DynamicMinisaacLib:ShouldNotMimic(entity.SpawnerEntity) == true then
                return
            end
            entity:GetData().RemoveMinisaacTimer = 1
            SFXManager():Play(SoundEffect.SOUND_TEARS_FIRE, 0)

            if player:HasCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK) then
                minisaac.Keys = minisaac.Keys + 1
            end

            local delay = 1

            if player:HasCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK) then
                delay = delay * DynamicMinisaacLib.TearDelayModif.CHOC
            end

            if player:HasCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK) then
                if minisaac.Keys >= delay then
                    local tempEffects = player:GetTearHitParams(WeaponType.WEAPON_LASER, 1, 1, player)

                    local fireDirection = minisaac.ShootDirection

                    if fireDirection == Direction.LEFT then
                        direction = Vector(-1, 0)
                    elseif fireDirection == Direction.RIGHT then
                        direction = Vector(1, 0)
                    elseif fireDirection == Direction.DOWN then
                        direction = Vector(0, 1)
                    elseif fireDirection == Direction.UP then
                        direction = Vector(0, -1)
                    end

                    local brimring = Isaac.Spawn(7, 2, 0, minisaac.Position, Vector.Zero, player):ToLaser()

                    brimring.Timeout = 1
                    brimring.CollisionDamage =
                        (1.2 * entity.CollisionDamage *
                        ((player.Damage / 3.5) * ((11 / 30) * (30 / (1 + player.MaxFireDelay)))))

                    brimring.Parent = entity.SpawnerEntity
                    brimring.AngleDegrees = direction:GetAngleDegrees()
                    brimring.MaxDistance = 150

                    minisaac.Keys = 0
                end
            else
                local tempEffects = player:GetTearHitParams(WeaponType.WEAPON_LASER, 1, 1, player)

                local fireDirection = minisaac.ShootDirection

                if fireDirection == Direction.LEFT then
                    direction = Vector(-1, 0)
                elseif fireDirection == Direction.RIGHT then
                    direction = Vector(1, 0)
                elseif fireDirection == Direction.DOWN then
                    direction = Vector(0, 1)
                elseif fireDirection == Direction.UP then
                    direction = Vector(0, -1)
                end

                local brimring = Isaac.Spawn(7, 2, 0, minisaac.Position, Vector.Zero, player):ToLaser()

                brimring.Timeout = 1
                brimring.CollisionDamage =
                    (0.4 * entity.CollisionDamage *
                    ((player.Damage / 3.5) * ((11 / 30) * (30 / (1 + player.MaxFireDelay)))))

                brimring.Parent = entity.SpawnerEntity
                brimring.AngleDegrees = direction:GetAngleDegrees()
                brimring.MaxDistance = 150
            end
        end
    end
end
ModReference:AddCallback(ModCallbacks.MC_POST_TEAR_INIT, DynamicMinisaacLib.InheritTech)

function DynamicMinisaacLib:InheritMorshu(entity)
    if
        entity.SpawnerEntity and entity.SpawnerEntity.Type == EntityType.ENTITY_FAMILIAR and
            entity.SpawnerEntity.Variant == FamiliarVariant.MINISAAC
     then
        local minisaac = entity.SpawnerEntity:ToFamiliar()
        local player = minisaac.Player

        if player and player:HasWeaponType(WeaponType.WEAPON_BOMBS) then
            if DynamicMinisaacLib:ShouldNotMimic(entity.SpawnerEntity) == true then
                return
            end
            entity:GetData().RemoveMinisaacTimer = 1
            SFXManager():Play(SoundEffect.SOUND_TEARS_FIRE, 0)

            minisaac.Keys = minisaac.Keys + 1

            local tempEffects = player:GetTearHitParams(WeaponType.WEAPON_BOMBS, 1, 1, player)

            local delay = DynamicMinisaacLib.TearDelayMult.MORSHU

            if player:HasCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK) then
                delay = delay * DynamicMinisaacLib.TearDelayModif.CHOC
            end

            if minisaac.Keys >= delay then
                local fireDirection = minisaac.ShootDirection

                if fireDirection == Direction.LEFT then
                    direction = Vector(-1, 0)
                elseif fireDirection == Direction.RIGHT then
                    direction = Vector(1, 0)
                elseif fireDirection == Direction.DOWN then
                    direction = Vector(0, 1)
                elseif fireDirection == Direction.UP then
                    direction = Vector(0, -1)
                end

                local bomb = Isaac.Spawn(4, 14, 0, minisaac.Position, direction * 11.5, player):ToBomb()
                bomb.SpriteScale = Vector(0.4, 0.4)

                local explmult = 15 * ((player.Damage / 3.5) * ((11 / 30) * (30 / (1 + player.MaxFireDelay))))

                if player:HasCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK) then
                    explmult = explmult * 3
                end

                bomb.ExplosionDamage = explmult

                bomb.RadiusMultiplier = 0.3
                bomb.Flags = tempEffects.TearFlags | TearFlags.TEAR_STICKY
                bomb.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYERONLY

                minisaac.Keys = 0
            end
        end
    end
end
ModReference:AddCallback(ModCallbacks.MC_POST_TEAR_INIT, DynamicMinisaacLib.InheritMorshu)

function DynamicMinisaacLib:InheritKNIFE(entity)
    if
        entity.SpawnerEntity and entity.SpawnerEntity.Type == EntityType.ENTITY_FAMILIAR and
            entity.SpawnerEntity.Variant == FamiliarVariant.MINISAAC
     then
        local minisaac = entity.SpawnerEntity:ToFamiliar()
        local player = minisaac.Player

        if
            player and player:HasWeaponType(WeaponType.WEAPON_KNIFE) and minisaac:GetData().IsWieldingBlade and
                minisaac:GetData().IsWieldingBlade == true
         then
            if DynamicMinisaacLib:ShouldNotMimic(entity.SpawnerEntity) == true then
                return
            end
            entity:GetData().RemoveMinisaacTimer = 1
            SFXManager():Play(SoundEffect.SOUND_TEARS_FIRE, 0)

            minisaac.Keys = minisaac.Keys + 1

            if minisaac.Keys >= math.ceil(0.65 * (1 + player.MaxFireDelay)) then
                minisaac:GetData().IsShootingMinisaacKnife = true

                minisaac.Keys = 0
            end
        end
    end
end
ModReference:AddCallback(ModCallbacks.MC_POST_TEAR_INIT, DynamicMinisaacLib.InheritKNIFE)

function DynamicMinisaacLib:RemoveUselessTears(tear)
    if tear:GetData().RemoveMinisaacTimer then
        SFXManager():Play(SoundEffect.SOUND_TEARS_FIRE, 0)
        local sfx = SFXManager()
        if sfx:IsPlaying(SoundEffect.SOUND_TEARS_FIRE) then
            sfx:Stop(SoundEffect.SOUND_TEARS_FIRE)
        end
        tear:GetData().RemoveMinisaacTimer = tear:GetData().RemoveMinisaacTimer - 1

        if tear:GetData().RemoveMinisaacTimer <= 0 then
            tear:Remove()

            if sfx:IsPlaying(SoundEffect.SOUND_TEARS_FIRE) then
                sfx:Stop(SoundEffect.SOUND_TEARS_FIRE)
            end
        end
    end
end
ModReference:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, DynamicMinisaacLib.RemoveUselessTears)

function DynamicMinisaacLib:InheritKNIFEUPD(minisaac)
    local player = minisaac.Player
    if player and player:HasWeaponType(WeaponType.WEAPON_KNIFE) and minisaac.Variant == FamiliarVariant.MINISAAC then
        if DynamicMinisaacLib:ShouldNotMimic(entity.SpawnerEntity) == true then
            return
        end
        if minisaac.SubType ~= 99 then
            local chara = Isaac.Spawn(8, 0, 0, minisaac.Position, Vector.Zero, minisaac):ToKnife()
            chara.Parent = minisaac
            chara.Scale = 0.6
            chara.SpriteScale = Vector(0.6, 0.6)

            minisaac:PickEnemyTarget(math.huge, 13, 16, ConeDir, ConeAngle)
            minisaac:GetData().IsWieldingBlade = true
        end
    end
end
ModReference:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, DynamicMinisaacLib.InheritKNIFEUPD)

function DynamicMinisaacLib:AddKnivesNow(minisaac)
    local player = minisaac.Player
    if player and minisaac.Variant == FamiliarVariant.MINISAAC then
        if DynamicMinisaacLib:ShouldNotMimic(minisaac) == true then
            return
        end
        if
            (player:HasWeaponType(2) or player:HasWeaponType(3) or player:HasWeaponType(4) or player:HasWeaponType(5) or
                player:HasWeaponType(6) or
                player:HasWeaponType(10) or
                player:HasWeaponType(13) or
                player:HasWeaponType(14) or
                player:HasWeaponType(14)) and
                minisaac.FireCooldown == 0
         then
            local sfx = SFXManager()
            if sfx:IsPlaying(SoundEffect.SOUND_TEARS_FIRE) then
                sfx:Stop(SoundEffect.SOUND_TEARS_FIRE)
            end
        end

        if player:HasWeaponType(WeaponType.WEAPON_KNIFE) then
            if minisaac.SubType ~= 99 then
                if minisaac:GetData().IsWieldingBlade == nil then
                    local chara = Isaac.Spawn(8, 0, 0, minisaac.Position, Vector.Zero, minisaac):ToKnife()
                    chara.Parent = minisaac
                    chara.Scale = 0.6
                    chara.SpriteScale = Vector(0.6, 0.6)

                    minisaac:PickEnemyTarget(math.huge, 13, 16, ConeDir, ConeAngle)
                    minisaac:GetData().IsWieldingBlade = true
                end
            end
        else
            if minisaac:GetData().IsWieldingBlade ~= nil then
                minisaac:GetData().IsWieldingBlade = nil
            end
        end
    end
end
ModReference:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, DynamicMinisaacLib.AddKnivesNow)

function DynamicMinisaacLib:InheritKNIFEBONER(knife)
    if knife.SpawnerEntity then
        local minisaac = knife.SpawnerEntity:ToFamiliar()
        if minisaac then
            local player = minisaac.Player
            if
                player and minisaac.Variant == FamiliarVariant.MINISAAC and minisaac.SubType == 99 and
                    player:HasWeaponType(WeaponType.WEAPON_BONE)
             then
                if DynamicMinisaacLib:ShouldNotMimic(minisaac) == true then
                    return
                end
                local tempEffects = player:GetTearHitParams(WeaponType.WEAPON_BONE, 1, 1, nil)

                knife:AddTearFlags(player.TearFlags)

                local fireDirection = minisaac.ShootDirection

                if fireDirection == Direction.LEFT then
                    direction = Vector(-1, 0)
                elseif fireDirection == Direction.RIGHT then
                    direction = Vector(1, 0)
                elseif fireDirection == Direction.DOWN then
                    direction = Vector(0, 1)
                elseif fireDirection == Direction.UP then
                    direction = Vector(0, -1)
                end

                if player:HasCollectible(118) then --brim
                    minisaac.Keys = minisaac.Keys + 1

                    local delay = DynamicMinisaacLib.TearDelayMult.BONERBRIM

                    if player:HasCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK) then
                        delay = delay * DynamicMinisaacLib.TearDelayModif.CHOC
                    end

                    if minisaac.Keys >= delay then
                        local brimring2 = Isaac.Spawn(7, 1, 2, minisaac.Position, direction * 6, player):ToLaser()
                        brimring2.Radius = 13
                        brimring2.Parent = knife.SpawnerEntity
                        brimring2.Timeout = 13

                        local multbrim =
                            (knife.CollisionDamage * 0.25 *
                            ((player.Damage / 5.25) * ((22 / 30) * (30 / (1 + player.MaxFireDelay)))))

                        if player:HasCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK) then
                            multbrim = multbrim * 3
                        end

                        brimring2.CollisionDamage = multbrim
                        brimring2.Visible = false

                        local brimring3 =
                            Isaac.Spawn(1000, 113, 0, brimring2.Position, brimring2.Velocity, player):ToEffect()
                        brimring3:GetData().ForgorMinisaacBrimBall = true
                        brimring3.SpriteScale = Vector(0.5, 0.5)
                        brimring3.Parent = brimring2
                        brimring3.Timeout = 12
                        local sfx = SFXManager()
                        sfx:Play(SoundEffect.SOUND_BLOOD_LASER_SMALL, Volume, FrameDelay, Loop, 1, Pan)
                        SFXManager():Play(273, 0)

                        minisaac.Keys = 0
                    end
                end

                if player:HasCollectible(68) or player:HasCollectible(395) then --tech
                    local brimring = Isaac.Spawn(7, 2, 3, minisaac.Position, Vector.Zero, player):ToLaser()
                    brimring.Radius = 40
                    brimring.Parent = knife.SpawnerEntity
                    brimring.Timeout = 1
                    brimring.CollisionDamage =
                        (knife.CollisionDamage * 0.25 *
                        ((player.Damage / 5.25) * ((22 / 30) * (30 / (1 + player.MaxFireDelay)))))
                end
            end
        end
    end
end
ModReference:AddCallback(ModCallbacks.MC_POST_KNIFE_INIT, DynamicMinisaacLib.InheritKNIFEBONER)

function DynamicMinisaacLib:RocketUpdate2(ItSeemsThatMyTurtleHasDiedNoooo)
    if
        not (ItSeemsThatMyTurtleHasDiedNoooo:GetData().ForgorMinisaacBrimBall and
            ItSeemsThatMyTurtleHasDiedNoooo:GetData().ForgorMinisaacBrimBall == true and
            ItSeemsThatMyTurtleHasDiedNoooo.Parent)
     then
        return
    end

    ItSeemsThatMyTurtleHasDiedNoooo.Velocity =
        (ItSeemsThatMyTurtleHasDiedNoooo.Parent.Position - ItSeemsThatMyTurtleHasDiedNoooo.Position)
    ItSeemsThatMyTurtleHasDiedNoooo.SpriteScale = Vector(0.5, 0.5)
end
ModReference:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, DynamicMinisaacLib.RocketUpdate2)

function DynamicMinisaacLib:InheritKNIFEBONER2(knife)
    if knife.SpawnerEntity then
        local minisaac = knife.SpawnerEntity:ToFamiliar()
        if minisaac then
            local player = minisaac.Player
            if player and minisaac.Variant == FamiliarVariant.MINISAAC and minisaac.SubType == 99 then
                knife.CollisionDamage =
                    (knife.CollisionDamage *
                    ((player.Damage / 5.25) * ((22 / 30) * (30 / (1 + player.MaxFireDelay)))) ^ 0.333333)

                local fireDirection = minisaac.ShootDirection

                if fireDirection == Direction.LEFT then
                    direction = Vector(-1, 0)
                elseif fireDirection == Direction.RIGHT then
                    direction = Vector(1, 0)
                elseif fireDirection == Direction.DOWN then
                    direction = Vector(0, 1)
                elseif fireDirection == Direction.UP then
                    direction = Vector(0, -1)
                end
            end
        end
    end
end
ModReference:AddCallback(ModCallbacks.MC_POST_KNIFE_UPDATE, DynamicMinisaacLib.InheritKNIFEBONER2)

function DynamicMinisaacLib:KnifeUpdate(knife)
    if knife.Parent then
        local minisaac = knife.Parent:ToFamiliar()
        if minisaac and minisaac.Variant == FamiliarVariant.MINISAAC then
            local player = minisaac.Player

            local fireDirection = minisaac.ShootDirection

            if fireDirection == Direction.LEFT then
                direction = Vector(-1, 0)
            elseif fireDirection == Direction.RIGHT then
                direction = Vector(1, 0)
            elseif fireDirection == Direction.DOWN then
                direction = Vector(0, 1)
            elseif fireDirection == Direction.UP then
                direction = Vector(0, -1)
            end

            if direction then
                if not knife:IsFlying() then
                    if knife.Rotation ~= (direction):GetAngleDegrees() then
                        knife.Rotation = knife.Rotation + ((direction):GetAngleDegrees() - knife.Rotation) / 4
                    else
                        knife.Rotation = (direction):GetAngleDegrees()
                    end
                end
            end

            local tempEffects = player:GetTearHitParams(WeaponType.WEAPON_KNIFE, 1, 1, player)

            knife.Scale = 0.4
            knife.SpriteScale = Vector(0.6, 0.6)
            knife.TearFlags = tempEffects.TearFlags

            if minisaac:GetData().IsShootingMinisaacKnife and minisaac:GetData().IsShootingMinisaacKnife == true then
                knife:Shoot(0.7, 190)

                minisaac:GetData().IsShootingMinisaacKnife = nil
            end

            if not (Game():GetFrameCount() % 3 == 0) then
                knife.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            else
                knife.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ENEMIES
            end
        end
    end
end
ModReference:AddCallback(ModCallbacks.MC_POST_KNIFE_UPDATE, DynamicMinisaacLib.KnifeUpdate)

function DynamicMinisaacLib:InheritBaby(entity)
    if
        entity.SpawnerEntity and entity.SpawnerEntity.Type == EntityType.ENTITY_FAMILIAR and
            entity.SpawnerEntity.Variant == FamiliarVariant.MINISAAC
     then
        local minisaac = entity.SpawnerEntity:ToFamiliar()
        local player = minisaac.Player

        if player and player:HasWeaponType(WeaponType.WEAPON_FETUS) then
            if DynamicMinisaacLib:ShouldNotMimic(entity.SpawnerEntity) == true then
                return
            end
            entity:GetData().RemoveMinisaacTimer = 1
            SFXManager():Play(SoundEffect.SOUND_TEARS_FIRE, 0)

            minisaac.Keys = minisaac.Keys + 1

            local tempEffects = player:GetTearHitParams(WeaponType.WEAPON_FETUS, 1, 1, player)

            local delay = DynamicMinisaacLib.TearDelayMult.FETUS

            if player:HasCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK) then
                delay = delay * DynamicMinisaacLib.TearDelayModif.CHOC
            end

            if minisaac.Keys >= delay then
                local sfx = SFXManager()
                sfx:Play(237, Volume, FrameDelay, Loop, 2, Pan)

                local multbaby =
                    (entity.CollisionDamage * ((player.Damage / 3.5) * ((11 / 30) * (30 / (1 + player.MaxFireDelay))))) /
                    (2 * player.Damage)

                if player:HasCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK) then
                    multbaby = multbaby * 3
                end

                local baby = player:FireTear(minisaac.Position, entity.Velocity, false, true, false, minisaac, multbaby)

                if baby.Variant ~= tempEffects.TearVariant then
                    baby:ChangeVariant(tempEffects.TearVariant)
                end

                baby.Color = tempEffects.TearColor
                baby.TearFlags = tempEffects.TearFlags | TearFlags.TEAR_FETUS

                if player:HasCollectible(395) then --Techx
                    baby:AddTearFlags(TearFlags.TEAR_FETUS_TECHX)
                end
                if player:HasCollectible(579) then --sword
                    baby:AddTearFlags(TearFlags.TEAR_FETUS_SWORD)
                end
                if player:HasCollectible(114) then --knife
                    baby:AddTearFlags(TearFlags.TEAR_FETUS_KNIFE)
                end
                if player:HasCollectible(52) then --Fetus
                    baby:AddTearFlags(TearFlags.TEAR_FETUS_BOMBER)
                end
                if player:HasCollectible(68) then --tech
                    baby:AddTearFlags(TearFlags.TEAR_FETUS_TECH)
                end

                minisaac.Keys = 0
            end
        end
    end
end
ModReference:AddCallback(ModCallbacks.MC_POST_TEAR_INIT, DynamicMinisaacLib.InheritBaby)

function DynamicMinisaacLib:InheritTechX(entity)
    if
        entity.SpawnerEntity and entity.SpawnerEntity.Type == EntityType.ENTITY_FAMILIAR and
            entity.SpawnerEntity.Variant == FamiliarVariant.MINISAAC
     then
        local minisaac = entity.SpawnerEntity:ToFamiliar()
        local player = minisaac.Player

        if player and player:HasWeaponType(WeaponType.WEAPON_TECH_X) then
            if DynamicMinisaacLib:ShouldNotMimic(entity.SpawnerEntity) == true then
                return
            end
            entity:GetData().RemoveMinisaacTimer = 1
            SFXManager():Play(SoundEffect.SOUND_TEARS_FIRE, 0)

            minisaac.Keys = minisaac.Keys + 1

            local tempEffects = player:GetTearHitParams(WeaponType.WEAPON_TECH_X, 1, 1, player)

            local delay = DynamicMinisaacLib.TearDelayMult.TECH_X

            if player:HasCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK) then
                delay = delay * DynamicMinisaacLib.TearDelayModif.CHOC
            end

            if minisaac.Keys >= delay then
                local fireDirection = minisaac.ShootDirection

                if fireDirection == Direction.LEFT then
                    direction = Vector(-1, 0)
                elseif fireDirection == Direction.RIGHT then
                    direction = Vector(1, 0)
                elseif fireDirection == Direction.DOWN then
                    direction = Vector(0, 1)
                elseif fireDirection == Direction.UP then
                    direction = Vector(0, -1)
                end

                local multbrim =
                    (entity.CollisionDamage * ((player.Damage / 3.5) * ((11 / 30) * (30 / (1 + player.MaxFireDelay))))) /
                    (2 * player.Damage)

                if player:HasCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK) then
                    multbrim = multbrim * 3
                end

                local brimring = player:FireTechXLaser(minisaac.Position, direction * 10, 40, player, multbrim)

                minisaac.Keys = 0
            end
        end
    end
end
ModReference:AddCallback(ModCallbacks.MC_POST_TEAR_INIT, DynamicMinisaacLib.InheritTechX)

function DynamicMinisaacLib:InheritROCKET(entity)
    if
        entity.SpawnerEntity and entity.SpawnerEntity.Type == EntityType.ENTITY_FAMILIAR and
            entity.SpawnerEntity.Variant == FamiliarVariant.MINISAAC
     then
        local minisaac = entity.SpawnerEntity:ToFamiliar()
        local player = minisaac.Player

        if player and player:HasWeaponType(WeaponType.WEAPON_ROCKETS) then
            if DynamicMinisaacLib:ShouldNotMimic(entity.SpawnerEntity) == true then
                return
            end
            entity:GetData().RemoveMinisaacTimer = 1
            SFXManager():Play(SoundEffect.SOUND_TEARS_FIRE, 0)

            minisaac.Keys = minisaac.Keys + 1

            local tempEffects = player:GetTearHitParams(WeaponType.WEAPON_ROCKETS, 1, 1, player)

            local delay = DynamicMinisaacLib.TearDelayMult.EPIC

            if player:HasCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK) then
                delay = delay * DynamicMinisaacLib.TearDelayModif.CHOC
            end

            if minisaac.Keys >= delay then
                local fireDirection = minisaac.ShootDirection

                local closestEnemy = nil
                local closestDist = math.huge

                for _, entity1 in pairs(Isaac.GetRoomEntities()) do
                    if entity1:IsVulnerableEnemy() and not entity1:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
                        local dist = minisaac.Position:Distance(entity1.Position)
                        if dist < closestDist then
                            closestEnemy = entity1
                            closestDist = dist
                        end
                    end
                end

                if closestEnemy then
                    local ItSeemsThatMyTurtleHasDiedNoooo1 =
                        Isaac.Spawn(EntityType.ENTITY_EFFECT, 30, 0, minisaac.Position, Vector.Zero, player):ToEffect()
                    ItSeemsThatMyTurtleHasDiedNoooo1:SetTimeout(35)
                    ItSeemsThatMyTurtleHasDiedNoooo1:GetData().IsMinisaacRocket = true
                    ItSeemsThatMyTurtleHasDiedNoooo1.SpriteScale = Vector(0.6, 0.6)
                    local ItSeemsThatMyTurtleHasDiedNoooo =
                        Isaac.Spawn(EntityType.ENTITY_EFFECT, 31, 0, minisaac.Position, Vector.Zero, player):ToEffect()
                    ItSeemsThatMyTurtleHasDiedNoooo.SpriteScale = Vector(0.4, 0.4)
                    ItSeemsThatMyTurtleHasDiedNoooo:SetTimeout(25)
                    ItSeemsThatMyTurtleHasDiedNoooo:GetData().IsMinisaacRocket = true
                    ItSeemsThatMyTurtleHasDiedNoooo:Update()
                    ItSeemsThatMyTurtleHasDiedNoooo.DepthOffset = 10000000
                end

                minisaac.Keys = 0
            end
        end
    end
end
ModReference:AddCallback(ModCallbacks.MC_POST_TEAR_INIT, DynamicMinisaacLib.InheritROCKET)

function DynamicMinisaacLib:RocketUpdate(ItSeemsThatMyTurtleHasDiedNoooo)
    if
        not (ItSeemsThatMyTurtleHasDiedNoooo:GetData().IsMinisaacRocket and
            ItSeemsThatMyTurtleHasDiedNoooo:GetData().IsMinisaacRocket == true)
     then
        return
    end

    if
        ItSeemsThatMyTurtleHasDiedNoooo.Variant == 30 or
            ItSeemsThatMyTurtleHasDiedNoooo.Variant == 31 and ItSeemsThatMyTurtleHasDiedNoooo:GetData().IsMinisaacRocket and
                ItSeemsThatMyTurtleHasDiedNoooo:GetData().IsMinisaacRocket == true
     then
        local closestEnemy = nil
        local closestDist = math.huge

        for _, entity1 in pairs(Isaac.GetRoomEntities()) do
            if entity1:IsVulnerableEnemy() and not entity1:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
                local dist = ItSeemsThatMyTurtleHasDiedNoooo.Position:Distance(entity1.Position)
                if dist < closestDist then
                    closestEnemy = entity1
                    closestDist = dist
                end
            end
        end

        if closestEnemy then
            if (closestEnemy.Position - ItSeemsThatMyTurtleHasDiedNoooo.Position):Length() >= 30 then
                ItSeemsThatMyTurtleHasDiedNoooo.Velocity =
                    (closestEnemy.Position - ItSeemsThatMyTurtleHasDiedNoooo.Position):Normalized() * 30
            else
                ItSeemsThatMyTurtleHasDiedNoooo.Velocity =
                    (closestEnemy.Position - ItSeemsThatMyTurtleHasDiedNoooo.Position)
            end
        end
    end

    if
        ItSeemsThatMyTurtleHasDiedNoooo.Variant == 31 and ItSeemsThatMyTurtleHasDiedNoooo:GetData().IsMinisaacRocket and
            ItSeemsThatMyTurtleHasDiedNoooo:GetData().IsMinisaacRocket == true
     then
        local player = ItSeemsThatMyTurtleHasDiedNoooo.SpawnerEntity:ToPlayer()

        if player then
            local dmg = math.ceil((player.Damage / 3.5) * ((11 / 30) * (30 / (1 + player.MaxFireDelay)))) * 10000 * 15 --Had to peek Epic Fetus synergy ModReference's code to get the DMG formula

            if player:HasCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK) then
                dmg = dmg * 3
            end

            ItSeemsThatMyTurtleHasDiedNoooo.DamageSource = dmg
        end
    end
end
ModReference:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, DynamicMinisaacLib.RocketUpdate)

function DynamicMinisaacLib:InheritSwordagain(minisaac)
    local player = minisaac.Player
    if player and player:HasWeaponType(WeaponType.WEAPON_SPIRIT_SWORD) then
        if DynamicMinisaacLib:ShouldNotMimic(entity.SpawnerEntity) == true then
            return
        end
        if minisaac.SubType ~= 99 then
            if not minisaac:GetData().MasterSkinColor then
                minisaac:GetData().MasterSkinColor = minisaac.SubType
            end
            minisaac.SubType = 99
        end

        if minisaac.FireCooldown >= 10 then
            minisaac.FireCooldown = 9
        end
    end
    if
        player and not player:HasWeaponType(WeaponType.WEAPON_SPIRIT_SWORD) and
            not player:HasWeaponType(WeaponType.WEAPON_BONE)
     then
        if minisaac.SubType == 99 then
            if minisaac:GetData().MasterSkinColor then
                minisaac.SubType = 1 + minisaac:GetData().MasterSkinColor --Can't fetch your skin color for some motherfucking reason. Fuck you Nicalis.
            end
        end
    end
end
ModReference:AddCallback(
    ModCallbacks.MC_FAMILIAR_UPDATE,
    DynamicMinisaacLib.InheritSwordagain,
    FamiliarVariant.MINISAAC
)

function DynamicMinisaacLib:InheritSwordagainagain(knife)
    if knife.SpawnerEntity then
        local minisaac = knife.SpawnerEntity:ToFamiliar()
        if minisaac then
            local player = minisaac.Player
            if
                player and minisaac.Variant == FamiliarVariant.MINISAAC and minisaac.SubType == 99 and
                    player:HasWeaponType(WeaponType.WEAPON_SPIRIT_SWORD) and
                    (knife.Variant ~= 10 and knife.Variant ~= 11)
             then
                if DynamicMinisaacLib:ShouldNotMimic(entity.SpawnerEntity) == true then
                    return
                end
                local tempEffects = player:GetTearHitParams(WeaponType.WEAPON_SPIRIT_SWORD, 1, 1, nil)

                knife:AddTearFlags(player.TearFlags)

                knife:Remove()

                if player and player:HasWeaponType(WeaponType.WEAPON_SPIRIT_SWORD) then
                    local tempEffects = player:GetTearHitParams(WeaponType.WEAPON_SPIRIT_SWORD, 1, 1, player)

                    local fireDirection = minisaac.ShootDirection

                    if fireDirection == Direction.LEFT then
                        direction = Vector(-1, 0)
                    elseif fireDirection == Direction.RIGHT then
                        direction = Vector(1, 0)
                    elseif fireDirection == Direction.DOWN then
                        direction = Vector(0, 1)
                    elseif fireDirection == Direction.UP then
                        direction = Vector(0, -1)
                    end

                    local knifevar = 10
                    local rVariant = 47
                    if player:HasCollectible(68) or player:HasCollectible(395) then
                        knifevar = 11
                        rVariant = 49
                    end

                    local ItSeemsThatMyTurtleHasDiedNoooo =
                        Isaac.Spawn(8, knifevar, 0, knife.Position, Vector.Zero, minisaac):ToKnife()

                    ItSeemsThatMyTurtleHasDiedNoooo:GetData().DisappearMinisaac = true
                    ItSeemsThatMyTurtleHasDiedNoooo:GetSprite():Play("AttackRight")
                    ItSeemsThatMyTurtleHasDiedNoooo.Parent = minisaac
                    local sfx = SFXManager()
                    sfx:Play(252, Volume, FrameDelay, Loop, 2, Pan)

                    minisaac.Keys = minisaac.Keys + 1

                    if minisaac.Keys >= 2 then
                        local baby =
                            player:FireTear(
                            minisaac.Position,
                            direction * 10,
                            false,
                            true,
                            false,
                            minisaac,
                            ((11 / 30) * (30 / (1 + player.MaxFireDelay)))
                        )

                        local tempEffects2 = player:GetTearHitParams(WeaponType.WEAPON_TEARS, 1, 1, player)
                        baby.Scale = 0.6
                        baby.TearFlags = tempEffects2.TearFlags
                        if baby.Variant ~= rVariant then
                            baby:ChangeVariant(rVariant)
                        end

                        minisaac.Keys = 0
                    end

                    if player:HasCollectible(68) or player:HasCollectible(395) then --tech
                        local brimring = Isaac.Spawn(7, 2, 3, minisaac.Position, Vector.Zero, player):ToLaser()
                        brimring.Radius = 80
                        brimring.Parent = knife.SpawnerEntity
                        brimring.Timeout = 1
                        brimring.CollisionDamage =
                            (knife.CollisionDamage * 0.25 *
                            ((player.Damage / 5.25) * ((22 / 30) * (30 / (1 + player.MaxFireDelay)))))
                    end
                end
            end
        end
    end
end
ModReference:AddCallback(ModCallbacks.MC_POST_KNIFE_INIT, DynamicMinisaacLib.InheritSwordagainagain)

function DynamicMinisaacLib:KnifeUpdate3(knife)
    if knife.Parent then
        local minisaac = knife.Parent:ToFamiliar()
        if
            minisaac and (knife.Variant == 10 or knife.Variant == 11) and knife:GetData().DisappearMinisaac and
                knife:GetData().DisappearMinisaac == true
         then
            local player = minisaac.Player

            local fireDirection = minisaac.ShootDirection

            if fireDirection == Direction.LEFT then
                direction = Vector(-1, 0)
            elseif fireDirection == Direction.RIGHT then
                direction = Vector(1, 0)
            elseif fireDirection == Direction.DOWN then
                direction = Vector(0, 1)
            elseif fireDirection == Direction.UP then
                direction = Vector(0, -1)
            elseif fireDirection == Direction.NO_DIRECTION then
                direction = Vector(0, 1)
            end

            if knife.Rotation ~= (direction):GetAngleDegrees() then
                knife.Rotation = knife.Rotation + ((direction):GetAngleDegrees() - knife.Rotation) / 1.7
            else
                knife.Rotation = (direction):GetAngleDegrees()
            end

            local tempEffects = player:GetTearHitParams(WeaponType.WEAPON_SPIRIT_SWORD, 1, 1, player)

            knife.Scale = 0.75
            knife.SpriteScale = Vector(0.75, 0.75)
            knife.TearFlags = tempEffects.TearFlags

            knife.CollisionDamage = ((player.Damage / 3.5) * ((11 / 30) * (30 / (1 + player.MaxFireDelay)))) * 14 * 0.4

            if knife:GetSprite():IsFinished() then
                knife:Remove()
            end
        end
    end
end
ModReference:AddCallback(ModCallbacks.MC_POST_KNIFE_UPDATE, DynamicMinisaacLib.KnifeUpdate3)

function DynamicMinisaacLib:InheritMon(entity)
    if
        entity.SpawnerEntity and entity.SpawnerEntity.Type == EntityType.ENTITY_FAMILIAR and
            entity.SpawnerEntity.Variant == FamiliarVariant.MINISAAC
     then
        local minisaac = entity.SpawnerEntity:ToFamiliar()
        local player = minisaac.Player

        if player and player:HasWeaponType(WeaponType.WEAPON_MONSTROS_LUNGS) then
            if DynamicMinisaacLib:ShouldNotMimic(entity.SpawnerEntity) == true then
                return
            end
            entity:GetData().RemoveMinisaacTimer = 1
            SFXManager():Play(SoundEffect.SOUND_TEARS_FIRE, 0)

            minisaac.Keys = minisaac.Keys + 1

            local tempEffects = player:GetTearHitParams(WeaponType.WEAPON_TEARS, 1, 1, player)

            local delay = DynamicMinisaacLib.TearDelayMult.MONSTRO

            if player:HasCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK) then
                delay = delay * DynamicMinisaacLib.TearDelayModif.CHOC
            end

            if minisaac.Keys >= delay then
                for i = 1, 10 do
                    local IceOut =
                        Isaac.Spawn(
                        EntityType.ENTITY_TEAR,
                        TearVariant.BLOOD,
                        0,
                        minisaac.Position,
                        entity.Velocity:Rotated(((player:GetCollectibleRNG(678):RandomInt(40) % 40) - 20)) *
                            (((player:GetCollectibleRNG(678):RandomInt(100) % 5) + 7) / 10),
                        player
                    ):ToTear()

                    if not IceOut then return end

                    local colldmg = entity.CollisionDamage * 0.4

                    if player:HasCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK) then
                        colldmg = colldmg * 3
                    end
                    IceOut.CollisionDamage = colldmg
                    local tempEffects = player:GetTearHitParams(WeaponType.WEAPON_TEARS, 1, 1, player)

                    if IceOut.Variant ~= tempEffects.TearVariant then
                        IceOut:ChangeVariant(tempEffects.TearVariant)
                    end
                    IceOut.Color = tempEffects.TearColor
                    IceOut.FallingSpeed = (-10 - player:GetCollectibleRNG(678):RandomInt(5)) * 0.3
                    IceOut.Height = 0.9 * (-player:GetCollectibleRNG(678):RandomInt(6) - 10)
                    IceOut.FallingAcceleration =
                    entity.FallingAcceleration + 0.3 * (player:GetCollectibleRNG(678):RandomInt(100) / 100)
                    IceOut.Scale = 0.6 + 0.1 * ((player:GetCollectibleRNG(678):RandomInt(100) / 100) - 0.5)
                    IceOut.TearFlags = tempEffects.TearFlags
                end

                minisaac.Keys = 0
            end
        end
    end
end
ModReference:AddCallback(ModCallbacks.MC_POST_TEAR_INIT, DynamicMinisaacLib.InheritMon)

function DynamicMinisaacLib:RemoveDefaultTear(EntityTear)
    EntityTear:GetData().RemoveMinisaacTimer = 1
    SFXManager():Play(SoundEffect.SOUND_TEARS_FIRE, 0)
end

---@param EntityPlayer EntityPlayer
---@param Position Vector
---@return EntityFamiliar
function DynamicMinisaacLib:AddIncubusAtHome(EntityPlayer, Position)
    local player = EntityPlayer or Isaac.GetPlayer()
    local pos = Position or player.Position
    local Minisaac = EntityPlayer:AddMinisaac(pos)
    savemanager.GetRunSave(Minisaac).IsMimickedMinisaac = true
    return Minisaac
end