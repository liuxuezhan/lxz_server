module("world_event", package.seeall)

WorldEventData = WorldEventData or {unlock_score = 0, events = {}}
WorldEventCategory = WorldEventCategory or {}

function init_world_event()
	local events = WorldEventData.events
	for k, v in pairs(resmng.prop_world_events or {}) do
		if events[v.ID] == nil then
			local unit = {}
			unit.id = v.ID
			unit.action = g_world_event_relation[unpack(v.FinishCondition)]
			unit.cur_num = 0
			unit.is_finish = 0
			unit.unlock = 0 --用来发公告的标记,没有逻辑的作用
			unit.timer = -1

			if WorldEventData.unlock_score >= v.UnlockScore then
				unit.unlock = 1
			end

			local cur_time = gTime - get_sys_status("start")
			local left_time = v.TmOpenServer - cur_time
			if left_time > 0 then
				unit.timer = timer.new("world_event", left_time, v.ID)
			else
				unit.unlock = 1
			end

			events[unit.id] = unit
			gPendingSave.world_event[unit.id] = unit

			WorldEventCategory[unit.action] = WorldEventCategory[unit.action] or {}
			WorldEventCategory[unit.action][unit.id] = unit
		else
			if events[v.ID].timer and events[v.ID].timer > 0 then
				local dest_time = get_sys_status("start") + v.TmOpenServer
				timer.adjust(events[v.ID].timer, dest_time)
			end
		end
	end
end

function reinit_world_event()
	for k, v in pairs(WorldEventData.events or {}) do
		if v.timer and v.timer > 0 then
			timer.del(v.timer)
		end
	end
	WorldEventData = {unlock_score = 0, events = {}}
	WorldEventCategory = {}
	gPendingSave.status["world_event_score"].score = 0

	local db = dbmng:getOne()
    while true do
        db.world_event:delete({})
        local info = db:runCommand("getPrevError")
        if info then break end
    end

    --清除现有玩家的数据
    for _, ply in pairs(gPlys or {}) do
    	ply.world_event_get_id = {}
    	ply.world_event_stage_award = {}
    end

	init_world_event()
end

function is_stage_finish(stage)
	local is_finish = true
	for k, v in pairs(resmng.prop_world_events or {}) do
		if v.Stage == stage then
			if WorldEventData.events[v.ID].is_finish == 0 then
				is_finish = false
				break
			end
		end
	end
	return is_finish
end

function get_event_by_action(action)
	return WorldEventCategory[action]
end

function load_world_event()
	local db = dbmng:getOne()
	local data = db.world_event:find()
	while data:hasNext() do
        local unit = data:next()
        WorldEventData.events[unit.id] = unit
		WorldEventCategory[unit.action] = WorldEventCategory[unit.action] or {}
		WorldEventCategory[unit.action][unit.id] = unit
    end

    local info = db.status:findOne({_id = "world_event_score"})
    if info then
        WorldEventData.unlock_score = info.score
    end
end

function packet_world_event_data()
	local msg = {}
	msg.tm_open = get_sys_status("start")
	msg.unlock_score = WorldEventData.unlock_score
	msg.data = {}
	for k, v in pairs(WorldEventData.events or {}) do
		table.insert(msg.data, v)
	end
	return msg
end

function notify_board(prop_event)
	if prop_event.OpenMail ~= nil then
		player_t.send_system_to_all(prop_event.OpenMail, {}, {prop_event.TITLE, prop_event.DESC})
	end

	if prop_event.Notify ~= nil then
		Rpc:tips({pid = -1, gid = _G.GateSid}, 2, prop_event.Notify, {prop_event.TITLE})
		player_t.add_chat({pid = -1, gid = _G.GateSid}, ChatChanelEnum.World, 0, {pid=0}, "", prop_event.Notify, {prop_event.TITLE})
		Rpc:display_ntf({pid = -1, gid = _G.GateSid}, {mode=DISPLY_MODE.ACHEVEMENT, event_id=prop_event.ID})
	end
end

function check_score()
	local flag = true
	while flag do
		flag = false
		for k, v in pairs(resmng.prop_world_events or {}) do
			local event = WorldEventData.events[v.ID]
			if event ~= nil then
				if event.unlock == 1 and event.is_finish == 1 and event.add_score == nil then
				    WorldEventData.unlock_score = WorldEventData.unlock_score + v.FinishScore
					gPendingSave.status["world_event_score"].score = WorldEventData.unlock_score
					event.add_score = 1
					flag = true
				end

				if event.unlock == 0 and WorldEventData.unlock_score >= v.UnlockScore then
					event.unlock = 1
					if event.timer > 0 then
						timer.del(event.timer)
					end
					event.timer = -1
					gPendingSave.world_event[v.ID] = event
					flag = true
					notify_board(v)
				end
			end
		end
	end
end

function check_time(sn, id)
	local prop_event = resmng.get_conf("prop_world_events", id)
	if prop_event == nil then
		return
	end
	local event = WorldEventData.events[id]
	if event == nil then
		return
	end
	if event.timer ~= sn then
		return
	end

	event.unlock = 1
	event.timer = -1
	gPendingSave.world_event[id] = event
	notify_board(prop_event)
	check_score()
end

function get_world_event_award(player, id)
	--判断领取
	if player.world_event_get_id[id] ~= nil then
		return
	end

	local prop_event = resmng.get_conf("prop_world_events", id)
	if prop_event == nil then
		return
	end
	--判断分数是否达到
	local unlock = false
	if WorldEventData.unlock_score >= prop_event.UnlockScore then
		unlock = true
	end
	--判断是否超过解锁时间
	local cur_time = gTime - get_sys_status("start")
	if cur_time >= prop_event.TmOpenServer then
		unlock = true
	end

	if unlock == false then
		return
	end

	--判断是否完成
	if WorldEventData.events[id] == nil or WorldEventData.events[id].is_finish ~= 1 then
		return
	end

	player.world_event_get_id[id] = id
	player.world_event_get_id = player.world_event_get_id
	player:add_bonus(prop_event.Bonus[1], prop_event.Bonus[2], VALUE_CHANGE_REASON.REASON_WORLD_EVENT)
