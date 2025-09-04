--[[
    Pre NPC kill callback by Kerkel!!!!
]]

local VERSION = 1.1

if PRE_NPC_KILL then
    if PRE_NPC_KILL.Internal.VERSION > VERSION then return end
    for _, v in ipairs(PRE_NPC_KILL.Internal.CallbackEntries) do
        PRE_NPC_KILL:RemoveCallback(v[1], v[3])
    end
end

PRE_NPC_KILL = RegisterMod("Pre NPC Kill Callback", 1)
---Called before an NPC is killed by damage
---
---Return `true` to prevent the kill
---
---Return `false` to prevent incoming damage that would cause the kill
---
---Optional argument `EntityType`
---
---Parameters:
---* npc `EntityNPC`
---* source `EntityRef`
---* frozen `boolean`
---* amt `number`
---* flags `DamageFlag`
---* cooldown `integer`
PRE_NPC_KILL.ID = "__PRE_NPC_KILL"
PRE_NPC_KILL.Internal = {}
PRE_NPC_KILL.Internal.VERSION = VERSION
PRE_NPC_KILL.Internal.CallbackEntries = {
    {
        ModCallbacks.MC_NPC_UPDATE,
        CallbackPriority.DEFAULT,
        ---@param npc EntityNPC 
        function (_, npc)
            npc:GetData().____PRE_NPC_KILL_STORED_DAMAGE = 0
        end,
    },
    {
        ModCallbacks.MC_ENTITY_TAKE_DMG,
        CallbackPriority.LATE,
        ---@param entity Entity
        ---@param amt number
        ---@param flags DamageFlag
        ---@param source EntityRef
        ---@param cooldown integer
        function (_, entity, amt, flags, source, cooldown)
            local data = entity:GetData() if data.____PRE_NPC_KILL_SKIP_NEXT then return end
            local npc = entity:ToNPC() if not npc then return end

            data.____PRE_NPC_KILL_STORED_DAMAGE = (data.____PRE_NPC_KILL_STORED_DAMAGE or 0) + amt

            if npc.HitPoints - data.____PRE_NPC_KILL_STORED_DAMAGE > 0 then return end

            local frozen = npc:HasEntityFlags(EntityFlag.FLAG_NO_DEATH_TRIGGER)
            or npc:HasEntityFlags(EntityFlag.FLAG_ICE)
            or npc:HasEntityFlags(EntityFlag.FLAG_FREEZE)
            or npc:HasEntityFlags(EntityFlag.FLAG_MIDAS_FREEZE)
            or (source.Type == EntityType.ENTITY_TEAR and source.Entity:ToTear():HasTearFlags(TearFlags.TEAR_ICE))

            for _, v in ipairs(Isaac.GetCallbacks(PRE_NPC_KILL.ID)) do
                if not v.Param or v.Param == npc.Type then
                    local result = v.Function(v.Mod, npc, source, frozen, amt, flags, cooldown)

                    if result == true then
                        data.____PRE_NPC_KILL_SKIP_NEXT = true
                        npc:TakeDamage(amt, flags | DamageFlag.DAMAGE_NOKILL, source, cooldown)
                        data.____PRE_NPC_KILL_SKIP_NEXT = false
                        return false
                    elseif result == false then
                        return false
                    end
                end
            end
        end
    }
}

for _, v in ipairs(PRE_NPC_KILL.Internal.CallbackEntries) do
    PRE_NPC_KILL:AddPriorityCallback(v[1], v[2], v[3], v[4])
end
