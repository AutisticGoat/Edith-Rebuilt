local SEL = StatusEffectLibrary
local mod = EdithRebuilt
local Salted = {}
local saltType = mod.Enums.SaltTypes
local SaltedColor = Color(1, 1, 1, 1, 0.3, 0.3, 0.3)
local data = mod.CustomDataWrapper.getData
local SaltedIcon = Sprite("gfx/EdithRebuiltSalted.anm2", true)
SaltedIcon:Play("Idle", true)
SEL.RegisterStatusEffect("EDITH_REBUILT_SALTED", SaltedIcon)

local SaltedFlag = SEL.StatusFlag.EDITH_REBUILT_SALTED

---Returns a boolean depending if `ent` is salted
---@param ent Entity
function EdithRebuilt.IsSalted(ent)
    return StatusEffectLibrary:HasStatusEffect(ent, SaltedFlag)
end

---@param ent Entity
---@param dur number
---@param src Entity
function EdithRebuilt.SetSalted(ent, dur, src)
    if mod.IsSalted(ent) then return end
    SEL:AddStatusEffect(ent, SaltedFlag, dur, EntityRef(src), SaltedColor)
end

---@param npc EntityNPC
function Salted:OnSaltedUpdate(npc)
    if not mod.IsSalted(npc) then return end
    npc:MultiplyFriction(0.6)

    -- if 
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, Salted.OnSaltedUpdate)

local flag = false
---@param entity Entity
---@param amount number
---@param flags DamageFlag
---@param source EntityRef
---@param Cooldown integer
function Salted:OnSaltedEnemyTakingDamage(entity, amount, flags, source, Cooldown)    
    if not mod.IsSalted(entity) then return end
    if not amount == (amount * 1.2) then return end
    if flag == true then return end

    flag = true
    entity:TakeDamage(amount * 1.2, flags, source, Cooldown)
    flag = false
    return false
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, Salted.OnSaltedEnemyTakingDamage)

---@param proj EntityProjectile
function Salted:OnSaltedProjInit(proj)
    local npc = proj.SpawnerEntity:ToNPC()

    if not npc then return end
    if not mod.IsSalted(npc) then return end
    if not mod.RandomBoolean(proj:GetDropRNG()) then return end
    proj.Visible = false
    proj:Kill()
end
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_INIT, Salted.OnSaltedProjInit)