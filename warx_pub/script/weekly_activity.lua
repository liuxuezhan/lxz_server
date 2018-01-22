module("weekly_activity", package.seeall)

Day2Index = {
	[0] = 1,
	[1] = 2,
	[2] = 3,
	[3] = 4,
	[4] = 5,
	[5] = 6,
	[6] = 6,
}

g_weekly_activity_data = g_weekly_activity_data or {
	data_list = {},	--活动数据,记录6个活动,每个的活动id
	current_index = 0,	--当前活动位置
	start_time = 0,	--开始时间
	unlock_time = 0,	--解锁时间
	activity_num = 0, --开启了几次活动
	is_started = 0, --活动是否已经开始
}

function load_weekly_activity()
	local db = dbmng:getOne()
    local info = db.status:findOne({_id = "weekly_activity"})
    if info then
        g_weekly_activity_data = info
    end
end

function save_weekly_activity()
	gPendingSave.status["weekly_activity"] = g_weekly_activity_data
end

function init_data()
	--初始化
	local random_array = {1,2,3,4,5,6,7}
	local count = 1
	local list = {}
	--前5天
	for i = 7, 1, -1 do
		local index = math.random(1, i)
		list[count] = random_array[index]
		random_array[index] = random_array[i]
		count = count + 1
		if count > 5 then
			break
		end
	end
	list[count] = 100
	return list
end

function refresh_data()
	--清空排行榜
	for k, v in pairs(resmng.prop_weekly_activity or {}) do
		rank_mng.clear(v.RankID)
	end

	--重置活动数据
	g_weekly_activity_data.data_list = init_data()
	local diff = get_diff_days(g_weekly_activity_data.start_time, gTime)
	g_weekly_activity_data.current_index = Day2Index[diff]
	g_weekly_activity_data.activity_num = g_weekly_activity_data.activity_num + 1
	g_weekly_activity_data.is_started = 1
end

function init_weekly_activity()
	if g_weekly_activity_data.unlock_time ~= 0 then
        return
    end

    local open_time = get_sys_status("start")
    local time_table = os.date("*t", open_time)
    g_weekly_activity_data.unlock_time = os.time({year = time_table.year, month = time_table.month, day = time_table.day + WEEKLY_ACTIVITY_OPEN_TIME, hour = 0, min = 0, sec = 0})

    --lua的wday1是从星期天开始的,要换算回来
    local start_time_table
    if gTime > g_weekly_activity_data.unlock_time then
    	start_time_table = os.date("*t", gTime)
    else
    	start_time_table = os.date("*t", g_weekly_activity_data.unlock_time)
    end
    local unlock_wday = start_time_table.wday % 7 - 1
    if unlock_wday == -1 then
        unlock_wday = 6
    end
    if unlock_wday == 0 then
        unlock_wday = 7
    end
    g_weekly_activity_data.start_time = os.time({year = start_time_table.year, month = start_time_table.month, day = (start_time_table.day - unlock_wday + 1), hour = 0, min = 0, sec = 0})
    g_weekly_activity_data.is_started = 0 --把进行标记重置

    --判断活动开启
    if gTime >= g_weekly_activity_data.start_time then
        refresh_data()
    end
    save_weekly_activity()

end

function reinit_weekly_activity()
	--清空排行榜
	for k, v in pairs(resmng.prop_weekly_activity or {}) do
		rank_mng.clear(v.RankID)
	end

	g_weekly_activity_data = {
		data_list = {},
		current_index = 0,
		start_time = 0,
		unlock_time = 0,
		activity_num = 0,
		is_started = 0,
	}

    local db = dbmng:getOne()
    while true do
        db.status:delete( {_id="weekly_activity"} )
        local info = db:runCommand("getPrevError")
        if info then break end
    end

    for _, ply in pairs(gPlys or {}) do
    	ply.weekly_activitiy_num = 0
    	ply.weekly_activity_info = {{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0}}
    end

	init_weekly_activity()
end

