
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

    local name = tostring(math.random(100,999))
    local a1 = get_account(name)
    loadData(a1)
    name = name + 1

    chat( a1, "@resetcity=2" )
    print("create ply a1 ", a1.pid)
    chat( a1, "@lvbuild=0=0=5" )
    chat( a1, "@set_val=gold=100000000" )
    chat( a1, "@starttw" )
    local u = gTime % 1000000
    Rpc:union_quit( a1 ) 
    sync(a1)
    Rpc:union_create(a1, tostring(u), tostring(u % 1000),40,1000)
    WARN("create u %d ", u)
    sync(a1)

    -- 创建账号A2 10级加入军团
    join_union(a1, 9, 10)
    -- 创建账号A3 6级加入军团
    join_union(a1, 29, 6)

    Rpc:get_city_for_robot_req(a1, ACT_NAME.NPC_CITY, {lv = city_lv})
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

    chat( a1, "@lvbuild=0=0=6" )
    Rpc:declare_tw_req(a1, eid) --A1 对2级资源带城市宣战
    WARN("delcare war again %d ", eid)
    sync(a1)
    tid = 0
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

    chat( a1, "@lvbuild=0=0=10" )
    tid = 0
    for k, v in pairs(a1._troop) do
        if v.target == eid then
            tid = k
            break
        end
    end
    if tid == 0 then
        WARN("declare again fail")
        return "declare error"
    end

    acc_troop_by_tid(a1, tid)

    chat(a1, "@fighttw")

    chat(a1, "@foract")
    chat(a1, "@addbuf=1=-1" )
    local arms = {}
    chat( a1, "@addarm=1001010=999999999" )
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

    a1.eye_info = nil
    Rpc:get_eye_info(a1, eid)
    wait_for_ack(a1, "get_eye_info")
    local info = a1.eye_info or {}
    if info.defender == a1.uid then
        return "atk error"
    end

    -- 创建账号A3 6级加入军团
    join_union(a1, 1, 6)
    chat(a1, "@foract")
    chat(a1, "@addbuf=1=-1" )
    local arms = {}
    chat( a1, "@addarm=1001010=999999999" )
    for id, num in pairs(a1._arm) do
        if num >  force_tb[city_lv][1] then
            arms[ id ] = force_tb[city_lv][1]
            break
        end
    end

    tid = 0
    tid = atk_by_eid(a1, eid, arms)
    if tid == 0 then
        reutn "atk error"
    end

    a1.eye_info = nil
    Rpc:get_eye_info(a1, eid)
    wait_for_ack(a1, "get_eye_info")
    local city = a1.eye_info or {}
    if info.defender == a1.uid then
        return "ok"
    end

    return "error"
end

return t1
