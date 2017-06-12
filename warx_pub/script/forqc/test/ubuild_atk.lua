--lxz
--军团建筑被攻击

local mod = {}

function mod.action( _idx )
    require("frame/debugger") 
    local name = tostring(math.random(100,999))
    lxz(name)

    local p = get_account2(name)
    Rpc:union_quit( p )
    chat( p, "@set_val=gold=100000000" )
    chat( p, "@buildtop" )
    chat( p, "@addbuf=1=-1" )
    sync( p )
    Rpc:union_create(p,"robot"..name,name,40,1000)
    wait_for_ack( p, "union_on_create" )

    local num,def = 10,{} 
    for i = 1, num do
        def[i] = get_account2(name..i)
        Rpc:union_quit( def[i] )
        Rpc:union_apply( def[i],p.uid)
        chat( def[i], "@set_val=gold=100000000" )
        chat( def[i], "@buildtop" )
        chat( def[i], "@addbuf=1=-1" )
        sync( def[i] )
    end

    local num,ps = 1,{} 
    for i = 1, num do
        ps[i] = get_account2(name.."_"..i)
        chat( ps[i], "@set_val=gold=100000000" )
        chat( ps[i], "@buildtop" )
        chat( ps[i], "@addbuf=1=-1" )
        sync( ps[i] )
    end

    local obj = set_build(p, 10021001, p.x, p.y ) 
    if obj.state == BUILD_STATE.CREATE then
        atk(ps[1],obj)
        wait_for_ack( p, "union_broadcast" )
        wait_for_ack( p, "union_broadcast" )
        wait_for_ack( p, "union_broadcast" )
        obj = _us[p.uid].build[obj.idx]
        if obj then  return "fail" end 
        obj = set_build(p, 10021001, p.x, p.y ) 
        if obj.state == BUILD_STATE.CREATE then
            build(p,obj,1)
        end
        lxz()
        atk(ps[1],obj)
        lxz()
        wait_for_ack( p, "union_broadcast" )
        wait_for_ack( p, "union_broadcast" )
        obj = _us[p.uid].build[obj.idx]
        lxz()
    else
        return "fail"
    end

    local hp = obj.hp
    lxz()
    Rpc:union_build_up(p,obj.idx,BUILD_STATE.FIX) 
    build(p,obj)

    return "ok"
end

return mod

