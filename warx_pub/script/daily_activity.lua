module("daily_activity", package.seeall)

g_daily_activity_data = g_daily_activity_data or {
	current_index = 0,	--当前活动id
	start_time = 0,	--开始时间
    end_time = 0,   --结束时间
	activity_num = 0, --开启了几次活动
	is_started = 0, --活动是否已经开始
}

g_bihourly_activity_data = g_bihourly_activity_data or {
	current_index = 0,	--当前活动id
	start_time = 0,	--开始时间
    end_time = 0,   --结束时间
	activity_num = 0, --开启了几次活动
	is_started = 0, --活动是否已经开始
}

g_activity_info = {
    [PERIODIC_ACTIVITY.DAILY] = {
        field_name = "daily_activity_info",
        score_mail = 10101,
    },
    [PERIODIC_ACTIVITY.BIHOURLY] = {
        field_name = "bihourly_activity_info",
        score_mail = 10103,
    },
}

function init_daily_activity()
    Rpc:callAgent(gCenterID, "periodic_activity_get_activity_data")
end

function reinit_daily_activity()
end

function update_data(mode, group_id, sn, start_time, end_time)
    if PERIODIC_ACTIVITY.DAILY == mode then
        if g_daily_activity_data.activity_num ~= sn then
            -- 新的activity
        end
        g_daily_activity_data.current_index = group_id
        g_daily_activity_data.start_time = start_time
        g_daily_activity_data.end_time = end_time
        g_daily_activity_data.activity_num = sn
        WARN("[PeriodicActivity] Update daily activity data: %d|%d|%d|%d", group_id, sn, start_time, end_time)
    elseif PERIODIC_ACTIVITY.BIHOURLY == mode then
        local last_sn = g_bihourly_activity_data.activity_num

        g_bihourly_activity_data.current_index = group_id
        g_bihourly_activity_data.start_time = start_time
        g_bihourly_activity_data.end_time = end_time
        g_bihourly_activity_data.activity_num = sn
        WARN("[PeriodicActivity] Update bihourly activity data: %d|%d|%d|%d", group_id, sn, start_time, end_time)

        if last_sn ~= sn then
            -- 新的activity
        end
    end
end

function check_player_data(player, mode, activity_data)
    if not activity_data then
        if mode == PERIODIC_ACTIVITY.DAILY then
            activity_data = g_daily_activity_data
        elseif mode == PERIODIC_ACTIVITY.BIHOURLY then
            activity_data = g_bihourly_activity_data
        else
            return
        end
    end
    local field_name = g_activity_info[mode].field_name
    local castle_lv = player:get_castle_lv()
    if 0 == activity_data.activity_num then
        -- 活动数据未同步时，不对玩家数据操作，否则可能导致错误清掉玩家积分信息
        return
    end
	if player[field_name].activity_num ~= activity_data.activity_num then
        player[field_name] = {
            activity_num = activity_data.activity_num,
            rank_lv = find_ply_rank(castle_lv, mode),
            award_tag = 0,
            score = {},
        }
	end
end

function get_player_data(player, mode)
    check_player_data(player, mode)
    local field_name = g_activity_info[mode].field_name
    return player[field_name]
end

function add_player_score(player, mode, activity_id, score)
    check_player_data(player, mode)
    local field_name = g_activity_info[mode].field_name

    local score_info = player[field_name].score
    score_info[activity_id] = (score_info[activity_id] or 0) + math.floor(score)

    player[field_name] = player[field_name]
    return player[field_name]
end

-- 采集				process_daily_activity(DAILY_ACTIVITY_ACTION.GATHER, 1, 1)
-- 训练士兵			process_daily_activity(DAILY_ACTIVITY_ACTION.TRAIN_ARM, 1, 1)
-- 提升战斗力		process_daily_activity(DAILY_ACTIVITY_ACTION.POWER_UP, 1, 1)
-- 攻击怪物			process_daily_activity(DAILY_ACTIVITY_ACTION.ATK_MONSTER, 1, 1)
-- 抽卡				process_daily_activity(DAILY_ACTIVITY_ACTION.GACHA, 1, 1)
-- 物资市场			process_daily_activity(DAILY_ACTIVITY_ACTION.RES_MARKET, 1, 1)
-- 黑市				process_daily_activity(DAILY_ACTIVITY_ACTION.BLACK_MARKET, 1, 1)
-- 攻击玩家击杀士兵	process_daily_activity(DAILY_ACTIVITY_ACTION.KILL_ARM, 1, 1)

function is_in_group(activity_id, group)
    for _, v in pairs(group or {}) do
        if v == activity_id then
            return true
        end
    end
    return false
end

function find_ply_rank(lv, mode)
    mode = mode or PERIODIC_ACTIVITY.DAILY
    local rank = 1
    for id, v in pairs(PERIODIC_ACTIVITY_CFG[mode].RANK or {}) do
        if lv >= v.CastleMinLv then
            rank = id
        else
            return rank
        end
    end
    return rank
end

