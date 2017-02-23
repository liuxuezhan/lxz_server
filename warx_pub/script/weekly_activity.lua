module("weekly_activity", package.seeall)

function get_relative_start()
	return _G._G.gSysStatus.start
end

Circulation = 0	--活动间隔周期
OpenTime = 2	--开放时间
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
	--周末
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

function init_activity()
	if g_weekly_activity_data.unlock_time ~= 0 then
        return
    end

    local open_time = get_relative_start()
    local time_table = os.date("*t", open_time)
    g_weekly_activity_data.unlock_time = os.time({year = time_table.year, month = time_table.month, day = time_table.day + OpenTime, hour = 0, min = 0, sec = 0})

    --lua的wday1是从星期天开始的,要换算回来
    local unlock_wday = (time_table.wday + OpenTime) % 7 - 1
    if unlock_wday == -1 then
        unlock_wday = 6
    end
    if unlock_wday == 0 then
        unlock_wday = 7
    end
    g_weekly_activity_data.start_time = os.time({year = time_table.year, month = time_table.month, day = (time_table.day + OpenTime - unlock_wday + 1), hour = 0, min = 0, sec = 0})
    g_weekly_activity_data.is_started = 0 --把进行标记重置

    --判断活动开启
    if gTime >= g_weekly_activity_data.start_time then
        refresh_data()
    end
    save_weekly_activity()

end

function on_day_pass()
	if gTime < g_weekly_activity_data.start_time then
		return
	end
	local diff = get_diff_days(g_weekly_activity_data.start_time, gTime)
	if diff >= 7 then
		--活动结束
		local end_time = start_time + 7 * 86400
		g_weekly_activity_data.start_time = end_time + Circulation * 7 * 86400	--算出新的开始时间
		g_weekly_activity_data.is_started = 0 --把进行标记重置
		--判断活动开启
		if gTime >= g_weekly_activity_data.start_time then
			refresh_data()
		end
	else
		if g_weekly_activity_data.is_started == 0 then
			refresh_data()
		end
		g_weekly_activity_data.current_index = Day2Index[diff]
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
	if g_weekly_activity_data.is_started == 0 or gTime < g_weekly_activity_data.unlock_time then
		return
	end
	local cur_idx = g_weekly_activity_data.current_index
	local cur_id = g_weekly_activity_data.data_list[cur_idx]
	if cur_id ~= activity_id then
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
	player.weekly_activity_score[cur_idx] = player.weekly_activity_score[cur_idx] + prop_score.Score * num
	player.weekly_activity_score = player.weekly_activity_score
	--判断阶段奖励
	send_score_award(player, cur_idx, activity_id)

	--更新排行榜
	local prop_tab1 = resmng.get_conf("prop_weekly_activity", activity_id)
	if prop_tab1 == nil then
		return
	end
	rank_mng.add_data(prop_tab1.RankID, player.pid, {player.weekly_activity[cur_idx]})
	--更新总榜
	local total_score = player:get_weekly_activity_total()
	local prop_tab2 = resmng.get_conf("prop_weekly_activity", 1000)
	if prop_tab2 == nil then
		return
	end
	rank_mng.add_data(prop_tab2.RankID, player.pid, {total_score})
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
		new_unit[3] = new_unit * get_ratio()
		table.insert(tab, new_unit)
	end
	return tab
end

--邮件发奖
function send_rank_award(index)
	local aid = g_weekly_activity_data.data_list[index]
	if aid == nil then
		ERROR("weekly activity can't find id, index:%d", index)
		return
	end
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
		local pids = rank_mng.get_range(key, v.RankZone[1], v.RankZone[2])
		for idx, pid in pairs(pids or {}) do
			local ply = getPlayer(pid)
			if ply ~= nil then
				local total_score = ply:get_weekly_activity_total()
				if total_score >= prop_tab.Cond then
					ply:send_system_notice(prop_tab.MailId, {}, {}, award_tab)
				end
			end
		end
	end
end

--单个活动积分奖励
function send_score_award(ply, index, aid)
	local castle_lv = ply:get_castle_lv()
	local award_id = aid * 1000 + castle_lv
	local prop_tab = resmng.get_conf("prop_weekly_activity_award", award_id)
	if prop_tab == nil then
		ERROR("weekly activity can't find award, castle lv:%d", castle_lv)
		return
	end
	--第一档
	if ply.weekly_activity_score[index] > prop_tab.Cond1 and ply.weekly_activity_award[index] < 1 then
		ply.weekly_activity_award[index] = 1
		ply.weekly_activity_award = ply.weekly_activity_award
		ply:send_system_notice(prop_tab.MailId, {}, {}, prop_tab.Award1)
	end
	--第二档
	if ply.weekly_activity_score[index] > prop_tab.Cond2 and ply.weekly_activity_award[index] < 2 then
		ply.weekly_activity_award[index]= 2
		ply.weekly_activity_award = ply.weekly_activity_award
		ply:send_system_notice(prop_tab.MailId, {}, {}, prop_tab.Award2)
	end
	--第三档
	if ply.weekly_activity_score[index] > prop_tab.Cond3 and ply.weekly_activity_award[index] < 3 then
		ply.weekly_activity_award[index]= 3
		ply.weekly_activity_award = ply.weekly_activity_award
		ply:send_system_notice(prop_tab.MailId, {}, {}, prop_tab.Award3)
	end
end




