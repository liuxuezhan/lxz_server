
local t1 = {}


function t1.action(_idx)
    local force_tb = 
    {
        {178000, 50000, 30000},
        {178000, 50000, 30000},
        {7800, 50000, 30000},
    }

    local p = get_one(true)
    loadData(p)

    chat(p, "@all")
    chat( p, "@lvbuild=0=0=30" )
    chat( p, "@buildtop" )
    chat( p, "@set_val=gold=100000000" )
    chat(p, "@debug1")

    chat(p, "@fightkw")
    WARN("fightkw")

    local city_lv = 1

    Rpc:get_city_for_robot_req(p, ACT_NAME.KING, 1)
    wait_for_ack(p, "get_city_for_robot_ack")
    local eid = p.king_eid
    WARN("get king  %d", eid)
    --local eid = 729095
    p.king_eid = nil


    local u = gTime % 1000000
    Rpc:union_quit( p ) 
    sync(p)

    Rpc:union_create(p, tostring(u), tostring(u % 1000),40,1000)
    WARN("create u %d ", u)
    wait_for_ack( p, "union_on_create" )
    buy_item(p, 39, 100)

    local arms = {}
    chat( p, "@addarm=1001010=999999999" )
    for id, num in pairs(p._arm) do
        if num >  force_tb[city_lv][1] then
            arms[ id ] = force_tb[city_lv][1]
            break
        end
    end
    Rpc:siege(p, eid, {live_soldier = arms})
    WARN("siege king  %d ", eid)
    sync(p)

    local tid = 0
    for k, v in pairs(p._troop) do
        if v.target == eid then
            tid = k
            break
        end
    end

    if tid == 0 then
        WARN("no troop")
        return
    end

    ts = p._troop
    while true do
        local flag = false
        local t = ts[tid]
        if t then
            print(t.tmOver,get_tm(p))
            if t.tmOver > get_tm(p) + 1 then
                 Rpc:troop_acc( p, tid, 7014001 )
                 sync(p)
                 flag = true
            end
        end
        if not flag then break end
    end

    wait_for_ack( p, "stateTroop" ) 

    Rpc:qry_troop_info(p, tid)
    --sync(p)
    wait_for_ack(p, "ack_troop_info")

    local left = p.arm_count - force_tb[city_lv][2]

    print(left, force_tb[city_lv][3])

    if left > force_tb[city_lv][3] or left < -force_tb[city_lv][3] then
        WARN( "fight error", left, force_tb[city_lv][3])
        return "fight error"
    end

    local p1 = get_one(true)
    loadData(p1)

    chat(p1, "@all")
    chat( p1, "@set_val=gold=1000000" )
    chat( p1, "@buildtop" )

    Rpc:union_quit( p1 ) 
    sync(p1)

    u = u + 1

    Rpc:union_create(p1, tostring(u), tostring(u % 1000),40,1000)
    WARN("create u %d ", u)
    wait_for_ack( p1, "union_on_create" )

    buy_item(p1, 39, 100)

    arms = {}
    chat( p1, "@addarm=1001010=999999999" )
    for id, num in pairs(p1._arm) do
        if num >  force_tb[city_lv][1] then
            arms[ id ] = force_tb[city_lv][1]
            break
        end
    end
    Rpc:siege(p1, eid, {live_soldier = arms})
    WARN("siege king  %d ", eid)
    sync(p1)

    tid = 0
    for k, v in pairs(p1._troop) do
        if v.target == eid then
            tid = k
            break
        end
    end

    if tid == 0 then
        WARN("no troop")
        return
    end

    ts = p1._troop
    while true do
        local flag = false
        local t = ts[tid]
        if t then
            if t.tmOver > gTime + 1 then
                 Rpc:troop_acc( p1, tid, 7014001 )
                 sync(p1)
                 flag = true
            end
        end
        if not flag then break end
    end

    chat( p1, "@endkw" )
    chat( p1, "@king" )



    return "ok"
end

return t1