function process_daily_activity(player, activity_id, class, num)
	if num == 0 then
		return
	end
    _process_activity(player, PERIODIC_ACTIVITY.DAILY, g_daily_activity_data, activity_id, class, num)
    _process_activity(player, PERIODIC_ACTIVITY.BIHOURLY, g_bihourly_activity_data, activity_id, class, num)
end

function _process_activity(player, mode, activity_data, activity_id, class, num)
    if gTime < activity_data.start_time or gTime > activity_data.end_time then
        return
    end

    local prop_group = resmng.get_conf(PERIODIC_ACTIVITY_CFG[mode].PROP_GROUP, activity_data.current_index)
    if not prop_group then
        return
    end

    if is_in_group(activity_id, prop_group.Group) == false then
        return
    end

    local prop_tab1 = resmng.get_conf(PERIODIC_ACTIVITY_CFG[mode].PROP_BASIC, activity_id)
    if prop_tab1 == nil then
        return
    end

    local castle_lv = player:get_castle_lv()
    if castle_lv < prop_tab1.LimitLevel then
        return
    end

    --更新积分
    local score_id = activity_id * 1000 + class
    local prop_score = resmng.get_conf(PERIODIC_ACTIVITY_CFG[mode].PROP_SCORE, score_id)
    if prop_score == nil then
        return
    end

    local player_info = add_player_score(player, mode, activity_id, math.floor(prop_score.Score * num))
    -- 判断阶段奖励
    send_score_award(player, mode, activity_data.current_index, activity_id)
    -- 上传排行榜数据
    upload_score(player, mode, player_info)
end

function upload_score(player, mode, player_info)
    player_info = player_info or get_player_data(player, mode)
    if player_info.award_tag >= 3 then
        local tot_score = get_tot_score(player_info)
        local sn = player:set_periodic_upload_watcher(mode)
        Rpc:callAgent(gCenterID, "periodic_activity_upload_score", mode, sn, player.emap, player.pid, player_info.rank_lv, tot_score, gTime)
    end
end

function get_tot_score(info)
    local score = 0
    for _, v in pairs(info.score or {}) do
        score = score + v
    end
    return score
end

--开服系数
function get_ratio()
	return 1
end

--组织奖励
function pack_award(prop_tab)
	local tab = {}
		ply_info[2] = 3
	for k, v in pairs(prop_tab.Award1 or {}) do
		table.insert(tab, v)
	end
	for k, v in pairs(prop_tab.Award2 or {}) do
		local new_unit = copyTab(v)
		new_unit[3] = math.floor(new_unit[3] * get_ratio())
		table.insert(tab, new_unit)
	end
	return tab
end

--单个活动积分奖励
function send_score_award(ply, mode, group_id, aid)
    local ply_info = get_player_data(ply, mode)
    local rank_lv = ply_info.rank_lv
    local award_id = rank_lv * 1000 + group_id
    local prop_tab = resmng.get_conf(PERIODIC_ACTIVITY_CFG[mode].PROP_AWARD, award_id)
    if prop_tab == nil then
        ERROR("[PeriodicActivity] Not found award %d, mode:%d", award_id, mode)
        return
    end

    local score = get_tot_score(ply_info)
    local field_name = g_activity_info[mode].field_name
    --第一档
    if score >= prop_tab.Cond1 and  ply_info.award_tag < 1 then
        ply_info.award_tag = 1
        ply[field_name] = ply[field_name]
        ply:send_system_notice(g_activity_info[mode].score_mail, {}, {1}, prop_tab.Award1)
        WARN("[PeriodicActivity] Send score award1, pid=%d, mode=%d", ply.pid, mode)
    end
    --第二档
    if score >= prop_tab.Cond2 and  ply_info.award_tag < 2 then
        ply_info.award_tag = 2
        ply[field_name] = ply[field_name]
        ply:send_system_notice(g_activity_info[mode].score_mail, {}, {2}, prop_tab.Award2)
        WARN("[PeriodicActivity] Send score award2, pid=%d, mode=%d", ply.pid, mode)
    end
    --第三档
    if score >= prop_tab.Cond3 and ply_info.award_tag < 3 then
        ply_info.award_tag = 3
        ply[field_name] = ply[field_name]
        ply:send_system_notice(g_activity_info[mode].score_mail, {}, {3}, prop_tab.Award3)
        WARN("[PeriodicActivity] Send score award3, pid=%d, mode=%d", ply.pid, mode)
    end
end

function pack_activity(player, mode)
    if mode == PERIODIC_ACTIVITY.DAILY then
        return _pack_activity(player, mode, g_daily_activity_data)
    elseif mode == PERIODIC_ACTIVITY.BIHOURLY then
        return _pack_activity(player, mode, g_bihourly_activity_data)
    end
end

function _pack_activity(player, mode, activity_data)
    if gTime < activity_data.start_time then
        return
    end

    check_player_data(player, mode)

    local msg = {}
    msg.group_id = activity_data.current_index
    msg.start_time = activity_data.start_time
    msg.end_time = activity_data.end_time
    msg.award_ratio = get_ratio()
    msg.activity_num = activity_data.activity_num
    return msg
end

