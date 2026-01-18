-- Custom Shockwave API by BrakeDude (https://github.com/BrakeDude/CustomShockwaveAPI)
local localversion = 1.3
local game = Game()
local sfx = SFXManager()
local function Log(str)
    print(str)
    Isaac.DebugString(str)
end

local function load()
	CustomShockwaveAPI = RegisterMod("Custom Shockwave", 1)
	CustomShockwaveAPI.Version = localversion
	CustomShockwaveAPI.Loaded = false
	--#region bless Fiend Folio (you read that right)
	local function runUpdates(tab) --This is from Fiend Folio
		for i = #tab, 1, -1 do
			local f = tab[i]
			f.Delay = f.Delay - 1
			if f.Delay <= 0 then
				f.Func()
				table.remove(tab, i)
			end
		end
	end

	local delayedFuncs = {}
	local function scheduleForUpdate(foo, delay, callback)
		if REPENTOGON then
			Isaac.CreateTimer(foo, delay, 1, false)
		else
			callback = callback or ModCallbacks.MC_POST_UPDATE
			if not delayedFuncs[callback] then
				delayedFuncs[callback] = {}
				local function Reset()
					delayedFuncs[callback] = {}
				end
				CustomShockwaveAPI:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, Reset)
				CustomShockwaveAPI:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, Reset)
				CustomShockwaveAPI:AddCallback(callback, function()
					runUpdates(delayedFuncs[callback])
				end)
			end

			table.insert(delayedFuncs[callback], { Func = foo, Delay = delay })
		end
	end
	--#endregion

	---@param position Vector
	---@param spawner Entity
	---@param step? number
	---@param angle? integer
	---@param delay? integer
	---@param limit? integer
	---@param damage? number
	---@param damageIncrement? number
	---@param tearFlags? TearFlags | number
	---@param minradius? number
	---@param maxradius? number
	---@param rng? RNG
	function CustomShockwaveAPI:SpawnCustomCrackwave(
		position,
		spawner,
		step,
		angle,
		delay,
		limit,
		damage,
		damageIncrement,
		tearFlags,
		minradius,
		maxradius,
		rng
	)
		limit = limit or -1
		if limit == 0 then return end
		angle = angle or 0
		delay = delay or 0
		step = step or 30
		tearFlags = tearFlags or 0
		damage = damage or 10
		damageIncrement = damageIncrement or 0
		minradius = minradius or 0
		maxradius = maxradius or 0
		limit = limit > 0 and (limit - 1) or limit
		rng = rng or spawner:GetDropRNG()
		scheduleForUpdate(function()
			local room = game:GetRoom()
			local radiusChange = rng:RandomInt(maxradius - minradius) + minradius
			while radiusChange < 0 do
				radiusChange = radiusChange + 360
			end
			local nextPos = position + Vector.FromAngle(angle + radiusChange):Resized(step)
			local gridCol = room:GetGridCollisionAtPos(nextPos)
			local grid = room:GetGridEntityFromPos(nextPos)
			local player = spawner:ToPlayer() or spawner.Parent:ToPlayer()
			local door
			if grid then
				if grid:ToDoor() then
					door = grid:ToDoor()
					door:Destroy()
					if
						door:GetVariant() == DoorVariant.DOOR_LOCKED
						or door:GetVariant() == DoorVariant.DOOR_LOCKED_DOUBLE
					then
						if player then
							if player:HasTrinket(TrinketType.TRINKET_BROKEN_PADLOCK) then
								door:Open()
							end
						end
					end
				end
			end
			if
				gridCol ~= GridCollisionClass.COLLISION_WALL
				and not door
				and (not grid or grid:GetType() ~= GridEntityType.GRID_ROCKB)
			then
				local effect = Isaac.Spawn(
					EntityType.ENTITY_EFFECT,
					EffectVariant.ROCK_EXPLOSION,
					0,
					nextPos,
					Vector.Zero,
					spawner
				):ToEffect()

                if not effect then return end
                local effectData = effect:GetData()
				local pit 

				effect.Parent = player --[[@as Entity]]
				effectData.CustomRockExplosion = true
				effectData.CustomRockExplosionTearFlags = tearFlags
				effectData.CustomRockExplosionDamage = damage
				
				for i = 0, 359, 10 do
					pit = room:GetGridEntityFromPos(nextPos + Vector.FromAngle(i):Resized(5)):ToPit()
					if not pit then goto continue end
					pit:MakeBridge(nil)
				    ::continue::
				end
				CustomShockwaveAPI:SpawnCustomCrackwave(
					nextPos,
					spawner,
					step,
					angle,
					delay,
					limit,
					damage + damageIncrement,
					damageIncrement,
					tearFlags,
					minradius,
					maxradius,
					rng
				)
			end
		end, delay)
	end

	---@param effect EntityEffect
	function CustomShockwaveAPI:UpdateCustomRockExplosion(effect)
		local data = effect:GetData()
		if not data.CustomRockExplosion then return end
        if effect.FrameCount ~= 2 then return end
        local scale = effect.SpriteScale.X

        sfx:Play(SoundEffect.SOUND_ROCK_CRUMBLE, 0.4, 0)
        game:BombDamage(
            effect.Position,
            data.CustomRockExplosionDamage,
            20 * scale,
            false,
            effect.SpawnerEntity,
            data.CustomRockExplosionTearFlags,
            DamageFlag.DAMAGE_CRUSH,
            false
        )
            
		for _, ent in ipairs(Isaac.FindInRadius(effect.Position, 20 * scale, EntityPartition.ENEMY)) do
			if ent.Type ~= EntityType.ENTITY_FIREPLACE then goto continue end
            if ent.Variant ~= 4 then goto continue end
            ent:Die()
            ::continue::
        end
	end
	CustomShockwaveAPI:AddCallback( ModCallbacks.MC_POST_EFFECT_UPDATE, CustomShockwaveAPI.UpdateCustomRockExplosion, EffectVariant.ROCK_EXPLOSION )

	function CustomShockwaveAPI:ModReset()
		CustomShockwaveAPI.Loaded = false
	end
	CustomShockwaveAPI:AddCallback(ModCallbacks.MC_PRE_MOD_UNLOAD, CustomShockwaveAPI.ModReset)

	function CustomShockwaveAPI:ModLoad()
		if not CustomShockwaveAPI.Loaded then
			Log("[" .. CustomShockwaveAPI.Name .. "] is loaded. Version " .. CustomShockwaveAPI.Version)
			CustomShockwaveAPI.Loaded = true
		end
	end
	CustomShockwaveAPI:AddCallback(
		REPENTOGON and ModCallbacks.MC_POST_MODS_LOADED or ModCallbacks.MC_POST_GAME_STARTED,
		CustomShockwaveAPI.ModLoad
	)
end

if CustomShockwaveAPI then
	if CustomShockwaveAPI.Version < localversion or not CustomShockwaveAPI.Loaded then
		if not CustomShockwaveAPI.Loaded then
			Log("[" .. CustomShockwaveAPI.Name .. "] Reloading...")
		else
			Log(
				"["
					.. CustomShockwaveAPI.Name
					.. "] Found old script V"
					.. CustomShockwaveAPI.Version
					.. ". Replacing with V"
					.. localversion
			)
		end
		CustomShockwaveAPI = nil
		load()
		CustomShockwaveAPI:ModLoad()
	end
elseif not CustomShockwaveAPI then
	load()
	CustomShockwaveAPI:ModLoad()
end