--lxz
--军团建筑采集

local mod = {}

function mod.action( _idx )
    require("frame/debugger") 

    local a = union_create("555",5)

    for _, v in pairs( _us[p.uid].build or {}  ) do
        while v.val > 0 do
            for _,p in pairs(a) do
                v = _us[p.uid].build[v.idx]
                lxz(v.val)
                gather(p,v)
                wait_for_ack( p, "stateTroop" )
            end
        end
    end

    return "ok"

end

return mod