function on_day_pass()
	if gTime < g_weekly_activity_data.start_time then
		return
	end
	local diff = get_diff_days(g_weekly_activity_data.start_time, gTime)
	if diff >= 7 then
        --排行榜发奖
        local aid = g_weekly_activity_data.data_list[g_weekly_activity_data.current_index]
        if aid then send_rank_award(aid) end
        
        --总榜发奖
        send_rank_award(resmng.WEEKLY_ACTIVITY_1000) --总榜id是1000
		
        --活动结束
		local end_time = g_weekly_activity_data.start_time + 7 * 86400
		g_weekly_activity_data.start_time = end_time + WEEKLY_ACTIVITY_CIRCULATION * 7 * 86400	--算出新的开始时间
		g_weekly_activity_data.is_started = 0 --把进行标记重置
		--判断活动开启
		if gTime >= g_weekly_activity_data.start_time then
			refresh_data()
		end
	else
		if g_weekly_activity_data.is_started == 0 then
			refresh_data()
        else
            if g_weekly_activity_data.current_index < 6 then
                --排行榜发奖
                local aid = g_weekly_activity_data.data_list[g_weekly_activity_data.current_index]
                send_rank_award(aid)
            end
            g_weekly_activity_data.current_index = Day2Index[diff]

            --offline ntf
            --offline_ntf.post(resmng.OFFLINE_NOTIFY_TIME_ACTIVITY, "all", g_weekly_activity_data.current_index)

        end
    end
    save_weekly_activity()
end


--采集				process_weekly_activity(WEEKLY_ACTIVITY_ACTION.GATHER, 1, 1)
--训练士兵			process_weekly_activity(WEEKLY_ACTIVITY_ACTION.TRAIN_ARM, 1, 1)
--提升战斗力		process_weekly_activity(WEEKLY_ACTIVITY_ACTION.POWER_UP, 1, 1)
--攻击怪物			process_weekly_activity(WEEKLY_ACTIVITY_ACTION.ATK_MONSTER, 1, 1)
--抽卡				process_weekly_activity(WEEKLY_ACTIVITY_ACTION.GACHA, 1, 1)
--物资市场			process_weekly_activity(WEEKLY_ACTIVITY_ACTION.RES_MARKET, 1, 1)
--黑市				process_weekly_activity(WEEKLY_ACTIVITY_ACTION.BLACK_MARKET, 1, 1)
--攻击玩家击杀士兵	process_weekly_activity(WEEKLY_ACTIVITY_ACTION.KILL_ARM, 1, 1)


function process_weekly_activity(player, activity_id, class, num)
	if num == 0 then
		return
	end
	if g_weekly_activity_data.is_started == 0 or gTime < g_weekly_activity_data.unlock_time then
		return
	end
	local cur_idx = g_weekly_activity_data.current_index
	local cur_id = g_weekly_activity_data.data_list[cur_idx]
	if cur_id ~= activity_id then
		return
	end

	local prop_tab1 = resmng.get_conf("prop_weekly_activity", activity_id)
	if prop_tab1 == nil then
		return
	end
	local castle_lv = player:get_castle_lv()
	if castle_lv < prop_tab1.LimitLevel then
		return
	end

	--更新积分
	local score_id = activity_id * 1000 + class
	local prop_score = resmng.get_conf("prop_weekly_activity_score", score_id)
	if prop_score == nil then
		return
	end
	if player.weekly_activitiy_num ~= g_weekly_activity_data.activity_num then
		player:clear_weekly_activity()
		player.weekly_activitiy_num = g_weekly_activity_data.activity_num
	end
	local ply_info = player.weekly_activity_info[cur_idx]
	if ply_info[3] == 0 then
		ply_info[3] = castle_lv
	end

	ply_info[1] = ply_info[1] + math.floor(prop_score.Score * num)
	if ply_info[1] < 0 then
		ply_info[1] = 0
	end
	player.weekly_activity_info = player.weekly_activity_info
	--判断阶段奖励
	send_score_award(player, cur_idx, activity_id)

	--更新排行榜
	rank_mng.add_data(prop_tab1.RankID, player.pid, {ply_info[1], gTime})

	--更新总榜
	local total_score = player:get_weekly_activity_total()
	local prop_tab2 = resmng.get_conf("prop_weekly_activity", 1000)
	if prop_tab2 == nil then
		return
	end
	rank_mng.add_data(prop_tab2.RankID, player.pid, {total_score, gTime})
