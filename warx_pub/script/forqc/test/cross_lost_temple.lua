
local t1 = {}


function t1.action(_idx)
    local force_tb = 
    {
        {96000, 35000, 40000},
        {71000, 35000, 30000},
        {40000, 20000, 20000},
    }

    local a = union_create(nil,1)
    local p = a[1] 
    loadData(p)

    chat(p, "@all")
    chat( p, "@lvbuild=0=0=30" )
    chat( p, "@buildtop" )
    chat( p, "@set_val=gold=100000000" )
    chat(p, "@crossgm=2")
    chat(p, "@jump=6")
    wait_for_ack(p, "onLogin")

    chat(p, "@debug1")

    chat(p, "@startlt")
    WARN("startlt")

    local city_lv = math.random(3)

    Rpc:get_city_for_robot_req(p, ACT_NAME.LOST_TEMPLE, {lv = city_lv})
    wait_for_ack(p, "get_city_for_robot_ack")
    local eid = p.lt_eid
    WARN("get lt %d", eid)
    --local eid = 729095
    p.lt_eid = nil

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
    WARN("siege lt  %d ", eid)
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

    -- print(left, force_tb[city_lv][3])

    -- if left > force_tb[city_lv][3] or left < -force_tb[city_lv][3] then
    --     return "fight error"
    -- end

    local b = union_create(nil,1)
    local p1 = b[1] 
    loadData(p1)

    chat( p1, "@all" )
    chat( p1, "@set_val=gold=1000000" )
    chat( p1, "@buildtop" )
    chat(p1, "@crossgm=2")
    chat(p1, "@jump=6")
    wait_for_ack(p1, "onLogin")

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
    WARN("siege lt  %d ", eid)
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

    return "ok"
end

return t1
