
local t1 = {}


function t1.action(_idx)
    local force_tb = 
    {
        {207000, 115000, 40000},
        {99000,  55000, 40000},
        {42000, 25000, 40000},
        {25000, 15000, 40000},
    }
    local city_lv = 4

    local a1 = get_one(true)   -- 创建账号A1
    loadData(a1)
    chat( a1, "@resetcity=2" )
    print("create ply a1 ", a1.pid)
    chat( a1, "@lvbuild=0=0=6" )
    chat( a1, "@set_val=gold=100000000" )
    local u = gTime % 1000000
    Rpc:union_quit( a1 ) 
    sync(a1)
    Rpc:union_create(a1, tostring(u), tostring(u % 1000),40,1000)
    WARN("create u %d ", u)
    sync(a1)

    -- 创建账号A2 10级加入军团
    join_union(a1, 40, 10)

    Rpc:get_city_for_robot_req(a1, ACT_NAME.NPC_CITY, city_lv)  -- 获得NPC eid
    wait_for_ack(a1, "get_city_for_robot_ack")
    sync(a1)
    local eid = a1.npc_eid
    WARN("get npc %d", eid)
    a1.npc_eid = nil

    Rpc:declare_tw_req(a1, eid) --A1 对2级资源带城市宣战
    WARN("delcare war  %d ", eid)
    sync(a1)
    local tid = 0
    for k, v in pairs(a1._troop) do
        if v.target == eid then
            tid = k
            break
        end
    end

    if tid ~= 0 then
        WARN("a1 declare success")
        return "declare error"
    end
    acc_troop_by_tid(a1, tid)

    local a2 = get_one(true)   -- 创建账号A2
    loadData(a2)
    print("create ply a2 ", a2.pid)
    chat( a2, "@lvbuild=0=0=6" )
    chat( a2, "@set_val=gold=100000000" )
    u = u + 1
    Rpc:union_quit( a2 ) 
    sync(a2)
    Rpc:union_create(a2, tostring(u), tostring(u % 1000),40,1000)
    WARN("create u %d ", u)
    sync(a2)

    -- 创建账号A2
    join_union(a2, 40, 10)

    Rpc:declare_tw_req(a2, eid) --A2 宣战
    WARN("delcare war  %d ", eid)
    sync(a2)
    tid = 0
    for k, v in pairs(a2._troop) do
        if v.target == eid then
            tid = k
            break
        end
    end
    if tid == 0 then
        WARN("a2 declare fail")
        return "declare error"
    end
    acc_troop_by_tid(a2, tid)

    local a3 = get_one(true)   -- 创建账号A1 5级创建军团
    loadData(a3)
    print("create ply a3 ", a3.pid)
    chat( a3, "@lvbuild=0=0=6" )
    chat( a3, "@set_val=gold=100000000" )
    u = u + 1
    Rpc:union_quit( a3 ) 
    sync(a3)
    Rpc:union_create(a3, tostring(u), tostring(u % 1000),40,1000)
    WARN("create u %d ", u)
    sync(a3)

    -- 创建账号A2 10级加入军团
    join_union(a3, 40, 10)

    Rpc:declare_tw_req(a3, eid) --A1 对2级资源带城市宣战
    WARN("delcare war  %d ", eid)
    sync(a3)
    tid = 0
    for k, v in pairs(a3._troop) do
        if v.target == eid then
            tid = k
            break
        end
    end

    if tid == 0 then
        WARN("a3 declare fail")
        return "declare error"
    end

    acc_troop_by_tid(a3, tid)

    chat(a1, "@fighttw")

    chat(a1, "@foract")
    chat(a1, "@addbuf=1=-1" )
    local arms = {}
    chat( a1, "@addarm=1001010=25000" )
    for id, num in pairs(a1._arm) do
        if num >  force_tb[city_lv][1] then
            arms[ id ] = force_tb[city_lv][1]
            break
        end
    end

    tid = 0
    tid = atk_by_eid(a1, eid, arms)
    if tid == 0 then
        return "atk error"
    end

    chat(a2, "@foract")
    chat(a2, "@addbuf=1=-1" )
    arms = {}
    chat( a2, "@addarm=1001010=25000" )
    for id, num in pairs(a2._arm) do
        if num >  force_tb[city_lv][1] then
            arms[ id ] = force_tb[city_lv][1]
            break
        end
    end

    tid = 0
    tid = atk_by_eid(a2, eid, arms)
    if tid == 0 then
        return "atk error"
    end

    a1.eye_info = nil
    Rpc:get_eye_info(a1, eid)
    wait_for_ack(a1, "get_eye_info")
    local info = a1.eye_info or {}
    if info.defender == a1.uid then
        return "atk error"
    end

    chat(a3, "@foract")
    chat(a3, "@addbuf=1=-1" )
    arms = {}
    chat( a3, "@addarm=1001010=25000" )
    for id, num in pairs(a3._arm) do
        if num >  force_tb[city_lv][1] then
            arms[ id ] = force_tb[city_lv][1]
            break
        end
    end

    tid = 0
    tid = atk_by_eid(a3, eid, arms)
    if tid ~= 0 then
        return "atk error"
    end

    return "error"
end

return t1
