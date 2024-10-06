local game = edithMod.Enums.Utils.Game
local mod = edithMod
local level = game:GetLevel()

local red = 255
local green = 0
local blue = 0
local state = 1
function edithMod:RGBCycle(step)
    step = step or 1 -- valor predeterminado si no se proporciona step
	
    if state == 1 then
        green = math.min(255, green + step)
        if green == 255 then
            state = 2
        end
    elseif state == 2 then
        red = math.max(0, red - step)
        if red == 0 then
            state = 3
        end
    elseif state == 3 then
        blue = math.min(255, blue + step)
        if blue == 255 then
            state = 4
        end
    elseif state == 4 then
        green = math.max(0, green - step)
        if green == 0 then
            state = 5
        end
    elseif state == 5 then
        red = math.min(255, red + step)
        if red == 255 then
            state = 6
        end
    elseif state == 6 then
        blue = math.max(0, blue - step)
        if blue == 0 then
            state = 1
        end
    end

    return Color(red/255, green/255, blue/255, 1)
end

local function interpolateVector2D(vectorA, vectorB, t)
    local Interpolated = {
        X = (1 - t) * vectorA.X + t * vectorB.X,
        Y = (1 - t) * vectorA.Y + t * vectorB.Y,
    }
    return Vector(Interpolated.X, Interpolated.Y)
end

function mod:EdithTargetLogic(effect)	
	local room = game:GetRoom()
	local player = effect.SpawnerEntity:ToPlayer()
	if player.ControlsEnabled == false then return end
		
	effect.Velocity = effect.Velocity * 0.6
	effect.DepthOffset = -100
	effect.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
	
	local playerPos = player.Position
	local effectPos = effect.Position
	
	local playerData = edithMod:GetData(player)
	
	local targetSprite = effect:GetSprite()
	
	if edithMod:IsKeyStompPressed(player) or playerData.ExtraJumps > 0 and playerData.EdithJumpTimer == 0 then
		targetSprite:Play("Blink")
	end
	
	if targetSprite:GetAnimation() == "Blink" then
		effect.Velocity = effect.Velocity * 0.3
	end

	local cameraPos = interpolateVector2D(playerPos, effectPos, 0.6)
	local Camera = room:GetCamera()
	Camera:SetFocusPosition(cameraPos)
	
	for _, entity in pairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.TARGET)) do
		local target = entity:ToEffect()
		local player = effect.SpawnerEntity:ToPlayer()
		
		target.Position = effectPos
		
		target:MultiplyFriction(0)
		target.Velocity = Vector.Zero
		
		local newColor = target.Color
		newColor.A = 0
		target.Color = newColor
	end
	
	if room:GetType() == RoomType.ROOM_DUNGEON then
    -- Definir las posiciones de los puntos de teletransporte
		local teleportPoints = {
			Vector(110, 135),
			Vector(595, 385),
			Vector(595, 272),
		}

		-- Verificar si el efecto está cerca de alguno de los puntos de teletransporte
		for _, point in ipairs(teleportPoints) do
			if (effect.Position - point):Length() <= 20 then
				-- Teletransportar al jugador a la posición del efecto con un desplazamiento de 25 unidades
				player.Position = effect.Position + effect.Velocity:Normalized():Resized(25)
				break
			end
		end
	end

	
	
	local distance = playerPos:Distance(effectPos)	
	local roomName = level:GetCurrentRoomDesc().Data.Name
	local isMirrorWorld = room:IsMirrorWorld()

	for i = 0, room:GetGridSize() do
		local gent = room:GetGridEntity(i)
		if gent and gent:ToDoor() then
			local door = gent:ToDoor()
			local distance = (effectPos - door.Position):Length()
			
			local isJumping = JumpLib:GetData(player).Jumping
			
			if distance <= 25 and effect:CollidesWithGrid() and not isJumping then
				if door:IsOpen() then
					local newColor = player.Color
					newColor.A = 0
					player.Color = newColor
					player.Position = door.Position
				else
					if room:IsClear() then
					
						local dimension = room:IsMirrorWorld() and 0 or 1					
						if roomName == "Mirror Room" and player:GetEffects():HasNullEffect(NullItemID.ID_LOST_CURSE) then
							player.Position = door.Position
						else
							door:TryUnlock(player)
						end
					end
				end
			end
		end
	end
