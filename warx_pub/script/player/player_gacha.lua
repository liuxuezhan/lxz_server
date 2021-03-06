module("player_t" )

--[[
gacha_yinbi_num = 0  --银币抽卡次数
gacha_yinbi_free_num = 0  --银币抽卡免费次数
gacha_yinbi_cd = 0  --银币抽卡CD
gacha_yinbi_index = 0  --银币抽卡的位置
gacha_jinbi_num = 0  --金币抽卡次数
gacha_jinbi_free_num = 0  --金币抽卡免费次数
gacha_jinbi_cd = 0  --金币抽卡CD
gacha_jinbi_index = 0 --金币抽卡的位置
gacha_hunxia_index = 0  --魂匣抽卡的位置
gacha_gift = 0  --抽卡奖励值
--]]

PROP_YINBI_ID = 1
PROP_JINBI_ID = 2
PROP_HUNXIA_ID = 3
HUNXIA_LIMIT_VIP = 10

ITEM_JINGYIN_ID = resmng.ITEM_MIDDLE_SEARCH --20001002
ITEM_HUNXIA_ID = resmng.ITEM_HIGH_SEARCH --20001003

function gacha_on_day_pass(self)
    self.gacha_yinbi_num = 0  --银币抽卡次数
    self.gacha_yinbi_free_num = 0 --银币抽卡免费次数
    self.gacha_yinbi_cd = 0  --银币抽卡CD
    self.gacha_jinbi_num = 0  --金币抽卡次数
    self.gacha_jinbi_free_num = 0  --金币抽卡免费次数,
    self.gacha_jinbi_cd = 0  --金币抽卡CD
    self.gacha_gift = 0  --抽卡奖励值
    self.gacha_box = 0  --抽卡奖励值箱子
end

function get_gacha_status(self)
	local msg_send = {}
	msg_send.gift = self.gacha_gift
	msg_send.box = self.gacha_box

	--银币
	local prop_yinbi = resmng.prop_gacha_gacha[PROP_YINBI_ID]
	if prop_yinbi == nil then
		return
	end
	if gTime >= self.gacha_yinbi_cd and self.gacha_yinbi_free_num < prop_yinbi.Free then
		msg_send.yinbi = {0, 0, self.gacha_yinbi_free_num, prop_yinbi.Free, self.gacha_yinbi_first}
	else
		local dest_stamp = self.gacha_yinbi_cd
		msg_send.yinbi = {1, dest_stamp, self.gacha_yinbi_free_num, prop_yinbi.Free}
	end
	local buff_num = self:get_val("SilverGachaCount")
	msg_send.yinbi_left_num = {self.gacha_yinbi_num, buff_num}

	--金币
	local prop_jinbi = resmng.prop_gacha_gacha[PROP_JINBI_ID]
	if prop_jinbi == nil then
		return
	end
	local gold_item = self:get_item_num(ITEM_JINGYIN_ID)

	if gTime >= self.gacha_jinbi_cd and self.gacha_jinbi_free_num < prop_jinbi.Free then
		msg_send.jinbi = {0, 0, self.gacha_jinbi_free_num, prop_jinbi.Free, self.gacha_jinbi_first}
	elseif gold_item > 0 then
		msg_send.jinbi = {2, 0, self.gacha_jinbi_free_num, prop_jinbi.Free}
	else
		local dest_stamp = self.gacha_jinbi_cd
		msg_send.jinbi = {1, dest_stamp, self.gacha_jinbi_free_num, prop_jinbi.Free}
	end

	--魂匣
	local item_num = self:get_item_num(ITEM_HUNXIA_ID)
    if self.vip_lv >= HUNXIA_LIMIT_VIP or item_num > 0 then
        msg_send.hunxia = item_num 
    end


	Rpc:get_gacha_status_resp(self, msg_send)
end

