local Autobot = {}

function Autobot.condCheck(p, tab, num)
    if tab then
        num = num or 1
        for _, v in pairs(tab) do
            local class, mode, lv = unpack(v)
            if class == "OR" or class == "AND" then 
                if not Autobot.doCondCheck(p, unpack(v) ) then return false 
                end
            elseif not Autobot.doCondCheck(p, class, mode, math.ceil( (lv or 0)* num ) ) then 
                return false
            end
        end
    end
    return true
end


function Autobot.doCondCheck(p, class, mode, lv, ...)
    if class == "OR" then
        local f,c,m,l 
        for _, v in pairs({mode, lv, ...}) do
            if Autobot.doCondCheck(p,unpack(v)) then return true end
        end
        return false

    elseif class == "AND" then 
        for _, v in pairs({mode, lv, ...}) do
            if not Autobot.doCondCheck(p,unpack(v)) then return false, class, mode, lv end
        end
        return true

    elseif class == resmng.CLASS_RES then
        -- if mode == resmng.DEF_RES_FOOD then
        --     if p.food - (gTime-p.foodTm)*p.foodUse / 3600 >= lv then return true end
        -- elseif mode == resmng.DEF_RES_WOOD then
        --     if p.wood >= lv then return true end
        -- end
    elseif class == resmng.CLASS_BUILD then
        local t = resmng.prop_build[ mode ]
        if t then
            for _, v in pairs( p._build or {} ) do
                local n = resmng.prop_build[ v.propid ]
                if n and n.Class == t.Class and n.Mode == t.Mode then 
                    if n.Lv >= t.Lv then
                        return true
                    end
                    return
                end
            end
        end
    elseif class == resmng.CLASS_GENIUS then
        local t = resmng.prop_genius[ mode ]
        if t then
            for _, v in pairs(p.genius) do
                local n = resmng.prop_genius[ v ]
                if n and n.Class == t.Class and n.Mode == t.Mode and n.Lv >= t.Lv then
                    return true
                end
            end
        end
    elseif class == resmng.CLASS_TECH then
        local t = resmng.prop_tech[ mode ]
        if t then
            for _, v in pairs(p.tech or {} ) do
                local n = resmng.prop_tech[ v ]
                if n and n.Class == t.Class and n.Mode == t.Mode then 
                    if n.Lv >= t.Lv then
                        return true
                    end
                    return
                end
            end
        end
    elseif class == resmng.CLASS_TASK_FINISH then
        return is_task_finished(p, mode)
    end
    return false, class, mode, lv
end

return Autobot

