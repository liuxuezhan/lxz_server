
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
    chat( a1, "@resetcity=2" )
    chat( a1, "@set_val=gold=100000000" )
    print("create ply a1 ", a1.pid)
    chat( a1, "@lvbuild=0=0=10" )
    chat( a1, "@set_val=gold=100000000" )
    Rpc:union_quit( a1 ) 
    sync(a1)

    Rpc:get_city_for_robot_req(a1, ACT_NAME.NPC_CITY,  {lv = city_lv})
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
    WARN("a1 declare fail")

    return "ok"
end

return t1
