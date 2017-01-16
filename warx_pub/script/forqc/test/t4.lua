--lxz
-- title: check siege monster
--
local t1 = {}
function t1.action( _idx )
    local p1 = get_one()
    loadData( p1 )
    chat( p1, "@set_val=gold=1000000" )
    chat( p1, "@buildtop" )
    chat( p1, "@initarm" )
    move_to( p1, 1103, 828, 30 )
    Rpc:union_quit( p1 )

    local p2 = get_one()
    loadData( p2 )
    chat( p2, "@set_val=gold=100000000" )
    chat( p2, "@buildtop" )
    chat( p2, "@initarm" )
    chat( p2, "@addbuf=1=-1" )
    Rpc:union_quit( p2 )

    dumpTab( p2._arm, "p2 arm" )

    local arms = {}
    for id, num in pairs( p2._arm ) do
        arms[ id ] = 10000
    end
    Rpc:siege( p2, p1.eid, { live_soldier = arms } )
    sync( p2 )

    buy_item( p2, 39, 100 )

    local tid = 0
    for k, v in pairs( p2._troop ) do
        if v.target == p1.eid then
            tid = k
            break
        end
    end

    if tid == 0 then 
        WARN( "no troop" )
        return
    end

    local ts = p2._troop
    while true do
        local flag = false
        local t = ts[ tid ]
        if t then
            if t.tmOver > gTime + 1 then
                Rpc:troop_acc( p2, tid, 7014001 )
                sync( p2 )
                flag = true
            end
        end
        if not flag then break end
    end

    wait_for_ack( p2, "stateTroop" )

    while true do
        local flag = false
        local t = ts[ tid ]
        if t then
            if t.tmOver > gTime + 5 then
                Rpc:troop_acc( p2, tid, 7014001 )
                sync( p2 )
                flag = true
            end
        end
        if not flag then break end
    end

    wait_for_ack( p2, "upd_arm" )
    dumpTab( p1._arm, " A_arms" )
    dumpTab( p1.hurts, "A_hurts" )

    dumpTab( p2._arm, "arms" )

    logout( p1 )
    logout( p2 )
end


return t1

