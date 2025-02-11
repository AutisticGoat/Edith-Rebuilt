local mod = edithMod
local enums = mod.Enums
local utils = enums.Utils
local tables = enums.Tables
local game = utils.Game
local misc = enums.Misc

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
	local playerData = edithMod.GetData(player)
	local targetSprite = effect:GetSprite()
	local room = game:GetRoom()

	if edithMod.IsKeyStompPressed(player) or playerData.ExtraJumps > 0 and playerData.EdithJumpTimer == 0 then
		targetSprite:Play("Blink")
	end
	
	if targetSprite:GetAnimation() == "Blink" then
		effect.Velocity = effect.Velocity * 0.3
	end

	local cameraPos = interpolateVector2D(playerPos, effectPos, 0.6)
	local Camera = room:GetCamera()
	Camera:SetFocusPosition(cameraPos)
	
	local markedTarget = player:GetMarkedTarget()
	if markedTarget then
		markedTarget.Position = effect.Position
		markedTarget.Velocity = Vector.Zero
		markedTarget.Visible = false
	end
	
	if room:GetType() == RoomType.ROOM_DUNGEON then
		for _, v in ipairs(teleportPoints) do
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

	if edithMod.SaveManager:IsLoaded() then
		local saveData = edithMod.SaveManager.GetDeadSeaScrollsSave()
		if not saveData then return end
		
		local edithData = saveData.EdithData

		local targetColor = edithData.TargetColor

		local RGBmode = edithData.RGBMode
		local RGBspeed = edithData.RGBSpeed
		local targetSpace = edithData.linespace
		local targetDesign = edithData.targetdesign

		local effectColor = effect.Color
		local effectSprite = effect:GetSprite()
		
		local color = (targetDesign == 1 and 
			(RGBmode and edithMod:RGBCycle(RGBspeed) or Color(targetColor.Red, targetColor.Green, targetColor.Blue)) 
		) or Color.Default

		effect:SetColor(color, -1, 100, false, false)
		
		effectSprite:ReplaceSpritesheet(0, targetPath .. tables.TargetSuffix[targetDesign] .. ".png", true)
		
		local targetLine = edithData.targetline

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
