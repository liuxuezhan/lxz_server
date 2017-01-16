
local t1 = {}

function t1.action(_idx)
    local p = get_one(true)
    loadData(p)

    chat( p, "@set_val=gold=1000000" )
    chat( p, "@lvbuild=0=0=30" )
    chat( p, "@buildtop" )
    chat( p, "@initarm" )
    chat(p, "@debug1")

    chat(p, "@starttw")
    WARN("starttw")

    --local index = math.random(40)
    --local num = 1
    --local city = {}
    --for k, eid in pairs(npc_city.citys) do
    --    if num == index then
    --        city = get_ety(eid)
    --        break
    --    end
    --end
    --

    Rpc:get_city_for_robot_req(p, ACT_NAME.NPC_CITY, 4)
    wait_for_ack(p, "get_city_for_robot_ack")
    sync(p)
    local eid = p.npc_eid
    WARN("get npc %d", eid)
    --local eid = 729095
    p.eid = nil


    local u = gTime % 1000000
    Rpc:union_quit( p ) 
    sync(p)

    Rpc:union_create(p, tostring(u), tostring(u % 1000),40,1000)
    WARN("create u %d ", u)
    sync(p)

    Rpc:declare_tw_req(p, eid) --宣战
    WARN("delcare war  %d ", eid)
    sync(p)

    buy_item(p, 39, 100)

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

    local ts = p._troop
    while true do
        local flag = false
        local t = ts[tid]
        if t then
            if t.tmOver > gTime + 1 then
                 Rpc:troop_acc( p, tid, 7014001 )
                 sync(p)
                 flag = true
            end
        end
        if not flag then break end
    end

    wait_for_ack(p, "stateTroop")

    local p1 = get_one(true)
    loadData(p1)

    chat( p1, "@set_val=gold=1000000" )
    chat( p1, "@buildtop" )
    chat( p1, "@initarm" )
    chat( p1, "@debug" )

    Rpc:union_quit( p1 ) 
    sync(p1)

    u = u + 1

    Rpc:union_create(p1, tostring(u), tostring(u % 1000),40,1000)
    WARN("create u %d ", u)
    sync(p1)

    Rpc:declare_tw_req(p1, eid) --宣战
    WARN("delcare war  %d ", eid)
    sync(p1)

    buy_item(p1, 39, 100)

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

    wait_for_ack(p1, "stateTroop")


    chat(p, "@fighttw")

    local arms = {}
    for id, num in pairs(p._arm) do
        arms[ id ] = 5000
    end
    Rpc:siege(p, eid, {live_soldier = arms})
    WARN("siege npc  %d ", eid)
    sync(p)

    tid = 0
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
            if t.tmOver > gTime + 1 then
                 Rpc:troop_acc( p, tid, 7014001 )
                 sync(p)
                 flag = true
            end
        end
        if not flag then break end
    end

    wait_for_ack( p, "stateTroop" ) 

    arms = {}
    for id, num in pairs(p1._arm) do
        arms[ id ] = 5000
    end
    Rpc:siege(p1, eid, {live_soldier = arms})
    WARN("siege npc  %d ", eid)
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

    wait_for_ack( p, "stateTroop" ) 
end

return t1
