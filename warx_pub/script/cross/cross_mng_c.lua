module( "cross_mng_c", package.seeall )

season = season or 0    -- 活动期数

act_state = act_state or 0   -- 活动状态 见 define

gs_pool = gs_pool or {}    -- game server 信息表

--u_pool = u_pool or {}      -- 军团基本信息发奖时用

power_pool = power_pool or {} -- 战斗力匹配池

group_pool = group_pool or {}  -- 分组

timer_id = timer_id or 0  --活动定时器

debug_tag = debug_tag or 1

function load_data()
    local db = dbmng:getOne()
    local info = db.gs_t:find({})
    while info:hasNext() do
        local gs = gs_t.wrap(info:next())
        gs_pool[gs._id] = gs
        local power = {}
        power.power = gs.power
        power._id = gs._id
        power_pool[gs._id] = info 
    end

    local info1 = db.status:findOne({_id = "cross_act"})
    if not info1 then
        info1 = {_id = "cross_act"}
        db.status:insert(info1)
    end
    group_pool = info1.group_pool
    season = info1.season or 0
    act_state = info1.act_state  or 0
    timer_id = info1.timer_id  or 0

    --local u_info = db.union_t:find({})
    --while u_info:hasNext() do
    --    local u = u_info:next()
    --    if u then
    --        u_pool[u._id] = u
    --    end
    --end
end

function upload_gs_info(gs_info)
    gs_info._id = gs_info.pid
    local gs = gs_pool[gs_info.pid] 
    if gs then
        gs.power = gs_info.power
        gs.name = tostring(gs_info.pid)
        gs.king_name = gs_info.king_name
        gs.king_u_name = gs_info.king_u_name
    else
        gs = {}
        gs._id = gs_info.pid
        gs.name = tostring(gs_info.pid)
        gs.pid = gs_info.pid
        gs.power = gs_info.power
        gs.king_name = gs_info.king_name
        gs.king_u_name = gs_info.king_u_name
        gs = gs_t.new(gs)
    end
    gs_pool[gs._id] = gs

    local info = {}
    info.power = gs.power
    info._id = gs._id
    power_pool[gs._id] = info
end

--function upload_union_info(union)
--    u_pool[union._id] = union
--    gPendingSave.status["union_t"][union._id] = union
--end
    
function cross_act_prepare()
    season = season + 1
    gPendingSave.status["cross_act"].season = season
    group_pool = {}
    gPendingSave.status["cross_act"].group_pool = group_pool
    act_state = CROSS_STATE.PREPARE
    gPendingSave.status["cross_act"].act_state = act_state

    make_group()

    make_act_ntf()

    local time = 24 * 3600
    timer.del(timer_id)
    timer_id = timer.new("cross_act", time, CROSS_STATE.FIGHT)
    gPendingSave.status["cross_act"].timer_id = timerid

end

function make_group()
    local pool = {}
    for k, v in pairs(power_pool) do
        table.insert(pool, v)
    end

    local fun = function(a, b) 
        if a.power ~= b.power then
            return a.power > b.power
        else
            return a._id > b._id
        end
    end

    table.sort(pool, fun)

    local num = 2
    if season % 4 == 0 then
        num = 5
    end

    local index = 1
    local count = 0
    local pool_num = #pool
    for i = 1, pool_num, 1 do
        local group = {}
        for j = #pool , 1, -1 do
            local gs_info = pool[j]
            if gs_info then
                local gs = gs_pool[gs_info._id or 0]
                if gs then
                    if not is_already_fight(gs, group) or #pool <= (num - count) then
                        group[gs._id] = gs._id
                        gs.group = index
                        table.remove(pool, j)
                        count = count + 1
                    end
                    if count == num then
                        local gr = copyTab(group)
                        group_pool[index] = gr
                        gPendingSave.status["cross_act"].group_pool[index] = gr
                        index = index + 1
                        count = 0
                        break
                    end
                end
            end
        end
        if #pool == 0 then
            break
        end
    end
end

function is_already_fight(gs, group)
    local ret = false
    for k, v in pairs(group or {}) do
        if gs.last_group == v and gs.last_group ~= 0 then
            return true
        end
    end
    return ret
end

function make_act_ntf()
    for k, v in pairs(resmng.prop_cross_act_notify or {}) do
        local time = resmng.prop_cross_act_stage[act_state].Spantime * 60

        if v.BeforeTime then
            local ahead = time - v.BeforeTime

            if debug_tag == -1 then -- debug 
                ahead = 2
            end

            if ahead > 0 then
                local time_str = format_time(v.BeforeTime)
                local timerId1 = timer.new("cross_act_notify", ahead, k, time_str)
            --    local timerId2 = timer.new("make_group_ntf", ahead, k, time_str)
            end
        end
    end
