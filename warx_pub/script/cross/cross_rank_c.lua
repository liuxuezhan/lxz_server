module("cross_rank_c", package.seeall)

players_info = players_info or {}
unions_info = unions_info or {}
servers_info = servers_info or {}

local wanted_ranks = {
    [CUSTOM_RANK_MODE.PLY] = {
        skeys = {-1},
        ntops = 50,
    },
    [CUSTOM_RANK_MODE.UNION] = {
        skeys = {-1},
        ntops = 10,
    },
    [CUSTOM_RANK_MODE.GS] = {
        skeys = {-1},
        ntops = 6,
    },
}

local function get_rank_base_id(group_index)
    return 1000000 + group_index * 1000
end

local function get_refugee_rank_id(group_index)
    return 2000000 + group_index * 1000
end

function create_ranks(group_index)
    local base_id = get_rank_base_id(group_index)
    for k, v in pairs(wanted_ranks) do
        custom_rank_mng.create_rank(base_id + k, v.skeys, v.ntops, CUSTON_RANK_CLASS.CROSS_RANK, k, "cross_rank_c")
    end
    local refugee_rank_id = get_refugee_rank_id(group_index)
    custom_rank_mng.create_rank(refugee_rank_id, {-1}, 50, CUSTON_RANK_CLASS.CROSS_REFUGEE, CUSTOM_RANK_MODE.PLY "cross_rank_c")
end

function reset_all_ranks()
    custom_rank_mng.reset_rank(CUSTON_RANK_CLASS.CROSS_RANK)
    custom_rank_mng.reset_rank(CUSTON_RANK_CLASS.CROSS_REFUGEE)
    clear_all_info()
end

function update_score(action, gs_id, val, ...)
    local gs = cross_mng_c.get_gs_info(gs_id)
    if not gs or 0 == gs.group then
        return
    end
    local base_id = get_rank_base_id(gs.group)

    local arg = {...}
    if action == RANK_ACTION.NORMAL
        or action == RANK_ACTION.CURE
        or action == RANK_ACTION.NPC_DMG
        or action == RANK_ACTION.KING_DMG then
        add_score(base_id + CUSTOM_RANK_MODE.PLY, arg[1], val)
        if 0 ~= arg[2] then
            add_score(base_id + CUSTOM_RANK_MODE.UNION, arg[2], val)
        end
        add_score(base_id + CUSTOM_RANK_MODE.GS, gs_id, val)
    else
        if 0 ~= arg[1] then
            add_score(base_id + CUSTOM_RANK_MODE.UNION, arg[1], val)
        end
        add_score(base_id + CUSTOM_RANK_MODE.GS, gs_id, val)
    end
end

function add_refugee_score(gs_id, pid, score)
    local gs = cross_mng_c.get_gs_info(gs_id)
    if not gs or 0 == gs.group then
        return
    end
    local rank_id = get_refugee_rank_id(gs.group)
    add_score(rank_id, pid, score)
end

function add_score(rank_id, key, val)
    local old_score = custom_rank_mng.get_score(rank_id, key) or 0
    val = old_score + val
    if val <= 0 then
        custom_rank_mng.rem_data(rank_id, key)
    else
        custom_rank_mng.add_data(rank_id, key, {val}, true)
    end
end

function get_rank_info(gs_id, rank_mode)
    local gs = cross_mng_c.get_gs_info(gs_id)
    if not gs or 0 == gs.group then
        return gTime, {}
    end
    local rank_id = get_rank_base_id(gs.group) + rank_mode
    return custom_rank_mng.get_rank_info(rank_id)
end

function get_rank(gs_id, rank_mode, key)
    local gs = cross_mng_c.get_gs_info(gs_id)
    if not gs or 0 == gs.group then
        return 0
    end
    local rank_id = get_rank_base_id(gs.group) + rank_mode
    return custom_rank_mng.get_rank(rank_id, key)
end

function get_refugee_rank_info(gs_id)
    local gs = cross_mng_c.get_gs_info(gs_id)
    if not gs or 0 == gs.group then
        return gTime, {}
    end
    local rank_id = get_refugee_rank_id(gs.group)
    return custom_rank_mng.get_rank_info(rank_id)
end

function get_refugee_rank(gs_id, pid)
    local gs = cross_mng_c.get_gs_info(gs_id)
    if not gs or 0 == gs.group then
        return 0
    end
    local rank_id = get_refugee_rank_id(gs.group)
    return custom_rank_mng.get_rank(rank_id, pid)
end

local ServerAwardKey =
{
    [2] = "Award_2",
    [3] = "Award_3",
    [4] = "Award_4",
    [5] = "Award_5",
    [6] = "Award_6",
}

