local SEL = StatusEffectLibrary
local mod = EdithRebuilt
local Peppered = {}
local PepperedColor = Color(0.5, 0.5, 0.5)
local data = mod.CustomDataWrapper.getData
local PepperedIcon = Sprite("gfx/EdithRebuiltPeppered.anm2", true)
PepperedIcon:Play("Idle", true)

SEL.RegisterStatusEffect("EDITH_REBUILT_PEPPERED", PepperedIcon)

local PepperedFlag = SEL.StatusFlag.EDITH_REBUILT_PEPPERED

---Returns a boolean depending if `ent` is salted
---@param ent Entity
function EdithRebuilt.IsPeppered(ent)
    return StatusEffectLibrary:HasStatusEffect(ent, PepperedFlag)
end

---@param ent Entity
---@param dur number
---@param src Entity
function EdithRebuilt.SetPeppered(ent, dur, src)
    if mod.IsPeppered(ent) then return end
    SEL:AddStatusEffect(ent, PepperedFlag, dur, EntityRef(src), PepperedColor)
end

---@param npc EntityNPC
function Peppered:OnPepperedUpdate(npc)
    if not mod.IsPeppered(npc) then return end
    npc:MultiplyFriction(0.6)

    if SEL:GetStatusEffectCountdown(npc, PepperedFlag) % 10 ~= 0 then return end
    mod:SpawnPepperCreep(data(npc).Player, npc.Position, 0.5, 3)
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, Peppered.OnPepperedUpdate)