--lxz
--军团建筑条件检查

local mod = {}

function mod.action( _idx )
    require("frame/debugger") 
    local name = tostring(math.floor(gTime%1000))
    local p = get_account(1024)
    Rpc:union_quit( p )
    chat( p, "@set_val=gold=100000000" )
    chat( p, "@buildtop" )
    chat( p, "@addbuf=1=-1" )
    sync( p )
    Rpc:union_create(p,name,name,40,1000)
    wait_for_ack( p, "union_on_create" )

    local num,def = 1,{} 
    for i = 1, num do
        def[i] = get_account(i)
        Rpc:union_quit( def[i] )
        Rpc:union_apply( def[i],p.uid)
        chat( def[i], "@set_val=gold=100000000" )
        chat( def[i], "@buildtop" )
        chat( def[i], "@addbuf=1=-1" )
        sync( def[i] )
    end

    local obj = set_build(p, 10021001, p.x, p.y ) 
    if obj.state == BUILD_STATE.CREATE then
        local obj12 = set_build(p, 10007001, obj.x, obj.y,14 ) 
        lxz()
        if obj12 then return "fail" end

        obj12 = set_build(p, 10031001, obj.x+50, obj.y+50,14 ) 
        lxz()
        if obj12 then return "fail" end

        obj12 = set_build(p, 10004001, obj.x, obj.y,14 ) 
        lxz()
        if obj12 then return "fail" end

        build(p,obj,1)
    end

    --超级矿
    local obj2 = set_build(p, 10007001, obj.x, obj.y, 14 ) 
    if not obj2 then return "fail" end
    lxz(obj2.state )
    if obj2.state == BUILD_STATE.CREATE then
        build(p,obj2,1)
    end

    --仓库
    local obj3 = set_build(p, 10004001, obj.x, obj.y, 14 ) 
    if not obj3 then return "fail" end
    lxz(obj3.state )
    if obj3.state == BUILD_STATE.CREATE then
        build(p,obj3,1)
    end

    --小奇迹
    local obj4 = set_build(p, 10031001, obj.x+50, obj.y+50 ) 
    if not obj4 then return "fail" end
    lxz(obj4.state )
    if obj4.state == BUILD_STATE.CREATE then
        build(p,obj4,1)
    end

    return "ok"
end

return mod