function send_rank_award(group_index, server_count)
    local player_rank_id = get_rank_base_id(group_index) + CUSTOM_RANK_MODE.PLY
    for k, v in pairs(resmng.prop_cross_person_rank_award or {}) do
        local plys = custom_rank_mng.get_range(player_rank_id, v.Rank[1], v.Rank[2])
        for idx, pid in pairs(plys or {}) do
            local pos = custom_rank_mng.get_rank(player_rank_id, pid)
            send_ply_award(resmng.MAIL_10100, tonumber(pid), v.Award, {pos})
        end
    end

    local union_rank_id = get_rank_base_id(group_index) + CUSTOM_RANK_MODE.UNION
    for k, v in pairs(resmng.prop_cross_union_rank_award or {}) do
        local unions = custom_rank_mng.get_range(union_rank_id, v.Rank[1], v.Rank[2])
        for idx, uid in pairs(unions or {}) do
            local pos = custom_rank_mng.get_rank(union_rank_id, uid)
            send_uid_award(resmng.MAIL_10099, tonumber(uid), v.Award, {pos})
        end
    end

    local gs_rank_id = get_rank_base_id(group_index) + CUSTOM_RANK_MODE.GS
    local award_key = ServerAwardKey[server_count]
    if award_key then
        for k, v in pairs(resmng.prop_cross_server_rank_award or {}) do
            local gs_ids = custom_rank_mng.get_range(gs_rank_id, v.Rank[1], v.Rank[2])
            for idx, gs_id in pairs(gs_ids or {}) do
                local pos = custom_rank_mng.get_rank(gs_rank_id, gs_id)
                send_gs_award(resmng.MAIL_10098, gs_id, v[award_key], {pos})
            end
        end
    end

    -- refugee award
    local refugee_rank_id = get_refugee_rank_id(group_index)
    for k, v in pairs(resmng.prop_cross_refugee_rank_award or {}) do
        local plys = custom_rank_mng.get_range(refugee_rank_id, v.Rank[1], v.Rank[2])
        for idx, pid in pairs(plys or {}) do
            local pos = custom_rank_mng.get_rank(refugee_rank_id, pid)
            send_ply_award(resmng.MAIL_10100, tonumber(pid), v.Award, {pos})
        end
    end
end

function send_ply_award(reward_mode, pid, award, param)
    local gs_id = get_player_map(pid)
    if gs_id then
        Rpc:callAgent(gs_id, "send_cross_award", CUSTOM_RANK_MODE.PLY, reward_mode, pid, award, param)
    end
end

function send_uid_award(reward_mode, uid, award, param)
    local gs_id = get_union_map(uid)
    if gs_id then
        Rpc:callAgent(gs_id, "send_cross_award", CUSTOM_RANK_MODE.UNION, reward_mode, uid, award, param)
    end
end

function send_gs_award(reward_mode, gs_id, award, param)
    Rpc:callAgent(gs_id, "send_cross_award", CUSTOM_RANK_MODE.GS, reward_mode, gs_id, award, param)
end

local info_getter = {}

function get_info(mode, id)
    local getter = info_getter[mode]
    if not getter then
        return {id}
    end
    return getter(id)
end

function clear_all_info()
    players_info = {}
    unions_info = {}
    servers_info = {}
end

info_getter[CUSTOM_RANK_MODE.PLY] = function(pid)
    local info = players_info[pid]
    if info then
        return info
    end
    -- get info from origin server
    local map_id = get_player_map(pid)
    if not map_id then
        return {pid}
    end
    local ret, info = remote_func(map_id, "get_rank_detail", {"player", pid})
    if not info then
        return {pid}
    end
    players_info[pid] = info
    return info
end

info_getter[CUSTOM_RANK_MODE.UNION] = function(uid)
    local info = unions_info[uid]
    if info then
        return info
    end
    -- get info from origin server
    local map_id = get_union_map(uid)
    if not map_id then
        return {uid}
    end
    local ret, info = remote_func(map_id, "get_rank_detail", {"union", uid})
    if not info then
        return {uid}
    end
    unions_info[uid] = info
    return info
end

info_getter[CUSTOM_RANK_MODE.GS] = function(gs_id)
    local info = servers_info[gs_id]
    if info then
        return info
    end
    -- get info from cross_mng_c
    local gs = cross_mng_c.get_gs_info(gs_id)
    if not gs then
        return {gs_id}
    end
    local info = {gs._id, gs.name, gs.king_name}
    servers_info[gs_id] = info
    return info
end

