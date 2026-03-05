local mod = EdithRebuilt
local enums = mod.Enums
local utils = enums.Utils
local effects = enums.EdithStatusEffects
local spicesMixID = enums.CollectibleType.COLLECTIBLE_SPICES_MIX
local game = utils.Game
local modules = mod.Modules
local StsEffects = modules.STATUS_EFFECTS
local Helpers = modules.HELPERS
local ModRNG = modules.RNG

local Descriptions = {
    [effects.SALTED] = "Slow and weakness, chance to destroy enemy's shots",
    [effects.PEPPERED] = "Enemies sneezes every 2nd hit, leave damaging creep on kill",
    [effects.CUMIN] = "Erratic movement, damaging enemies stops them",
    [effects.OREGANO] = "Slower enemies, slowing creep, constant damage over time",
    [effects.TURMERIC] = "Weaker enemies, infecting clouds on hit",
    [effects.GINGER] = "More pushable enemies, infecting clouds on kill",
    [effects.GARLIC] = "The enemies retreat, scattered shots",
    [effects.CINNAMON] = "Dusty Cough, persistent damaging and slowing cinnamon clouds",
}

local function ShowSpiceInfo(name, desc)
    game:GetHUD():ShowItemText(name, desc)
end

local SpicesJar = Sprite("gfx/EdithRebuiltSpicesMixJar.anm2", true)
SpicesJar:Play("Idle", true)

HudHelper.RegisterHUDElement({
    ItemID = spicesMixID,
    OnRender = function (player, _, _, position, alpha, scale, _, slot)
        if scale < 1 then return end

        SpicesJar.Scale = Vector.One * scale
        SpicesJar.Color = Color(1, 1, 1, alpha)
        SpicesJar:SetFrame("Idle", player:GetActiveItemDesc(slot --[[@as ActiveSlot]]).VarData - 1)
        SpicesJar:Render(position + Vector(16, 16))
    end
}, HudHelper.HUDType.ACTIVE_ID)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function(_, player)
    if not player:HasCollectible(spicesMixID) then return end

    for i = ActiveSlot.SLOT_PRIMARY, ActiveSlot.SLOT_POCKET do
        if player:GetActiveItem(i) ~= spicesMixID  then goto continue end
        local active = player:GetActiveItemDesc(i)

        if active.VarData == 0 then
            player:SetActiveVarData(1, i)
            ShowSpiceInfo(effects.SALTED, Descriptions[effects.SALTED])
        end

        if Input.IsActionTriggered(ButtonAction.ACTION_MAP, player.ControllerIndex) then
            local spice = StsEffects.GetSpiceEffect(active.VarData)
            ShowSpiceInfo(spice.ID, Descriptions[spice.ID])
        end

        if not Input.IsActionTriggered(ButtonAction.ACTION_DROP, player.ControllerIndex) then goto continue end
        player:SetActiveVarData(active.VarData + 1, i)

        if active.VarData > 8 then
            player:SetActiveVarData(1, i)
        end

        local spice = StsEffects.GetSpiceEffect(active.VarData)
        ShowSpiceInfo(spice.ID, Descriptions[spice.ID])
        ::continue::
    end
end)

---@param RNG RNG
---@param player EntityPlayer
---@param slot ActiveSlot
mod:AddCallback(ModCallbacks.MC_USE_ITEM, function (_, _, RNG, player, _, slot)
    local spice = StsEffects.GetSpiceEffect(player:GetActiveItemDesc(slot).VarData)
    local effect = spice.ID
    local RandCol = spice.Color
    local newColor = effect == "Salted" and RandCol or Color(RandCol.RO, RandCol.GO, RandCol.BO)
    local X = ModRNG.RandomFloat(RNG, 0.85, 1.15)
    local Y = ModRNG.RandomFloat(RNG, 0.85, 1.15)
    local Puff = StsEffects.SpawnSpicePuff(player, RNG)

    Puff.SpriteScale = Vector(X, Y)
    Puff:GetSprite().PlaybackSpeed = ModRNG.RandomFloat(RNG, 0.9, 1.1)
    Puff:SetColor(newColor, -1, 1000, false, false)

    for _, enemy in ipairs(Isaac.FindInRadius(player.Position, 60, EntityPartition.ENEMY)) do
        if not Helpers.IsEnemy(enemy) then goto continue end
        Helpers.TriggerPush(enemy, player, 30)
        StsEffects.SetStatusEffect(effect, enemy, spice.Duration, player)
        ::continue::
    end

    return true
end, spicesMixID)

---@param varData integer
mod:AddCallback(ModCallbacks.MC_PLAYER_GET_ACTIVE_MAX_CHARGE, function(_, _, _, varData)
    return StsEffects.GetSpiceEffect(varData).Cooldown
end, spicesMixID)