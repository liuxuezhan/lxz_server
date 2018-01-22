
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

    local name = 899
    local a1 = get_account(name)
    loadData(a1)
    name = name + 1

    --local a1 = get_one(true)   -- 创建账号A1 5级创建军团
    --loadData(a1)
    chat( a1, "@resetcity=2" )
    print("create ply a1 ", a1.pid)
    chat( a1, "@starttw" ) 
    chat( a1, "@lvbuild=0=0=10" )
    chat( a1, "@set_val=gold=100000000" )
    Rpc:union_quit( a1 ) 
    sync(a1)
    local u = gTime % 1000000
    Rpc:union_create(a1, tostring(u), tostring(u % 1000),40,1000)
    WARN("create u %d ", u) 
    sync(a1)
    join_union(a1, 8, 10)

    --local a2 = get_one(true)   -- 创建账号A1 5级创建军团
    --loadData(a2)
    local a2 = get_account(name)
    loadData(a2)
    name = name + 1
    chat( a2, "@resetcity=2" )
    print("create ply a2 ", a2.pid)
    chat( a2, "@lvbuild=0=0=10" )
    chat( a2, "@set_val=gold=100000000" )
    Rpc:union_quit( a2 ) 
    sync(a2)
    Rpc:union_apply(a2, a1.uid)
    sync(a2)

    Rpc:get_city_for_robot_req(a1, ACT_NAME.NPC_CITY,  {lv = city_lv})
    wait_for_ack(a1, "get_city_for_robot_ack")
    sync(a1)
    local eid = a1.npc_eid
    WARN("get npc %d", eid)
    a1.npc_eid = nil

    Rpc:union_member_rank(a1, a2.pid, resmng.UNION_RANK_3)
    sync(a2)
    Rpc:declare_tw_req(a2, eid) --A1 对2级资源带城市宣战
    WARN("delcare war  %d ", eid)
    sync(a2)
    local tid = 0
    for k, v in pairs(a2._troop) do
        if v.target == eid then
            tid = k
            break
        end
    end
    if tid ~= 0 then
        WARN("a1 declare success")
        return "declare error"
    end

    Rpc:union_member_rank(a1, a2.pid, resmng.UNION_RANK_4)
    Rpc:declare_tw_req(a2, eid) --A1 对2级资源带城市宣战
    WARN("delcare war  %d ", eid)
    sync(a2)
    tid = 0
    for k, v in pairs(a2._troop) do
        if v.target == eid then
            tid = k
            break
        end
    end
    if tid ~= 0 then
        WARN("a1 declare success")
    end

    return "ok"
end

return t1