end

function make_group_ntf(ntf_id)
    for k, group in pairs(group_pool) do
        local gs_names = {}

        for _, gs_id in pairs(group) do
            local gs = gs_pool[gs_id]
            if gs then
                table.insert(gs_names, gs.name)
            end
        end
        
        send_act_ntf(ntf_id, gs_names, {}, group)

    end
end

function cross_act_notify(ntf_id, time_str)
    send_all_gs("cross_act_ntf", ntf_id, {time_str}, {})
end

function cross_act_fight()
    --cross_rank_c.clear_rank()   -- clear rank first

    act_state = CROSS_STATE.FIGHT  -- set state
    gPendingSave.status["cross_act"].act_state = act_state

    local time = 2 * 24 * 3600   -- set timer
    timer.del(timer_id)
    timer_id = timer.new("cross_act", time, CROSS_STATE.PEACE)
    gPendingSave.status["cross_act"].timer_id = timer_id

    cross_act_st_cast()    --cast status

end

function cross_act_st_cast()
    local pack = {}
    local act = {}
    act.state = act_state
    local time = timer.get(timer_id)
    if time then
        act.tm_over = time.over
    end
    pack[ACT_NAME.CROSS_NPC] = act

    act = {}
    act.state = cross_refugee_c.act_state
    pack[ACT_NAME.REFUGEE] = act
    send_all_gs("cross_act_st_cast", pack)
end

function cross_act_st_req(gs_id)
    local pack = {}
    local act = {}
    act.state = act_state
    local time = timer.get(timer_id)
    if time then
        act.tm_over = time.over
    end
    pack[ACT_NAME.CROSS_NPC] = act

    act = {}
    act.state = cross_refugee_c.act_state
    pack[ACT_NAME.REFUGEE] = act

    Rpc:callAgent(gs_id, "cross_act_st_cast", pack)
    
end

function send_act_ntf(ntf_id, param1, param2, pids)
    if pids then
        for k, v in pairs(pids) do
            send_each_ntf(v, ntf_id, param1, param2)
        end
    else
        send_all_gs("cross_act_ntf", ntf_id, param1, param2)
    end
end

function send_each_ntf(map_id, ntf_id, param1, param2)
    Rpc:callAgent(map_id, "cross_act_ntf", ntf_id, param1, param2)
end

function send_all_gs(fname, ...)
    for k, gs in pairs(gs_pool) do
        Rpc:callAgent(gs.pid, fname, ...)
    end
end

function npc_change(gs_id, propid, map_id, tag)
    local prop = resmng.prop_world_unit[propid]
    if not prop then
        return
    end
    local lv = prop.Lv

    local gs = gs_pool[gs_id]
    if gs then
        local gs1 = gs_pool[map_id]
        if gs1 then
            local left_npc = gs.left_npc
            if left_npc[lv] then
                left_npc[lv] = left_npc[lv] - tag
            end
            gs.left_npc = left_npc

            local occu_npc = gs1.occu_npc
            if occu_npc[lv] then
                occu_npc[lv] = occu_npc[lv] + tag
            end
        end
    end
end

function cross_npc_info(gs_id, pid)
    local gs = gs_pool[gs_id]
    if not gs then
        return
    end

    local group = group_pool[gs.group]
    if not group then
        return
    end

   -- local pack = {}
   -- pack.my_gs = gs.occu_npc
   -- local npc_info = {}
   -- for k, v in pairs(group) do
   --     local server = gs_pool[v]
   --     if server then
   --         npc_info[v] = server.left_npc
   --     end
   -- end
   -- pack.npc_info = npc_info

   -- Rpc:cross_npc_info_ack({pid = pid}, pack)

    local pack = {}
    local info = {}
    info.occu_npc = gs.occu_npc
    local left_npc = {}
    for k, v in pairs(group) do
        local server = gs_pool[v]
        if server then
            left_npc[v] = server.left_npc
        end
    end
    pack.pid = pid
    pack.info = info

    Rpc:callAgent(gs_id, "cross_npc_info_ack", pack)
end

function cross_act_end()
    act_state = CROSS_STATE.PEACE
    gPendingSave.status["cross_act"].act_state = act_state
    cross_refugee_c.cross_refugee_end()
    cross_act_st_cast()
    cross_rank_c.send_rank_award()
end

