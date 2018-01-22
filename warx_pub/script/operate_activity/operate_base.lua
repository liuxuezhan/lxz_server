module("operate_activity", package.seeall)

--抽象类、派生类实现 start
BaseClass = {_name_=""}
function BaseClass:GetName()
	return self._name_
end

function BaseClass:Ctor()
end

function BaseClass:Dtor()
end

function BaseClass:New(...)
	local new = {}
	setmetatable(new, {__index = self})
	new:Ctor(...)
	return new
end

function DeclareClass(class, abstract_class)
	local new_class = {}
	new_class._name_ = class
	if abstract_class == nil then
		setmetatable(new_class, {__index = BaseClass})
	else
		setmetatable(new_class, {__index = abstract_class})
	end
	
	return new_class
end
--抽象类、派生类实现 end


--活动抽象类  (活动必须继承这个类)
CActivityBase = DeclareClass("CActivityBase")
function CActivityBase:Ctor(...)
    local arg = {...}
    data = arg[1] or {}
	self.activity_id = data.activity_id or 0
	self.start_time = data.start_time or 0
	self.end_time = data.end_time or 0

	self.is_start = data.is_start or 0
	self.is_end = data.is_end or 0
	self.action_array = data.action_array or {}
	self.action_startid = data.action_startid or 0
	self.action_endid = data.action_endid or 0

	self.version = data.version or 0
end

------------------------------
--重载函数
------------------------------
--活动初始化
function CActivityBase:init_activity()
end
--活动开始
function CActivityBase:start_activity()
end
--活动结束
function CActivityBase:end_activity()
end
--每分钟tick
function CActivityBase:loop()
end
--重置排行榜
function CActivityBase:reset_rank()
	local prop_tab = resmng.get_conf("prop_operate_activity", self.activity_id)
	if prop_tab == nil or prop_tab.Rank == nil then
		return
	end
	rank_mng.clear(prop_tab.Rank)
end
--更新排行榜
function CActivityBase:update_rank(player, prop_action, score_type, score)
	local prop_activity = resmng.get_conf("prop_operate_activity", self.activity_id)
	if prop_activity == nil or prop_activity.Rank == nil then
		return
	end

	local prop_rank = resmng.get_conf("prop_rank", prop_activity.Rank)
	if prop_rank == nil then
		return
	end

	local key = nil
	if prop_rank.IsPerson == 1 then
		key = player.pid
	else
		key = player.uid
	end
	local rank_score = score
	if score_type == OPERATE_SCORE_TYPE_INC then
		rank_score = rank_score + (rank_mng.get_score(prop_activity.Rank, key) or 0)
	elseif score_type == OPERATE_SCORE_TYPE_ALL then
		rank_score = score
	end
	rank_mng.add_data(prop_activity.Rank, key, {rank_score})
end

--兑换
function CActivityBase:exchage(player, exchange_id)
	self:handout_exchange_award(player, exchange_id)
end
--领取单一奖励
function CActivityBase:single_get(p)
	local prop_activity = resmng.get_conf("prop_operate_activity", self.activity_id)
	if prop_activity == nil or prop_activity.SingleBonus == nil then
		return
	end

	--判断是否完成了任务
	if prop_activity.ActionRange[1] ~= prop_activity.ActionRange[2] then
		return
	end

	local action_id = prop_activity.ActionRange[1]
	local prop_action = resmng.get_conf("prop_operate_action", action_id)
	if prop_action == nil then
		return
	end

    local num = 0
    if prop_action.Action[1] == "union_power" then
        local u = p:get_union()
        if not u then
            return
        end
        num = u:union_pow()
    else
        local action_flag = p:get_operate_info(self.activity_id, OPERATE_PLAYER_DATA.ACTION)
        if action_flag == nil then
            return
        end

        local num = action_flag[action_id]
        if num == nil then
            return
        end
    end

	if num >= prop_action.Num then
		p:add_bonus(prop_activity.SingleBonus[1], prop_activity.SingleBonus[2], VALUE_CHANGE_REASON.REASON_OPERATE_SINGLE)
		p:set_operate_info(self.activity_id, OPERATE_PLAYER_DATA.ACTION_AWARD, action_id, 1)
        --p:tlog_ten2("ActivityFlow",p.vip_lv,self.activity_id,action_id)
	end
