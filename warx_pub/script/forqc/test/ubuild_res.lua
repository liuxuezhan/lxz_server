--军团
--军团建筑仓库

local mod = {}

function mod.action( _idx )

    local def = union_create()
    local p = def[1]
    for i = 1, 10 do
        chat( def[i], "@addarm=4010=100000" )
        chat( def[i], "@ef_add=SpeedGather_R=90000000" )
        sync( def[i] )
    end

    local id = 10031001
    local obj2 = set_build(p, id, 0, 0, 14 ) 
    for i = 1, 10 do
        save_res(def[i],obj2)
        wait_for_ack( def[i], "stateTroop" )
    end
    Rpc:get_eye_info( p, obj2.eid )
    sync( p )
    lxz(p.eye_info.res)
    for i = 1, 10 do
        get_res(def[i],obj2)
        wait_for_ack( def[i], "stateTroop" )
    end
    Rpc:get_eye_info( p, obj2.eid )
    sync( p )
    lxz(p.eye_info.res)

    return "ok"

end

return mod

