local mod = EdithRebuilt
local funcs = require("resources.scripts.stompSynergies.Funcs")
local EdithJump = require("resources.scripts.stompSynergies.JumpData")

---@param player EntityPlayer
function mod:GodHeadStomp(player)
	if funcs.DefensiveStomp(player) then return end
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_GODHEAD) then return end		
	
    local godTear = player:FireTear(player.Position, Vector.Zero)
    
    godTear.Scale = 1.5 * player.SpriteScale.X
    godTear.CollisionDamage = 0
    godTear.Height = -10
    godTear:AddTearFlags(TearFlags.TEAR_GLOW | TearFlags.TEAR_SPECTRAL | TearFlags.TEAR_PIERCING)

    funcs.GetData(godTear).IsStompGodTear = true
    mod:ChangeColor(godTear, nil, nil, nil, 0)
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, mod.GodHeadStomp, EdithJump)

---@param tear EntityTear  
function mod:RemoveKnife(tear)	
    if not funcs.GetData(tear).IsStompGodTear then return end
    tear.Height = -10
    tear.Position = (tear.Parent or tear.SpawnerEntity).Position

    if tear.FrameCount < 12 then return end
    tear:Remove()
end
mod:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, mod.RemoveKnife)

---@param player EntityPlayer
---@param ent Entity
function mod:OnStatusEffectLand(player, ent)
    print("Hola")
end
mod:AddCallback(mod.Enums.Callbacks.OFFENSIVE_STOMP, mod.OnStatusEffectLand, EdithJump)