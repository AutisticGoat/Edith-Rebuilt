local mod = edithMod
local enums = mod.Enums
local utils = enums.Utils
local tables = enums.Tables
local game = utils.Game
local misc = enums.Misc

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
	local player = effect.SpawnerEntity:ToPlayer()
	if player.ControlsEnabled == false then return end
		
	effect.Velocity = effect.Velocity * 0.6
	effect.DepthOffset = -100
	effect.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
	
	local playerPos = player.Position
	local effectPos = effect.Position
	local playerData = edithMod:GetData(player)
	local targetSprite = effect:GetSprite()
	local room = game:GetRoom()

	if edithMod:IsKeyStompPressed(player) or playerData.ExtraJumps > 0 and playerData.EdithJumpTimer == 0 then
		targetSprite:Play("Blink")
	end
	
	if targetSprite:GetAnimation() == "Blink" then
		effect.Velocity = effect.Velocity * 0.3
	end

	local cameraPos = interpolateVector2D(playerPos, effectPos, 0.6)
	local Camera = room:GetCamera()
	Camera:SetFocusPosition(cameraPos)
	
	local markedTarget = player:GetMarkedTarget()
	-- local 
	if markedTarget then
		markedTarget.Position = effect.Position
		markedTarget.Velocity = Vector.Zero
		markedTarget.Visible = false
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
	
	edithMod:TargetDoorManager(effect, player, 25)
end 
edithMod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.EdithTargetLogic, edithMod.Enums.EffectVariant.EFFECT_EDITH_TARGET)

local targetPath = "gfx/effects/EdithTarget/effect_000_edith_target"

local targetlineColor = Color(1, 1, 1, 1)

function mod:EdithTargetSprite(effect)
	local room = game:GetRoom()	
	if room:GetRenderMode() == RenderMode.RENDER_WATER_REFLECT then return false end
	
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
				-- player.Color = effect.Color
			else		
				edithMod:ChangeColor(effect, targetColor.Red, targetColor.Green, targetColor.Blue)
			end
		else
			effect.Color = Color.Default
		end
		
		effectSprite:ReplaceSpritesheet(0, targetPath .. tables.TargetSuffix[targetDesign] .. ".png", true)
		
		local targetLine = saveData.targetline
		if targetLine ~= true then return end
								
		if targetDesign == 1 then
			targetlineColor = effectColor
		else
			targetlineColor.R = tables.ColorValues[targetDesign].R
			targetlineColor.G = tables.ColorValues[targetDesign].G
			targetlineColor.B = tables.ColorValues[targetDesign].B
		end

		local animation = effectSprite:GetAnimation()
		local frame = effectSprite:GetFrame()
		local isObscure = frame >= (tables.FrameLimits[animation] or 0)

		if isObscure then
			local newObcureColor = targetlineColor
			newObcureColor.R = newObcureColor.R * misc.ObscureDiv
			newObcureColor.G = newObcureColor.G * misc.ObscureDiv
			newObcureColor.B = newObcureColor.B * misc.ObscureDiv
		
			targetlineColor = newObcureColor
		end
		edithMod:drawLine(player.Position, effect.Position, targetlineColor, targetSpace) 
	end
end
edithMod:AddCallback(ModCallbacks.MC_PRE_EFFECT_RENDER, mod.EdithTargetSprite,edithMod.Enums.EffectVariant.EFFECT_EDITH_TARGET)
