--lxz
--修建军团建筑

local mod = {}

function mod.action( _idx )
    require("frame/debugger") 
    local p = get_one2("r01")
    chat( p, "@set_val=gold=100000000" )
    chat( p, "@buildtop" )
    chat( p, "@addbuf=1=-1" )
    sync( p )

    local p2 = get_one2("r02")
    chat( p2, "@set_val=gold=100000000" )
    chat( p2, "@buildtop" )
    chat( p2, "@addbuf=1=-1" )
    sync( p2 )

    local p3 = get_one2("r03")
    chat( p3, "@set_val=gold=100000000" )
    chat( p3, "@buildtop" )
    chat( p3, "@addbuf=1=-1" )
    sync( p3 )

    if p.uid < 10000 then
        Rpc:union_quit( p )
        sync( p )
    end

    if p.uid == 0 then
        Rpc:union_create(p,tostring(p.pid),p.account,40,1000)
        wait_for_ack( p, "union_on_create" )
    end

    if p2.uid ~= p.uid then
        Rpc:union_quit( p2 )
        Rpc:union_apply(p2,p.uid)
        sync( p2 )
    end

    if p3.uid < 10000 then
        Rpc:union_quit( p3 )
        sync( p3 )
    end

    if p3.uid == 0 then
        Rpc:union_create(p3,tostring(p3.pid),p3.account,40,1000)
        wait_for_ack( p3, "union_on_create" )
    end

    local obj = set_build(p, 10021001, p.x, p.y ) 
    lxz(obj.state )
    if obj.state == BUILD_STATE.CREATE then
        local obj12 = set_build(p, 10007001, obj.x, obj.y,14 ) 
        if obj12 then return "fail" end

        local obj12 = set_build(p, 10031001, obj.x+50, obj.y+50 ) 
        lxz()
        if obj12 then return "fail" end

        local obj12 = set_build(p, 10004001, obj.x, obj.y,14 ) 
        lxz()
        if obj12 then return "fail" end


        build(p,obj)
        obj = _us[p.uid].build[obj.idx]
        local speed1 = obj.speed_b
        lxz(speed1)

        build(p2,obj)
        obj = _us[p.uid].build[obj.idx]
        local speed2 = obj.speed_b
        lxz(speed2)
        if  2*speed1 ~= speed2  then lxz(speed1,speed2) return "fail"  end

        back(p2)
        obj = _us[p.uid].build[obj.idx]
        local speed3 = obj.speed_b
        if  speed1 ~= speed3 then lxz() return "fail"  end

        atk(p3,obj)
        obj = _us[p.uid].build[obj.idx]
        if obj.speed_f ~= 0.5 then lxz() return "fail"  end

        build(p,obj,1)
    elseif obj.state == BUILD_STATE.WAIT then
        --超级矿
        local obj2 = set_build(p, 10007001, obj.x, obj.y, 14 ) 
        if obj2 then return "fail" end
        lxz(obj2.state )
        if obj2.state == BUILD_STATE.CREATE then
            build(p,obj2,1)
        elseif obj2.state == BUILD_STATE.WAIT then
            gather(p,obj2)
            obj2 = _us[p.uid].build[obj2.idx]
            local speed1 = obj2.speed_g
            gather(p2,obj2)
            obj2 = _us[p.uid].build[obj2.idx]
            local speed2 = obj2.speed_g
            if  speed1*2 ~= speed2 then lxz() return "fail"  end
        end

        --仓库
        local obj3 = set_build(p, 10004001, obj.x, obj.y, 14 ) 
        if obj3 then return "fail" end
        lxz(obj3.state )
        if obj3.state == BUILD_STATE.CREATE then
            build(p,obj3,1)
        end

        --小奇迹
        local obj4 = set_build(p, 10031001, obj.x+50, obj.y+50 ) 
        if obj4 then return "fail" end
        lxz(obj4.state )
        if obj4.state == BUILD_STATE.CREATE then
            build(p,obj4,1)
        end

        chat( p, "@build_lv=1=2" )
        sync( p )
        Rpc:union_build_up(p,obj.idx,BUILD_STATE.UPGRADE) 
        build(p,obj,1)

    end

    return "ok"

end




return mod

