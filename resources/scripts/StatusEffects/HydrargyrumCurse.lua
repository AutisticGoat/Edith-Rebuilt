local SEL = StatusEffectLibrary
local mod = EdithRebuilt
local HydrargyrumCurse = {}
local HydrargyrumCurseColor = Color(1, 1, 1, 1, 0.5, 0.06, 0.06, 0.91, 0.72, 0.72, 1)
local data = mod.CustomDataWrapper.getData
local HydrargyrumIcon = Sprite("gfx/EdithRebuiltHydrargyrum.anm2", true)
HydrargyrumIcon:Play("Idle", true)

SEL.RegisterStatusEffect("EDITH_REBUILT_HYDRARGYRUM_CURSE", HydrargyrumIcon)

local HydrargyrumFlag = SEL.StatusFlag.EDITH_REBUILT_HYDRARGYRUM_CURSE

---Returns a boolean depending if `ent` is salted
---@param ent Entity
function EdithRebuilt.IsHydrargyrumCursed(ent)
    return StatusEffectLibrary:HasStatusEffect(ent, HydrargyrumFlag)
end

---@param ent Entity
---@param dur number
---@param src Entity
function EdithRebuilt.SetIsHydrargyrumCurse(ent, dur, src)
    if mod.IsHydrargyrumCursed(ent) then return end
    SEL:AddStatusEffect(ent, HydrargyrumFlag, dur, EntityRef(src), HydrargyrumCurseColor)
end

---@param npc EntityNPC
function HydrargyrumCurse:OnNPCUpdate(npc)
    if not mod.IsHydrargyrumCursed(npc) then return end
    if SEL:GetStatusEffectCountdown(npc, HydrargyrumFlag) % 15 ~= 0 then return end

    print(SEL:GetStatusEffectCountdown(npc, HydrargyrumFlag) % 15 == 0)

    local entData = data(npc)

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
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, HydrargyrumCurse.OnNPCUpdate)