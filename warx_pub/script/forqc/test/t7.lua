--lxz
--打怪伤兵5%

local t1 = {}
function t1.action( _idx )
    local p = get_one()
    lxz(p.acc)
    loadData( p )
    chat( p, "@set_val=gold=100000000" )
    chat( p, "@buildtop" )
    chat( p, "@initarm" )
    chat( p, "@addbuf=1=-1" )
    Rpc:union_quit( p )

    local arms = {}
    local aid = 0
    for id, num in pairs( p._arm ) do
        aid = id
        arms[ aid ] = 10000
        break
    end
    lxz()

    --move_to( p, math.random(100,1000), math.random(100,1000), 30 )
    get_eye( p, 30 )
    lxz()
    local obj = {}
    for k, v in pairs( p._etys or {} ) do
        lxz( "siege", v.propid, v.eid )
        if is_monster( v ) then
            local conf = resmng.get_conf( "prop_world_unit", v.propid )
            if conf and conf.Clv and conf.Clv < 10 then
                Rpc:siege( p, v.eid, { live_soldier=arms } )
                obj = v
                sync( p )
                break
            end
        end
    end

    buy_item( p, 39, 100 )

    local tid = 0
    for k, v in pairs( p._troop ) do
        if v.target == obj.eid then
            tid = k
            break
        end
    end

    if tid == 0 then WARN( "no troop" ) return end

    local ts = p._troop
    while true do
        local flag = false
        local t = ts[ tid ]
        if t then
            print(t.tmOver,get_tm(p))
            if t.tmOver > get_tm(p) + 2 then
                Rpc:troop_acc( p, tid, 7014001 )
                sync( p )
                flag = true
            end
        end
        if not flag then break end
    end

    wait_for_ack( p, "stateTroop" )

    while true do
        local flag = false
        local t = ts[ tid ]
        if t then
            if t.tmOver > get_tm(p) + 2 then
                Rpc:troop_acc( p, tid, 7014001 )
                sync( p )
                flag = true
            end
        end
        if not flag then break end
    end

    wait_for_ack( p, "upd_arm" )

    --logout( p )
    lxz(aid,p._arm)
    local r = 10000 - p._arm[aid]  
    if r > 0 and r < 501 then return "ok" end
    return "fail"
end


return t1

