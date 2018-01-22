module("daily_activity", package.seeall)

g_daily_activity_data = g_daily_activity_data or {
	current_index = 0,	--当前活动id
	start_time = 0,	--开始时间
    end_time = 0,   --结束时间
	activity_num = 0, --开启了几次活动
	is_started = 0, --活动是否已经开始
}

function gen_group_pool()
    local pool = {}
    for _, v in pairs(resmng.prop_daily_activity_group or {}) do
        pool[v.ID] = v.Weight
    end
    return pool
end

group_pool = group_pool or gen_group_pool()

function load_daily_activity()
	local db = dbmng:getOne()
    local info = db.status:findOne({_id = "daily_activity"})
    if info then
        g_daily_activity_data = info
    end
end

function save_daily_activity()
	gPendingSave.status["daily_activity"] = g_daily_activity_data
end

function get_act_id(rem_id)
    local pool = copyTab(group_pool)
    pool[rem_id] = nil
    local tot = 0
    for _, v in pairs(pool or {}) do
        tot = tot + v
    end
    local num = math.random(tot)
    local num1 = 0
    for k, v in pairs(pool or {}) do
        num1 = num1 + v
        if num1 >=  num then
            return k
        end
    end
    return 1
end

function refresh_data()
	--清空排行榜

	--重置活动数据
	g_daily_activity_data.current_index = get_act_id( g_daily_activity_data.current_index)
	g_daily_activity_data.activity_num = g_daily_activity_data.activity_num + 1
	g_daily_activity_data.is_started = 1
    local start_time_table = os.date("*t", gTime)
    g_daily_activity_data.start_time = os.time({year = start_time_table.year, month = start_time_table.month, day = start_time_table.day, hour = 0, min = 0, sec = 0})
	g_daily_activity_data.end_time =  g_daily_activity_data.start_time + 24 * 3600
end

function init_daily_activity()
    if g_daily_activity_data.activity_num ~= 0 then
        return
    end

    refresh_data()
    save_daily_activity()
end

function reinit_daily_activity()
	--清空排行榜
	for k, v in pairs( DAILY_ACTIVITY_RANK_ID or {}) do
		rank_mng.clear(v)
	end

	g_daily_activity_data = {
		current_index = 0,
		start_time = 0,
        end_time = 0,
		activity_num = 0,
		is_started = 0,
	}

    local db = dbmng:getOne()
    while true do
        db.status:delete( {_id="daily_activity"} )
        local info = db:runCommand("getPrevError")
        if info then break end
    end

    for _, ply in pairs(gPlys or {}) do
    	ply.daily_activitiy_num = 0
    	ply.daily_activity_info = {}
    end

	init_daily_activity()
end

function on_day_pass()
--	if gTime < g_daily_activity_data.start_time then
--		return
--	end

    send_rank_award(g_daily_activity_data.current_index)
    g_daily_activity_data.current_index = get_act_id(g_daily_activity_data.current_index) 
	g_daily_activity_data.activity_num = g_daily_activity_data.activity_num + 1
    local start_time_table = os.date("*t", gTime)
    g_daily_activity_data.start_time = os.time({year = start_time_table.year, month = start_time_table.month, day = start_time_table.day, hour = 0, min = 0, sec = 0})
	g_daily_activity_data.end_time =  g_daily_activity_data.start_time + 24 * 3600
    save_daily_activity()

	for k, v in pairs( DAILY_ACTIVITY_RANK_ID or {}) do
		rank_mng.clear(v)
	end
end

-- 采集				process_daily_activity(daily_ACTIVITY_ACTION.GATHER, 1, 1)
-- 训练士兵			process_daily_activity(daily_ACTIVITY_ACTION.TRAIN_ARM, 1, 1)
--提升战斗力		process_daily_activity(daily_ACTIVITY_ACTION.POWER_UP, 1, 1)
-- 攻击怪物			process_daily_activity(daily_ACTIVITY_ACTION.ATK_MONSTER, 1, 1)
-- 抽卡				process_daily_activity(daily_ACTIVITY_ACTION.GACHA, 1, 1)
--物资市场			process_daily_activity(daily_ACTIVITY_ACTION.RES_MARKET, 1, 1)
-- 黑市				process_daily_activity(daily_ACTIVITY_ACTION.BLACK_MARKET, 1, 1)
--攻击玩家击杀士兵	process_daily_activity(daily_ACTIVITY_ACTION.KILL_ARM, 1, 1)

function is_in_group(activity_id, group)
    for _, v in pairs(group or {}) do
        if v == activity_id then
            return true
        end
    end
    return false
end

function find_ply_rank(lv)
    local rank = 1
    for id, num in pairs(DAILY_ACTIVITY_CASTLE or {}) do
        if lv > num then
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

    local prop_group = resmng.get_conf("prop_daily_activity_group", g_daily_activity_data.current_index)
    if not prop_group then
        return
    end

    if is_in_group(activity_id, prop_group.Group) == false then
        return
    end

	local prop_tab1 = resmng.get_conf("prop_daily_activity", activity_id)
	if prop_tab1 == nil then
		return
	end

	local castle_lv = player:get_castle_lv()
