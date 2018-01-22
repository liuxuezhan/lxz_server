module( "cross_mng_c", package.seeall )

season = season or 0    -- 活动期数

act_state = act_state or 0   -- 活动状态 见 define

gs_pool = gs_pool or {}    -- game server 信息表

--u_pool = u_pool or {}      -- 军团基本信息发奖时用

power_pool = power_pool or {} -- 战斗力匹配池

group_pool = group_pool or {}  -- 分组

timer_id = timer_id or 0  --活动定时器
prop_id = prop_id or 0

debug_tag = debug_tag or 1

function init()
    load_data()
    load_next_war()
end

function load_data()
    local db = dbmng:getOne()
    local info = db.gs_t:find({})
    while info:hasNext() do
        local gs = gs_t.wrap(info:next())
        gs_pool[gs._id] = gs
        local power = {}
        power.power = gs.power
        power._id = gs._id
        power_pool[gs._id] = power 
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
    prop_id = info1.prop_id or 0
end

function load_next_war()
    if act_state == CROSS_STATE.PREPARE or act_state == CROSS_STATE.FIGHT then
        return
    end

    timer.del(timer_id)
    timer_id = 0
    gPendingSave.status["cross_act"].timer_id = timer_id

    local prop
    local last_start_time = math.huge
    for _, v in pairs(resmng.prop_cross_group) do
        local start_time = tab_to_timestamp(v.Tm)
        if start_time > gTime and start_time <= last_start_time then
            prop = v
            last_start_time = start_time
        end
    end

    if not prop then
        return
    end

    act_state = CROSS_STATE.PEACE
    gPendingSave.status["cross_act"].act_state = act_state
    timer_id = timer.new("cross_act", last_start_time - gTime, CROSS_STATE.PREPARE)
    gPendingSave.status["cross_act"].timer_id = timer_id
    prop_id = prop.ID
    gPendingSave.status["cross_act"].prop_id = prop_id
    WARN("[CrossWar] the war %d will start at %s", prop_id, timestamp_to_str(last_start_time))
end

function upload_gs_info(gs_info)
    gs_info._id = gs_info.pid
    local gs = gs_pool[gs_info.pid] 
    if gs then
        gs.power = gs_info.power
        gs.name = tostring(gs_info.pid)
        gs.king_name = gs_info.king_name
        gs.king_culture = gs_info.king_culture
        gs.king_u_name = gs_info.king_u_name
        gs.king_language = gs_info.king_language
    else
        gs = {}
        gs._id = gs_info.pid
        gs.name = tostring(gs_info.pid)
        gs.pid = gs_info.pid
        gs.power = gs_info.power
        gs.king_name = gs_info.king_name
        gs.king_culture = gs_info.king_culture
        gs.king_u_name = gs_info.king_u_name
        gs.king_language = gs_info.king_language
        gs = gs_t.new(gs)
        for id, prop in pairs(resmng.prop_cross_royalty) do
            gs.left_npc[id] = prop.Num
        end
    end
    gs_pool[gs._id] = gs

    local info = {}
    info.power = gs.power
    info._id = gs._id
    power_pool[gs._id] = info
end

function get_gs_info(gs_id)
    return gs_pool[gs_id]
    --[[
    local gs = gs_pool[gs_id]
    if not gs then
        gs = {}
        gs._id = gs_id
        gs.name = string.format("Map_%d", gs_id)
        gs.pid = gs_id
        gs.power = 0
        gs.king_name = ""
        gs.king_culture = CULTURE_TYPE.EAST
        gs.king_u_name = ""
        gs.king_language = 10000
        gs = gs_t.new(gs)
        for id, prop in pairs(resmng.prop_cross_royalty) do
            gs.left_npc[id] = prop.Num
        end
        gs_pool[gs_id] = gs

        power_pool[gs_id] = {
            _id = gs_id,
            power = gs.power,
        }
    end
    return gs
    --]]
end

