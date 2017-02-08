--lxz
--军团建筑被攻击

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

    local num,ps = 1,{} 
    for i = 1, num do
        ps[i] = get_one2(name..i)
        chat( ps[i], "@set_val=gold=100000000" )
        chat( ps[i], "@buildtop" )
        chat( ps[i], "@addbuf=1=-1" )
        sync( ps[i] )
    end

    local obj = set_build(p, 10021001, p.x, p.y ) 
    if obj.state == BUILD_STATE.CREATE then
        lxz()
        atk(ps[1],obj)
        wait_for_ack( p, "union_broadcast" )
        wait_for_ack( p, "union_broadcast" )
        wait_for_ack( p, "union_broadcast" )
        obj = _us[p.uid].build[obj.idx]
        if obj then  return "fail" end 
        lxz()
        obj = set_build(p, 10021001, p.x, p.y ) 
        if obj.state == BUILD_STATE.CREATE then
            build(p,obj,1)
        end
        lxz()
        atk(ps[1],obj)
        wait_for_ack( p, "union_broadcast" )
        wait_for_ack( p, "union_broadcast" )
        obj = _us[p.uid].build[obj.idx]
    else
        return "fail"
    end

    local hp = obj.hp
    Rpc:union_build_up(p,obj.idx,BUILD_STATE.FIX) 
    build(p,obj)

    return "ok"
end

return mod

