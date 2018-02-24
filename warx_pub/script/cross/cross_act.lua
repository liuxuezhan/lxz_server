module( "cross_act", package.seeall ) 

act_state = act_state or CROSS_STATE.LOCK
act_season = act_season or 0

refugee_state = refugee_state  or 0

group_info = group_info or {}

tm_over = tm_over or 0

function rec_cross_act_st(act_st)
    local last_st = act_state
    for k, st in pairs(act_st or {}) do
        if k == ACT_NAME.CROSS_NPC then
            act_state = st.state or 0
            act_season = st.season or 0
            tm_over = st.tm_over or 0
        elseif k == ACT_NAME.REFUGEE then
            refugee.act_state = st.state or 0
            refugee_state = st.state or 0
        end
    end
    WARN("[CrossWar] The war enter state %d", act_state)
    if last_st == CROSS_STATE.LOCK then
        if act_state == CROSS_STATE.FIGHT or act_state == CROSS_STATE.PREPARE then
            WARN("[CrossWar] upload royal city info during the server's boot time")
            upload_royal_city_info()
        end
        return
    end

    if act_state == CROSS_STATE.PREPARE then
        --for k, player in pairs(gPlys) do
        --    player:check_cross_data()
        --end
    end

    if last_st == CROSS_STATE.FIGHT and act_state == CROSS_STATE.PEACE then
        drop_back_all_ply()
        drop_all_union2()
        king_city.clear_foreign_data()
    end

    if act_state == CROSS_STATE.PEACE then
        group_info = {}
        npc_city.clear_royal_data()
        king_city.clear_royal_data()
    end

    if act_state == CROSS_STATE.PEACE or act_state == CROSS_STATE.FIGHT then
        Rpc:cross_act_st_ack({pid = -1, gid = _G.GateSid}, get_cross_act_st())
    end

    if act_state == CROSS_STATE.FIGHT and last_st ~= CROSS_STATE.FIGHT then
        npc_city.update_royal_data()
        king_city.update_royal_data()
        upload_royal_city_info()
    end
end

function rec_group_info(servers)
    group_info = servers
end

function load_data()
end

function init_game_data()
    crontab.upload_gs_info()
    Rpc:callAgent(gCenterID, "cross_act_st_req")
end

function get_cross_act_st()
    local pack = {}
    local act = {}
    act.state = act_state
    act.tm_over = tm_over
    act.season = act_season
    pack[ACT_NAME.CROSS_NPC] = act

    act = {}
    act.state = refugee.act_state
    pack[ACT_NAME.REFUGEE] = act

    return pack
end

function upload_royal_city_info()
    local cities = {}
    -- king city
    local king = king_city.get_king()
    if king and king.royal ~= ROYAL_STATE.NO_ROYAL then
        table.insert(cities, npc_city.pack_royal_city_info(king, king.uid))
    end
    -- npc city
    for k, v in pairs(npc_city.citys) do
        local city = get_ety(v)
        if city and city.royal ~= ROYAL_STATE.NO_ROYAL then
            table.insert(cities, city:pack_royal_city_info(city.uid))
        end
    end
    if #cities > 0 then
        Rpc:callAgent(gCenterID, "cross_royal_city_info", cities)
    end
end

function cross_act_st_req(ply)
    if ply then
        Rpc:cross_act_st_ack(ply, get_cross_act_st())
    end
end

function cross_act_group_req(ply)
    if ply then
        Rpc:cross_act_group_ack(ply, group_info)
    end
end

function is_fighting()
    return act_state == CROSS_STATE.FIGHT
end

function get_season()
    return act_season
end

function is_in_group(map_id)
    for k, v in pairs(group_info) do
        if v._id == map_id then
            return true
        end
    end
    return false
end

function drop_back_all_ply()
    for _, ply in pairs(gPlys or {}) do
        ply:clear_cross_data()
        if check_ply_cross(ply) then
            ply:cross_migrate_back(-1, -1)
        end
    end
end

function drop_all_union2()
    for k, union in pairs(unionmng.get_all(1)) do
        if union.map_id then
            unionmng.rm_union2(union)
        end
    end
end

