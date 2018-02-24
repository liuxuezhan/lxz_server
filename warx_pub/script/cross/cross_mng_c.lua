module( "cross_mng_c", package.seeall )

season = season or 0    -- 活动期数

act_state = act_state or 0   -- 活动状态 见 define

gs_pool = gs_pool or {}    -- game server 信息表

group_pool = group_pool or {}  -- 分组

timer_id = timer_id or 0  --活动定时器
prop_id = prop_id or 0
end_time = end_time or 0

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
    end

    local info1 = db.status:findOne({_id = "cross_act"})
    if not info1 then
        info1 = {_id = "cross_act"}
        db.status:insert(info1)
    end
    group_pool = info1.group_pool or {}
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
    end_time = last_start_time
    gPendingSave.status["cross_act"].end_time = end_time
    prop_id = prop.ID
    gPendingSave.status["cross_act"].prop_id = prop_id
    WARN("[CrossWar] the war %d will start at %s", prop_id, timestamp_to_str(last_start_time))
end

function init_game_data()
    cross_act_st_cast()
    if act_state == CROSS_STATE.PREPARE or act_state == CROSS_STATE.FIGHT then
        notify_group_info()
        for k, group in pairs(group_pool) do
            for _, gs_id in pairs(group) do
                Rpc:callAgent(gs_id, "cross_ask_game_info")
            end
        end
    end
end

function upload_gs_info(gs_info)
    local gs = get_gs_info(gs_info.pid)
    gs.power = gs_info.power
    gs.king_name = gs_info.king_name
    gs.king_culture = gs_info.king_culture
    gs.king_u_name = gs_info.king_u_name
    gs.king_language = gs_info.king_language

    return gs
end

function get_gs_info(gs_id)
    local gs = gs_pool[gs_id]
    if not gs then
        gs = {}
        gs._id = gs_id
        gs.name = string.format("%d", gs_id)
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
    end
    return gs
end

function update_royal_city_info(gs_id, city_info)
    if act_state ~= CROSS_STATE.PREPARE and act_state ~= CROSS_STATE.FIGHT then
        return
    end
    local gs = get_gs_info(gs_id)
    local cities = gs.royal_cities or {}
    for k, v in pairs(city_info) do
        cities[v.propid] = v
    end
    gs.royal_cities = cities
end

function clear_royal_city_info()
    for k, v in pairs(gs_pool or {}) do
        v.royal_cities = {}
    end
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
    notify_group_info()

    make_act_ntf()
    reset_royalty_data()

    local time = 24 * 3600
    timer.del(timer_id)
    timer_id = timer.new("cross_act", time, CROSS_STATE.FIGHT)
    gPendingSave.status["cross_act"].timer_id = timerid
    end_time = gTime + time
    gPendingSave.status["cross_act"].end_time = end_time

    cross_act_st_cast()
end

function make_group_with_config(prop)
    for k, v in pairs(gs_pool) do
        v.group = 0
    end

    for index, group in pairs(prop.Group) do
        local pool = {}
        local count = 0
        for _, gs_id in pairs(group) do
            local gs = get_gs_info(gs_id)
            count = count + 1
            gs.group = index
            pool[gs_id] = gs_id
        end
        if count >= 2 then
            group_pool[index] = pool
        else
            WARN("[CrossWar] Group %d doesn't activate because ther is only %d valid server", index, count)
        end
    end
    gPendingSave.status["cross_act"].group_pool = group_pool
end

function notify_group_info()
    for index, group in pairs(group_pool) do
        local pack = {
            servers = _pack_group_info(group),
        }
        send_to_group("cross_group_info", index, pack)
    end
end

function _pack_group_info(group)
    local servers = {}
    for gid, _ in pairs(group or {}) do
        local server = get_gs_info(gid)
        servers[gid] = {
            _id = gid,
            name = server.name,
            king_name = server.king_name,
            king_culture = server.king_culture,
            king_u_name = server.king_u_name,
            king_language = server.king_language,
        }
    end
    return servers
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
            local gs = get_gs_info(gs_id)
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
    if act_state ~= CROSS_STATE.FIGHT then
        act_state = CROSS_STATE.FIGHT  -- set state
        gPendingSave.status["cross_act"].act_state = act_state

        for k, v in pairs(group_pool) do
            cross_rank_c.create_ranks(k)
        end

        local time = SECONDS_ONE_DAY   -- set timer
        timer.del(timer_id)
        timer_id = timer.new("cross_act", time, CROSS_STATE.FIGHT)
        gPendingSave.status["cross_act"].timer_id = timer_id
        end_time = gTime + SECONDS_ONE_DAY * 2
        gPendingSave.status["cross_act"].end_time = end_time

        cross_act_st_cast()    --cast status
    else
        cross_refugee_c.cross_refugee_start()

        local time = SECONDS_ONE_DAY   -- set timer
        timer.del(timer_id)
        timer_id = timer.new("cross_act", time, CROSS_STATE.PEACE)
        gPendingSave.status["cross_act"].timer_id = timer_id
        end_time = gTime + SECONDS_ONE_DAY
        gPendingSave.status["cross_act"].end_time = end_time
    end
end

function cross_act_st_cast()
    local pack = {}
    local act = {}
    act.state = act_state
    act.season = season
    act.tm_over = end_time
    pack[ACT_NAME.CROSS_NPC] = act

    act = {}
    act.state = cross_refugee_c.act_state
    pack[ACT_NAME.REFUGEE] = act
    send_to_all_group("cross_act_st_cast", pack)
end

function cross_act_st_req(gs_id)
    local pack = {}
    local gs = get_gs_info(gs_id)
    if not gs then
        return
    elseif 0 == gs.group then
        pack[ACT_NAME.CROSS_NPC] = {
            state = CROSS_STATE.PEACE
        }
        pack[ACT_NAME.REFUGEE] = {
            state = CROSS_STATE.PEACE
        }
        Rpc:callAgent(gs_id, "cross_act_st_cast", pack)
    else
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

        if act_state == CROSS_STATE.PREPARE or act_state == CROSS_STATE.FIGHT then
            local group = group_pool[gs.group]
            if group then
                Rpc:callAgent(gs_id, "cross_group_info", {
                    servers = _pack_group_info(group),
                })
            end
        end
    end
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
    local gs = get_gs_info(gs_id)
    if gs then
        local gs1 = get_gs_info(map_id)
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
    local gs = get_gs_info(gs_id)
    if not gs then
        return
    end
    local score = 0
    local left_count = 0
    for rank, count in pairs(gs.left_npc) do
        local prop = resmng.prop_cross_royalty[rank]
        if prop then
            score = score + prop.Point_2 * count
        end
        left_count = left_count + count
    end
    local occu_count = 0
    for rank, count in pairs(gs.occu_npc) do
        local prop = resmng.prop_cross_royalty[rank]
        if prop then
            score = score + prop.Point_1 * count
        end
        occu_count = occu_count + count
    end
    return score, left_count, occu_count
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
    local gs = get_gs_info(gs_id)
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

    clear_royal_city_info()
    load_next_war()
end

function pack_royalty_servers(group_index)
    local servers = {}
    for _, gs_id in pairs(group_pool[group_index] or {}) do
        local score, left_count, occu_count = calc_royalty_score(gs_id)
        if nil ~= score then
            table.insert(servers, {
                gid = gs_id,
                occu_count = occu_count,
                left_count = left_count,
                score = score,
            })
        end
    end
    return servers
end