function do_gacha(self, type)
	local prop_yinbi = resmng.prop_gacha_gacha[PROP_YINBI_ID]

	local msg_send = {}
	msg_send.result = 0
	msg_send.award = {}
	msg_send.gift = 0
	if type < GACHA_TYPE.YINBI_ONE or type > GACHA_TYPE.HUNXIA_TEN then
		msg_send.result = 1
		Rpc:do_gacha_resp(self, msg_send)
		return
	end

	local task_type = 0
	local task_num = 0
	if type == GACHA_TYPE.YINBI_ONE then
		if self:get_gacha_yinbi_limit() < 1 then
			if self.gacha_yinbi_free_num >= prop_yinbi.Free or gTime < self.gacha_yinbi_cd then
				msg_send.result = 2
				Rpc:do_gacha_resp(self, msg_send)
				return
			end
		end
		self:do_yinbi_one(msg_send)
		task_type = 1
		task_num = 1
	elseif type == GACHA_TYPE.YINBI_TEN then
		if self:get_gacha_yinbi_limit() < 10 then
			msg_send.result = 2
			Rpc:do_gacha_resp(self, msg_send)
			return
		end
		self:do_yinbi_ten(msg_send)
		task_type = 1
		task_num = 10
	elseif type == GACHA_TYPE.JINBI_ONE then
		self:do_jinbi_one(msg_send)
		task_type = 2
		task_num = 1
	elseif type == GACHA_TYPE.JINBI_TEN then
		self:do_jinbi_ten(msg_send)
		task_type = 2
		task_num = 10
	elseif type == GACHA_TYPE.HUNXIA_ONE then
		self:do_hunxia_one(msg_send)
		task_type = 3
		task_num = 1
	elseif type == GACHA_TYPE.HUNXIA_TEN then
		self:do_hunxia_ten(msg_send)
		task_type = 3
		task_num = 10
	end

	if msg_send.result == 0 then
		task_logic_t.process_task(self, TASK_ACTION.GACHA_MUB, task_type, task_num)
	    self:add_count( resmng.ACH_COUNT_GACHA, task_num )

	    --周限时活动
	    weekly_activity.process_weekly_activity(self, WEEKLY_ACTIVITY_ACTION.GACHA, task_type, task_num)
        --每日限时活动
	    daily_activity.process_daily_activity(self, DAILY_ACTIVITY_ACTION.GACHA, task_type, task_num)
	    --运营活动
	    operate_activity.process_operate_activity(self, OPERATE_ACTIVITY_ACTION.GACHA, task_type, task_num)
	end

	msg_send.gift = self.gacha_gift
	msg_send.type = type


	Rpc:do_gacha_resp(self, msg_send)
end

function get_gacha_yinbi_limit(self)
	local basic_num = 0
	local buff_num = self:get_val("SilverGachaCount")

	if self.gacha_yinbi_num >= buff_num then
		return 0
	end
	return buff_num - self.gacha_yinbi_num
end

function random_gacha(self, group_id)
	local sid = group_id * 1000
	local eid = (group_id + 1) * 1000 - 1
    local prop_gacha_group = resmng.prop_gacha_group
	local prop_tab = prop_gacha_group[sid]
	if prop_tab == nil then
		return nil
	end

	local p = math.random(prop_tab.TotWeight)
	local cur_p = 0
	for i = sid, eid, 1 do
		local prop_tmp = prop_gacha_group[i]
		if prop_tmp ~= nil then
			cur_p = cur_p + prop_tmp.Weight
			if cur_p >= p then
				local award = gacha_limit_t.get_gacha_world_limit(prop_tmp.Bonus)
				if award == nil then
					return prop_tmp.BonusPolicy, prop_tmp.Bonus, prop_tmp.Forcused
				else
					return award[1], award[2], 0
				end
			end
		end
	end
end

function do_yinbi_one(self, msg_send)
	local prop_yinbi = resmng.prop_gacha_gacha[PROP_YINBI_ID]
	if prop_yinbi == nil then
		msg_send.result = 1
		return
	end
	if self.gacha_yinbi_free_num < prop_yinbi.Free and gTime >= self.gacha_yinbi_cd then
		self.gacha_yinbi_free_num = self.gacha_yinbi_free_num + 1
		if self.gacha_yinbi_free_num >= prop_yinbi.Free then
			self.gacha_yinbi_cd = get_next_day_stamp(gTime)
		else
			self.gacha_yinbi_cd = gTime + prop_yinbi.FreeCD[self.gacha_yinbi_free_num]
		end
	else
		if self.silver < prop_yinbi.Price then
            msg_send.result = 3
            msg_send.silver = prop_yinbi.Price
            return
        end
        local con = {{resmng.CLASS_RES, resmng.DEF_RES_SILVER, prop_yinbi.Price}}
        self:consume(con, 1, VALUE_CHANGE_REASON.REASON_GACHA_YINBI_ONE)
        self.gacha_yinbi_num = self.gacha_yinbi_num + 1
    end
    
    local group = prop_yinbi.Group
    if self.gacha_yinbi_index > #group then
    	self.gacha_yinbi_index = 1
    end
    local group_id = 0
    if self.gacha_yinbi_first == true then
    	group_id = 21  --银币首抽固定组21
    	self.gacha_yinbi_first = false
    else
	    group_id = group[self.gacha_yinbi_index]
	    self.gacha_yinbi_index = self.gacha_yinbi_index + 1
	end

    local bonus_policy, bonus, focus = self:random_gacha(group_id)
    local is_chip = false 
    if bonus[1][1] == "hero" and self:get_hero_by_propid(bonus[1][2]) then
        is_chip = true
    end
    local res = self:add_bonus_not_notify(bonus_policy, bonus, VALUE_CHANGE_REASON.REASON_GACHA_AWARD_YINBI_ONE)
    if res == true then
        table.insert(msg_send.award, {bonus[1], focus, is_chip})
    	gacha_limit_t.set_gacha_world_limit(bonus)
    end
	self.gacha_gift = self.gacha_gift + prop_yinbi.GachaPoint