function cross_act_prepare()
    local prop = resmng.prop_cross_group[prop_id]
    if not prop then
        load_next_war()
        return
    end
    season = season + 1
    gPendingSave.status["cross_act"].season = season
    group_pool = {}
    gPendingSave.status["cross_act"].group_pool = group_pool
    act_state = CROSS_STATE.PREPARE
    gPendingSave.status["cross_act"].act_state = act_state

    cross_rank_c.reset_all_ranks()
    make_group_with_config(prop)
    --make_group()
    notify_group_info()

    make_act_ntf()
    reset_royalty_data()

    local time = 24 * 3600
    timer.del(timer_id)
    timer_id = timer.new("cross_act", time, CROSS_STATE.FIGHT)
    gPendingSave.status["cross_act"].timer_id = timerid

    cross_act_st_cast()
end

function make_group_with_config(prop)
    for k, v in pairs(gs_pool) do
        v.last_group = v.group
        v.group = 0
    end

    for index, group in pairs(prop.Group) do
        local pool = {}
        local count = 0
        for _, gs_id in pairs(group) do
            local gs = get_gs_info(gs_id)
            if gs then
                count = count + 1
                gs.group = index
                pool[gs_id] = gs_id
            else
                WARN("[CrossWar] server %d in group %d is not found", gs_id, index)
            end
        end
        if count >= 2 then
            group_pool[index] = pool
        else
            WARN("[CrossWar] Group %d doesn't activate because ther is only %d valid server", index, count)
        end
    end
    gPendingSave.status["cross_act"].group_pool = group_pool
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
        num = 2
    end

    for k, v in pairs(gs_pool) do
        v.last_group = v.group
        v.group = 0
    end

    local server_count = #pool
    local group_count = math.floor((server_count + server_count - 2) / num)
    for index = 1, group_count do
        local group = {}
        local last_group_flag = {}
        local i = 0
        while i < num do
            local gs = nil
            for k, v in ipairs(pool) do
                if not last_group_flag[gs_pool[v._id].last_group] then
                    gs = gs_pool[v._id]
                    table.remove(pool, k)
                    break
                end
            end
            if not gs then
                if #pool > 0 then
                    gs = gs_pool[pool[1]._id]
                    table.remove(pool, 1)
                    WARN("[CrossWar] server %d and %d was in a same group %d in the last war", gs._id, last_group_flag[gs.last_group], gs.last_group)
                else
                    WARN("[CrossWar|MakeGroup] Out of servers")
                    break
                end
            end
            -- 加入战斗组
            if 0 ~= gs.last_group then
                last_group_flag[gs.last_group] = gs._id
            end
            i = i + 1
            group[gs._id] = gs._id
            gs.group = index
        end
        if i == num then
            group_pool[index] = group
            gPendingSave.status["cross_act"].group_pool[index] = group
        else
            WARN("[CrossWar] No enough server in group %d", i)
            for k, v in pairs(group) do
                local gs = gs_pool[v]
                gs.group = 0
            end
        end
    end
end

function notify_group_info()
    for index, group in pairs(group_pool) do
        local servers = {}
        for gid, _ in pairs(group) do
            local server = gs_pool[gid]
            local info = {}
            info._id = gid
            info.name = server.name
            info.king_name = server.king_name
            info.king_culture = server.king_culture
            info.king_u_name = server.king_u_name
            info.king_language = server.king_language
            servers[gid] = info
        end
        local pack = {}
        pack.servers = servers
        send_to_group("cross_group_info", index, pack)
    end
end

function make_act_ntf()
    local time = resmng.prop_cross_act_stage[act_state].Spantime
    for k, v in pairs(resmng.prop_cross_act_notify or {}) do
        if v.BeforeTime then
            local ahead = time - v.BeforeTime

            if debug_tag == -1 then
                ahead = 2
            end

            if ahead >= 0 then
                local time_str = format_time(v.BeforeTime)
                local timerId1 = timer.new("cross_act_notify", ahead, k, time_str)
            end
        end
    end
end

function cross_act_notify(ntf_id, time_str)
    send_to_all_group("cross_act_ntf", ntf_id, {time_str}, {})
end

function reset_royalty_data()
    for k, group in pairs(group_pool) do
        for _, gs_id in pairs(group) do
            local gs = gs_pool[gs_id]
            if gs then
                gs.left_npc = {}
                gs.occu_npc = {}
                for id, prop in pairs(resmng.prop_cross_royalty) do
                    gs.left_npc[id] = prop.Num
                    gs.occu_npc[id] = 0
                end
            end
        end
    end