end
--多条目领奖
function CActivityBase:task_get(p, task_id)
	local prop_activity = resmng.get_conf("prop_operate_activity", self.activity_id)
	if prop_activity == nil or prop_activity.ActionRange == nil then
		return
	end

	if prop_activity.ActionRange[1] > task_id or task_id > prop_activity.ActionRange[2] then
		return
	end
	local prop_action = resmng.get_conf("prop_operate_action", task_id)
	if prop_action == nil then
		return
	end

	local action_data = p:get_operate_info(self.activity_id, OPERATE_PLAYER_DATA.ACTION)
	if action_data == nil then
        if prop_action.Action[1] ~= "union_power" then
            return
        else
            action_data = {}
        end
	end

	local award_data = p:get_operate_info(self.activity_id, OPERATE_PLAYER_DATA.ACTION_AWARD)
	if award_data ~= nil and award_data[task_id] ~= nil then
        return
	end

	local num = action_data[task_id]
	if num == nil then
        if prop_action.Action[1] == "union_power" then
            local u = p:get_union()
            if not u then
                return
            end
            num = u:union_pow()
        else
            return
        end
	end

	if num >= prop_action.Num then
		p:add_bonus(prop_action.Bonus[1], prop_action.Bonus[2], VALUE_CHANGE_REASON.REASON_OPERATE_SINGLE)
		p:set_operate_info(self.activity_id, OPERATE_PLAYER_DATA.ACTION_AWARD, task_id, 1)
        --p:tlog_ten2("ActivityFlow",p.vip_lv,self.activity_id,task_id)
		return
	end
end
------------------------------
--重载函数
------------------------------



function CActivityBase:init(prop_tab)
	self.activity_id = prop_tab.ID
	self.start_time = self:calc_stamp(prop_tab.StartTime)
	self.end_time = self.start_time + prop_tab.Duration
	--新任务如果循环，算出最近的时间
	if prop_tab.Circulation ~= nil and self.end_time <= gTime then
		local period = prop_tab.Duration + prop_tab.Circulation
		local span = gTime - self.end_time
		self.start_time = self.start_time + math.floor(span / period) * period
		self.end_time = self.start_time + prop_tab.Duration
	end
end

function CActivityBase:init_action()
	self.action_array = {}
	local prop_activity = resmng.get_conf("prop_operate_activity", self.activity_id)
	if prop_activity == nil or prop_activity.ActionRange == nil then
		return
	end
	self.action_startid = prop_activity.ActionRange[1]
	self.action_endid = prop_activity.ActionRange[2]
	for i = self.action_startid, self.action_endid, 1 do
		local prop_action = resmng.get_conf("prop_operate_action", i)
		if prop_action ~= nil and prop_action.Action ~= nil then
			local action = unpack(prop_action.Action)
			local action_id = g_operate_activity_relation[action]
			if action_id ~= nil then
				self.action_array[action_id] = true
			end
		end
	end
end

function CActivityBase:calc_stamp(con_tb)
	local stamp = gTime
	local class = con_tb[1]
	if class == "relative" then
		local con_day = con_tb[2]
		local con_hour = con_tb[3]
		local open_time = get_sys_status("start")
		local time_table = os.date("*t", open_time)
		stamp = os.time({year = time_table.year, month = time_table.month, day = time_table.day + con_day, hour = con_hour, min = 0, sec = 0})

	elseif class == "absolute" then
		local con_year = con_tb[2]
		local con_month = con_tb[3]
		local con_day = con_tb[4]
		local con_hour = con_tb[5]
		stamp = os.time({year = con_year, month = con_month, day = con_day, hour = con_hour, min = 0, sec = 0})

	end
	return stamp
