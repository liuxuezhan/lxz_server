module("player_t")

function on_day_pass_month_award(self)
    local cross_day = get_diff_days(gTime, gSysStatus.start) + 1
    local cur_month = math.ceil(cross_day/28)
    if cur_month > self.month_award_cur then
        self.month_award_cur = cur_month 
        self.month_award_com = 0
    end
end

function month_award_compensation(self)
    local limit_num = 2
    if limit_num <= self.month_award_com then
        return false
    end
    self.month_award_com = self.month_award_com + 1
    return self:month_award_get_award()
end

function month_award_get_award(self)
    if get_diff_days(gTime, self.month_award_time) <= 0 then
        return false
    end
    self.month_award_time = gTime
    local cross_day = get_diff_days(gTime, gSysStatus.start) + 1
    local month_day = cross_day % #resmng.prop_month_award
    local prop = resmng.prop_month_award[month_day]
    local ratio = self:month_award_get_extra(prop)
    self:add_bonus(prop.BonusPolicy, prop.Bonus, VALUE_CHANGE_REASON.REASON_MONTH_AWARD, ratio)
    --任务 
    task_logic_t.process_task(self, TASK_ACTION.MONTH_AWARD, 1)
    return true
end

function month_award_get_extra(self, prop)
    if prop == nil or prop.Extra == nil then
        return 1
    end
    local vip_level = prop.Extra[1]
    local vip_ratio = prop.Extra[2]
    if vip_level <= self.vip_lv then
        return vip_ratio
    end
    return 1
end

function month_award_is_checked(self)
    if get_diff_days(gTime, self.month_award_time) <= 0 then
        return true
    end
    return false
end