end

function get_end_time()
    if act_state ~= CROSS_STATE.FIGHT then
        return 0
    end
    local t = timer.get(timer_id)
    if not t then
        return 0
    end
    return t.over
end

function cross_act_fight()
    act_state = CROSS_STATE.FIGHT  -- set state
    gPendingSave.status["cross_act"].act_state = act_state

    for k, v in pairs(group_pool) do
        cross_rank_c.create_ranks(k)
    end

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
    act.season = season
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
    act.season = season
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

function send_all_gs(fname, ...)
    for k, gs in pairs(gs_pool) do
        Rpc:callAgent(gs.pid, fname, ...)
    end
end

function send_to_all_group(fname, ...)
    for _, group in pairs(group_pool) do
        for _, gs_id in pairs(group) do
            Rpc:callAgent(gs_id, fname, ...)
        end
    end
end

function send_to_group(fname, index, ...)
    local group = group_pool[index]
    if nil == group then
        return
    end
    for gid, _ in pairs(group) do
        Rpc:callAgent(gid, fname, ...)
    end
end

function npc_change(gs_id, royalty_id, map_id, tag)
    local gs = gs_pool[gs_id]
    if gs then
        local gs1 = gs_pool[map_id]
        if gs1 then
            local left_npc = gs.left_npc
            if left_npc[royalty_id] then
                left_npc[royalty_id] = left_npc[royalty_id] - tag
            end
            gs.left_npc = left_npc

            local occu_npc = gs1.occu_npc
            if occu_npc[royalty_id] then
                occu_npc[royalty_id] = occu_npc[royalty_id] + tag
            end
            gs1.occu_npc = occu_npc
        end
    end
end

function calc_royalty_score(gs_id)
    local gs = gs_pool[gs_id]
    if not gs then
        return
    end
    local score = 0
    for rank, count in pairs(gs.left_npc) do
        local prop = resmng.prop_cross_royalty[rank]
        if prop then
            score = score + prop.Point_2 * count
        end
    end
    for rank, count in pairs(gs.occu_npc) do
        local prop = resmng.prop_cross_royalty[rank]
        if prop then
            score = score + prop.Point_1 * count
        end
    end
    return score
end

function process_royalty_group_reward(group)
    local gs_scores = {}
    for gid, _ in pairs(group) do
        table.insert(gs_scores, {gs_id = gid, score = calc_royalty_score(gid)})
    end
    table.sort(gs_scores, function(a, b) return a.score > b.score end)
    if #gs_scores >= 2 then
       if gs_scores[1].score > gs_scores[2].score then
           INFO("[CrossWar] server %d is the royalty winner", gs_scores[1].gs_id)
           process_winner_royalty(gs_scores[1].gs_id)
       else
           INFO("[CrossWar] Two equal score in server %d(%d) and %d(%d)", gs_scores[1].gs_id, gs_scores[1].score, gs_scores[2].gs_id, gs_scores[2].score)
       end
   else
        WARN("[CrossWar] no enough server, only %d server", #gs_scores)
    end
end

function process_winner_royalty(gs_id)
    local gs = gs_pool[gs_id]
    if not gs then
        return
    end
    local items = {}
    for royalty_id, count in pairs(gs.occu_npc) do
        local prop = resmng.prop_cross_royalty[royalty_id]
        if prop then
            local num = count > prop.BuffLimit and prop.BuffLimit or count
            if num > 0 then
                table.insert(items, {prop.BuffItem, num})
            end
        end
    end
    Rpc:callAgent(gs_id, "cross_royalty_reward", items)
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
    timer.del(timer_id)
    timer_id = 0
    gPendingSave.status["cross_act"].timer_id = timer_id

    cross_refugee_c.cross_refugee_end()
    cross_act_st_cast()

    for k, v in pairs(group_pool) do
        local count = tabNum(v)
        process_royalty_group_reward(v)
        cross_rank_c.send_rank_award(k, count)
    end

    load_next_war()
end