end

function process_world_event(action, ...)
	local list = get_event_by_action(action)
	for k, v in pairs(list or {}) do
		if v.is_finish == 0 then
			local prop_event = resmng.get_conf("prop_world_events", v.id)
			if prop_event ~= nil then
				local con_tab = copyTab(prop_event.FinishCondition)
		        table.remove(con_tab, 1)
			    for i, j in pairs({...}) do
			        table.insert(con_tab, j)
			    end

			    local res = do_world_event[action](v, unpack(con_tab))
			    if res == true then
			    	gPendingSave.world_event[v.id] = v
			    end
			    if v.is_finish == 1 and v.unlock == 1 then
					check_score()
			    end
			end
		end
	end
end

do_world_event = {}

--升级城堡
do_world_event[WORLD_EVENT_ACTION.CASTLE_LEVEL] = function(event_data, con_lv, con_num, real_lv)
	if con_lv == real_lv then
		event_data.cur_num = event_data.cur_num + 1
		if event_data.cur_num >= con_num then
			event_data.is_finish = 1
		end
		return true
	end
	return false
end

--攻击怪物
do_world_event[WORLD_EVENT_ACTION.ATTACK_MONSTER] = function(event_data, con_mode, con_num, real_propid)
	local prop_monster = resmng.get_conf("prop_world_unit", real_propid)
	if prop_monster == nil then
		return false
	end
	local flag = false
	if con_mode == 1 then--1 - 30 普通怪
		if prop_monster.Mode >= 1 and prop_monster.Mode <= 30 then
			flag = true
		end
	elseif con_mode == 2 then--31 - 40 精英
		if prop_monster.Mode >= 31 and prop_monster.Mode <= 40 then
			flag = true
		end
	elseif con_mode == 3 then--41 - 50 首领
		if prop_monster.Mode >= 41 and prop_monster.Mode <= 50 then
			flag = true
		end
	elseif con_mode == 4 then--51 - 60 超级首领
		if prop_monster.Mode >= 51 and prop_monster.Mode <= 60 then
			flag = true
		end
	end

	if flag == true then
		event_data.cur_num = event_data.cur_num + 1
		if event_data.cur_num >= con_num then
			event_data.is_finish = 1
		end
		return true
	end
	return false
end

--占领城市
do_world_event[WORLD_EVENT_ACTION.OCCUPY_CITY] = function(event_data, con_lv, con_num, real_lv)
	if con_lv == real_lv then
		event_data.cur_num = event_data.cur_num + 1
		if event_data.cur_num >= con_num then
			event_data.is_finish = 1
		end
		return true
	end
	return false
end

--收集英雄数量
do_world_event[WORLD_EVENT_ACTION.HERO_NUM] = function(event_data, con_quality, con_num, real_propid)
	local prop_hero = resmng.get_conf("prop_hero_basic", real_propid)
	if prop_hero == nil then
		return false
	end
	if prop_hero.Quality >= con_quality then
		event_data.cur_num = event_data.cur_num + 1
		if event_data.cur_num >= con_num then
			event_data.is_finish = 1
		end
		return true
	end
	return false
end

--击杀叛军
do_world_event[WORLD_EVENT_ACTION.PANJUN_KILL] = function(event_data, con_power, real_power)
	event_data.cur_num = event_data.cur_num + real_power
	if event_data.cur_num >= con_power then
		event_data.is_finish = 1
	end
	return true
end

--治疗士兵
do_world_event[WORLD_EVENT_ACTION.CURE_SOLDIER] = function(event_data, con_num, real_num)
	event_data.cur_num = event_data.cur_num + real_num
	if event_data.cur_num >= con_num then
		event_data.is_finish = 1
	end
	return true
end

--军团数量
do_world_event[WORLD_EVENT_ACTION.UNION_TECH_NUM] = function(event_data, con_propid, con_num, real_propid)
	if con_propid == real_propid then
		event_data.cur_num = event_data.cur_num + 1
		if event_data.cur_num >= con_num then
			event_data.is_finish = 1
		end
		return true
	end
	return false
end

--采集量
do_world_event[WORLD_EVENT_ACTION.GATHER_NUM] = function(event_data, con_type, con_num, real_type, real_num)
	if con_type == real_type then
		event_data.cur_num = event_data.cur_num + real_num
		if event_data.cur_num >= con_num then
			event_data.is_finish = 1
		end
		return true
	end
	return false
end

--占领王城
do_world_event[WORLD_EVENT_ACTION.OCCUPY_KING_CITY] = function(event_data)
	event_data.cur_num = event_data.cur_num + 1
	event_data.is_finish = 1
	return true
end

--获得怪物积分
do_world_event[WORLD_EVENT_ACTION.MONSTER_POINT] = function(event_data, con_num, real_num)
	event_data.cur_num = event_data.cur_num + real_num
	if event_data.cur_num >= con_num then
		event_data.is_finish = 1
	end
	return true
end



function gm_finish_world_event(id, num)
	--[[local unit = WorldEventData[id]
	if unit ~= nil then
		unit.cur_num = num
		unit.is_finish = 1
        gPendingInsert.world_event[unit.id] = unit
	end--]]
    WorldEventData.unlock_score = 999999
    for k, v in pairs(WorldEventData.events or {}) do
        v.unlock = 1
        v.is_finish = 1
    end




    
end

