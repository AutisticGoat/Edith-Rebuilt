local SEL = StatusEffectLibrary
local mod = EdithRebuilt
local misc = mod.Enums.Misc
local Cinder = {}
local CinderColor = Color(0.3, 0.3, 0.3)
local data = mod.CustomDataWrapper.getData
local HydrargyrumIcon = Sprite("gfx/EdithRebuiltCinder.anm2", true)
HydrargyrumIcon:Play("Idle", true)

SEL.RegisterStatusEffect("EDITH_REBUILT_CINDER", HydrargyrumIcon)

local CinderFlag = SEL.StatusFlag.EDITH_REBUILT_CINDER

--[[
Cinder Status Effect:
- Tints enemy in black
- Enemies are receive more damage from Tainted Edith parries
- enemies are more pushed from Tainted Edith parries
- Killing a cinder enemy with a parry will set nearby enemies on fire
]]

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

---@param npc EntityNPC
function Cinder:OnCinderNPCUpdate(npc)
    if not mod.IsCinder(npc) then return end

    local playerPos = SEL:GetStatusEffectData(npc, CinderFlag).Source.Position
    local dist = playerPos:Distance(npc.Position)
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, Cinder.OnCinderNPCUpdate)

---@param npc EntityNPC 
---@param amount number
function Cinder:OnCinderNPCDeath(npc, _, _, amount)
    if not mod.IsCinder(npc) then return end
    local Ent = SEL:GetStatusEffectData(npc, CinderFlag).Source.Entity
    local capsule = Capsule(Ent.Position, Vector.One, 0, misc.ImpreciseParryRadius)

    DebugRenderer.Get(1, false):Capsule(capsule)

    for _, ent in ipairs(Isaac.FindInCapsule(capsule, EntityPartition.ENEMY)) do
        if ent.HitPoints <= amount then goto continue end
        print("saodjopjsadop")
        mod.SpawnFireJet(Ent:ToPlayer() --[[@as EntityPlayer]], npc.Position, 3, true, 1)
        ::continue::
    end
end
mod:AddCallback(PRE_NPC_KILL.ID, Cinder.OnCinderNPCDeath)

--[[
    Tarea, traer definición propia de Usabilidad y Accesibilidad en un ejemplo
]]