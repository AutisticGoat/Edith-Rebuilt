local SEL = StatusEffectLibrary
local mod = EdithRebuilt
local enums = mod.Enums
local misc = enums.Misc
local Cinder = {}
local CinderColor = Color(0.3, 0.3, 0.3)
local data = mod.CustomDataWrapper.getData
local HydrargyrumIcon = Sprite("gfx/EdithRebuiltCinder.anm2", true)
HydrargyrumIcon:Play("Idle", true)

SEL.RegisterStatusEffect("EDITH_REBUILT_CINDER", HydrargyrumIcon)

local CinderFlag = SEL.StatusFlag.EDITH_REBUILT_CINDER

---@param ent Entity
function EdithRebuilt.IsCinder(ent)
    return StatusEffectLibrary:HasStatusEffect(ent, CinderFlag)
end

---@param ent Entity
---@param dur number
---@param src Entity
function EdithRebuilt.SetCinder(ent, dur, src)
    if mod.IsCinder(ent) then return end
    SEL:AddStatusEffect(ent, CinderFlag, dur, EntityRef(src), CinderColor)
end

---@param player EntityPlayer
---@param ent Entity
function Cinder:OnCinderParry(player, ent)
    if not mod.IsCinder(ent) then return end
    mod.SpawnFireJet(player, ent.Position, player.Damage, true, 0.7)

    local capsule = Capsule(ent.Position, Vector.One, 0, misc.ImpreciseParryRadius + 15)
    DebugRenderer.Get(1, true):Capsule(capsule)
end
mod:AddCallback(enums.Callbacks.PERFECT_PARRY, Cinder.OnCinderParry)