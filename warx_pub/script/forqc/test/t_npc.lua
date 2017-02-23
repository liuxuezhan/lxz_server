
local t1 = {}


function t1.action(_idx)
    local force_tb = 
    {
        {207000, 115000, 40000},
        {99000,  55000, 40000},
        {42000, 25000, 40000},
        {25000, 15000, 40000},
    }

    local p = get_one(true)
    loadData(p)

  --  chat(p, "@all")
    chat( p, "@lvbuild=0=0=30" )
    chat( p, "@buildtop" )
    chat( p, "@set_val=gold=100000000" )
--    chat( p, "@addbuf=1=-1" )
    --chat( p, "@addarm=1=999999999" )
--    chat( p, "@initarm" )
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
    local city_lv = math.random(4)


    Rpc:get_city_for_robot_req(p, ACT_NAME.NPC_CITY, city_lv)
    wait_for_ack(p, "get_city_for_robot_ack")
    sync(p)
    local eid = p.npc_eid
    WARN("get npc %d", eid)
    --local eid = 729095
    p.npc_eid = nil


    local u = gTime % 1000000
    Rpc:union_quit( p ) 
    sync(p)

    Rpc:union_create(p, tostring(u), tostring(u % 1000),40,1000)
    WARN("create u %d ", u)
    sync(p)
    --wait_for_ack( p, "union_on_create" )

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
            print(t.tmOver,get_tm(p))
            if t.tmOver > get_tm(p) + 1 then
                 Rpc:troop_acc( p, tid, 7014001 )
                 sync(p)
                 flag = true
            end
        end
        if not flag then break end
    end

    wait_for_ack(p, "stateTroop")


    chat(p, "@fighttw")

    chat(p, "@foract")
    local arms = {}
    chat( p, "@addarm=1001010=999999999" )
    for id, num in pairs(p._arm) do
        if num >  force_tb[city_lv][1] then
            arms[ id ] = force_tb[city_lv][1]
            break
        end
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
        return "fight error"
    end

    local p1 = get_one(true)
    loadData(p1)

    chat( p1, "@set_val=gold=1000000" )
    chat( p1, "@buildtop" )
    chat( p1, "@debug1" )

    chat(p1, "@starttw")

    Rpc:union_quit( p1 ) 
    sync(p1)

    u = u + 1

    Rpc:union_create(p1, tostring(u), tostring(u % 1000),40,1000)
    WARN("create u %d ", u)
    wait_for_ack( p1, "union_on_create" )

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


    chat(p1, "@fighttw")

    arms = {}
    chat(p1, "@foract")
    chat( p1, "@addarm=1001010=999999999" )
    for id, num in pairs(p1._arm) do
        if num >  force_tb[city_lv][1] then
            arms[ id ] = force_tb[city_lv][1]
            break
        end
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

    return "ok"
end

return t1
