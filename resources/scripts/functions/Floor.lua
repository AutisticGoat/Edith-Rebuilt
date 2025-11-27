---@diagnostic disable: undefined-global, param-type-mismatch
local mod = EdithRebuilt
local enums = mod.Enums
local utils = enums.Utils
local game = utils.Game
local tables = enums.Tables

local Floor = {}

---Checks if player is in Last Judgement's Mortis 
---@return boolean
function Floor.IsLJMortis()
	if not StageAPI then return false end
	if not LastJudgement then return false end

	local stage = LastJudgement.STAGE
	local IsMortis = StageAPI and (stage.Mortis:IsStage() or stage.MortisTwo:IsStage() or stage.MortisXL:IsStage())

	return IsMortis
end

---@return integer
function Floor.GetMortisDrop()
	if not Floor.IsLJMortis() then return 0 end

	if LastJudgement.UsingMorgueisBackdrop then
		return tables.MortisBackdrop.MORGUE
	elseif LastJudgement.UsingMoistisBackdrop then 
		return tables.MortisBackdrop.MOIST
	else
		return tables.MortisBackdrop.FLESH
	end
end

---Checks if player run is in Chapter 4 (Womb, Utero, Scarred Womb, Corpse)
---@return boolean
function Floor.IsChap4()
	local backdrop = game:GetRoom():GetBackdropType()
	
	if floor.IsLJMortis() then return true end
	return mod.When(backdrop, tables.Chap4Backdrops, false)
end

return floor
