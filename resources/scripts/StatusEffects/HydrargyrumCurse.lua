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
    local entData = data(npc)
    if not entData.MercuryTimer then return end
    entData.MercuryTimer = math.max(entData.MercuryTimer - 1, 0)
    if entData.MercuryTimer % 15 ~= 0 or entData.MercuryTimer == 0 then return end

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