end

function do_yinbi_ten(self, msg_send)
	local prop_yinbi = resmng.prop_gacha_gacha[PROP_YINBI_ID]
	if prop_yinbi == nil then
		msg_send.result = 1
		return
	end

	if self.silver < prop_yinbi.ComboPrice then
        msg_send.result = 3
        msg_send.silver = prop_yinbi.ComboPrice
        return
    end
    local con = {{resmng.CLASS_RES, resmng.DEF_RES_SILVER, prop_yinbi.ComboPrice}}
    self:consume(con, 1, VALUE_CHANGE_REASON.REASON_GACHA_YINBI_TEN)
    self.gacha_yinbi_num = self.gacha_yinbi_num + 10

    local group = prop_yinbi.Group
    for i = 1, 10, 1 do
	    if self.gacha_yinbi_index > #group then
	    	self.gacha_yinbi_index = 1
	    end
	    local group_id = group[self.gacha_yinbi_index]
	    self.gacha_yinbi_index = self.gacha_yinbi_index + 1

	    local bonus_policy, bonus, focus = self:random_gacha(group_id)
        local is_chip = false 
        if bonus[1][1] == "hero" and self:get_hero_by_propid(bonus[1][2]) then
            is_chip = true
        end
	    local res = self:add_bonus_not_notify(bonus_policy, bonus, VALUE_CHANGE_REASON.REASON_GACHA_AWARD_YINBI_TEN)
	    --local res = self:add_bonus(bonus_policy, bonus, VALUE_CHANGE_REASON.REASON_GACHA_AWARD_YINBI_TEN)
        if res == true then
		    table.insert(msg_send.award, {bonus[1], focus, is_chip})
		    gacha_limit_t.set_gacha_world_limit(bonus)
		end
    end

    self.gacha_gift = self.gacha_gift + prop_yinbi.ComboGachaPoint
end