end

function CActivityBase:recalc_activity()
	local prop_tab = resmng.get_conf("prop_operate_activity", self.activity_id)
	if prop_tab == nil then
		return
	end
	--不循环的不管
	local interval_time = prop_tab.Circulation
	if interval_time == nil then
		return
	end

	--判断循环次数
	if prop_tab.CirculationNum ~= nil then
		if self.version + 1 >= prop_tab.CirculationNum then
			return
		end
	end

	--计算新的时间
	self.start_time = self.end_time + interval_time
	self.end_time = self.start_time + prop_tab.Duration
	self.is_start = 0
	self.is_end = 0
	self.version = self.version + 1
end

function CActivityBase:tick()
	if self.is_end == 1 then
		return false
	end
	
	local need_save = false
	if self.is_start == 0 and gTime >= self.start_time then
		self.is_start = 1
		self.is_end = 0
		self:reset_rank()	--重置排行榜
		self:start_activity()
		need_save = true
	end
	if self.is_end == 0 and gTime >= self.end_time then
		self.is_end = 1
		self.is_start = 0
		self:handout_rank_award() --排行榜邮件发奖
		self:end_activity()
		self:recalc_activity()
		need_save = true
		if self.is_end == 1 then
			Rpc:broadcast_operate_end({pid = -1, gid = _G.GateSid}, self.activity_id)
        elseif gTime >= self.start_time then
            self.is_start = 1
            self.is_end = 0
            self:reset_rank()
            self:start_activity()
		end
	end
	if self.is_start == 1 and self.is_end == 0 then
		self:loop()
	end
	return need_save
end

--排行榜邮件发奖
function CActivityBase:handout_rank_award()
	local prop_tab = resmng.get_conf("prop_operate_activity", self.activity_id)
	if prop_tab == nil or prop_tab.Rank == nil or prop_tab.RankRange == nil then
		return
	end
	local s_id = prop_tab.RankRange[1]
	local e_id = prop_tab.RankRange[2]

	for i = s_id, e_id, 1 do
		local prop_award = resmng.get_conf("prop_operate_award_rank", i)
		if prop_award ~= nil then
			local pids = rank_mng.get_range(prop_tab.Rank, prop_award.RankRange[1], prop_award.RankRange[2])
			local temp_rank = prop_award.RankRange[1]
			for k, pid in pairs(pids or {}) do
				local p = getPlayer(pid)
				if p ~= nil and prop_award.Mail ~= nil then
					p:send_system_notice(prop_award.Mail, {}, {temp_rank}, prop_award.Bonus[2])
                    --p:tlog_ten2("ActivityFlow",p.vip_lv,self.activity_id,i)
				end
				temp_rank = temp_rank + 1
			end
		end
	end

end

function CActivityBase:can_exchange(player, exchange_id)
	local prop_activity = resmng.get_conf("prop_operate_activity", self.activity_id)
	if prop_activity == nil or prop_activity.NeedExchange == nil or prop_activity.ExchangeRange == nil then
		return false
	end

	if prop_activity.NeedExchange == 1 then
		return true
	end

	if prop_activity.ExchangeRange[1] > exchange_id or prop_activity.ExchangeRange[2] < exchange_id then
		return false
	end
	local prop_award = resmng.get_conf("prop_operate_award_exchange", exchange_id)
	if prop_award == nil then
		return false
	end

	local exchange_data = player:get_operate_info(self.activity_id, OPERATE_PLAYER_DATA.EXCHANGE)
	if exchange_data == nil then
		return true
	end

	local num = exchange_data[exchange_id]
	if num == nil then
		return true
	else
		return false
	end

	--判断兑换的条件
	for k, v in pairs(prop_award.Need) do
		if v[1] == "item" then
			if v[3] > player:get_item_num(v[2]) then
				return false
			end
		elseif v[1] == "res" then
			if v[3] > player:get_res_num(v[2]) then
				return false
			end
		end
	end 

	return true