--	if castle_lv < prop_tab1.LimitLevel then
---		return
--	end

	--更新积分
	local score_id = activity_id * 1000 + class
	local prop_score = resmng.get_conf("prop_daily_activity_score", score_id)
	if prop_score == nil then
		return
	end

	if player.daily_activitiy_num ~= g_daily_activity_data.activity_num then
		player:clear_daily_activity()
		player.daily_activitiy_num = g_daily_activity_data.activity_num
        local ply_info = player.daily_activity_info or {}
        ply_info.rank_lv =  find_ply_rank(castle_lv)
        player.daily_activity_info = ply_info
	end

    local score_info = player.daily_activity_info.score or {}
    score_info[activity_id] = score_info[activity_id] or 0
    score_info[activity_id] = score_info[activity_id] + math.floor(prop_score.Score * num) 
    if score_info[activity_id] < 0 then
        score_info[activity_id] = 0
    end
    player.daily_activity_info.score = score_info

	player.daily_activity_info = player.daily_activity_info
    local tot_score = get_tot_score(player.daily_activity_info)
	--判断阶段奖励
	send_score_award(player, g_daily_activity_data.current_index, activity_id)
	--更新排行榜
	rank_mng.add_data(DAILY_ACTIVITY_RANK_ID[ player.daily_activity_info.rank_lv], player.pid, {tot_score, gTime})
end

function get_tot_score(daily_activity_info)
    local score = 0
    for _, v in pairs(daily_activity_info.score or {}) do
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

--邮件发奖
function send_rank_award(group_id)
	local prop_tab = resmng.get_conf("prop_daily_activity_group", group_id)
	if prop_tab == nil then
		ERROR("daily activity can't find rank, aid:%d", aid)
		return
	end
        for i, _ in pairs(DAILY_ACTIVITY_CASTLE or {}) do
            local key = DAILY_ACTIVITY_RANK_ID[i]
            local rank_id = i * 1000 + group_id
            local prop_tab = resmng.get_conf("prop_daily_activity_award", rank_id)
            if prop_tab == nil then
                break
            end

            local min = 1
            for id, max in pairs(DAILY_ACTIVITY_RANK or {}) do
                --发邮件
                local rank_award = "RankAward" .. tostring(i)
                local pids = rank_mng.get_range(key, min, max)
                local temp_rank = min
                for idx, pid in pairs(pids or {}) do
                    local ply = getPlayer(pid)
                    if ply ~= nil then
                        local ply_info = ply.daily_activity_info
                        if ply_info  then
                            local total_score = get_tot_score(ply.daily_activity_info)
                            --local Cond = "Cond" .. tostring(id)
                            --if total_score >= prop_tab[Cond] then
                            --
                            ply:send_system_notice(10102 , {}, {total_score, temp_rank}, prop_tab[rank_award])
                            INFO("daily activity send rank award, pid=%d, rankid=%d", pid, rank_id)
                            --end
                        end
                    end
                end
                min = max + 1
            end
    end
end

--单个活动积分奖励
function send_score_award(ply, group_id, aid)
    local ply_info = ply.daily_activity_info
    if ply_info == nil then
        return
    end

    local rank_lv = ply_info.rank_lv
    local award_id = rank_lv * 1000 + group_id
    local prop_tab = resmng.get_conf("prop_daily_activity_award", award_id)
	if prop_tab == nil then
		ERROR("daily activity can't find award, castle lv:%d", castle_lv)
		return
	end

    local score = get_tot_score(ply.daily_activity_info)
    ply_info.award_tag  =  ply_info.award_tag or 0
	
	--第一档
	if score >= prop_tab.Cond1 and  ply_info.award_tag < 1 then
        ply_info.award_tag = 1
		ply.daily_activity_info = ply.daily_activity_info
		ply:send_system_notice(10101, {}, {1}, prop_tab.Award1)
		WARN("daily activity send score award1, pid=%d", ply.pid)
	end
	--第二档
	if score >= prop_tab.Cond2 and  ply_info.award_tag < 2 then
        ply_info.award_tag = 2
		ply.daily_activity_info = ply.daily_activity_info
		ply:send_system_notice(10101, {}, {2}, prop_tab.Award2)
		WARN("daily activity send score award2, pid=%d", ply.pid)
	end
	--第三档
	if score >= prop_tab.Cond3 and ply_info.award_tag < 3 then
        ply_info.award_tag = 3
		ply.daily_activity_info = ply.daily_activity_info
		ply:send_system_notice(10101, {}, {3}, prop_tab.Award3)
		WARN("daily activity send score award3, pid=%d", ply.pid)
	end
end

function pack_activity(player)
	if gTime < g_daily_activity_data.start_time then
		return
	end
    local castle_lv = player:get_castle_lv()
	if player.daily_activitiy_num ~= g_daily_activity_data.activity_num then
		player:clear_daily_activity()
		player.daily_activitiy_num = g_daily_activity_data.activity_num
        local ply_info = player.daily_activity_info or {}
        ply_info.rank_lv =  find_ply_rank(castle_lv)
        player.daily_activity_info = ply_info
	end
	local ply_info = player.daily_activity_info or {}
	if ply_info.rank_lv == nil then
        ply_info.rank_lv =  find_ply_rank(castle_lv)
		player.daily_activity_info = ply_info
	end

    local msg = {}
    msg.group_id = g_daily_activity_data.current_index
    msg.start_time = g_daily_activity_data.start_time
    msg.end_time = g_daily_activity_data.end_time
    msg.award_ratio = get_ratio()
    msg.activity_num = g_daily_activity_data.activity_num
    return msg
end