function do_jinbi_one(p, msg_send)
	local prop_jinbi = resmng.prop_gacha_gacha[PROP_JINBI_ID]
	if prop_jinbi == nil then
		msg_send.result = 1
		return
	end
	local gold_item = p:get_item_num(ITEM_JINGYIN_ID)
	if p.gacha_jinbi_free_num < prop_jinbi.Free and gTime >= p.gacha_jinbi_cd then
		p.gacha_jinbi_free_num = p.gacha_jinbi_free_num + 1
		if p.gacha_jinbi_free_num >= prop_jinbi.Free then
			p.gacha_jinbi_cd = get_next_day_stamp(gTime)
		else
			p.gacha_jinbi_cd = gTime + prop_jinbi.FreeCD[p.gacha_jinbi_free_num]
		end
	elseif gold_item > 0 then
		local con = {{resmng.CLASS_ITEM, ITEM_JINGYIN_ID, 1}}
	    p:consume(con, 1, VALUE_CHANGE_REASON.REASON_GACHA_DEC_ITEM)
	else
		if p.gold < prop_jinbi.Price then
            msg_send.result = 3
            msg_send.gold = prop_jinbi.Price
            return
        end
        local con = {{resmng.CLASS_RES, resmng.DEF_RES_GOLD, prop_jinbi.Price}}
        p:consume(con, 1, VALUE_CHANGE_REASON.REASON_GACHA_JINBI_ONE)
        p.gacha_jinbi_num = p.gacha_jinbi_num + 1
        --p:tlog_ten2("LotteryFlow",p.vip_lv,GACHA_TYPE.JINBI_ONE,prop_jinbi.Price)
    end

    local group = prop_jinbi.Group
    if p.gacha_jinbi_index > #group then
    	p.gacha_jinbi_index = 1
    end
    local group_id = 0
    if p.gacha_jinbi_first == true then
    	--group_id = 1  --金币首抽固定组1
        group_id = 300 + math.floor( p.propid / 1000 ) 
    	p.gacha_jinbi_first = false

    else
	    group_id = group[p.gacha_jinbi_index]
	    p.gacha_jinbi_index = p.gacha_jinbi_index + 1
	end

    local bonus_policy, bonus, focus = p:random_gacha(group_id)
    local is_chip = false 
    if bonus[1][1] == "hero" and p:get_hero_by_propid(bonus[1][2]) then
        is_chip = true
    end
    local res = p:add_bonus_not_notify(bonus_policy, bonus, VALUE_CHANGE_REASON.REASON_GACHA_AWARD_JINBI_ONE)
    --local res = p:add_bonus(bonus_policy, bonus, VALUE_CHANGE_REASON.REASON_GACHA_AWARD_JINBI_ONE)
    if res == true then
    	table.insert(msg_send.award, {bonus[1], focus, is_chip})
    	gacha_limit_t.set_gacha_world_limit(bonus)
    end

    p.gacha_gift = p.gacha_gift + prop_jinbi.GachaPoint
end

function do_jinbi_ten(p, msg_send)
	local prop_jinbi = resmng.prop_gacha_gacha[PROP_JINBI_ID]
	if prop_jinbi == nil then
		msg_send.result = 1
		return
	end

	if p.gold < prop_jinbi.ComboPrice then
        msg_send.result = 3
        msg_send.gold = prop_jinbi.ComboPrice
        return
    end
    local con = {{resmng.CLASS_RES, resmng.DEF_RES_GOLD, prop_jinbi.ComboPrice}}
    p:consume(con, 1, VALUE_CHANGE_REASON.REASON_GACHA_JINBI_TEN)
    p.gacha_jinbi_num = p.gacha_jinbi_num + 10

    local group = prop_jinbi.Group
    for i = 1, 10, 1 do
	    if p.gacha_jinbi_index > #group then
	    	p.gacha_jinbi_index = 1
	    end
	    local group_id = group[p.gacha_jinbi_index]
	    if group_id == GACHA_EXCHANGE_1[1] then
	    	group_id = GACHA_EXCHANGE_1[2]
	    end
	    p.gacha_jinbi_index = p.gacha_jinbi_index + 1

	    local bonus_policy, bonus, focus = p:random_gacha(group_id)
        local is_chip = false 
        if bonus[1][1] == "hero" and p:get_hero_by_propid(bonus[1][2]) then
            is_chip = true
        end
	    local res = p:add_bonus_not_notify(bonus_policy, bonus, VALUE_CHANGE_REASON.REASON_GACHA_AWARD_JINBI_TEN)
	    if res == true then
		    table.insert(msg_send.award, {bonus[1], focus, is_chip})
		    gacha_limit_t.set_gacha_world_limit(bonus)
		end
    end

    p.gacha_gift = p.gacha_gift + prop_jinbi.ComboGachaPoint
    --p:tlog_ten2("LotteryFlow",p.vip_lv,GACHA_TYPE.JINBI_TEN,prop_jinbi.ComboPrice)
end

