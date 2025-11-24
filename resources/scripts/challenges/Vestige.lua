--[[
	Vestigio:
	- Edith se moverá muy parecido a como lo hacía en Antibirth
	- Se mantendrán mejoras al movimiento como el botón asignado al salto y ciertas interacciones con stats
	- Daño del pisotón buffeado
	- Los objetos de sal aplicarán miedo en vez de salación
	- La meta será mother
	- Se desbloquea completando la rua de Antibirth con Edith 
	- Desbloquea Effigy

	Por hacer:
	- Mejorar la animación de caer por la trampilla
	- Arreglar un error donde el puntero se mueve más lento cuando Edith no está saltando
]]


local mod = EdithRebuilt
local data = mod.CustomDataWrapper.getData
local Vestige = {}

---@param player EntityPlayer
function Vestige:EdithJumpHandler(player)
    if not mod.IsVestigeChallenge() then return end
	if not mod.IsEdith(player, false) then return end

	local playerData = data(player)
	if player:IsDead() then mod.RemoveEdithTarget(player); playerData.isJumping = false return end

	local isKeyStompTriggered = mod:IsKeyStompTriggered(player)
	local jumpData = JumpLib:GetData(player)
	local isJumping = jumpData.Jumping 
	local target = mod.GetEdithTarget(player)
	local sprite = player:GetSprite()
	local jumpInternalData = JumpLib.Internal:GetData(player)

	playerData.isJumping = playerData.isJumping or false
	playerData.ExtraJumps = playerData.ExtraJumps or 0

    if isKeyStompTriggered and not isJumping and not sprite:IsPlaying("BigJumpUp") and not sprite:IsPlaying("BigJumpFinish") then
        player:PlayExtraAnimation("BigJumpUp")
	end

    if sprite:IsEventTriggered("StartJump") and not isJumping then
        mod.InitVestigeJump(player)
    end

	if jumpInternalData.UpdateFrame and jumpInternalData.UpdateFrame > 6 then
		mod.EdithDash(player, mod.GetEdithTargetDirection(player), mod.GetEdithTargetDistance(player), 50)
	end

	if target and JumpLib:IsFalling(player) then
		player.Position = target.Position
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, Vestige.EdithJumpHandler)

local NonTriggerAnimPickupVar = {
	[PickupVariant.PICKUP_COLLECTIBLE] = true,
	[PickupVariant.PICKUP_TRINKET] = true,
	[PickupVariant.PICKUP_BROKEN_SHOVEL] = true,
	[PickupVariant.PICKUP_SHOPITEM] = true,
	[PickupVariant.PICKUP_PILL] = true,
	[PickupVariant.PICKUP_TAROTCARD] = true,
}

---@param player EntityPlayer
---@param collider Entity
function Vestige:OnPickupColl(player, collider)
	local pickup = collider:ToPickup()
	local sprite = player:GetSprite()

	if not pickup then return end
	if not NonTriggerAnimPickupVar[pickup.Variant] then return end
	if not sprite:IsPlaying("BigJumpFinish") then return end 

	sprite:SetFrame(11)
end
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_COLLISION, Vestige.OnPickupColl)

print("sadpjapsjdj")