end 
edithMod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.EdithTargetLogic, edithMod.Enums.EffectVariant.EFFECT_EDITH_TARGET)

function mod:EdithTargetSprite(effect)
	if game:GetRoom():GetRenderMode() == RenderMode.RENDER_WATER_REFLECT then return end
	
    local player = effect.SpawnerEntity:ToPlayer()
    if not player then return end

	if player:GetPlayerType() ~= edithMod.Enums.PlayerType.PLAYER_EDITH then return end

	if edithMod.saveManager:IsLoaded() then
		local saveData = edithMod.saveManager.GetDeadSeaScrollsSave()
		if not saveData then return end
		
		local targetColor = saveData.TargetColor

		local RGBmode = saveData.RGBMode
		local RGBspeed = saveData.RGBSpeed
		local targetSpace = saveData.linespace
		local targetDesign = saveData.targetdesign

		local effectSprite = effect:GetSprite()
		
		if saveData.targetdesign == 1 then
			if RGBmode then
				effect.Color = edithMod:RGBCycle(RGBspeed)
			else
				local NewTargetColor = effect.Color
		
				NewTargetColor.R = targetColor.Red
				NewTargetColor.G = targetColor.Green
				NewTargetColor.B = targetColor.Blue
				
				effect.Color = NewTargetColor
			end
		else
			effect.Color = Color.Default
		end

		local colorValues = {
			[1] = {R = effectSprite.Color.R, G = effectSprite.Color.G, B = effectSprite.Color.B},
			[2] = {R = 245/255, G = 169/255, B = 184/255},
			[3] = {R = 1, G = 0, B = 1},
			[4] = {R = 1, G = 154/255, B = 86/255},
			[5] = {R = 155/255, G = 79/255, B = 150/255},
			[6] = {R = 123/255, G = 173/255, B = 226/255},
			[7] = {R = 128/255, G = 0, B = 128/255},
			[8] = {R = 154/255, G = 89/255, B = 207/255},
			[9] = {R = 0, G = 36/255, B = 125/255},
		}
		
		local ObscureDiv = 155/255

		local targetlineColor = Color(colorValues[targetDesign].R, colorValues[targetDesign].G, colorValues[targetDesign].B, 1)

		local frameLimits = {
			["Idle"] = 12,
			["Blink"] = 2
		}

		local animation = effectSprite:GetAnimation()
		local frame = effectSprite:GetFrame()
		local isObscure = frame >= (frameLimits[animation] or 0)

		if isObscure then
			local newObcureColor = targetlineColor
			newObcureColor.R = newObcureColor.R * ObscureDiv
			newObcureColor.G = newObcureColor.G * ObscureDiv
			newObcureColor.B = newObcureColor.B * ObscureDiv
		
			targetlineColor = newObcureColor
		end
		
		local targetDesign = saveData and saveData.targetdesign or 1
	
		local targetSuffix = {
			[1] = "",
			[2] = "_trans",
			[3] = "_rainbow",
			[4] = "_lesbian",
			[5] = "_bisexual",
			[6] = "_gay",
			[7] = "_ace",
			[8] = "_enby",
			[9] = "_Venezuela",
		}		
		
		effectSprite:ReplaceSpritesheet(0, "gfx/effects/effect_000_edith_target" .. targetSuffix[targetDesign] .. ".png", true)

		local targetLine = saveData.targetline
		if targetLine ~= true then return end
		
		edithMod:drawLine(player.Position, effect.Position, targetlineColor, targetSpace) 
	end
end
edithMod:AddCallback(ModCallbacks.MC_PRE_EFFECT_RENDER, mod.EdithTargetSprite,edithMod.Enums.EffectVariant.EFFECT_EDITH_TARGET)
