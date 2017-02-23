--lxz
--军团建筑仓库

local mod = {}

function mod.action( _idx )
    require("frame/debugger") 
    local name = math.floor(gTime%1000)
    local p = get_one2(name.."0")
    Rpc:union_quit( p )
    chat( p, "@set_val=gold=100000000" )
    chat( p, "@buildtop" )
    chat( p, "@addbuf=1=-1" )
    sync( p )
    Rpc:union_create(p,tostring(p.pid),p.account,40,1000)
    wait_for_ack( p, "union_on_create" )

    local num,def = 2,{} 
    for i = 1, num do
        def[i] = get_one2(name..i)
        Rpc:union_quit( def[i] )
        Rpc:union_apply( def[i],p.uid)
        chat( def[i], "@set_val=gold=100000000" )
        chat( def[i], "@buildtop" )
        chat( def[i], "@addbuf=1=-1" )
        chat( def[i], "@addarm=4010=100000" )
        chat( def[i], "@ef_add=SpeedGather_R=90000000" )
        sync( def[i] )
    end

    local obj = set_build(p, 10021001, p.x, p.y ) 
    build(p,obj,1)
    local obj2 = set_build(p, 10004001, obj.x, obj.y, 14 ) 
    build(p,obj2,1)
    for i = 1, num do
        save_res(def[i],obj2)
        wait_for_ack( def[i], "stateTroop" )
    end
    Rpc:get_eye_info( p, obj2.eid )
    sync( p )
    lxz(p.eye_info.res)
    for i = 1, num do
        get_res(def[i],obj2)
        wait_for_ack( def[i], "stateTroop" )
    end
    Rpc:get_eye_info( p, obj2.eid )
    sync( p )
    lxz(p.eye_info.res)

    return "ok"

end

return mod