end

--兑换奖励
function CActivityBase:handout_exchange_award(player, exchange_id)
	if self:can_exchange(player, exchange_id) == false then
		return false
	end

	--扣物品
	local prop_award = resmng.get_conf("prop_operate_award_exchange", exchange_id)
	for k, v in pairs(prop_award.Need) do
		if v[1] == "item" then
			player:dec_item_by_item_id(v[2], v[3], VALUE_CHANGE_REASON.REASON_DEC_ITEM_OPERATE_EXCHANGE)

		elseif v[1] == "res" then
			player:do_dec_res(v[2], v[3], VALUE_CHANGE_REASON.REASON_DEC_RES_OPERATE_EXCHANGE)
		end
	end

	--更新玩家数据
	player:set_operate_info(self.activity_id, OPERATE_PLAYER_DATA.EXCHANGE, exchange_id, 1)

	--加
	player:add_bonus(prop_award.Bonus[1], prop_award.Bonus[2], VALUE_CHANGE_REASON.REASON_OPERATE_EXCHANGE)
end

--根据任务版本刷新玩家身上的任务标记
function CActivityBase:refresh_player_by_version(player)

end

function CActivityBase:first_start(player)
	if self.is_start ~= 1 then
		return
	end
	if player:get_operate_first_flag(self.activity_id) == true then
		return
	end
	for k, v in pairs(OPERATE_ACTIVITY_ACTION) do
		self:process_action(player, v)
	end
	player:set_operate_first_flag(self.activity_id)
end

function CActivityBase:process_action(player, action, ...)
	if self.is_start ~= 1 or self.is_end ~= 0 or self.action_array[action] ~= true then
		return
	end
	player:operate_check_version(self)
	for i = self.action_startid, self.action_endid, 1 do
		local prop_action = resmng.get_conf("prop_operate_action", i)
		if prop_action ~= nil and prop_action.Action ~= nil then
			local key = unpack(prop_action.Action)
			local cur_action = g_operate_activity_relation[key]
			if cur_action == action then
				self:refresh_player_by_version(player)
				local score_type, score = self:finish_action(action, player, prop_action, ...)
				if score ~= nil and score > 0 then
					self:update_rank(player, prop_action, score_type, score)
				end
			end
		end
	end
end

function CActivityBase:finish_action(action, player, prop_action, ...)
	if action == OPERATE_ACTIVITY_ACTION.GACHA then--抽卡
		return self:action_gacha(player, prop_action, ...)

	elseif action == OPERATE_ACTIVITY_ACTION.KILL_SOLDIER then--领主杀敌
		return self:action_kill_soldier(player, prop_action, ...)

	elseif action == OPERATE_ACTIVITY_ACTION.OCCUPY_CITY then--军团占领城市
		return self:action_occupy_city(player, prop_action, ...)

	elseif action == OPERATE_ACTIVITY_ACTION.BLACK_MARKET then--黑市购买
		return self:action_black_market(player, prop_action, ...)

	elseif action == OPERATE_ACTIVITY_ACTION.RESOURCE_MARKET then--资源兑换
		return self:action_resource_market(player, prop_action, ...)

	elseif action == OPERATE_ACTIVITY_ACTION.COLLECT_GRADE_HERO then--收集不通品阶的英雄
		return self:action_collect_grade_hero(player, prop_action, ...)
	elseif action == OPERATE_ACTIVITY_ACTION.CASTLE_UP then--城堡升级
		return self:action_castle_upgrade(player, prop_action, ...)
	elseif action == OPERATE_ACTIVITY_ACTION.FIGHT_POWER then--战力提升
		return self:action_power_improve(player, prop_action, ...)
	elseif action == OPERATE_ACTIVITY_ACTION.UNION_POWER then--军团战力提升
		return self:action_union_power_improve(player, prop_action, ...)
	end
