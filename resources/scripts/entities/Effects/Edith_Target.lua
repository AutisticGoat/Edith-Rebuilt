local game = edithMod.Enums.Utils.Game
local mod = edithMod
local level = game:GetLevel()

local red = 255
local green = 0
local blue = 0
local state = 1

local RGBCyclingColor = Color(1, 1, 1, 1)
function edithMod:RGBCycle(step)
    step = step or 1 
	
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

	RGBCyclingColor.R = red / 255
	RGBCyclingColor.G = green / 255
	RGBCyclingColor.B = blue / 255
end

local function interpolateVector2D(vectorA, vectorB, t)
    local Interpolated = {
        X = (1 - t) * vectorA.X + t * vectorB.X,
        Y = (1 - t) * vectorA.Y + t * vectorB.Y,
    }
    return Vector(Interpolated.X, Interpolated.Y)
end

local DungeonVector = Vector(0, 0)

local teleportPoints = {
	{X = 110, Y = 135},
	{X = 595, Y = 385},
	{X = 595, Y = 272},
}

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
		for k, v in pairs(teleportPoints) do
			DungeonVector.X = v.X
			DungeonVector.Y = v.Y
			
			if (effectPos - DungeonVector):Length() <= 20 then
				player.Position = effectPos + effect.Velocity:Normalized():Resized(25)
				break
			end
		end
	end

	local roomName = level:GetCurrentRoomDesc().Data.Name
	local isMirrorWorld = room:IsMirrorWorld()

	local roomSize = room:GetGridSize()

	for i = 0, roomSize do
		local grid = room:GetGridEntity(i)
		
		if grid then
			local door = grid:ToDoor()
			
			if door then
				local doorPos = door.Position
				local distance = effectPos:Distance(doorPos)
								
				if distance <= 25 then
					if door:IsOpen() then
						local newColor = player.Color
						newColor.A = 0
						player.Color = newColor
						player.Position = door.Position
					else
						local dimension = room:IsMirrorWorld() and 0 or 1			
						local playerEffetts = player:GetEffects()
						
						if roomName == "Mirror Room" and playerEffetts:HasNullEffect(NullItemID.ID_LOST_CURSE) then
							player.Position = doorPos
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

local ObscureDiv = 155/255
local targetPath = "gfx/effects/EdithTarget/effect_000_edith_target"
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

local frameLimits = {
	["Idle"] = 12,
	["Blink"] = 2
}

local targetlineColor = Color(1, 1, 1, 1)

local colorValues = {
	[2] = {R = 245/255, G = 169/255, B = 184/255},
	[3] = {R = 1, G = 0, B = 1},
	[4] = {R = 1, G = 154/255, B = 86/255},
	[5] = {R = 155/255, G = 79/255, B = 150/255},
	[6] = {R = 123/255, G = 173/255, B = 226/255},
	[7] = {R = 128/255, G = 0, B = 128/255},
	[8] = {R = 154/255, G = 89/255, B = 207/255},
	[9] = {R = 0, G = 36/255, B = 125/255},
}

function mod:EdithTargetSprite(effect)
	local room = game:GetRoom()
	if room:GetRenderMode() == RenderMode.RENDER_WATER_REFLECT then return end
	
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

		local effectColor = effect.Color
		local effectSprite = effect:GetSprite()
		
		if saveData.targetdesign == 1 then
			if RGBmode then
				edithMod:RGBCycle(RGBspeed)
				effect.Color = RGBCyclingColor
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
		
		effectSprite:ReplaceSpritesheet(0, targetPath .. targetSuffix[targetDesign] .. ".png", true)
		
		local targetLine = saveData.targetline
		if targetLine ~= true then return end
				
		if targetDesign == 1 then
			targetlineColor = effectColor
		else
			targetlineColor.R = colorValues[targetDesign].R
			targetlineColor.G = colorValues[targetDesign].G
			targetlineColor.B = colorValues[targetDesign].B
		end

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
		edithMod:drawLine(player.Position, effect.Position, targetlineColor, targetSpace) 
	end
end
edithMod:AddCallback(ModCallbacks.MC_PRE_EFFECT_RENDER, mod.EdithTargetSprite,edithMod.Enums.EffectVariant.EFFECT_EDITH_TARGET)