end

--开服系数
function get_ratio()
	return 1
end

--组织奖励
function pack_award(prop_tab)
	local tab = {}
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
function send_rank_award(aid)
	local prop_tab = resmng.get_conf("prop_weekly_activity", aid)
	if prop_tab == nil then
		ERROR("weekly activity can't find rank, aid:%d", aid)
		return
	end
	local key = prop_tab.RankID

	for i = 1, 100, 1 do
		local rank_id = aid * 1000 + i
		local prop_tab = resmng.get_conf("prop_weekly_activity_rank", rank_id)
		if prop_tab == nil then
			break
		end
		--组织奖励
		local award_tab = pack_award(prop_tab)

		--发邮件
		local pids = rank_mng.get_range(key, prop_tab.RankZone[1], prop_tab.RankZone[2])
        local temp_rank = prop_tab.RankZone[1]
		for idx, pid in pairs(pids or {}) do
			local ply = getPlayer(pid)
			if ply ~= nil then
				local total_score = ply:get_weekly_activity_total()
				if total_score >= prop_tab.Cond then
					ply:send_system_notice(prop_tab.MailId, {}, {temp_rank, g_weekly_activity_data.current_index}, award_tab)
					WARN("weekly activity send rank award, pid=%d, rankid=%d", pid, rank_id)
				end
			end
            temp_rank = temp_rank + 1
		end
	end
end

--单个活动积分奖励
function send_score_award(ply, index, aid)
	local ply_info = ply.weekly_activity_info[index]
	if ply_info == nil then
		return
	end
	local castle_lv = ply_info[3]
	if castle_lv == nil or castle_lv == 0 then
		castle_lv = ply:get_castle_lv()
	end
	local award_id = aid * 1000 + castle_lv
	local prop_tab = resmng.get_conf("prop_weekly_activity_award", award_id)
	if prop_tab == nil then
		ERROR("weekly activity can't find award, castle lv:%d", castle_lv)
		return
	end
	
	--第一档
	if ply_info[1] >= prop_tab.Cond1 and ply_info[2] < 1 then
		ply_info[2] = 1
		ply.weekly_activity_info = ply.weekly_activity_info
		ply:send_system_notice(prop_tab.Mail, {}, {g_weekly_activity_data.current_index, ply_info[1]}, prop_tab.Award1)
		WARN("weekly activity send score award1, pid=%d", ply.pid)
	end
	--第二档
	if ply_info[1] >= prop_tab.Cond2 and ply_info[2] < 2 then
		ply_info[2] = 2
		ply.weekly_activity_info = ply.weekly_activity_info
		ply:send_system_notice(prop_tab.Mail, {}, {g_weekly_activity_data.current_index, ply_info[1]}, prop_tab.Award2)
		WARN("weekly activity send score award2, pid=%d", ply.pid)
	end
	--第三档
	if ply_info[1] >= prop_tab.Cond3 and ply_info[2] < 3 then
		ply_info[2] = 3
		ply.weekly_activity_info = ply.weekly_activity_info
		ply:send_system_notice(prop_tab.Mail, {}, {g_weekly_activity_data.current_index, ply_info[1]}, prop_tab.Award3)
		WARN("weekly activity send score award3, pid=%d", ply.pid)
	end
end

function pack_activity(player)
	if gTime >=  g_weekly_activity_data.start_time then
        if player.weekly_activitiy_num ~= g_weekly_activity_data.activity_num then
            player:clear_weekly_activity()
            player.weekly_activitiy_num = g_weekly_activity_data.activity_num
        end
        local ply_info = player.weekly_activity_info[g_weekly_activity_data.current_index]
        if ply_info[3] == 0 then
            ply_info[3] = player:get_castle_lv()
            player.weekly_activity_info = player.weekly_activity_info
        end
	end

    local msg = {}
    msg.cur_day = g_weekly_activity_data.current_index
    msg.activity_id = g_weekly_activity_data.data_list[msg.cur_day]
    msg.start_time = g_weekly_activity_data.start_time
    msg.unlock_time = g_weekly_activity_data.unlock_time
    msg.award_ratio = get_ratio()
    msg.activity_num = g_weekly_activity_data.activity_num
    return msg
end


