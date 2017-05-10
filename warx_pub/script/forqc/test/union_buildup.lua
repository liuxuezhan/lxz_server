--lxz
--修建军团建筑升级

local mod = {}

function mod.action( _idx )
    require("frame/debugger") 
    local p = get_account(1024)
    Rpc:union_quit( p )
    chat( p, "@set_val=gold=100000000" )
    chat( p, "@buildtop" )
    chat( p, "@addbuf=1=-1" )
    chat(p, "@additem=7001001=100")
    chat(p, "@additem=7001002=100")
    chat(p, "@additem=7001003=100")
    sync( p )
    Rpc:union_create(p,tostring(p.pid),p.account,40,1000)
    wait_for_ack( p, "union_on_create" )

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

    local num, def = 100, {}
    for i = 1, num do
        def[i] = get_account(i)
        Rpc:union_quit( def[i] )
        Rpc:union_apply( def[i],p.uid)
        chat(def[i], "@set_val=gold=100000000")
        chat(def[i], "@additem=7001001=100")
        chat(def[i], "@additem=7001002=100")
        chat(def[i], "@additem=7001003=100")
        
        chat(def[i], "@additem=7002001=100")
        chat(def[i], "@additem=7002002=100")
        chat(def[i], "@additem=7002003=100")
        
        chat(def[i], "@additem=7003001=100")
        chat(def[i], "@additem=7003002=100")
        chat(def[i], "@additem=7003003=100")
        
        chat(def[i], "@additem=7004001=100")
        chat(def[i], "@additem=7004002=100")
        chat(def[i], "@additem=7004003=100")

        Rpc:union_load( def[i],"build" )
        Rpc:union_buildlv_donate(def[i],1)
        --lxz(def[i].union_buildlv_donate)

        Rpc:union_buildlv_donate(def[i],2)
        --lxz(def[i].union_buildlv_donate)

        Rpc:union_buildlv_donate(def[i],3)
        --lxz(def[i].union_buildlv_donate)

        Rpc:union_buildlv_donate(def[i],5)
        sync(def[i])
        lxz(def[i].union_buildlv_donate)

        Rpc:union_quit( def[i] )
    end

    sync( p )
    Rpc:union_build_up(p,obj.idx,BUILD_STATE.UPGRADE) 
    build(p,obj,1)

    lxz(name.."0")
    return "ok"

end




return mod