end

function CActivityBase:action_castle_upgrade(player, prop_action, real_num)
    if real_num == nil then
        return
    end

	local action, con_type = unpack(prop_action.Action)
	player:update_operate_info(self.activity_id, OPERATE_PLAYER_DATA.ACTION, prop_action.ID, real_num)
	return OPERATE_SCORE_TYPE_INC, (prop_action.Score * real_num)
end

function CActivityBase:action_power_improve(player, prop_action, real_num)
    if real_num == nil then
        return
    end

	local action, con_type = unpack(prop_action.Action)
	player:update_operate_info(self.activity_id, OPERATE_PLAYER_DATA.ACTION, prop_action.ID, real_num)
	return OPERATE_SCORE_TYPE_INC, (prop_action.Score * real_num)
end

function CActivityBase:action_union_power_improve(player, prop_action, real_num)
    if real_num == nil then
        return
    end

	local action, con_type = unpack(prop_action.Action)
	player:set_operate_info(self.activity_id, OPERATE_PLAYER_DATA.ACTION, prop_action.ID, real_num)
	return OPERATE_SCORE_TYPE_INC, (prop_action.Score * real_num)
end

function CActivityBase:action_gacha(player, prop_action, real_type, real_num)
	if real_type == nil or real_num == nil then
		return
	end

	local action, con_type = unpack(prop_action.Action)
	if con_type ~= real_type then
		return 0
	end
	--更新玩家数据
	player:set_operate_info(self.activity_id, OPERATE_PLAYER_DATA.ACTION, prop_action.ID, real_num)

	return OPERATE_SCORE_TYPE_INC, (prop_action.Score * real_num)
end

function CActivityBase:action_kill_soldier(player, prop_action, real_type, real_num)
	if real_type == nil or real_num == nil then
		return
	end
	local action, con_type = unpack(prop_action.Action)
	if con_type ~= 0 and con_type ~= real_type then
		return 0
	end
	--更新玩家数据
	player:set_operate_info(self.activity_id, OPERATE_PLAYER_DATA.ACTION, prop_action.ID, real_num)
	
	return OPERATE_SCORE_TYPE_INC, (prop_action.Score * real_num)
end

function CActivityBase:action_occupy_city(player, prop_action, real_type, real_num)
end

function CActivityBase:action_black_market(player, prop_action, real_num)
	if real_num == nil then
		return
	end
	--更新玩家数据
	player:set_operate_info(self.activity_id, OPERATE_PLAYER_DATA.ACTION, prop_action.ID, real_num)
	
	return OPERATE_SCORE_TYPE_INC, (prop_action.Score * real_num)
end

function CActivityBase:action_resource_market(player, prop_action, real_num)
	if real_num == nil then
		return
	end
	--更新玩家数据
	player:set_operate_info(self.activity_id, OPERATE_PLAYER_DATA.ACTION, prop_action.ID, real_num)
	
	return OPERATE_SCORE_TYPE_INC, (prop_action.Score * real_num)
end

function CActivityBase:action_collect_grade_hero(player, prop_action)
	local action, con_quality = unpack(prop_action.Action)
    local real_num = 0
    local hero_list = player:get_hero()
    for k, v in pairs(hero_list or {}) do
        if con_quality == 0 then
            real_num = real_num + 1
        elseif con_quality ~= 0 and con_quality == v.quality then
        	real_num = real_num + 1
        end
    end
	--更新玩家数据
	player:update_operate_info(self.activity_id, OPERATE_PLAYER_DATA.ACTION, prop_action.ID, real_num)
	return OPERATE_SCORE_TYPE_INC, (prop_action.Score * real_num)
end




