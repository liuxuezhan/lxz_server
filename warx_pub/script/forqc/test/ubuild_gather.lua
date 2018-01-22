--军团
--军团建筑采集

local mod = {}

function mod.action( _idx )

    local a = union_create("sss")

    local obj = set_build(a[1], 10007001, 0, 0, 14 ) 
    lxz(obj.val)
    while obj.val > 0 do
        for _,p in pairs(a) do
            v = _us[p.uid].build[obj.idx]
            lxz(v.val)
            gather(p,v)
            wait_for_ack( p, "stateTroop" )
        end
    end

    return "ok"

end

return mod