function do_hunxia_one(self, msg_send)
	local prop_hunxia = resmng.prop_gacha_gacha[PROP_HUNXIA_ID]
	if prop_hunxia == nil then
		msg_send.result = 1
		return
	end

	local item_num = self:get_item_num(ITEM_HUNXIA_ID)
    if item_num <= 0 then
        local vip = self.vip_lv
        if vip < HUNXIA_LIMIT_VIP then
            msg_send.result = 4
            return	
        end

        if not self:is_vip_enable() then
            msg_send.result = 5
            return	
        end

		if self.gold < prop_hunxia.Price then
	        msg_send.result = 3
	        msg_send.gold = prop_hunxia.Price
	        return
	    end
	    local con = {{resmng.CLASS_RES, resmng.DEF_RES_GOLD, prop_hunxia.Price}}
	    self:consume(con, 1, VALUE_CHANGE_REASON.REASON_GACHA_HUNXIA_ONE)
	else
		local con = {{resmng.CLASS_ITEM, ITEM_HUNXIA_ID, 1}}
	    self:consume(con, 1, VALUE_CHANGE_REASON.REASON_GACHA_DEC_ITEM)
	end

    local group = prop_hunxia.Group
    if self.gacha_hunxia_index > #group then
    	self.gacha_hunxia_index = 1
    end
    local group_id = group[self.gacha_hunxia_index]
    self.gacha_hunxia_index = self.gacha_hunxia_index + 1

    local bonus_policy, bonus, focus = self:random_gacha(group_id)
    local is_chip = false 
    if bonus[1][1] == "hero" and self:get_hero_by_propid(bonus[1][2]) then
        is_chip = true
    end
    local res = self:add_bonus_not_notify(bonus_policy, bonus, VALUE_CHANGE_REASON.REASON_GACHA_AWARD_HUNXIA_ONE)
    if res == true then
	    table.insert(msg_send.award, {bonus[1], focus, is_chip})
	    gacha_limit_t.set_gacha_world_limit(bonus)
	end

    self.gacha_gift = self.gacha_gift + prop_hunxia.GachaPoint
    local left_num = self:get_item_num(ITEM_HUNXIA_ID)
    if left_num > 0 then
    	msg_send.left_hunxia = left_num
    end
    if self.vip_lv >= HUNXIA_LIMIT_VIP then
    	msg_send.open_hunxia = true
    end
end

function do_hunxia_ten(self, msg_send)
	local prop_hunxia = resmng.prop_gacha_gacha[PROP_HUNXIA_ID]
	if prop_hunxia == nil then
		msg_send.result = 1
		return
	end
	local vip = self.vip_lv
	if vip < HUNXIA_LIMIT_VIP then
		msg_send.result = 4
		return	
    end

	if not self:is_vip_enable() then
		msg_send.result = 5
		return	
	end

	if self.gold < prop_hunxia.ComboPrice then
        msg_send.result = 3
        msg_send.gold = prop_hunxia.ComboPrice
        return
    end

    local con = {{resmng.CLASS_RES, resmng.DEF_RES_GOLD, prop_hunxia.ComboPrice}}
    self:consume(con, 1, VALUE_CHANGE_REASON.REASON_GACHA_HUNXIA_TEN)

    local group = prop_hunxia.Group
    for i = 1, 10, 1 do
	    if self.gacha_hunxia_index > #group then
	    	self.gacha_hunxia_index = 1
	    end
	    local group_id = group[self.gacha_hunxia_index]
	   	if group_id == GACHA_EXCHANGE_2[1] then
	    	group_id = GACHA_EXCHANGE_2[2]
	    end
	    self.gacha_hunxia_index = self.gacha_hunxia_index + 1

        local bonus_policy, bonus, focus = self:random_gacha(group_id)
        local is_chip = false 
        if bonus[1][1] == "hero" and self:get_hero_by_propid(bonus[1][2]) then
            is_chip = true
        end
        local res = self:add_bonus_not_notify(bonus_policy, bonus, VALUE_CHANGE_REASON.REASON_GACHA_AWARD_HUNXIA_TEN)
        if res == true then
		    table.insert(msg_send.award, {bonus[1], focus, is_chip})
		    gacha_limit_t.set_gacha_world_limit(bonus)
		end
    end

    self.gacha_gift = self.gacha_gift + prop_hunxia.ComboGachaPoint
end

function get_gacha_box(self)
	if self.gacha_box >= resmng.GACHA_PIONT_3 then
		Rpc:get_gacha_box_resp(self, 1)
		return
	end
	local index = self.gacha_box + 1
	local prop_tab = resmng.prop_gacha_piont[index]
	if prop_tab == nil then
		Rpc:get_gacha_box_resp(self, 1)
		return
	end
	if self.gacha_gift < prop_tab.Require then
		Rpc:get_gacha_box_resp(self, 1)
		return
	end
	self.gacha_box = index
	self.gacha_gift = self.gacha_gift - prop_tab.Require
	self:add_bonus(prop_tab.BonusPolicy, prop_tab.Bonus, VALUE_CHANGE_REASON.REASON_GACHA_GIFT_BOX)

	Rpc:get_gacha_box_resp(self, 0)
end



