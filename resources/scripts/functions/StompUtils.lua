local StompUtils = {}

---@param params TEdithHopParryParams|EdithJumpStompParams
function StompUtils.GetDamage(params)
    return params.Damage or params.ParryDamage
end

---@param params TEdithHopParryParams|EdithJumpStompParams
function StompUtils.SetDamage(params, value)
    if params.Damage ~= nil then
        params.Damage = value
    else
        params.ParryDamage = value
    end
end

return StompUtils