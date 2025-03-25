local mod = edithMod
local funcs = require("resources.scripts.stompSynergies.Funcs")
local EdithJump = require("resources.scripts.stompSynergies.JumpData")
local shockwaveDir = Vector(-1, 0)
local shockwaveSpace = 20

---@param player EntityPlayer
function mod:RockStomp(player)
	if funcs.KeyStompPressed(player) then return end
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_TERRA) then return end
	
	local birthright = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)
	local shockwaveDamage = birthright and player.Damage * 1.4 or player.Damage
	local shockwaveRings = birthright and 2 or 1
	
	local shockwaveParams = {
		Duration = 6,
		Size = 1,
		Damage = shockwaveDamage,
		DamageCooldown = 120,
		SelfDamage = false,
		DamagePlayers = true,
		DestroyGrid = true,
		GoOverPits = false,
		Color = Color.Default,
		SpriteSheet = funcs.ShockwaveSprite(),
		SoundMode = TSIL.Enums.ShockwaveSoundMode.ON_CREATE
	}
			
	TSIL.ShockWaves.CreateShockwaveRing(
		player, -- Quien creó el shockwave
		player.Position, -- Donde se creó
		30, -- El radio
		shockwaveParams, -- Parámetros extra, definidos arriba
		shockwaveDir, -- Dirección
		360, -- Qué tan abierto o cerrado estará el círculo
		30, -- Espacio entre cada piedra
		shockwaveRings, -- Número de anillos
		shockwaveSpace, -- Espacio entre cada anillo
		1-- Cuánto dura cada anillo
	) 
end
mod:AddCallback(JumpLib.Callbacks.ENTITY_LAND, mod.RockStomp, EdithJump)

