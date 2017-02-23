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

    local a1 = get_one(true)   -- 军团1 创建军团并宣战
    loadData(a1)
    chat( a1, "@resetcity=2" )
    chat( a1, "@starttw" ) 
    Rpc:get_city_for_robot_req(a1, ACT_NAME.NPC_CITY, city_lv)
    wait_for_ack(a1, "get_city_for_robot_ack")
    sync(a1)
    local eid = a1.npc_eid
    WARN("get npc %d", eid)
    a1.npc_eid = nil

    if new_declare_war(eid) ~= "ok" then
        return "union 1 declare error"
    end

    if new_declare_war(eid) ~= "ok" then
        return "union 2 declare error"
    end

    if new_declare_war(eid) ~= "ok" then
        return "union 3 declare error"
    end

    if new_declare_war(eid) ~= "ok" then
        return "union 4 declare error"
    end

    if new_declare_war(eid) ~= "ok" then
        return "union 5 declare error"
    end

    if new_declare_war(eid) == "ok" then
        return "union 6 declare error"
    end
    return "ok"
end

function new_declare_war(eid)
    local a1 = get_one(true)   -- 军团1 创建军团并宣战
    loadData(a1)
    chat( a1, "@resetcity=2" )
    print("create ply  ", a1.pid)
    chat( a1, "@lvbuild=0=0=10" )
    chat( a1, "@set_val=gold=100000000" )
    --chat( a1, "@debug1" )
    chat( a1, "@addres=9=9999999" )
    Rpc:union_quit( a1 ) 
    sync(a1)
    local u = math.random(100000, 999999)
    Rpc:union_create(a1, tostring(u), tostring(u % 1000),40,1000)
    WARN("create u %d ", u) 
    sync(a1)
    join_union(a1, 9, 10)

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

    if tid == 0 then
        WARN("a1 declare unsuccess")
        return "declare error"
    end

    acc_troop_by_tid(a1, tid)

    a1.ety_info = nil
    local cmd = "@etyinfo=" .. tostring(eid)
    chat( a1, "@set_val=gold=100000000" )
    Rpc:chat( a1, 0, cmd, 0 )
    wait_for_ack(a1, "ety_info_ack")
    local city = a1.ety_info

    if not city then
        return "case error"
    end

    if not city._pro.declareUnions[a1.uid] then
        return "declare error"
    end

    return "ok"
end

return t1
